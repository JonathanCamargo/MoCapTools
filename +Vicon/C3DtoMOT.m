function mot = C3DtoMOT(c3dFile, varargin)
% Exports filtered force plate data from a C3D file and returns a table
% containing the data. The data is expressed in OpenSim coordinte frame
% (i.e Y is up), you can use Vicon.transform to change the data to other 
% orientations.
% [motTable,cornersTbl] = Vicon.C3DtoMOT(c3dFile, varargin)
%
% c3dFile is the file that data will be exported from. 
% Optional Inputs: 
% FilterFreq - the cutoff frequency for filtering the data using a 10th
% order zero-lag Butterworth filter. If this input is not included, the
% data will be filtered at 15Hz. If this input is negative, the data will
% not be filtered.
% CombinedForceplates - adds another forceplate data (virtual) produced from
% combining other forceplates together.
% DeviceNames - cell array of the devices names that should be used as
% table headers. Default is {'FP1', 'FP2', ...'}
%
% See also transform

    narginchk(1,7);
    p = inputParser;
    addRequired(p,'c3dFile',@ischar);
    addParameter(p,'FilterFreq',15);
    addParameter(p,'CombinedForceplates',[],@isnumeric);
    addParameter(p,'DeviceNames',{},@(x)iscellstr(x) || isstring(x));
    
    p.parse(c3dFile,varargin{:});
    
    FilterFreq=p.Results.FilterFreq;
    CombineForceplates = p.Results.CombinedForceplates;
    DeviceNames=p.Results.DeviceNames;
    
    c3dHandle = btkReadAcquisition(c3dFile);
    
    samplingFreq = btkGetAnalogFrequency(c3dHandle);    

    nRows = btkGetAnalogFrameNumber(c3dHandle);
    % Assume that frist frame (usually frame1) is equivalent to time t=0
    t0 = (btkGetFirstFrame(c3dHandle)-1)/btkGetPointFrequency(c3dHandle);    
    time = t0+(((1:nRows) - 1 )' / btkGetAnalogFrequency(c3dHandle));
    
    fpList=btkGetForcePlatforms(c3dHandle);
    fpWrenches=btkGetForcePlatformWrenches(c3dHandle);
    fpWrenches_Local=btkGetForcePlatformWrenches(c3dHandle,0);            
    btkCloseAcquisition(c3dHandle);
        
        
    %Extract transformation and F,M data for each forceplate
    fpData=[];
    for fp_idx=1:length(fpList)
        fpProperties=fpList(fp_idx);
        fpValues=fpWrenches(fp_idx);
        fpValues_Local=fpWrenches_Local(fp_idx);
        
        cp_Local=zeros(size(fpValues_Local.P));
        Fz=fpValues_Local.F(:,3);
        My=fpValues_Local.M(:,2);
        Mx=fpValues_Local.M(:,1);
        
        
        if FilterFreq>0
            FS=samplingFreq; 
            fcut=FilterFreq;
            wn=2*fcut/FS; order=5;
            [b,a]=butter(order,wn);
            Fz=filtfilt(b,a,Fz);Mx=filtfilt(b,a,Mx);My=filtfilt(b,a,My);
        end
        
        %crop all Fz>10N
        toCrop=(Fz>-10);
        Fz(toCrop)=0;Mx(toCrop)=0;My(toCrop)=0;
        
        h=0; %Top cover thickness (mm)
        cp_Local(:,1)=(-h*fpValues_Local.F(:,1)-My)./Fz;
        cp_Local(~isfinite(cp_Local(:,1)),1)=0;
        cp_Local(:,2)=(-h*fpValues_Local.F(:,2)+Mx)./Fz;
        cp_Local(~isfinite(cp_Local(:,2)),2)=0;
        

        %Obtain transformation from local space
        origin=fpProperties.origin;
        % required for transforming treadmill force plates to global
        % coordinate system (for some reason)
        origin(2) = -origin(2);
        corners=fpProperties.corners;
        corners_0=corners - origin;
        H=getTransform(corners_0)';
        
        %Transform CP to global coordinates
        c = [cp_Local, ones(size(cp_Local, 1), 1)];
        c_Global = c * H;
        cp_Global = c_Global(:, 1:3);
        
		%Collect information of this forceplate in a big struct array

        a=struct();
        a.F=fpValues.F; %(N)
        a.M=fpValues.M/1000; %(N.m)
        a.P=cp_Global/1000; %(m)
        
        % concatenating structs rather than arrays so that dealing with the
        % data after this loop is more clear
        fpData = [fpData, a];
    end
    
    if ~isempty(CombineForceplates)
        combinedData = combineForcePlates(fpData(CombineForceplates));
        fpData = [fpData, combinedData];
    end
    
    if isempty(DeviceNames)
        deviceNames=compose("FP%d", 1:length(fpData));
    else
        if length(DeviceNames) > length(fpData)
            deviceNames = string(DeviceNames(1:length(fpData)));
        elseif length(DeviceNames) < length(fpData)
            deviceNames=compose("FP%d", 1:length(fpData));
            deviceNames(1:length(DeviceNames)) = string(DeviceNames);
        else
            deviceNames=string(DeviceNames);
        end
    end
    
    fpData = arrayfun(@(fp) {[fp.F, fp.P, fp.M]}, fpData);
    fpData = [fpData{:}];
    fpData = Vicon.transform(fpData, 'OsimXYZ');
    
    colHeaders = {'Header'};
    
    suffix = ["vx","vy","vz","px","py","pz","moment_x","moment_y","moment_z"];
    newHeaders = compose('%s_%s', deviceNames(:), suffix)';
    colHeaders = [colHeaders; newHeaders(:)];
    mot = array2table([time, fpData], 'VariableNames', colHeaders);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                            Helper Functions                           %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function H = getTransform(corners)
% Compute the homogeneous transformation matrix between the corners tile
% frame to the pattern tile frame centered at the origin.

    p1=[2 3 0];
    p2=[-2 3 0];    
    p3=[-2 -3 0];
    p4=[2 -3 0];
    
    pattern=[p1' p2' p3' p4'];
    
    pattern_centroid=mean(pattern,2);
    corners_centroid=mean(corners,2);
    
    xi=pattern-repmat(pattern_centroid,1,4);
    yi=corners-repmat(corners_centroid,1,4);
    
    S=xi*yi';
    
    [U,~,V]=svd(S);
    L = eye(3);
    if det(U * V') < 0
        L(3, 3) = -1;
    end
    r = V * L * U';
    t = corners_centroid - r*pattern_centroid;        
    H=[r t; 0 0 0 1];    
    
end

function combined = combineForcePlates(wrenches)
    M_mean = mean(cat(3, wrenches.M), 3);
    Mz = M_mean(:, 3);
    P = cat(3, wrenches.P);
    F = cat(3, wrenches.F);
    % P(frame, coordinate, fpIdx)
    dM_x = P(:, 2, :) .* F(:, 3, :);
    dM_y = P(:, 1, :) .* F(:, 3, :);
    Mx = sum(dM_x, 3);
    My = -sum(dM_y, 3);
    
    Pz = P(:, 3, :);
    Fz = F(:, 3, :);
    Pz = sum((Pz.*Fz)./sum(Fz, 3), 3);
    
    F = sum(F, 3);
    Px = -My./F(:, 3);
    Py = Mx./F(:, 3);

    combined.P = [Px, Py, Pz];
    combined.F = F;
    combined.M = [Mx, My, Mz];
    
    combined.P(~isfinite(combined.P)) = 0;
end
