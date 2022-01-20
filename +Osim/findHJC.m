function[] = findHJC(staticFile, Dir, filesAddHJC)

%       Using a calibration full hip range-of-motion trial, findHJC.m locates the
%       hip joint center between a pelvis and thigh and writes the hip joint
%       center location to one or many selected *.trc files.  

% OTHER M.Files REQUIRED:
%       soder, load_A, calcHJC
%       see GITHUB REPOSITORY for more 
%
% INPUTS:
%       Inputs are selected from the prompts displayed while running finHJC.m.
%
%     'Static Calibration Trial':
%         Pick a static trial to set a starting reference location for
%         finding marker locations throughout calibration trials and for a
%         reference to determine HJC locations when writting to files
%
%     'Right and Left Leg HJC Calibration Trial':
%         Find and open the calibration trial for finding the HJC relative
%         to the anatomical pelvis frame.
%
%     'Pelvis and Thigh Markers for HJC Locating':
%         Of the markers from the selected calibration trial, select the
%         pelvis markers you want to use in HJC calculation. Multiple
%         markers can be selected.
%
%     'Select Files to Write HJC Locations':
%         Select the files that you would like to write the HJC locations to.
%         A new folder 'HJC' will be created in the same directory as the 
%         selected files.  Multiple files may be selected
%
%
% OUTPUTS:
%       The selected files to write the HJC locations to are rewritten in the
%       new folder with the HJC's added.  Also, a text file with the HJC's
%       relative to the pelvic mid-ASIS frame, the mean difference calculated
%       between HJC locations relative to the pelvis and the thigh, and the
%       standard deviation of the means; is written as /HJCstatistics.txt
%
% AUTHORS: Joseph Farron, NMBL, University of Wisconsin-Madison
% DATE: November 2, 2005
% UPDATES:
% Amy Silder, June 5, 2006
% Ricky Pimentel, September 2021

%% Set Defaults
dbstop if error;

% Default Marker Names for pelvis and thighs
PelvMarks={'L.ASIS';'R.ASIS';'L.PSIS';'R.PSIS';'S2'}; % pelvis
RTMarks={'R.TH1';'R.TH2';'R.TH3';'R.Knee'}; % right thigh
LTMarks={'L.TH1';'L.TH2';'L.TH3';'L.TH4';'L.Knee'}; % left thigh
% PelvMarks={'LASI';'RASI';'LPSI';'RPSI'}; % pelvis
% RTMarks={'RTH1';'RTH2';'RTH3';'RKNEL'}; % right thigh
% LTMarks={'LTH1';'LTH2';'LTH3';'LKNEL'}; % left thigh

if length(RTMarks)<3
    error('not enough right thigh markers selected for HJC analysis'); 
end
if length(LTMarks)<3
    error('not enough left thigh markers selected for HJC analysis'); 
end

addpath(genpath('C:\Users\richa\Documents\Packages\MoCapTools'))

%% FIRST STEP
% Use a static trial to average all marker locations.  These will be used to:
%   1.  Find a starting reference from which movements can be related
%   2.  Note marker locations with reference to each other, so that a
%       reference frame can be determined in HJC-written files in which
%       markers normally used for reference are missing.

if exist('staticFile', 'var') == 0
    % static trial if not specified
    [staticFile,Dir]=uigetfile('*.trc','Select Static Calibration Trial');
end

if exist('Dir', 'var') == 0
    Dir = fileparts(which(staticFile));
end

if exist('filesAddHJC', 'var') == 0
    disp('Select Files to Add Hip Joint Center Locations')
    filesAddHJC = uigetfile('*.trc','Select Files to Add HJC Locations','multiselect','on');
end

addpath(genpath(Dir)); 
cd(Dir);

% get static markers to reference
trc = Osim.readTRC(staticFile);
Markers = trc.Properties.VariableNames;
trcData = table2array(trc); 
meanTRC = mean(trcData, 1); % average static marker data

% create variables for static reference data
PelvRef = meanTRC(contains(Markers, PelvMarks)); 
RTRef = meanTRC(contains(Markers, RTMarks)); 
LTRef = meanTRC(contains(Markers, LTMarks)); 


%% SECOND STEP
% Find the hip joint center location using a least squares method to find where
% pelvis and thigh share a common point.  It finds the point relative to thigh and pelvic frames and averages the distance between the two.  It
% outputs the averaged HJC in the mid-asis pelvic frame, along with the average distance between the two HJC's calculated and the standard
% deviation of all locations.

D = dir(Dir(1:end-1));
Dt = struct2table(D);
Dc = table2cell(Dt);
% Rind = strcmp('RHJC_1.trc', Dc(:,1));
Rind = strcmp('rhjc_1.trc', Dc(:,1));
if sum(Rind) == 0
    Rind = strcmp('RHJC_1.trc', Dc(:,1));
elseif sum(Rind) == 0 
    Rind = strcmp('R_HJC_1.trc', Dc(:,1));
end
RhjcFile = Dc{Rind};
Lind = strcmp('lhjc_1.trc', Dc(:,1));
% Lind = strcmp('LHJC_1.trc', Dc(:,1));
if sum(Lind) == 0
    Lind = strcmp('LHJC_1.trc', Dc(:,1));
elseif sum(Rind) == 0 
    Lind = strcmp('L_HJC_1.trc', Dc(:,1));
end
LhjcFile = Dc{Lind};

% calculate HJCs
[R_HJC, R_HJC_avg, R_HJC_std] = Osim.calcHJC(RhjcFile, PelvMarks, RTMarks, PelvRef, RTRef);
[L_HJC, L_HJC_avg, L_HJC_std] = Osim.calcHJC(LhjcFile, PelvMarks, LTMarks, PelvRef, LTRef);


%% THIRD STEP
%Select files to write HJC's to, and calculate the HJC's

%A pelvic reference frame is determined based on available
%markers.  The HJC is then transformed into this reference frame, and from
%the marker data in the file, the HJC is calculated in the global frame and
%written into the file.

%Select files to which the HJC locations should be added (multiple must be
%selected).  The same directory will be used to create a file for new files
%with HJC locations.
close all;
mkdir('HJC')

% Locate pelvic markers in each data file, find the pelvic center, locate
% the HJC's and marker data and HJC data into a new file
for j=1:length(filesAddHJC)
    
    disp(['Adding HJCs to ' filesAddHJC{j}]);
    trc = Osim.readTRC(filesAddHJC{j});
    Markers = trc.Properties.VariableNames;
    trcData = table2array(trc); 
    meanTRC = mean(trcData); % average static marker data
    sampFreq = 1 / (trc.Time(2) - trc.Time(1));
    
    % Find the center of the markers and define the coordinate
    % system of the marker set as identical to the global frame.
    PelvRef = meanTRC(contains(Markers, PelvMarks));
    D_ref = [mean(reshape(PelvRef, 3, length(PelvMarks))')]';
    
    % For static data, locate the rotation and location of the
    % coordinate system that the known HJC is in.
    RASInames = {'R.ASIS','RASI'}; % multiple options for ASIS marker names
    LASInames = {'L.ASIS','LASI'};
    i = 1;
    rasis = trcData(i, contains(Markers, RASInames))';
    lasis = trcData(i, contains(Markers, LASInames))';
    if sum(contains(Markers, 'S2')) == 0
        RPSInames = {'R.PSIS','RPSI'}; % multiple options for PSIS marker names
        LPSInames = {'L.PSIS','LPSI'};
        rpsis = trcData(i, contains(Markers, RPSInames))';
        lpsis = trcData(i, contains(Markers, LPSInames))';
        sacral = mean([rpsis, lpsis], 2); % average PSIS markers if no sacral marker
    else
        sacral = trcData(i, contains(Markers, 'S2'))';
    end
    
   
    % create pelvis coodinate system
    midasis = (lasis+rasis)/2;
    y = lasis-rasis;
    y = y/sqrt(sum(y.*y));
    z = cross((sacral-lasis),(rasis-lasis));
    z = z/sqrt(sum(z.*z));
    X = cross(y,z);
    R = [X y z];
    
    %Find the Transformation Matrix from the HJC system to the marker-set system.
    D = midasis - D_ref;
    T = [R D;0 0 0 1];
    % Find the HJC in the m-s system.
    rhjcms = T * R_HJC;
    lhjcms = T * L_HJC;
    
    % Locate the markers in the marker set throughout the trial being written to
    % then use soder to find the transformations to each time set of markers.
    [m,~] = size(trcData);
    center = zeros(m, 3);
    r_hjc = zeros(m, 3);
    l_hjc = zeros(m, 3);
    time = zeros(m, 1);
    

    % get all pelvis markers
    marks = trcData(:, contains(Markers, PelvMarks));
    
    for i = 1:m
        % get pelvis orientation for each frame
        [T_pelv,~] = Osim.soder([PelvRef; marks(i,:)]);
        
        % From these T, find the HJC in the global frame.
        center(i,:) = mean(reshape(marks(i,:),3,length(marks(1,:))/3)');
        rr = [center(i,:)]'+[T_pelv(1:3,1:3)*rhjcms(1:3,1)];
        r_hjc(i,(1:3)) = [rr(1:3)]';
        ll = [center(i,:)]'+[T_pelv(1:3,1:3)*lhjcms(1:3,1)];
        l_hjc(i,(1:3)) = [ll(1:3)]';

        time(i,1) = i/sampFreq - 1/sampFreq; % time array
    end
    
     figure; hold on; 
    plot3(rasis(1), rasis(2), rasis(3), '.');
    text(rasis(1), rasis(2), rasis(3),'rasis'); 
    plot3(lasis(1), lasis(2), lasis(3), '.');
    text(lasis(1), lasis(2), lasis(3),'lasis'); 
    plot3(sacral(1), sacral(2), sacral(3), '.');
    text(sacral(1), sacral(2), sacral(3),'sacral'); 
%     plot3(rpsis(1), rpsis(2), rpsis(3), '.');
%     text(rpsis(1), rpsis(2), rpsis(3),'rpsis'); 
%     plot3(lpsis(1), lpsis(2), lpsis(3), '.');
%     text(lpsis(1), lpsis(2), lpsis(3),'lpsis'); 

    plot3( r_hjc(1),  r_hjc(2),  r_hjc(3), '.');
    text( r_hjc(1),  r_hjc(2),  r_hjc(3),'rhjc'); 
    plot3( l_hjc(1), l_hjc(2), l_hjc(3), '.');
    text(l_hjc(1), l_hjc(2), l_hjc(3),'lhjc'); 
    axis equal; 
    

    Markers{1} = 'Header';
    trcTable = array2table([trcData r_hjc l_hjc]);
    trcTable.Properties.VariableNames = cellstr([Markers, ...
        {'R.HJC_x'}, {'R.HJC_y'}, {'R.HJC_z'},...
        {'L.HJC_x'}, {'L.HJC_y'}, {'L.HJC_z'}]);
    
    % write HJC data to new TRC file
    HJCfile = [filesAddHJC{j}(1:end-4) '_hjc.trc'];
    Osim.writeTRC(trcTable, 'FilePath', HJCfile);
    close all; 
    % move non-hjc files to new folder

    movefile(HJCfile, strcat('HJC/', HJCfile));

end


for j = 1:length(filesAddHJC)
     Osim.plotMarkers(strcat('HJC/', HJCfile))
end


%% Write a text file that gives statistical information about HJC location
fid=fopen('HJC/HJCstatistics.txt','w');
fprintf(fid,['Statistics of Calibration of HJC (locations relative to pelvis)      \n']);
fprintf(fid,['                                                                     \n']);
fprintf(fid,['Right Leg HJC                      Left Leg HJC                      \n']);
fprintf(fid,['X          Y           Z           X          Y          Z           \n']);
fprintf(fid,'%-f',R_HJC(1)); fprintf(fid,['   ']); 
fprintf(fid,'%-f',R_HJC(2)); fprintf(fid,['   ']); 
fprintf(fid,'%-f',R_HJC(3)); fprintf(fid,['   ']);
fprintf(fid,'%-f',L_HJC(1)); fprintf(fid,['   ']); 
fprintf(fid,'%-f',L_HJC(2)); fprintf(fid,['   ']); 
fprintf(fid,'%-f',L_HJC(3)); fprintf(fid,['   \n']);fprintf(fid,['                                                                     \n']);
fprintf(fid,['Mean         Std. Dev.             Mean         Std. Dev.            \n']);
fprintf(fid,'%-f',R_HJC_avg);fprintf(fid,['     ']);
fprintf(fid,'%-f',R_HJC_std);fprintf(fid,['              ']);
fprintf(fid,'%-f',L_HJC_avg);fprintf(fid,['     ']);
fprintf(fid,'%-f\n',L_HJC_std);
fclose(fid);

disp(' '); 
disp('All files written!'); 

end


