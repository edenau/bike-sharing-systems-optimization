%% Defines neighbourhood *after GenerateJourneys
%  MinNbhDistance == 700.8876 metres
clearvars -except InfoOfStations Journey NumStation
tic

NbhDistance = zeros(NumStation);

%% Compute distance with every (i,j) station pair

for cnt_s = 1:NumStation
    for cnt_n = 1:NumStation
        if cnt_s == cnt_n
            NbhDistance(cnt_s,cnt_n) = Inf;  % Assume distance i->i is infinity
        else
            startLocation = InfoOfStations(cnt_s,3:4);
            endLocation = InfoOfStations(cnt_n,3:4);
            NbhDistance(cnt_s,cnt_n) = HaversineDistance(startLocation,endLocation)*1000;
            % distances in metre
        end
    end
end

%% Compute min. neighbourhood distance required

AllMinNbhDistance = max(min(NbhDistance,[],2));
% min: distance with the nearest station, for every station
% max: make sure every station has at least one neighbour
fprintf('Min. distance defining neighbourhood is %.2f m\n',AllMinNbhDistance);

MinNbhDistance = (min(NbhDistance,[],2));
DistanceThreshold = 450; % can be changed
DistantStations = find(MinNbhDistance>DistanceThreshold);
% Find stations that are lonely 
% i.e. no other stations within DistanceThreshold

NbhDistance(NbhDistance == Inf) = 0;  % distance i->i is zero 

toc