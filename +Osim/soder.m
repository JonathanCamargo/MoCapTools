function [T,res]=soder(data)

%% soder
% Description:	Program calculates the transformation matrix T containing
%		the rotation matrix (3x3) and the translation translation
%		vector d (3x1) for a rigid body segment using a singular
%		value decomposition method (Soederkvist & Wedin 1993).
%
% Input:    data:   columns represent the XYZ positions and the rows
%                   represent time.
% Output:   T:      4x4 Matrix containing the rotation matrix R and the
%                   translation d: T = [R,d; 0 0 0 1]
%           res:    norm of residuals (measure of fit; "rigidity" of body
%
% References:     Soderkvist I. and Wedin P. -A., (1993). Determining the
%                 movements of the skeleton using well-configured markers.
%                 Journal of Biomechanics, 26:1473-1477
%
% Author:	Christoph Reinschmidt, HPL, The University of Calgary
%               (Matlab code adapted from Ron Jacobs, 1993)
% Date:		February, 1995
% Last Changes: December 09, 1996
% Version:      3.1

if (size(data,2)/3)~=fix(size(data,2)/3)
    disp('ERROR: input has to be multiple of 3 (XYZ coordinates)'); 
    return
end

A=[reshape(data(1,:)',3,size(data,2)/3)]';
B=[reshape(data(2,:)',3,size(data,2)/3)]';

% Checking for NaNs and also checking if still 3 pts left and if not
cut=[0];
qA=isnan(A); qB=isnan(B); qAB=[qA,qB];
qsum=sum(qAB'); cut=find(qsum~=0);
A([cut],:)=[];
B([cut],:)=[];
if size(A,1)<3
    T=[NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN;];
    return;
end

% 
Amean=mean(A)';
Bmean=mean(B)';

%
for i=1:size(A,1)-size(cut,2)
    Ai(:,i)=[A(i,:)-Amean']';
    Bi(:,i)=[B(i,:)-Bmean']';
end

C=Bi*Ai';
[P,~,Q]=svd(C);
R=P*diag([1 1 det(P*Q')])*Q';
d=Bmean-R*(Amean);
T=[R d;0 0 0 1];

% Calculating the norm of residuals
A=A'; A(4,:)=ones(1,size(A,2));
B=B';
Bcalc=T*A; Bcalc(4,:)=[]; Diff=B-Bcalc; Diffsquare=Diff.^2;
%DOF=3*(number of points)-6 unknowns (Hx,Hy,Hz,alpha,beta,gamma):
DOF=size(B,1)*size(B,2)-6;
res=[sum(Diffsquare(:))/DOF].^0.5;

end