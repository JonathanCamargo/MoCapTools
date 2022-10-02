function A=Mat2array(matvariable)
%A=Mat2array(matvariable)
% Copy matrix data from opensim object
    M=matvariable.ncol();
    N=matvariable.nrow();
    A=zeros(N,M);
    if (M>1)
        for i=1:N
            for j=1:M
                A(i,j)=matvariable.get(i-1,j-1);
            end
        end
    else    
        for i=1:N
                A(i,1)=matvariable.get(i-1);
        end    
    end
end
