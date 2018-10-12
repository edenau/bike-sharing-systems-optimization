%% Deletes Distant Stations *after SimulateStations
%%% make sure not to run this twice
tic

Arrival(DistantStations,:) = [];
capacity(DistantStations,:) = [];
eta(DistantStations,:) = [];
iifl(DistantStations,:) = [];
NbhSet(DistantStations) = [];
StrangerSet(DistantStations) = [];
NumStation = NumStation - length(DistantStations);

toc