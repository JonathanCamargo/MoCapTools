function [] = MakeVirtualMkr(StaticMarkerFile, file2write)

% MakeVirtualMkr 
% make virtual markers for OpenSim model scaling
% writes a new static file (.trc) in /OpenSim/ScaleFiles

% for more info, see this OpenSim Webinar: 
% Tips and Tricks for Data Collection, Scaling and Inverse Kinematics in OpenSim
% https://youtu.be/ZG7wzvQC6eU

%% Settings
PlotVirtual = 'Yes';
close all;

if exist('StaticMarkerFile', 'var') == 0
    % selects static trial if not specified
    [StaticMarkerFile, ~]=uigetfile('*.trc','Select Static Calibration Trial');
end

if exist('file2write', 'var') == 0
    file2write = [StaticMarkerFile(1:end-4) '_Virtual.trc'];
end

% specify floor height (even floor height = 0) in mm
FloorLvl = -50; 

%% Load Static TRC file
trc = Osim.readTRC(StaticMarkerFile); 
MkrNames = trc.Properties.VariableNames; 
trcData = table2array(trc); 

%% Make Virtual Markers
[m, ~] = size(trcData); 
A = zeros(m, 3, 2);

% markers loaded in subjects structure
% pelvis mid HJC
Ind = contains(MkrNames, 'L.HJC');
L.HJC = trcData(:,Ind);
Ind = contains(MkrNames, 'R.HJC');
R.HJC = trcData(:,Ind);
A(:,:,1) = L.HJC;
A(:,:,2) = R.HJC;
Mid.HJC = mean(A, 3);

% mid ASIS
Ind = Osim.GetMarkerInds(MkrNames, {'L.ASIS', 'LASI'});
L.ASIS = trcData(:,Ind);
Ind = Osim.GetMarkerInds(MkrNames, {'R.ASIS','RASI'});
R.ASIS = trcData(:,Ind);
A(:,:,1) = L.ASIS;
A(:,:,2) = R.ASIS;
Mid.ASIS = mean(A, 3);

% mid PSIS
Osim.GetMarkerInds(MkrNames, {'L.PSIS','LPSI'});
L.PSIS = trcData(:,Ind);
Osim.GetMarkerInds(MkrNames, {'R.PSIS','RPSI'});
R.PSIS = trcData(:,Ind);
A(:,:,1) = L.PSIS;
A(:,:,2) = R.PSIS;
Mid.PSIS = mean(A, 3);

% mid pelvis
A(:,:,1) = Mid.ASIS;
A(:,:,2) = Mid.PSIS;
Mid.Pelvis = mean(A, 3);

% knee joint center
Osim.GetMarkerInds(MkrNames, {'L.Knee','LKNEL'});
L.Knee = trcData(:,Ind);
Osim.GetMarkerInds(MkrNames, {'L.MKnee','LKNEM'});
L.MKnee = trcData(:,Ind);
A(:,:,1) = L.Knee;
A(:,:,2) = L.MKnee;
L.KJC = mean(A, 3);

Osim.GetMarkerInds(MkrNames, {'R.Knee','RKNEL'});
R.Knee = trcData(:,Ind);
Osim.GetMarkerInds(MkrNames, {'R.MKnee','RKNEM'});
R.MKnee = trcData(:,Ind);
A(:,:,1) = R.Knee;
A(:,:,2) = R.MKnee;
R.KJC = mean(A, 3);

% ankle joint center
Osim.GetMarkerInds(MkrNames, {'L.Ankle','LANKL'});
L.Ankle = trcData(:,Ind);
Osim.GetMarkerInds(MkrNames, {'L.MAnkle','LANKM'});
L.MAnkle = trcData(:,Ind);
A(:,:,1) = L.Ankle;
A(:,:,2) = L.MAnkle;
L.AJC = mean(A, 3);

Osim.GetMarkerInds(MkrNames, {'R.Ankle','RANKL'});
R.Ankle = trcData(:,Ind);
Osim.GetMarkerInds(MkrNames, {'R.MAnkle','RANKM'});
R.MAnkle = trcData(:,Ind);
A(:,:,1) = R.Ankle;
A(:,:,2) = R.MAnkle;
R.AJC = mean(A, 3);

% for floor markers, set Y coords to floor level
% AJC floor
L.AJC_Floor = L.AJC;
L.AJC_Floor(:,2) = FloorLvl;
R.AJC_Floor = R.AJC;
R.AJC_Floor(:,2) = FloorLvl;

% heel floor
Osim.GetMarkerInds(MkrNames, {'L.Heel','LHEE'});
L.Heel = trcData(:,Ind);
L.Heel_Floor = L.Heel;
L.Heel_Floor(:,2) = FloorLvl;
Osim.GetMarkerInds(MkrNames, {'R.Heel','RHEE'});
R.Heel = trcData(:,Ind);
R.Heel_Floor = R.Heel;
R.Heel_Floor(:,2) = FloorLvl;

% MT1 floor
Osim.GetMarkerInds(MkrNames, {'L.MT1','LMT1'});
L.MT1 = trcData(:,Ind);
L.MT1_Floor = L.MT1;
L.MT1_Floor(:,2) = FloorLvl;
Osim.GetMarkerInds(MkrNames, {'R.MT1','RMT1'});
R.MT1 = trcData(:,Ind);
R.MT1_Floor = R.MT1;
R.MT1_Floor(:,2) = FloorLvl;

% MT5 floor
Osim.GetMarkerInds(MkrNames, {'L.MT5','LMT5'});
L.MT5 = trcData(:,Ind);
L.MT5_Floor = L.MT5;
L.MT5_Floor(:,2) = FloorLvl;
Osim.GetMarkerInds(MkrNames, {'R.MT5','RMT5'});
R.MT5 = trcData(:,Ind);
R.MT5_Floor = R.MT5;
R.MT5_Floor(:,2) = FloorLvl;

% MidMT floor
A(:,:,1) = L.MT1_Floor;
A(:,:,2) = L.MT5_Floor;
L.MidMT_Floor = mean(A, 3);
A(:,:,1) = R.MT1_Floor;
A(:,:,2) = R.MT5_Floor;
R.MidMT_Floor = mean(A, 3);

%% Export static trial with virtual makers to new TRC file
VirtualData = [Mid.HJC, Mid.ASIS, Mid.PSIS, Mid.Pelvis, R.KJC, L.KJC, R.AJC, L.AJC, R.AJC_Floor, L.AJC_Floor,...
    R.Heel_Floor, L.Heel_Floor, R.MT1_Floor, L.MT1_Floor, R.MT5_Floor, L.MT5_Floor, R.MidMT_Floor, L.MidMT_Floor];

VirtualHeaders = {'Mid.HJC', 'Mid.ASIS', 'Mid.PSIS', 'Mid.Pelvis', 'R.KJC', 'L.KJC', 'R.AJC', 'L.AJC', 'R.AJC_Floor', 'L.AJC_Floor',...
    'R.Heel_Floor', 'L.Heel_Floor', 'R.MT1_Floor', 'L.MT1_Floor', 'R.MT5_Floor', 'L.MT5_Floor', 'R.MidMT_Floor', 'L.MidMT_Floor'};



VH = cell(length(VirtualHeaders), 3); 
for i = 1:length(VirtualHeaders)
    VH{i, 1} = [VirtualHeaders{i} '_x'];
    VH{i, 2} = [VirtualHeaders{i} '_y'];
    VH{i, 3} = [VirtualHeaders{i} '_z'];
end
VH = reshape(VH', [length(VirtualHeaders) * 3, 1])';
MkrNames{1} = 'Header';

if sum(contains(MkrNames, 'L.ASIS')) == 0
    % if non-conventional marker names, change to match labels later on
    
end
V = array2table([trcData, VirtualData], 'VariableNames', [MkrNames, VH]); 
Osim.writeTRC(V, 'FilePath', file2write);

%% plot all virtual markers to check accuracy
if strcmp(PlotVirtual, 'Yes')
    
end


end



