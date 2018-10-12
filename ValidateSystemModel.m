%% Constructs and validates a model from historical data
clear  % clear workspace
tic    % measure execution time

%% Data input

J1 = csvread('./data/data1.csv');  % 13/09/2017 to 19/09/2017
J2 = csvread('./data/data2.csv');  % 06/09/2017 to 12/09/2017
J3 = csvread('./data/data3.csv');  % 30/08/2017 to 05/09/2017
J4 = csvread('./data/data4.csv');  % 23/08/2017 to 29/08/2017
J5 = csvread('./data/data5.csv');  % 15/08/2017 to 22/08/2017
J6 = csvread('./data/data6.csv');  % 08/08/2017 to 14/08/2017
J7 = csvread('./data/data7.csv');  % 01/08/2017 to 07/08/2017
J = [J1;J2;J3;J4;J5;J6;J7]; % historical data
clear J1 J2 J3 J4 J5 J6 J7

NumDays = datenum(2017,9,19) - datenum(2017,8,1) +1;
NumWeekdays = 36;  % count manually
NumWeekends = NumDays - NumWeekdays;

InfoOfStations = csvread('./data/station_info.csv');  
% [ stationID capacity lat lon ]

[Jrow,Jcol] = size(J);
[Inforow,Infocol] = size(InfoOfStations);
NumStation = Inforow;

%% Initialisation

% 72 time slices for a day
DayTsliceCnt = zeros(72,1);  % total no. of journeys in weekdays
EndTsliceCnt = zeros(72,1);  % total no. of journeys in weekends

MaxDur = 60;  % only consider journeys with duration within 60 min
DurCnt = zeros(MaxDur,1);  % total no. of particular durations
AvgWeekdayDuration = 0;
WeekdayJnyCnt = 0;

MaxSpeed = 20*3;  % only consider bike speed under 20 km/h
SpeedCnt = zeros(MaxSpeed,1);

Lambda = zeros(NumStation,NumStation,72);

%% Every journey

for HistJnyCnt = 1:Jrow % for every journey
    
    startStation = find(InfoOfStations(:,1) == J(HistJnyCnt,14));  % start station
    endStation = find(InfoOfStations(:,1) == J(HistJnyCnt,8));   % end station
    
    startD = J(HistJnyCnt,9:11);   % journey start date (Day,Month,Year)
    startT = J(HistJnyCnt,12:13);  % journey start time (Hour,Minute)
    Tslice = startT(1)*3 + floor(startT(2)/20) +1; 
    % +1 because counting starts at 1 in MATLAB
    
    %%% Identify Tslice for start of journey AND weekday/weekend
    
    if IsWeekend(startD(1),startD(2),startD(3)) == 1  % if weekend
        EndTsliceCnt(Tslice) = EndTsliceCnt(Tslice) + 1; else   
        DayTsliceCnt(Tslice) = DayTsliceCnt(Tslice) + 1;
    end
    
    %% Identify duration AND speed
    
    %%% Compute duration
    
    DurationInMin = round(J(HistJnyCnt,1)/60);  % Duration in min
    if DurationInMin <= MaxDur && DurationInMin > 0
        % Ignore journeys with duration 0 or > MaxDur
        DurCnt(DurationInMin) = DurCnt(DurationInMin) + 1;
        
        if IsWeekend(startD(1),startD(2),startD(3)) == 0
            % Only weekdays are considered for AvgWeekdayDuration
            AvgWeekdayDuration = AvgWeekdayDuration + DurationInMin;
            WeekdayJnyCnt = WeekdayJnyCnt + 1;
        end
        
        %%% Compute distance
        
        if ~isempty(startStation) && ~isempty(endStation)
            startLocation = InfoOfStations(startStation,3:4);
            endLocation = InfoOfStations(endStation,3:4);

            dist = HaversineDistance(startLocation,endLocation);  % euclidean distance
        end
        
        %%% Compute speed
        
        Speedslice = round(dist/DurationInMin*180) +1;  % km/(3hrs)
        if Speedslice <= MaxSpeed && Speedslice > 0
            SpeedCnt(Speedslice) = SpeedCnt(Speedslice) + 1;
        end
    end
end

%% Compute no. of journeys per weekday for each Tslice

JnyTsliceCnt = zeros(72,1);  % no. of journeys per weekday

for Tslice = 1:72
    JnyTsliceCnt(Tslice) = round(DayTsliceCnt(Tslice) / NumWeekdays);
end

%% Validity Check

%%% Average duration in weekdays
AvgWeekdayDuration = AvgWeekdayDuration / WeekdayJnyCnt;  % onPaper = 15
fprintf('Avg. duration in weekdays is %.1f min\n',AvgWeekdayDuration);

%%% Average no. of journeys in weekdays
AvgWeekdayJnys = sum(JnyTsliceCnt);    % onPaper = 26500
fprintf('Avg. no. of journeys in weekdays is %d \n',AvgWeekdayJnys);

%%% onPaper graphs

figure('Name','Average Weekday Departures')
bar(0:1/3:71/3,DayTsliceCnt/NumWeekdays,1)  
% Normalise x-axis into hours
% Normalise y-axis into counts per day
% 1 is the full bar width
xlabel('Hour')
ylabel('Departures')
axis([0,71/3,0,max(DayTsliceCnt)/NumWeekdays])
set(gca,'fontsize',15)

figure('Name','Average Weekend Departures')
bar(0:1/3:71/3,EndTsliceCnt/NumWeekends,1)  % ditto
xlabel('Hour')
ylabel('Departures')
axis([0,71/3,0,max(DayTsliceCnt)/NumWeekdays])
set(gca,'fontsize',15)

figure('Name','Journey Duration Distribution')
bar(1:MaxDur,DurCnt,1)     
xlabel('Duration (minutes)')
ylabel('Journeys')
axis([1,MaxDur,0,max(DurCnt)])
set(gca,'fontsize',15)

figure('Name','Jouney Speed Distribution')
bar(0:1/3:(MaxSpeed-1)/3,SpeedCnt,1) 
xlabel('Speed (km/h)')
ylabel('Journeys')
axis([0,(MaxSpeed-1)/3,0,max(SpeedCnt)])
set(gca,'fontsize',15)
toc