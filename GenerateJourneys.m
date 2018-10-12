%% Generates sampled journeys *after InitialiseModel
clearvars -except D Lambda InfoOfStations NumStation NumWeekdays
tic

%% Poisson distribution

Poiss = poissrnd(Lambda);
Poiss = round(Poiss ./ NumWeekdays + 0.375); % Normalise by no. of weekdays
% +0.375 is a design choice by calibration
% Lower limit for having a journey generated = 0.125

%%% Weighted ceil/floor decision (time-consuming)

%for Tslice = 1:72
%    for cnt_i = 1:NumStation
%        for cnt_j = 1:NumStation
%            decimal = Poiss(cnt_i,cnt_j,Tslice) - floor(Poiss(cnt_i,cnt_j,Tslice));
%            if decimal > 0
%                increment = datasample([1,0],1,'Weights',[decimal,1-decimal]);
%                Poiss(cnt_i,cnt_j,Tslice) = floor(Poiss(cnt_i,cnt_j,Tslice)) + increment;
%            end
%        end
%    end
%end

%% Initialisation

NumJourney = sum(sum(sum(Poiss)));
Journey = zeros(NumJourney,4);  % [ startTslice endTslice startSta endSta ]
JnyCnt = 0;

%% Generate Journeys for every triplet(i,j,t)

for Tslice = 1:72  % for each (i,j,t)
    for cnt_i = 1:NumStation
        for cnt_j = 1:NumStation
            NumJny_ijt = Poiss(cnt_i,cnt_j,Tslice);
            % No. of journeys going to be sampled for particular (i,j,t)
            
            if NumJny_ijt > 0
                D_ij = datasample(D{cnt_i,cnt_j},NumJny_ijt,'Replace',true);
                D_ij = D_ij + rand(size(D_ij)) *60*20;
                % Journey may start at any second over a particular Tslice
                % (assume uniform distribution, hence rand)
            
                endTslice = mod(Tslice + round(D_ij/60/20)-1,72) +1;
                % tranform from sec to Tslice (i.e. 1 to 72)
                
                %%% Put the sampled journey into Journey
                
                for JnyCnt_ij = 1:length(D_ij)
                    JnyCnt = JnyCnt + 1;
                    Journey(JnyCnt,:) = [Tslice,endTslice(JnyCnt_ij),cnt_i,cnt_j];
                end
            end
        end
    end
end

toc