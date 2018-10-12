%% Truncated Decentralised followed by Greedy Algorithm
clearvars -except Arrival capacity e eta fl_record iifl NbhDistance NumStation 
addpath(genpath('/Applications/MATLAB_R2014b.app/toolbox/yalmip/'));  
% add yalmip solver to matlab search path
tic
%% Initialise optimisation variables/constraints/objective

%ProblemSize = NumStation;
ProblemSize = 150;
distance = NbhDistance(1:ProblemSize,1:ProblemSize);
NbhVec = e(1:ProblemSize,1:ProblemSize);
k_count = Inf(72,1);

interim = Inf(ProblemSize,ProblemSize,72); % decision variable
solution = Inf(ProblemSize,ProblemSize,72); % decision variable

obj_td = Inf(72,1);
residual_td = Inf(72,1);

obj_g = Inf(72,1);
residual_g = zeros(72,1); % well, it is hard constraint 
seq_choice = Inf(72,1);
toc_td = zeros(72,1);
toc_greedy = zeros(72,1);

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

seed = RandStream('mlfg6331_64','Seed',1); % For reproducibility
for cnt = 1:NumOfSeq
    seq(:,cnt) = datasample(seed,1:ProblemSize,ProblemSize,'Replace',false);
end

StartT = 50; % avoid calculating all the shits again
EndT = 58;
for Tslice = StartT:EndT
    %% Fill level dynamics
    
    if Tslice == StartT
        if StartT == 1
            fl = iifl(1:ProblemSize);
        else
            fl = fl_record(1:ProblemSize,StartT-1);
        end
    else
        
        fl = fl + eta(1:ProblemSize,Tslice-1) ...
            + sum(solution(:,:,Tslice-1),1)' ...
            - sum(solution(:,:,Tslice-1),2);
        % carry the previous fill level
        % include the net change eta
        % consider the extra #bikes deviated to here at time t-1
        % consider #bikes left at time t-1
    end
    
    fl(fl<0) = 0; % under-empty stations will be set as empty
    % some customers would not be able to depart
    
    emptylevel = capacity(1:ProblemSize)-fl;    
    % It should not be over-full after optimising
    if min(emptylevel) < 0 % If so, error message
        fprintf('Station %d with empty level %d at Tslice %d\n', ...
            find(emptylevel == min(emptylevel),1), min(emptylevel), Tslice);
    end
    
    emptylevel(emptylevel<0) = 0; % avoid unbounded problem
    
    diagonal = min(Arrival(1:ProblemSize,Tslice),emptylevel);
    for cnt = 1:ProblemSize
        emptylevel(cnt) = max(capacity(cnt) * 0.75 - fl(cnt), diagonal(cnt)); % Capacity Tightening
    end
    %% Distributed Constrained Optimisation
    
    skipflag = false(1);
    converged = false(1);
    arrival_ok = false(1);
    
    beta = 10;
    c = Inf(ProblemSize,1);
    k_max = 100+1; % NUMBER OF ITERATIONS
    k_si = k_max;
    k = 1;
    
    primal_obj_x = Inf(k_max,1);
    primal_obj_xhat = Inf(k_max,1);
    viola_x = Inf(k_max,1);
    viola_xhat = Inf(k_max,1);
    
    x = Inf(ProblemSize,ProblemSize,k_max); % row vectors
    xhat = Inf(ProblemSize,ProblemSize,k_max); % row vectors
    xhat(:,:,1) = zeros(ProblemSize,ProblemSize);
    for i = 1:ProblemSize
        xhat(i,i,1) = Arrival(i,Tslice);
        % The optimised case neglecting capacity-fl inequality constraints
    end
    
    lamb = Inf(ProblemSize,ProblemSize,k_max); % row vectors
    lamb(:,:,1) = zeros(ProblemSize,ProblemSize); % lamb(1) = 0
    l = Inf(ProblemSize,ProblemSize,k_max); % row vectors
    lamb_convergence = Inf(k_max,1); % lamb convergence rate at each iteration
    
    % Skip computation if no Arrivals at all
    if sum(Arrival(1:ProblemSize,Tslice)) == 0
        skipflag = true(1);
        solution(:,:,Tslice) = zeros(ProblemSize,ProblemSize);
    end

    %% Repeat until convergence
    
    sum_tocI = zeros(ProblemSize,1);
    if ~skipflag % if there are some Arrivals
        while k<k_max && ~converged && ~arrival_ok
            c(k) = beta/k;
            % Implement two different sequences for xhat/xtilta
            if k < k_si
                cc = c(k)/sum(c(1:k));
            else
                cc = c(k)/sum(c(k_si:k));
            end
            
            %diagonal = min(Arrival(1:ProblemSize,Tslice),emptylevel);
            % we know u_ss in advance
            fulllist = zeros(ProblemSize,1);
            countfull = 0;
            for checki = 1:ProblemSize
                if emptylevel(checki) - diagonal(checki) == 0
                    countfull = countfull+1;
                    fulllist(countfull) = checki;
                end
            end
            fulllist = fulllist(1:countfull);
            % If station is full, do not receive any 
            for i = 1:ProblemSize
                ticI = tic;
                l(i,:,k) = mean(lamb(:,:,k),1);  % by considering a(i,j) = 1/m
        
                opt = sdpvar(ProblemSize,1); % row vector illustrated as a column
                constraints = [opt >= 0, sum(opt) == Arrival(i,Tslice), opt(i) == diagonal(i)];
                for counti = 1:countfull % if a station is full, do not receive any
                    if fulllist(counti) ~= i
                        constraints = [constraints, opt(fulllist(counti)) == 0];
                    end
                end
                %local constraints
                objective =  distance(i,:) * opt + l(i,:,k) * (opt - emptylevel./ProblemSize);  
                options = sdpsettings('verbose',0,'solver','linprog');
                sol = optimize(constraints,objective,options);

                if sol.problem == 0  % no problem
                    x(i,:,k+1) = value(opt); % row vector
                    primal_obj_x(k+1) = value(objective);
                else
                    display('Something went wrong');
                    sol.info
                    yalmiperror(sol.problem)
                end
        
                lamb_next = l(i,:,k) + c(k) * (x(i,:,k+1) - emptylevel'./ProblemSize);
                lamb_next(lamb_next <0) = 0; %projection
                lamb(i,:,k+1) = lamb_next;
                xhat(i,:,k+1) = xhat(i,:,k) + cc * (x(i,:,k+1)-xhat(i,:,k));
                
                tocI = toc(ticI);
                %fprintf('Agent %d with elapsed time', i);toc(ticI);
                sum_tocI(i) = sum_tocI(i) + tocI;
            end
            
            
            primal_obj_x(k+1) = sum(sum(x(:,:,k+1) .* distance));
            primal_obj_xhat(k+1) = sum(sum(xhat(:,:,k+1) .* distance));
            v = sum(x(:,:,k+1),1) - emptylevel'; v(v <0) = 0; viola_x(k+1) = sum(v);
            v = sum(xhat(:,:,k+1),1) - emptylevel'; v(v <0) = 0; viola_xhat(k+1) = sum(v);
     
            %%% Check Convergence
        
            if k > 1
                temp = 0;
                for checki = 1:ProblemSize
                    lamb_change = lamb(checki,:,k+1)-lamb(checki,:,k);
                    temp = temp + norm(lamb_change) ./ norm(lamb(checki,:,k));
                end
                lamb_convergence(k) = temp ./ ProblemSize;

            end
            % if almost converges AND still in phase 1
            if lamb_convergence(k) < 0.005 && k < k_si
                k_si = k+1;
            end
            
            converged = true(1);
            for checki = 1:ProblemSize
                if sum(round(xhat(:,checki,k+1))) > emptylevel(checki)  
                    % if any column violates filllevel constraints
                    converged = false(1);
                    break;
                end
            end
            
            if converged
                arrival_ok = true(1);
                for checki = 1:ProblemSize
                    diff = sum(round(xhat(checki,:,k+1))) - Arrival(checki,Tslice);
                    % if any row (after round off) gets incorrect #Arrival
                    
                    if diff > 0
                        converged = false(1);
                        for cnt = 1:diff
                            RoundVec = xhat(checki,:,k+1) - round(xhat(checki,:,k+1));
                            [mm,ii] = min(RoundVec);
                            xhat(checki,ii,k+1) = floor(xhat(checki,ii,k+1));
                        end
                    
                    elseif diff < 0
                        converged = false(1);
                        for cnt = 1:(-diff)
                            RoundVec = xhat(checki,:,k+1) - round(xhat(checki,:,k+1));
                            [mm,ii] = max(RoundVec);
                            xhat(checki,ii,k+1) = ceil(xhat(checki,ii,k+1));
                        end                                
                    end
                end
                
                if round(sum(xhat(checki,:,k+1))) ~= Arrival(checki,Tslice)
                    arrival_ok = false(1);
                end
            end
            
            k = k + 1;
        end
        k_end = k;
    
        % Store interim solution for time at Tslice
        interim(:,:,Tslice) = round(xhat(:,:,k_end));
        
        obj_td(Tslice) = primal_obj_xhat(k);
        residual_td(Tslice) = viola_xhat(k);
        
        if k_end == k_max
            %% Greedy
            fprintf('Time %d is greedy\n', Tslice);
            tic_greedy = tic;
            %% Modification before running sequences

            u = interim(:,:,Tslice);
            emptylevel = capacity(1:ProblemSize)-fl; emptylevel(emptylevel<0)=0; % Constraint loosening back to normal
            empty_temp = emptylevel - sum(interim(:,:,Tslice),1)';
            arrival_temp = Arrival(1:ProblemSize,Tslice);

            %%% Each station kicks away furthest deviations to avoid being overly full

            for cnt_station = 1:ProblemSize % Search for overly full stations (searching column vectors)
                cnt_nbh = 0;
                station = cnt_station; % sequence won't matter in this loop

                while empty_temp(station) < 0 % if the station is overly full
                    cnt_nbh = cnt_nbh +1;
                    neighbour = NbhOrderSet(ProblemSize - cnt_nbh,station); % furthest neighbour
                    %neighbour = NbhOrderSet(cnt_nbh,station); % TRY nearest neighbour

                    kick_away = min(-empty_temp(station),u(neighbour,station)); % kick away some deviations from the furthest agent
                    u(neighbour,station) = u(neighbour,station) - kick_away;
                    empty_temp(station) = empty_temp(station) + kick_away;
                end
            end

            %% Greedy Allocation

            for cnt_seq = 1:NumOfSeq
                %%% Copy parameters
                u_bar = u;
                empty_bar = empty_temp;
                arrival_bar = arrival_temp;

                %%% Find the redistribution needed, and compensate for over redistributed scenario

                redistribute = arrival_bar - sum(u_bar(:,:),2);
                for cnt_station = 1:ProblemSize
                    cnt_nbh = 0;
                    station = seq(cnt_station,cnt_seq);

                    if redistribute(station) < 0
                        fprintf('Redistribution is %d in station %d\n',redistribute(station), station);
                    end
                    while redistribute(station) < 0 % over redistribute
                        cnt_nbh = cnt_nbh +1;
                        neighbour = NbhOrderSet(ProblemSize - cnt_nbh,station); % furthest neighbour

                        cancel = min(-redistribute(station),u_bar(station,neighbour)); % cancel redistributing to the furthest
                        u_bar(station,neighbour) = u_bar(station,neighbour) - cancel;
                        empty_bar(neighbour) = empty_bar(neighbour) + cancel;
                        redistribute(station) = redistribute(station) + cancel;
                    end
                end

                %%% Redistribute
                for cnt_station = 1:ProblemSize
                    cnt_nbh = 0;
                    station = seq(cnt_station,cnt_seq);

                    while redistribute(station) > 0
                        cnt_nbh = cnt_nbh +1;
                        neighbour = NbhOrderSet(cnt_nbh,station);% nearest neighbour
                        
                        re = min(redistribute(station),empty_bar(neighbour)); 
                        u_bar(station,neighbour) = u_bar(station,neighbour) + re;
                        empty_bar(neighbour) = empty_bar(neighbour) - re;
                        redistribute(station) = redistribute(station) - re;
                    end
                end

                objective_bar = sum(sum(u_bar .* distance));
                if objective_bar < obj_g(Tslice)
                    solution(:,:,Tslice) = u_bar;
                    obj_g(Tslice) = objective_bar;
                    seq_choice(Tslice) = cnt_seq;
                end

            end


            %%% Toc
            toc_greedy(Tslice) = toc(tic_greedy);
            toc_td(Tslice) = mean(sum_tocI);
        else
            solution(:,:,Tslice) = interim(:,:,Tslice);
        end
    end

    k_count(Tslice) = k_end-1;
    fprintf('Tslice = %d, k_end = %d, ', Tslice, k_count(Tslice));
    
    %% Checking
    error = 0;
    for cnt = 1:ProblemSize
        error = error + abs(sum(solution(cnt,:,Tslice)) - Arrival(cnt,Tslice));
        some = sum(solution(:,cnt,Tslice)) - capacity(cnt)+fl(cnt);
        error = error + max(0,some);
    end
    fprintf('CV = %d\n',error);

end

toc