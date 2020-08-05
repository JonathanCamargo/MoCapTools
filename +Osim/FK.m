function fkTable = FK(processedMotFilename,osimFilePath,varargin)
% Compute forward kinematics for an opensim model based on model
% coordinates from ik mot file. The output is in Opensim coordinate system
% or use a parameter 'Transform' to modify.
% fkTable=FK(IKdata,osimFilePath)
% IKdata can be a path to a .mot file, a path to a .mat file, or a table of
% IK data. 
% Optional:
% 'OutputType' 'H' Homogeneous transformation for each body
%              'loc_rot' location and rotation('xyz') for each body
%              'Markers' marker positions, formatted as TRC table
% 'Transform'  Additional transformation to apply
%                 (4x4 matrix) tp premultiply
%                 'zup' transformation to make z axis up (blender)

import org.opensim.modeling.*

% Transform to z up coordinate frame
RotX=@(theta) ([1 0 0; 0 cos(theta) -sin(theta) ; 0 sin(theta) cos(theta)]);
Rzup=RotX(pi/2);%*RotY(pi);
Hzup=[Rzup [0 0 0]';0 0 0 1];

p = inputParser;
outputTypes = {'H', 'loc_rot', 'Markers'};
p.addParameter('OutputType','H',@(in) ischar(in) && any(strcmp(outputTypes, in)));
p.addParameter('Transform',eye(4),@(H) ischar(H) || isequal(size(H), [4, 4]));
p.parse(varargin{:});
outputType = p.Results.OutputType;

HTransform=p.Results.Transform;
if ischar(HTransform) && strcmpi(HTransform,'zup')
    HTransform=Hzup;
end
    

%% Extract model and coordinates
evalc('model=Model(osimFilePath);model.buildSystem();');
state=model.initializeState();
[coordinates,coordinateNames]=set2cell(model.getCoordinateSet);
[bodies,bodyNames]=set2cell(model.getBodySet);
[markers,markerNames] = set2cell(model.getMarkerSet);
%% Read the mot file
if strcmp(processedMotFilename,'')
    coordinateValues=zeros(1,numel(coordinates));
    for i=1:length(coordinates)
        c=coordinates{i};        
        coordinateValues(i)=c.getValue(state);
        if strcmp(c.getMotionType.toString.toCharArray','Rotational')
            coordinateValues(i)=rad2deg(coordinateValues(i));
        end        
    end
    ik=array2table([0 coordinateValues],'VariableNames',['Header',coordinateNames']);
else
    ik = Osim.interpret(processedMotFilename, 'MOT');
end
ikArr = ik{:, coordinateNames'};

%% Set the state of each coordinate to a value from IK
Hcell=cell(height(ik),length(bodies));
markerArray = nan(height(ik), length(markers)*3);
isRotational=false(1,numel(coordinates));
for coordinateIdx=1:numel(coordinates)
   if strcmp(char(coordinates{coordinateIdx}.getMotionType),'Rotational')
       isRotational(coordinateIdx)=true;
   end
end

%Transform rotational coordinates to radians
mask = ones(size(ikArr));
mask(:, isRotational) = deg2rad(1);
ikArr = ikArr .* mask;

% Loop through the IK state and compute the locations using getLocationInGround.
for row_idx=1:height(ik)
    %Update the coordinates state
    for idx = 1:length(coordinates)
        c=coordinates{idx};
        value = ikArr(row_idx, idx);
        c.setValue(state,value,false);
    end    
    model.assemble(state);
        
    if strcmp(outputType, 'Markers')
        %thisRow = nan(1, 3*length(markers));
        thisRow =cell(1,length(markers));
        for marker_idx = 1:length(markers)
            m = markers{marker_idx};
            p = m.getLocationInGround(state);
            p = [p.get(0), p.get(1), p.get(2)] * 1000; % Mat2array(p)';
            p=(HTransform*[p 1]')'; p=p(1:3);
            thisRow{marker_idx} = p;
        end
        markerArray(row_idx, :) = [thisRow{:}];
    else
        %Compute body transform
        % Get the transform for every body in the model    
        for body_idx=1:length(bodies)        
            b=bodies{body_idx};
            t=b.getTransformInGround(state);
            R=Mat2array(t.R);   
            p=Mat2array(t.p);
            H=[R p; 0 0 0 1];
            Hcell{row_idx,body_idx}=HTransform*H;
        end 
    end
end

%% Generate the table for markersq
if strcmp(outputType, 'Markers')
    markerHeaders = compose('%s_%c', string(markerNames), 'xyz')';
    markerHeaders = markerHeaders(:)';
    fkTable = array2table(markerArray, 'VariableNames', markerHeaders);
    fkTable = [ik(:, 1), fkTable];
else
    a=cell2table(Hcell,'VariableNames',bodyNames);   
    fkTable=[ik(:,1) a];
end

%% Generate the table for loc_rot
if strcmp(outputType,'loc_rot')
    % Asuming euler xyz premultiplication (i.e. zyx postmultiplication blender default)
    eul=cellfun(@(x)(rotm2eul(x(1:3,1:3),'zyx')),Hcell,'Uni',0);
    pos=cellfun(@(x)(x(1:3,4)'),Hcell,'Uni',0);
    allBodyData=cell(size(eul,1),size(eul,2)*2);
    allBodyData(:,1:2:end)=pos;
    allBodyData(:,2:2:end)=cellfun(@(x)rad2deg(fliplr(x)),eul,'Uni',0);
    bodyNames=fkTable.Properties.VariableNames;bodyNames=bodyNames(2:end);
    a=repmat(bodyNames,6,1); 
    allTableNames=join([a(:) repmat({'_x','_y','_z','_rotx','_roty','_rotz'}',numel(bodyNames),1)],'');
    fkTable=array2table([fkTable.Header cell2mat(allBodyData)],'VariableNames',['Header';allTableNames]);    
end    



end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                         HELPER FUNCTIONS                              %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TODO: move this into a library
function [content,toString]=set2cell(setvariable)
% Converts a set to a cell array
    a=setvariable;
    content=cell(a.getSize(),1);
    toString=cell(a.getSize(),1);
    for i=1:a.getSize()
        content(i)=a.get(i-1);
        toString(i)={content{i}.toString.toCharArray'};
    end
end

function A=Mat2array(matvariable)
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
