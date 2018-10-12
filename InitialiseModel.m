%% Constructs a model with historical data
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
NumWeekdays = 36;  % count manually

InfoOfStations = csvread('./data/station_info.csv');  
% [ stationID capacity lat lon ]

[Jrow,Jcol] = size(J);
[Inforow,Infocol] = size(InfoOfStations);
NumStation = Inforow;

%% Initialisation

% 72 time slices for a day
TsliceCnt = zeros(72,1);  % total no. of journeys in *weekdays*

% Lambda(i,j,t) and D(i,j) please refer to the paper
Lambda = zeros(NumStation,NumStation,72);
D = cell(NumStation,NumStation);

%% Log every historical journey

for HistJnyCnt = 1:Jrow % for every journey
    startD = J(HistJnyCnt,9:11);   % journey start date (Day,Month,Year)
    
    if IsWeekend(startD(1),startD(2),startD(3)) == 0  % if weekday  
        
        %%% Compute departure Tslice
        
        startT = J(HistJnyCnt,12:13);  % journey start time (Hour,Minute)
        Tslice = startT(1)*3 + floor(startT(2)/20) +1; 
        % +1 because counting starts at 1 in MATLAB
        TsliceCnt(Tslice) = TsliceCnt(Tslice) + 1;
        
        %%% Increment Lambda(i,j,t) and add element into D(i,j)
        
        startStation = find(InfoOfStations(:,1) == J(HistJnyCnt,14));  % start station
        endStation = find(InfoOfStations(:,1) == J(HistJnyCnt,8));   % end station
        
        if ~isempty(startStation) && ~isempty(endStation)
            % e.g. station 201 exists in data of bike journeys
            % but not in station_info.csv
            % TfL is a joke
            Lambda(startStation,endStation,Tslice) = Lambda(startStation,endStation,Tslice) + 1;
            % Only weekdays are considered for Lambda
            
            Duration = J(HistJnyCnt,1);  % duration in sec
            D{startStation,endStation} = cat(1,D{startStation,endStation},Duration);
            % Add a duration into the D(i,j) array
        end
    end
end

toc