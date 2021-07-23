function [content,toString]=set2cell(setvariable)
% content,toString]=set2cell(setvariable)
% Converts a set to a cell array
    a=setvariable;
    content=cell(a.getSize(),1);
    toString=cell(a.getSize(),1);
    for i=1:a.getSize()
        content(i)=a.get(i-1);
        toString(i)={content{i}.toString.toCharArray'};
    end
end
