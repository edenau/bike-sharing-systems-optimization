%% Optimises 2D matrices *after DeleteDistantStations
%clearvars -except Arrival capacity DistantStations e eta iifl NbhDistance NumStation
addpath(genpath('/Applications/MATLAB_R2014b.app/toolbox/yalmip/'));  
% add yalmip solver to matlab search path
%global ProblemSize C_elapsed_per_t
ticExternal = tic;
C_elapsed_per_t = Inf(72,1);
%% Initialise optimisation variables/constraints/objective

%ProblemSize = NumStation;
ProblemSize = 150;
distance = NbhDistance(1:ProblemSize,1:ProblemSize);
%NbhVec = e(1:ProblemSize,1:ProblemSize);
Deviation_Indicator = 0;

solution_cen = Inf(ProblemSize,ProblemSize,72);  % decision variable
fl_record = Inf(ProblemSize,72);
sad_total = 0;

obj_cen = Inf(72,1);
residual_cen = zeros(72,1); % well, it is hard constraint 

for Tslice = 1:72
    dev = sdpvar(ProblemSize,ProblemSize,'full');
    % dev(n,s): #bikes that deviates from arriving at n->s at Tslice

    %%% Fill level dynamics
    if Tslice == 1
        fl = iifl(1:ProblemSize);
    else
        fl = fl + eta(1:ProblemSize,Tslice-1) ...
            + sum(solution_cen(:,:,Tslice-1),1)' ...
            - sum(solution_cen(:,:,Tslice-1),2);
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
    emptylevel(emptylevel<0) = 0; % avoid unbounded problem
        
    %%% Constraints and objectives    
    tInternal = tic;
    %diagonal = min(Arrival(1:ProblemSize,Tslice),emptylevel);
    
    constraints = [dev >= 0 ...
        sum(dev,2) == Arrival(1:ProblemSize,Tslice), ...
        sum(dev,1)' <= emptylevel];
    
    % self greedy law, refer to the paper
    
    %for counti = 1:ProblemSize
    %    constraints = [constraints, dev(counti,counti) == diagonal(counti)];
    %end
    
    % Stranger means not a neighbour
    
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
        solution_cen(:,:,Tslice) = value(dev);
    else
        display('Hmm, something went wrong!');
        sol.info
        yalmiperror(sol.problem)
    end
    
    solution_cen(:,:,Tslice) = round(solution_cen(:,:,Tslice));
    C_elapsed_per_t(Tslice) = toc(tInternal);
    
    obj_cen(Tslice) = sum(sum(solution_cen(:,:,Tslice) .* distance));
    
    Deviation_Indicator = Deviation_Indicator + sum(sum(solution_cen(:,:,Tslice))) - trace(solution_cen(:,:,Tslice));
    if mod(Tslice,10) == 0
        fprintf('Time slice computed is %d\n', Tslice);
    end
end

C_elapsed_all = toc(ticExternal);