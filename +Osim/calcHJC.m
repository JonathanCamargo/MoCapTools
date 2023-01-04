function [HJC, HJC_avg, HJC_std] = calcHJC(filename, PelvMarks, ThiMarks, PelvRef, ThiRef)


trc = Osim.readTRC(filename);
mnames = trc.Properties.VariableNames;
sampFreq = 1 / (trc.Time(2) - trc.Time(1));
[m,~] = size(trc);
trcData = table2array(trc);

%Find the initial vector to the center of the right thigh frame
pmat=reshape(PelvRef, 3, length(PelvMarks));
d_p0=[mean([pmat]')]';
pcoords = trcData(:, contains(mnames, PelvMarks)); %Identify pelvis coordinates

%Find the initial vector to the center of the right thigh frame
tmat=reshape(ThiRef, 3, length(ThiMarks));
d_t0=[mean([tmat]')]';
tcoords = trcData(:, contains(mnames, ThiMarks)); % Identify right thigh coordinates belongs to each requested right
     
 for i=1:m
    %Find pelvis transfer function, rotation matrix, and coordinates
    [T_p,~] = Osim.soder([PelvRef; pcoords(i,:)]);
    R_p=T_p(1:3,1:3);
    d_p(:,i)=R_p*d_p0+T_p(1:3,4);
    
    % record R_p in horizontal vectors
    pp(i,:)=reshape(R_p',1,9);
    dp(:,i)=T_p(1:3,4);

    % Find thigh transfer function, rotation matrix, and vector
    [T_t,~] = Osim.soder([ThiRef; tcoords(i,:)]);
    R_t=T_t(1:3,1:3);
    % record rotation matrices and location vectors
    d_t(:,i)=R_t*d_t0+T_t(1:3,4);
    r_t(i,:)=reshape(R_t',1,9);
    % Find directional vector and rotation matrix from pelvis to thigh and record them in rr and txr
    p_d_t=d_t(:,i)-d_p(:,i);
    [p_R_t]=(R_p)'*(R_t);
    tt(i,:)=reshape(p_R_t',1,9);
    txt(i,:)=R_p'*p_d_t;
end

%Find matrix A and vector b so that A^-1*b=x, where x=[x y z u v w]', and
%(x,y,z) is the vector from the pelvis to the HJC, and (u,v,w) is the
%vector from the thigh to the HJC
if length(ThiMarks)>2
    [A,b] = Osim.load_A(tt,txt);
    HJC_t = (A^(-1))*b;
end

% Locate Pelv Ref Marks in file
% RASISnum=strcmp('R.ASIS',mnames);
% LASISnum=strcmp('L.ASIS',mnames);
% SACnum=strcmp('S2',mnames);

% Find the pelvic and thigh rotation frames and vector locations to
% calculate the HJC in the global reference frame for the locations found
% by HJC_r and HJC_l
time = zeros(m, 1);
HJC_t_p = zeros(m, 3);
HJC_t_t = zeros(m, 3);
ptp = zeros(m, 16);
ttp = zeros(m, 16);
Hdiff = zeros(m, 1);

for i=1:m
    R_p=[reshape(pp(i,:),3,3)]';
    if length(ThiMarks)>2
        R_t = reshape(r_t(i,:),3,3)';
        HJC_t_p(i,:) = [R_p* HJC_t(1:3,1) + d_p(:,i)]';
        HJC_t_t(i,:) = [R_t * HJC_t(4:6,1) + d_t(:,i)]';
    else
        d_t(:,i)=[0;0;0];
    end
    
    time(i,1) = i/sampFreq; % creat time vector
    
    % Convert the HJC locations into the pelvic anatomical reference frame
    RASInames = {'R.ASIS','RASI'}; % multiple options for ASIS marker names
    LASInames = {'L.ASIS','LASI'}; 
    rasis = trcData(i, contains(mnames, RASInames))';
    lasis = trcData(i, contains(mnames, LASInames))';
%     rasis = trcData(i, contains(mnames, 'R.ASIS'))';
%     lasis = trcData(i, contains(mnames, 'L.ASIS'))';
    if sum(contains(mnames, 'S2')) == 0
        RPSInames = {'R.PSIS','RPSI'}; % multiple options for PSIS marker names
        LPSInames = {'L.PSIS','LPSI'};
        rpsis = trcData(i, contains(mnames, RPSInames))';
        lpsis = trcData(i, contains(mnames, LPSInames))';
        sacral = mean([rpsis, lpsis], 2); % average PSIS markers if no sacral marker
    else
        sacral = trcData(i, contains(mnames, 'S2'))';
    end
    
    
    % find pelvis coorinate system
    midasis=(lasis+rasis)/2;
    y=lasis-rasis;
    y=y/sqrt(sum(y.*y));
    z=cross((sacral-lasis),(rasis-lasis));
    z=z/sqrt(sum(z.*z));
    X=cross(y,z);
    R=[X y z];
%     T=[R midasis; 0 0 0 1];
    
    Rp = reshape(pp(i,:),3,3)';
    pRp = Rp' * R;
    p_d_p = R' * (d_p(:,i) - midasis);
    pTp = [pRp' p_d_p; 0 0 0 1];
    ptp(i,:) = reshape(pTp',1,16);
    
    Rt = reshape(r_t(i,:),3,3)';
    tRp = Rt' * R;
    t_d_p = R' * (d_t(:,i)-midasis);
    tTp = [tRp' t_d_p; 0 0 0 1];
    ttp(i,:) = reshape(tTp',1,16);
    
end

% Average the transformation matrices over the trial
if m > 1
    pTp=mean(ptp);
    pTp=reshape(pTp,4,4)';
end
    
while size(tTp) ~= [4, 4]
    tTp=mean(ttp);
    tTp=reshape(tTp,4,4)';
end

hjc_pt = pTp * [HJC_t(1:3);1];
hjc_tt = tTp * [HJC_t(4:6);1];

%Estimate the HJC as the mean location between the two HJC estimations
HJC = mean([hjc_pt';hjc_tt'])';

for i=1:m
    Hdiff(i,1) = sqrt((HJC_t_p(i,1)-HJC_t_t(i,1))^2 + (HJC_t_p(i,2)-HJC_t_t(i,2))^2 + (HJC_t_p(i,3)-HJC_t_t(i,3))^2);
end

HJC_avg = sum((Hdiff(:,1))) / m;
HJC_std = sqrt((sum((Hdiff(:,1) - HJC_avg).^2)) / (m-1));

end