%% Optimises distributed contrained system *after DeleteDistantStations
clearvars -except Arrival capacity e eta iifl NbhDistance NumStation
addpath(genpath('/Applications/MATLAB_R2014b.app/toolbox/yalmip/'));  
% add yalmip solver to matlab search path
tic

%% Initialise optimisation variables/constraints/objective

%ProblemSize = NumStation;
ProblemSize = 10;
distance = NbhDistance(1:ProblemSize,1:ProblemSize);
NbhVec = e(1:ProblemSize,1:ProblemSize);
Deviation_Indicator = 0;

solution = Inf(ProblemSize,ProblemSize,72); % decision variable

for Tslice = 1:72
    %% Fill level dynamics
    
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
    emptylevel = capacity(1:ProblemSize)-fl;
    
    fl(fl<0) = 0; % under-empty stations will be set as empty
    % some customers would not be able to depart
    
    % It should not be over-full after optimising
    if min(emptylevel) < 0 % If so, error message
        fprintf('Station %d with empty level %d at Tslice %d\n', ...
            find(emptylevel == min(emptylevel),1), min(emptylevel), Tslice);
    end
    
    %% Distributed Constrained Optimisation
    
    skipflag = false(1);
    converged = false(1);
    
    beta = 20;
    c = Inf(ProblemSize,1);
    k_max = 100;
    k_si = round(0.4*k_max);
    k = 1;
    
    primal_obj_x = Inf(k_max,1);
    primal_obj_xhat = Inf(k_max,1);
    viola_x = Inf(k_max,1);
    viola_xhat = Inf(k_max,1);
    
    x = Inf(ProblemSize,ProblemSize,k_max); % column vectors
    xhat = Inf(ProblemSize,ProblemSize,k_max); % column vectors
    xhat(:,:,1) = zeros(ProblemSize,ProblemSize);
    % The optimised case neglecting #arrival equality constraints
    
    lamb = Inf(ProblemSize,ProblemSize,k_max); % column vectors
    lamb(:,:,1) = zeros(ProblemSize,ProblemSize); % lamb(1) = 0
    l = Inf(ProblemSize,ProblemSize,k_max); % column vectors
    
    % Skip computation if no Arrivals at all
    if sum(Arrival(1:ProblemSize,Tslice)) == 0
        skipflag = true(1);
        solution(:,:,Tslice) = zeros(ProblemSize,ProblemSize);
    end

    %% Repeat until convergence
    
    if ~skipflag % if there is some Arrivals
        while k<k_max && ~converged
            c(k) = beta/k;
            % Implement two different sequences for xhat/xtilta
            if k < k_si
                cc = c(k)/sum(c(1:k));
            else
                cc = c(k)/sum(c(k_si:k));
            end
            diagonal = min(Arrival(1:ProblemSize,Tslice),emptylevel);
            
            for i = 1:ProblemSize
                l(:,i,k) = mean(lamb(:,:,k),2);  % by considering a(i,j) = 1/m
        
                opt = sdpvar(ProblemSize,1); % column vector
                constraints = [opt >= 0, sum(opt) <= emptylevel(i)];
                constraints = [constraints, opt(i) == diagonal(i)];
                %local constraints
                objective =  distance(i,:) * opt + l(:,i,k)' * (opt - Arrival(1:ProblemSize,Tslice)./ProblemSize);  
                options = sdpsettings('verbose',0,'solver','linprog');
                sol = optimize(constraints,objective,options);

                if sol.problem == 0  % no problem
                    x(:,i,k+1) = value(opt);
                    primal_obj_x(k+1) = value(objective);
                else
                    display('Something went wrong');
                    sol.info
                    yalmiperror(sol.problem)
                end

                lamb_next = l(:,i,k) + c(k) * (x(:,i,k+1) - Arrival(1:ProblemSize,Tslice)./ProblemSize);
                %positive projection NOT needed
                lamb(:,i,k+1) = lamb_next;
                xhat(:,i,k+1) = xhat(:,i,k) + cc * (x(:,i,k+1)-xhat(:,i,k));
            end
            
            primal_obj_x(k+1) = sum(x(:,:,k+1) * distance(:,i));
            primal_obj_xhat(k+1) = sum(xhat(:,:,k+1) * distance(:,i));
            v = sum(x(:,:,k+1),1) - emptylevel'; v(v <0) = 0; viola_x(k+1) = sum(v);
            v = sum(xhat(:,:,k+1),1) - emptylevel'; v(v <0) = 0; viola_xhat(k+1) = sum(v);
            
            %%% Check Convergence
        
            %converged = true(1);
            %for checki = 1:ProblemSize
            %    lamb_check = lamb(checki,:,k+1);
            %    if max(lamb_check) - min(lamb_check) > 0
            %        converged = false(1);
            %        break;
            %    end
            %end
            
            converged = true(1);
            for checki = 1:ProblemSize
                if sum(round(xhat(:,checki,k+1))) > emptylevel(checki) ... 
                        || sum(round(xhat(checki,:,k+1))) ~= Arrival(checki,Tslice) 
                    % if any column violates filllevel constraints
                    % or if any row (after round off) gets incorrect #Arrival
                    converged = false(1);
                    break;
                end
            end
            
            k = k + 1;
        end
        k_end = k;
        
        % Print graph of lamb
        figure('Name','Lambda Convergence')
        for c1 = 1:ProblemSize
            for c2 = 1:ProblemSize
                plot(2:k_end,squeeze(lamb(c1,c2,2:k_end)));
                hold on
            end
        end
        hold off
        xlabel('Iteration')
        ylabel('Lambda')
        
        % Print graph of primal objective
        figure('Name','Primal Objective Cost for x and xhat')
        plot(2:k_end,primal_obj_x(2:k_end),'red');
        hold on
        plot(2:k_end,primal_obj_xhat(2:k_end),'blue');
        hold off
        xlabel('Iteration')
        ylabel('Primal Objective Cost')
        legend('x','xhat')
        
        % Print graph of constraint violation
        figure('Name','Constraint Violation for x and xhat')
        plot(2:k_end,viola_x(2:k_end),'red');
        hold on
        plot(2:k_end,viola_xhat(2:k_end),'blue');
        hold off
        xlabel('Iteration')
        ylabel('Constraint Violation')
        legend('x','xhat')
        
        % Store final solution for time at Tslice
        solution(:,:,Tslice) = round(xhat(:,:,k_end));
    end
    
    Deviation_Indicator = Deviation_Indicator + sum(sum(solution(:,:,Tslice))) - trace(solution(:,:,Tslice));
    if mod(Tslice,10) == 0
        fprintf('Time slice computed is %d\n', Tslice);
    end
end

toc
