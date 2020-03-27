function filled = rigidBodyFill(traj, donors, t0, t1)
% filled = rigidBodyFill(traj, donors, t0, t1)
% rigidBodyFill fills a gap in the data of traj with the data in donors,
% using Vicon's rigid body filling algorithm. Only the data between t0 and
% t1 (exclusive) will be filled. traj should be an nx3 array of doubles
% representing the x, y, and z components of position over time. donors
% should be a cell array of nx3 arrays or an nx3xm array, where n is the
% number of frames, and m is the number of donors. Supplied donors will be
% ignored if they do not have data at t0 or t1, but may have smaller gaps
% within between t0 and t1, as long as there are at least 3 valid donor
% trajectories at every frame. 
% 
% Implementation based on info from:
% https://www.vicon.com/faqs/software/what-gap-filling-algorithms-are-used-nexus-2

    p = @(v) permute(v, [3,2,1]);
    if iscell(donors)
        donors = p(cat(3, donors{:}));
    elseif ndims(donors) == 3
        donors = p(donors);
    else
        error('GapFill:BadInput', 'Donors must be a cell array of nx3 arrays or an nx3xm array.');
    end
    
    if any(any(isnan(traj([t0, t1], :))))
        error('GapFill:NoDataAtEnds', 'Fill trajectory must have data at t0 and t1.');
    end
    if ~all(all(isnan(traj(t0+1:t1-1, :))))
        warning('Fill trajectory already has some data between t0 and t1.');
    end
    % remove donors that are missing data at t0 or t1
    goodDonors = ~any(isnan(donors(:, :, t0)), 2);
    goodDonors = goodDonors & ~any(isnan(donors(:, :, t1)), 2);
    donors = donors(goodDonors, :, :);
    if size(donors,2) < 3
        error('GapFill:NoDonors', 'Not enough valid donors.')
    end
    % validDonorIdxs must be defined after donors is updated 
    validDonorMask = @(t) ~any(isnan(donors(:, :, t)), 2);
    
    goods = validDonorMask(t0+1:t1-1);
    nGoods = sum(goods, 1);
    if all(nGoods < 3)
        error('GapFill:NoDonors', 'Not enough valid donors.')
    end
    %if any(nGoods < 3)
        %warning('Gap will be partially filled.');
        %error('Fewer than 3 valid donors between frame(s) %d to %d.', t0, t1);
    %end
    
    traj = p(traj);
    filled = traj;
    O = @(t) mean(donors(validDonorMask(t), :, t));
    Ottx = @(t, tx) mean(donors(validDonorMask(t), :, tx));
    M = @(t) donors(validDonorMask(t), :, t) - O(t);
    Mttx = @(t, tx) donors(validDonorMask(t), :, tx) - Ottx(t, tx);
    x = @(t) (t-t0)/(t1-t0);
    C = @(t, tx) Mttx(t, tx)' * M(t);
    G = @(t, tx) R(t, tx) * (traj(:, :, tx) - Ottx(t, tx))' + O(t)';
    F = @(t) G(t, t1)*x(t) + G(t, t0)*(1-x(t));
    
    for t = t0+1:t1-1
        if sum(validDonorMask(t)) < 3
            continue;
        end
        filled(:, :, t) = F(t);
    end
    filled = p(filled);
    
    function r = R(t, tx)
        [U, ~, V] = svd(C(t, tx));
        L = eye(3);
        if det(U * V') < 0
            L(3, 3) = -1;
        end
        r = V * L * U';
    end
end
