function traj = patternFill(traj, donor, t0, t1)
% filled = patternFill(traj, donor, t0, t1)
% patternFill fills a gap in the data of traj with the data in donor, using
% Vicon's pattern filling algorithm. Only the data between t0 and t1
% (exclusive) will be filled. traj and donor should be nx3 arrays of
% doubles representing the x, y, and z components of position over time. 
%
% Implementation based on info from:
% https://www.vicon.com/faqs/software/what-gap-filling-algorithms-are-used-nexus-2
    if any(any(isnan(donor([t0, t1], :))))
        error('GapFill:NoDataAtEnds', 'Donor trajectory is missing data at the endpoints.')
    end
    
    if any(any(isnan(traj([t0, t1], :))))
        error('GapFill:NoDataAtEnds', 'Fill trajectory is missing data at the endpoints.')
    end    

    if all(all(isnan(donor(t0+1:t1-1, :))))
        error('GapFill:NoDonors', 'Donor trajectory has no data in the gap.')
    end
    %if any(isnan(donor(t0+1:t1-1)))
        %warning('Gap will be partially filled.');
        %error('Donor trajectory is missing data in the gap.')
    %end
    interpolatedDonor = interp1([t0, t1], donor([t0, t1], :), t0:t1);
    interpolatedTraj = interp1([t0, t1], traj([t0, t1], :), t0:t1);
    traj(t0:t1, :) = interpolatedTraj + donor(t0:t1, :) - interpolatedDonor;
end
