%% Compare Beta
ticCB = tic;

k_stack_all = Inf(72,3);
PS=100;
cnt2 = 0;
%cnt = [0.1 0.25 0.5 1 2 4 8 12 16 20 24 28 32]
%cnt = [40 60 80 100 125 150 175 200]
for cnt = [0.0001]
    cnt2 = cnt2+1;
    beta = cnt;
    OptimiseDistributed2Beta;
    k_stack_all(:,cnt2) = k_stack;
    fprintf('Beta is now %d\n',beta);
end

toc(ticCB);

% beta = 0.1 results is in k_stack_all(:,1)
% 0.25 in (:,2) etc.