%% Compare computation speed for different problem size
tic

C_speed_per_t = Inf(14,1);
cnt = 4;
for PS = 100:50:ProblemSize
    ProblemSize = PS;
    OptimiseCentralised;
    cnt = cnt+1;
    C_speed_per_t(cnt) = mean(C_elapsed_per_t);
    fprintf('Average computation time for %d Stations is %.2f\n',PS,C_speed_per_t(cnt));
end

toc