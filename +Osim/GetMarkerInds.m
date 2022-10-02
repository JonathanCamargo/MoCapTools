<<<<<<< HEAD
function [Ind] = GetMarkerInds(MkrNames, MkrList)

for i = 1:length(MkrList)
    Ind = contains(MkrNames, MkrList{i});
    if sum(Ind) > 0
        break
    end
end

=======
function [Ind] = GetMarkerInds(MkrNames, MkrList)

for i = 1:length(MkrList)
    Ind = contains(MkrNames, MkrList{i});
    if sum(Ind) > 0
        break
    end
end

>>>>>>> 24f5088f525711da84836f7b08fcef79826aedb4
end