function out = splitLogical(sig)
% out = splitLogical(sig)
% given a logical vector, return a cell array of indices of every separate
% region where the vector is true.
% 
% Example: 
% sig = [true, true, false, false, true, true, true, false];
% out = splitLogical(sig);  % out = {[1, 2], [5, 6, 7]};

    edges = conv(sig, [1, -1]);
    risings = find(edges == 1);
    fallings = find(edges == -1);
    out = arrayfun(@(a, b) {a:b-1}, risings, fallings);
    if isempty(out)
        out = {};
    end
end
