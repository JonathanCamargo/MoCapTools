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

% if exist('Dir', 'var') == 0
%     [filepath, ~, ~] = fileparts(StaticMarkerFile);
% end

if exist('file2write', 'var') == 0
    file2write = [StaticMarkerFile(1:end-4) '_Virtual.trc'];
end

%% Load Static TRC file
trc = Osim.readTRC(StaticMarkerFile); 
MkrNames = trc.Properties.VariableNames; 
trcData = table2array(trc); 

%% Make Virtual Markers

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
S = {'L.ASIS','LASI'}; 
Ind = contains(MkrNames, S);
L.ASIS = trcData(:,Ind);
S = {'R.ASIS','RASI'}; 
Ind = contains(MkrNames, S);
R.ASIS = trcData(:,Ind);
A(:,:,1) = L.ASIS;
A(:,:,2) = R.ASIS;
Mid.ASIS = mean(A, 3);

% mid PSIS
S = {'L.PSIS','LPSI'}; 
Ind = contains(MkrNames, S);
L.PSIS = trcData(:,Ind);
S = {'R.PSIS','RPSI'}; 
Ind = contains(MkrNames, S);
R.PSIS = trcData(:,Ind);
A(:,:,1) = L.PSIS;
A(:,:,2) = R.PSIS;
Mid.PSIS = mean(A, 3);

% mid pelvis
A(:,:,1) = Mid.ASIS;
A(:,:,2) = Mid.PSIS;
Mid.Pelvis = mean(A, 3);

% knee joint center
S = {'L.Knee','LKNEL'}; 
Ind = contains(MkrNames, S);
L.Knee = trcData(:,Ind);
S = {'L.MKnee','LKNEM'}; 
Ind = contains(MkrNames, S);
L.MKnee = trcData(:,Ind);
A(:,:,1) = L.Knee;
A(:,:,2) = L.MKnee;
L.KJC = mean(A, 3);

S = {'R.Knee','RKNEL'}; 
Ind = contains(MkrNames, S);
R.Knee = trcData(:,Ind);
S = {'R.MKnee','RKNEM'}; 
Ind = contains(MkrNames, S);
R.MKnee = trcData(:,Ind);
A(:,:,1) = R.Knee;
A(:,:,2) = R.MKnee;
R.KJC = mean(A, 3);

% ankle joint center
S = {'L.Ankle','LANKL'}; 
Ind = contains(MkrNames, S);
L.Ankle = trcData(:,Ind);
S = {'L.MAnkle','LANKM'}; 
Ind = contains(MkrNames, S);
L.MAnkle = trcData(:,Ind);
A(:,:,1) = L.Ankle;
A(:,:,2) = L.MAnkle;
L.AJC = mean(A, 3);

S = {'R.Ankle','RANKL'}; 
Ind = contains(MkrNames, S);
R.Ankle = trcData(:,Ind);
S = {'R.MAnkle','RANKM'}; 
Ind = contains(MkrNames, S);
R.MAnkle = trcData(:,Ind);
A(:,:,1) = R.Ankle;
A(:,:,2) = R.MAnkle;
R.AJC = mean(A, 3);

% for floor markers, set Y coords to 0 (putting them on the floor)
% AJC floor
L.AJC_Floor = L.AJC;
L.AJC_Floor(:,2) = 0;
R.AJC_Floor = R.AJC;
R.AJC_Floor(:,2) = 0;

% heel floor
S = {'L.Heel','LHEE'}; 
Ind = contains(MkrNames, S);
L.Heel = trcData(:,Ind);
L.Heel_Floor = L.Heel;
L.Heel_Floor(:,2) = 0;
S = {'R.Heel','RHEE'}; 
Ind = contains(MkrNames, S);
R.Heel = trcData(:,Ind);
R.Heel_Floor = R.Heel;
R.Heel_Floor(:,2) = 0;

% MT1 floor
S = {'L.MT1','LMT1'}; 
Ind = contains(MkrNames, S);
L.MT1 = trcData(:,Ind);
L.MT1_Floor = L.MT1;
L.MT1_Floor(:,2) = 0;
S = {'R.MT1','RMT1'}; 
Ind = contains(MkrNames, S);
R.MT1 = trcData(:,Ind);
R.MT1_Floor = R.MT1;
R.MT1_Floor(:,2) = 0;

% MT5 floor
S = {'L.MT5','LMT5'}; 
Ind = contains(MkrNames, S);
L.MT5 = trcData(:,Ind);
L.MT5_Floor = L.MT5;
L.MT5_Floor(:,2) = 0;
S = {'R.MT5','RMT5'}; 
Ind = contains(MkrNames, S);
R.MT5 = trcData(:,Ind);
R.MT5_Floor = R.MT5;
R.MT5_Floor(:,2) = 0;

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
V = array2table([trcData, VirtualData], 'VariableNames', [MkrNames, VH]); 
Osim.writeTRC(V, 'FilePath', file2write);

%% plot all virtual markers to check accuracy
if strcmp(PlotVirtual, 'Yes')
    
end


end
