%% Determine if a day is weekday/weekend in year 2017

function WeekEnd = IsWeekend(day,month,year)

WeekEnd = 0;          % Assume weekday
moddate = mod(day,7);

if year == 17  % manual calculation
    
    if     month == 1 || month == 10
        if moddate == 0 || moddate == 1
            WeekEnd = 1;
        end
    elseif month == 4 || month == 7
        if moddate == 1 || moddate == 2
            WeekEnd = 1;
        end
    elseif month == 9 || month == 12
        if moddate == 2 || moddate == 3
            WeekEnd = 1;
        end
    elseif month == 6
        if moddate == 3 || moddate == 4
            WeekEnd = 1;
        end
    elseif month == 2 || month == 3 || month == 11
        if moddate == 4 || moddate == 5
            WeekEnd = 1;
        end
    elseif month == 8
        if moddate == 5 || moddate == 6
            WeekEnd = 1;
        end
    elseif month == 5
        if moddate == 6 || moddate == 0
            WeekEnd = 1;
        end
    end
    
else error('Year 2017 expected');
end

end