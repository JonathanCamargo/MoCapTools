function [A,b]=load_A(r,tx)

%% load_A
% Description: Finds the matrix A and the vector b such that Ax-b=0, so A'b=x
%     Where x is the vector [x y z u v w]', where (x,y,z) is the location of
%     the hip joint center in the pelvis frame, and (u,v,w) is the HJC in
%     the thigh reference frame.
%
% INPUTS: r is a 9 column matrix that is a reshaping of the rotational matrix
%           from the pelvis reference frame to the thigh reference frame at
%           every point in time, organized as:
%           r=[rxx rxy rxz ryx ryy ryz rzx rzy rzz]
%
%        tx is a three column matrix that lists the directional vector from
%           the pelvic reference frame to the thigh reference frame,
%           defined in pelvic coordinates:
%           tx=[tx ty tz]
%
% OUTPUTS: A is a 6 x 6 matrix
%         B is a 6 x 1 vector
%
% Reference: Piazza, S. J., A. Erdemir, et al. (2004). "Assessment of the
%     functional method of hip joint center location subject to reduced range
%     of hip motion." J Biomech 37(3): 349-56.
%
% AUTHOR: Joseph Farron, NMBL, University of Wisconsin-Madison
% DATE: October 10, 2005


%First find 6x6 matrix A:
A=zeros(6,6);
A(1,1)=length(r); A(2,2)=length(r); A(3,3)=length(r);
A(4,4)=sum(r(:,1).^2)+sum(r(:,4).^2)+sum(r(:,7).^2);
A(4,5)=sum(r(:,2).*r(:,1))+sum(r(:,5).*r(:,4))+sum(r(:,8).*r(:,7));
A(4,6)=sum(r(:,3).*r(:,1))+sum(r(:,6).*r(:,4))+sum(r(:,9).*r(:,7));
A(5,6)=sum(r(:,3).*r(:,2))+sum(r(:,6).*r(:,5))+sum(r(:,9).*r(:,8));
A(5,5)=sum(r(:,2).^2)+sum(r(:,5).^2)+sum(r(:,8).^2);
A(6,6)=sum(r(:,3).^2)+sum(r(:,6).^2)+sum(r(:,9).^2);
A(5,4)=sum(r(:,2).*r(:,1))+sum(r(:,5).*r(:,4))+sum(r(:,8).*r(:,7));
A(6,4)=sum(r(:,3).*r(:,1))+sum(r(:,6).*r(:,4))+sum(r(:,9).*r(:,7));
A(6,5)=sum(r(:,3).*r(:,2))+sum(r(:,6).*r(:,5))+sum(r(:,9).*r(:,8));
for l=1:3
    for m=1:3
        A((l),m+3)=-sum(r(:,((l-1)*3+m)));
        A((m+3),l)=-sum(r(:,((l-1)*3+m)));
    end
end

%Find the vector b:
b=zeros(6,1);
for p=1:3
    b(1,1)=sum(tx(:,1));
    b(2,1)=sum(tx(:,2));
    b(3,1)=sum(tx(:,3));
    b((p+3),1)=-(sum(tx(:,1).*r(:,p))+sum(tx(:,2).*r(:,(p+3)))+sum(tx(:,3).*r(:,(p+6))));
end

end