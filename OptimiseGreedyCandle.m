%% Optimises in greedy way - candle plot in time 50 to 58
%clearvars -except Arrival capacity DistantStations e eta iifl NbhDistance NumStation StrangerSet NbhSet
tic

%% Initialise

%ProblemSize = NumStation;
ProblemSize = 150;
distance = NbhDistance(1:ProblemSize,1:ProblemSize);
%NbhVec = e(1:ProblemSize,1:ProblemSize);
sad_total = 0;

fl_record_g = Inf(ProblemSize,Tslice);
solution_g = Inf(ProblemSize,ProblemSize,72);

obj_g = Inf(72,1);
residual_g = zeros(72,1); % well, it is hard constraint 
seq_choice = Inf(72,1);

%% Construct NbhSet in order of distance

NbhOrderSet = Inf(ProblemSize-1,ProblemSize); % column vectors
distance_bar = NbhDistance(1:ProblemSize,1:ProblemSize);
for cnt = 1:ProblemSize
    distance_bar(cnt,cnt) = Inf;
    for cnt2 = 1:(ProblemSize-1)
        [val, ind] = min(distance_bar(:,cnt));
        NbhOrderSet(cnt2,cnt) = ind;
        distance_bar(ind,cnt) = Inf;
    end
end

%% Generate Greedy Sequence
NumOfSeq = 100;
seq = Inf(ProblemSize,NumOfSeq);
obj_seq = Inf(72,NumOfSeq);

seed = RandStream('mlfg6331_64','Seed',1); % For reproducibility
for cnt = 1:NumOfSeq
    seq(:,cnt) = datasample(seed,1:ProblemSize,ProblemSize,'Replace',false);
end

%% Dynamics

for Tslice = 1:72
    
    %%% Fill level dynamics
    if Tslice == 1
        fl = iifl(1:ProblemSize);
    else
        fl = fl + eta(1:ProblemSize,Tslice-1) ...
            + sum(solution_g(:,:,Tslice-1),1)' ...
            - sum(solution_g(:,:,Tslice-1),2);
    end
    
    sad = -fl; sad(sad<0) = 0; sad_total = sad_total +sum(sad);
    fl(fl<0) = 0; % under-empty stations will be set as empty
    % some customers would not be able to depart
    
    fl_record_g(:,Tslice) = fl;
    emptylevel = capacity(1:ProblemSize)-fl;
    emptylevel(emptylevel<0) = 0; % avoid unbounded problem
 
    %% Fill u_ss first
    
    u = zeros(ProblemSize,ProblemSize);
    empty_temp = emptylevel;
    arrival_temp = Arrival(1:ProblemSize,Tslice);
    for cnt = 1:ProblemSize
        u(cnt,cnt) = min(empty_temp(cnt),arrival_temp(cnt));
        empty_temp(cnt) = empty_temp(cnt) - u(cnt,cnt);
        arrival_temp(cnt) = arrival_temp(cnt) - u(cnt,cnt);
    end
    
    %% Greedy
    
    for cnt_seq = 1:NumOfSeq
        u_bar = u;
        empty_bar = empty_temp;
        arrival_bar = arrival_temp;
        for cnt_station = 1:ProblemSize
            cnt_nbh = 0;
            station = seq(cnt_station,cnt_seq);
            while arrival_bar(station) > 0
                cnt_nbh = cnt_nbh +1;
                neighbour = NbhOrderSet(cnt_nbh,station);
                
                u_bar(station,neighbour) = min(empty_bar(neighbour),arrival_bar(station));
                empty_bar(neighbour) = empty_bar(neighbour) - u_bar(station,neighbour);
                arrival_bar(station) = arrival_bar(station) - u_bar(station,neighbour);
            end
        end
        
        objective_bar = sum(sum(u_bar .* distance));
        obj_seq(Tslice,cnt_seq) = objective_bar;
        if objective_bar < obj_g(Tslice)
            solution_g(:,:,Tslice) = u_bar;
            obj_g(Tslice) = objective_bar;
            seq_choice(Tslice) = cnt_seq;
        end
    end
    
end

toc

%% Candlestick Plotting

boxplot(obj_seq(50:58,:)','Widths',0.6,'Labels',50:58)
axis([0.5 9.5 0 650])
hold on
plot(1:9,obj_cen(50:58,1))
xlabel('Time Slice')
ylabel('Primal Objective (km)')