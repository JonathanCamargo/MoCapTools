function [Ind] = GetMarkerInds(MkrNames, MkrList)

for i = 1:length(MkrList)
    Ind = contains(MkrNames, MkrList{i});
    if sum(Ind) > 0
        break
    end
end

end