%% Optimises 2D matrices *after DeleteDistantStations
clearvars -except Arrival capacity DistantStations e eta iifl NbhDistance NumStation StrangerSet NbhSet
addpath(genpath('/Applications/MATLAB_R2014b.app/toolbox/yalmip/'));  
% add yalmip solver to matlab search path
%global ProblemSize C_elapsed_per_t

tic_toc = Inf(15,1);

%% Initialise optimisation variables/constraints/objective

%ProblemSize = NumStation;
%NbhVec = e(1:ProblemSize,1:ProblemSize);
Deviation_Indicator = 0;

sad_total = 0;
cnt = 0;
for ProblemSize = 50:50:750
    Tslice = 1;
    distance = NbhDistance(1:ProblemSize,1:ProblemSize);
    solution = Inf(ProblemSize,ProblemSize,72);  % decision variable
    fl_record = Inf(ProblemSize,72);
    cnt = cnt+1;
    
    dev = sdpvar(ProblemSize,ProblemSize,'full');
    % dev(n,s): #bikes that deviates from arriving at n->s at Tslice
    
    %%% Fill level dynamics
    if Tslice == 1
        fl = iifl(1:ProblemSize);
    else
        fl = fl + eta(1:ProblemSize,Tslice-1) ...
            + sum(solution(:,:,Tslice-1),1)' ...
            - sum(solution(:,:,Tslice-1),2);
        % carry the previous fill level
        % include the net change eta
        % consider the extra #bikes deviated to here at time t-1
        % consider #bikes left at time t-1
    end
    
    sad = -fl; sad(sad<0) = 0; sad_total = sad_total +sum(sad);
    fl(fl<0) = 0; % under-empty stations will be set as empty
    % some customers would not be able to depart
    
    fl_record(:,Tslice) = fl;
    emptylevel = capacity(1:ProblemSize)-fl;
    
    %%% Constraints and objectives    
    tInternal = tic;
    %diagonal = min(Arrival(1:ProblemSize,Tslice),emptylevel);
    
    constraints = [dev >= 0 ...
        sum(dev,2) == Arrival(1:ProblemSize,Tslice), ...
        sum(dev,1)' <= emptylevel];
    %for counti = 1:ProblemSize
    %    constraints = [constraints, dev(counti,counti) == diagonal(counti)];
    %end
    
    %for cnt_s = 1:ProblemSize
    %    for cnt_n = 1:length(StrangerSet{cnt_s})
    %        if StrangerSet{cnt_s}(cnt_n) <= ProblemSize
    %            constraints = [constraints, dev(cnt_s,StrangerSet{cnt_s}(cnt_n)) == 0]; 
    %        end
    %    end
    %end
    
    %% Optimise
    
    objective = sum(sum(dev .* distance));
    %solveroption = sdpsettings('verbose',1,'solver','quadprog','quadprog.maxiter',100);
    options = sdpsettings('verbose',0,'solver','linprog','linprog.maxiter',500);
    sol = optimize(constraints,objective,options);

    if sol.problem == 0
        % no problem
        solution(:,:,Tslice) = value(dev);
    else
        display('Hmm, something went wrong!');
        sol.info
        yalmiperror(sol.problem)
    end
    
    solution(:,:,Tslice) = round(solution(:,:,Tslice));
    tic_toc(cnt) = toc(tInternal);
    fprintf('PS = %d, Elapsed time = %.4f sec\n',ProblemSize,tic_toc(cnt));
    Deviation_Indicator = Deviation_Indicator + sum(sum(solution(:,:,Tslice))) - trace(solution(:,:,Tslice));

end
