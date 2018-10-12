%% Capacity count to check if there isn't enough parking spaces in the whole system after all

c_count = Inf(15,72);
cnt = 0;
for ProblemSize = 50:50:750
    cnt = cnt+1;
    fl = Inf(ProblemSize,1);
    for Tslice = 1:72
        
        if Tslice == 1
            fl = iifl(1:ProblemSize);
        else
            fl = fl + eta(1:ProblemSize,Tslice-1);
        end
        c_count(cnt,Tslice) = sum(capacity(1:ProblemSize)-fl);
        if c_count(cnt,Tslice) < 0
            fprintf('PS = %d, t = %d, c_cnt = %d',ProblemSize,Tslice,c_count)
        end
    end
end