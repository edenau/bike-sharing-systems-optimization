%% Simulates stations with their fill levels *after GenerateJourneys
clearvars -except InfoOfStations Journey NumStation
tic

%% Initialisation
NbhDef = 0.701;  % no stations have no neighbours
%NbhDef = 0.45;  % 7 stations have no neighbours
% manual definition for 'neighbourhood' in km
%  MinNbhDistance == 0.7008876 km

NbhDistance = zeros(NumStation);

NbhSet = cell(NumStation,1);
StrangerSet = cell(NumStation,1);
e = zeros(NumStation);

DistantStations = [];

%% Construct NbhSet/StrangerSet for every station and identify DistantStations

for cnt_i = 1:NumStation
    for cnt_j = 1:NumStation
        if cnt_i == cnt_j
            NbhDistance(cnt_i,cnt_j) = 0;
            NbhSet{cnt_i} = cat(1,NbhSet{cnt_i},cnt_j);
            e(cnt_i,cnt_j) = 1;
        else
            Location_i = InfoOfStations(cnt_i,3:4);
            Location_j = InfoOfStations(cnt_j,3:4);
            NbhDistance(cnt_i,cnt_j) = HaversineDistance(Location_i,Location_j);
            % distances in km
            
            if NbhDistance(cnt_i,cnt_j) < NbhDef  % qualified as being a neighbour
                NbhSet{cnt_i} = cat(1,NbhSet{cnt_i},cnt_j);
                e(cnt_i,cnt_j) = 1;
            else
                StrangerSet{cnt_i} = cat(1,StrangerSet{cnt_i},cnt_j);
            end
        end
    end
    
    if length(NbhSet{cnt_i}) == 1  % if station s only has itself as neighbour
        DistantStations = [DistantStations, cnt_i];
    end
end

%% Simulate fill level 

[Journeyrow,Journeycol] = size(Journey);

Departure = zeros(NumStation,72);
Arrival = zeros(NumStation,72);
% no. of bikes departing/arriving station s at timeslice t

fl_zeroinitial = zeros(NumStation,72);
% (cumulative) fill level of station s at timeslice t
% assuming initial fill level is zero
eta = zeros(NumStation,72);
% net change in fill level of station s at timeslice t
iifl = zeros(NumStation,1);
% ideal initial fill level of station s
capacity = zeros(NumStation,1);
% maximum capacity of station n

%%% Compute Departure(s,t) and Arrival(s,t)

for JnyCnt = 1:Journeyrow
    startTslice = Journey(JnyCnt,1);
    endTslice = Journey(JnyCnt,2);
    startStation = Journey(JnyCnt,3);
    endStation = Journey(JnyCnt,4);
    
    Departure(startStation,startTslice) = Departure(startStation,startTslice) + 1;
    Arrival(endStation,endTslice) = Arrival(endStation,endTslice) + 1;
end

%%% Compute ita(s,t)

for Tslice = 1:72
    for cnt_s = 1:NumStation
        eta(cnt_s,Tslice) = Arrival(cnt_s,Tslice) - Departure(cnt_s,Tslice);
        if Tslice == 1
            fl_zeroinitial(cnt_s,Tslice) = 0 + eta(cnt_s,Tslice);
        else
            fl_zeroinitial(cnt_s,Tslice) = fl_zeroinitial(cnt_s,Tslice-1) + eta(cnt_s,Tslice);
        end
    end
end

%%% Optimise fl_zeroinitial(s) & capacity(s)

for cnt_s = 1:NumStation
    capacity(cnt_s) = InfoOfStations(cnt_s,2);
    iifl(cnt_s) = min(capacity(cnt_s),max(0,-min(fl_zeroinitial(cnt_s,:))));  
    % prevent <0 or >capacity value
end

toc