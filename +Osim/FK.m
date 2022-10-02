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
outputTypes = {'H', 'loc_rot','xyz'};
objectTypes = {'Bodies','Markers','Joints'};
p.addParameter('ObjectType','Bodies',@(in) ischar(in) && any(strcmp(objectTypes, in)));
p.addParameter('OutputType','H',@(in) ischar(in) && any(strcmp(outputTypes, in)));
p.addParameter('Transform',eye(4),@(H) ischar(H) || isequal(size(H), [4, 4]));
p.parse(varargin{:});
outputType = p.Results.OutputType;
objectType = p.Results.ObjectType;


HTransform=p.Results.Transform;
if ischar(HTransform) && strcmpi(HTransform,'zup')
    HTransform=Hzup;
end
    

%% Extract model and coordinates
fprintf('Computing forward kinematics for %s\n',osimFilePath);
evalc('model=Model(osimFilePath);model.buildSystem();');
state=model.initializeState();
[coordinates,coordinateNames]=set2cell(model.getCoordinateSet);
[bodies,bodyNames]=set2cell(model.getBodySet);
[markers,markerNames] = set2cell(model.getMarkerSet);

switch objectType       
    case 'Markers'
        nObjects=numel(markers);
        objectNames=markerNames;
    case 'Bodies'
        nObjects=numel(bodies);
        objectNames=bodyNames;
    case 'Joints'
        nObjects=numel(coordinates);   
        objectNames=coordinateNames;
    otherwise
        error('Unknown object type');
end

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
Hcell=cell(height(ik),nObjects);
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
    
    % Do different process depending on the type of object to compute the FK
    switch objectType
        
        case 'Markers'
            %thisRow = nan(1, 3*length(markers));
            %thisRow =cell(1,length(markers));
            for marker_idx = 1:nObjects
                m = markers{marker_idx};
                p = m.getLocationInGround(state);
                p = [p.get(0), p.get(1), p.get(2)] * 1000; % Mat2array(p)';
                p=(HTransform*[p 1]');                
                Hcell{row_idx,marker_idx}=[eye(3)  p; 0 0 0 1];
            end            
            
        case 'Bodies'
            %Compute body transform
            % Get the transform for every body in the model    
            for body_idx=1:nObjects   
                b=bodies{body_idx};
                t=b.getTransformInGround(state);
                R=Mat2array(t.R);   
                p=Mat2array(t.p);
                H=[R p; 0 0 0 1];
                Hcell{row_idx,body_idx}=HTransform*H;
            end                             
        
        case 'Joints'
           for coordinate_idx=1:nObjects
                c=coordinates{coordinate_idx};
                j=c.getJoint;
                parent=j.getChildFrame;
                t=parent.getTransformInGround(state);
                R=Mat2array(t.R);   
                p=Mat2array(t.p);
                H=[R p; 0 0 0 1];
                Hcell{row_idx,coordinate_idx}=HTransform*H*[roty(deg2rad(90)) [0 0 0]'; 0 0 0 1];
           end                   
            
    end
    
end

if strcmp(outputType, 'H')   
    tableHeaders = compose('%s_%c', string(objectNames), 'H')';
    tableHeaders = tableHeaders(:)';
    fkTable=array2table(Hcell,'VariableNames',tableHeaders);
    fkTable.Header=ik.Header;
end

%% Generate the as table with position using TRC table format
if strcmp(outputType, 'xyz')
    tableHeaders = compose('%s_%c', string(objectNames), 'xyz')';
    tableHeaders = tableHeaders(:)';
    pos=cellfun(@(x)(x(1:3,4)'),Hcell,'Uni',0);
    fkTable=array2table([ik.Header pos],'VariableNames',['Header';tableHeaders]);
    %fkTable = array2table(markerArray, 'VariableNames', markerHeaders);
    %fkTable = [ik(:, 1), fkTable];
end

%% Generate the table for loc_rot
if strcmp(outputType,'loc_rot')
    % Asuming euler xyz premultiplication (i.e. zyx postmultiplication blender default)
    eul=cellfun(@(x)(rotm2eul(x(1:3,1:3),'zyx')),Hcell,'Uni',0);
    pos=cellfun(@(x)(x(1:3,4)'),Hcell,'Uni',0);
    allBodyData=cell(size(eul,1),size(eul,2)*2);
    allBodyData(:,1:2:end)=pos;
    allBodyData(:,2:2:end)=cellfun(@(x)rad2deg(fliplr(x)),eul,'Uni',0);    
    a=repmat(objectNames',6,1); 
    allTableNames=join([a(:) repmat({'_x','_y','_z','_rotx','_roty','_rotz'}',numel(objectNames),1)],'');
    fkTable=array2table([ik.Header cell2mat(allBodyData)],'VariableNames',['Header';allTableNames]);    
end    



end

