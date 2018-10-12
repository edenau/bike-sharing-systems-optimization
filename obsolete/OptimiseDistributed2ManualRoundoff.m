%% Optimises distributed contrained system *after DeleteDistantStations
clearvars -except Arrival capacity e eta iifl NbhDistance NumStation 
addpath(genpath('/Applications/MATLAB_R2014b.app/toolbox/yalmip/'));  
% add yalmip solver to matlab search path
tic
%% Initialise optimisation variables/constraints/objective

%ProblemSize = NumStation;
ProblemSize = 150;
distance = NbhDistance(1:ProblemSize,1:ProblemSize);
NbhVec = e(1:ProblemSize,1:ProblemSize);
k_count = Inf(72,1);
solution = Inf(ProblemSize,ProblemSize,72); % decision variable
obj = Inf(72,1);
residual = Inf(72,1);

for Tslice = 1:72
    %% Fill level dynamics
    ticTslice = tic;
    
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
    
    fl(fl<0) = 0; % under-empty stations will be set as empty
    % some customers would not be able to depart
    
    emptylevel = capacity(1:ProblemSize)-fl;    
    % It should not be over-full after optimising
    if min(emptylevel) < 0 % If so, error message
        fprintf('Station %d with empty level %d at Tslice %d\n', ...
            find(emptylevel == min(emptylevel),1), min(emptylevel), Tslice);
    end
    
    emptylevel(emptylevel<0) = 0; % avoid unbounded problem
    
    %% Distributed Constrained Optimisation
    
    skipflag = false(1);
    converged = false(1);
    arrival_ok = false(1);
    
    beta = 20;
    c = Inf(ProblemSize,1);
    k_max = 41;
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
            
            diagonal = min(Arrival(1:ProblemSize,Tslice),emptylevel);
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
        
        if Tslice == 73
        % Print graph of lamb
        figure('Name','Lambda Convergence')
        for c1 = 1:ProblemSize
            for c2 = 1:ProblemSize
                plot(2:k_end,squeeze(lamb(c1,c2,2:k_end)));
                hold on
            end
        end
        %hold off
        xlabel('Iteration')
        ylabel('Lambda')
        
        % Print graph of primal objective
        figure('Name','Primal Objective Cost for x and xhat')
        plot(2:k_end,primal_obj_x(2:k_end),'red');
        hold on
        plot(2:k_end,primal_obj_xhat(2:k_end),'blue');
        %hold off
        xlabel('Iteration')
        ylabel('Primal Objective Cost')
        legend('x','xhat')
        
        % Print graph of constraint violation
        figure('Name','Constraint Violation for x and xhat')
        plot(2:k_end,viola_x(2:k_end),'red');
        hold on
        plot(2:k_end,viola_xhat(2:k_end),'blue');
        %hold off
        xlabel('Iteration')
        ylabel('Constraint Violation')
        legend('x','xhat')
        end
        
        
        % Store final solution for time at Tslice
        solution(:,:,Tslice) = round(xhat(:,:,k_end));
    end

    obj(Tslice) = primal_obj_xhat(k);
    residual(Tslice) = viola_xhat(k);
    
    if mod(Tslice,10) == 0
        fprintf('Time slice computed is %d\n', Tslice);
    end
    tocTslice = toc(ticTslice);
    k_count(Tslice) = k_end-1;
    fprintf('Tslice = %d, k_end = %d\n', Tslice, k_count(Tslice))
end

toc
