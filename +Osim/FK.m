function fkTable = FK(processedMotFilename,osimFilePath,varargin)
% Compute forward kinematics for an opensim model based on model
% coordinates from ik mot file. 
% fkTable=FK(IKdata,osimFilePath)
% IKdata can be a path to a .mot file, a path to a .mat file, or a table of
% IK data. 
% Optional:
% 'OutputType' 'H' Homogeneous transformation
%              'loc_rot' location and rotation xyz
%              'Markers' marker positions, formatted as TRC table

import org.opensim.modeling.*

% Transform to z up coordinate frame
RotX=@(theta) ([1 0 0; 0 cos(theta) -sin(theta) ; 0 sin(theta) cos(theta)]);
RotY=@(theta) [cos(theta) 0 sin(theta);0 1 0; -sin(theta) 0 cos(theta); ];
RotZ=@(theta) [cos(theta) -sin(theta) 0;sin(theta) cos(theta) 0; 0 0 1];
Rzup=RotX(pi/2);%*RotY(pi);
Hzup=[Rzup [0 0 0]';0 0 0 1];

p = inputParser;
outputTypes = {'H', 'loc_rot', 'Markers'};
p.addParameter('OutputType','H',@(in) ischar(in) && any(strcmp(outputTypes, in)));
p.addParameter('Transform',Hzup,@(H) isequal(size(H), [4, 4]));
p.parse(varargin{:});
outputType = p.Results.OutputType;

Hzup=p.Results.Transform;

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
mask = ones(size(ikArr));
mask(:, isRotational) = deg2rad(1);
ikArr = ikArr .* mask;

for row_idx=1:height(ik)
    for idx = 1:length(coordinates)
        c=coordinates{idx};
        value = ikArr(row_idx, idx);
        c.setValue(state,value,false);
    end
    
    model.assemble(state);
    
    if strcmp(outputType, 'Markers')
        thisRow = nan(1, 3*length(markers));
        for marker_idx = 1:length(markers)
            m = markers{marker_idx};
            p = m.getLocationInGround(state);
            p = [p.get(0), p.get(1), p.get(2)] * 1000; % Mat2array(p)';
            thisRow(3*marker_idx - [2,1,0]) = p;
        end
        markerArray(row_idx, :) = thisRow;
    else
        %Compute body transform
        % Get the transform for every body in the model    
        for body_idx=1:length(bodies)        
            b=bodies{body_idx};
            t=b.getTransformInGround(state);
            R=Mat2array(t.R);   
            p=Mat2array(t.p);
            H=[R p; 0 0 0 1];
            Hcell(row_idx,body_idx)={Hzup*H};
        end 
    end
end
if strcmp(outputType, 'Markers')
    markerHeaders = compose('%s_%c', string(markerNames), 'xyz')';
    markerHeaders = markerHeaders(:)';
    fkTable = array2table(markerArray, 'VariableNames', markerHeaders);
    fkTable = [ik(:, 1), fkTable];
else
    a=cell2table(Hcell,'VariableNames',bodyNames);   
    fkTable=[ik(:,1) a];
end
% thanks for stealing my code, best regards ossip

if strcmp(outputType, 'loc_rot')
    Hzup=eye(4);% Reset the transformation because it was already applied 
    allBodyTable=[];
    bodyNames=fkTable.Properties.VariableNames;bodyNames=bodyNames(2:end);
    for body_idx=1:numel(bodyNames)
        body=bodyNames{body_idx};
        fprintf('Trajectory for %s\n',body);
        d=fkTable.(body);
        H=cell2mat(d);
        allP=H(:,4);
        allH=H(:,1:3);
        p=reshape(allP,4,length(d))'; p=p(:,1:3);
        H=permute(reshape(allH',3,4,length(d)),[2 1 3]); H=H(1:3,1:3,:);
        
        % Origin in opensim is the same as origin in blender
        p_osim=p;
        H_osim=H;
        p_blender=zeros(size(p_osim));
        H_blender=zeros(size(H_osim));
        rot_blender=zeros(size(p_osim));
        for i=1:size(p_osim,1)
            p_blender(i,:)=Hzup(1:3,1:3)*p_osim(i,:)'+Hzup(1:3,4); 
            H_blender(:,:,i)=Hzup(1:3,1:3)*H_osim(:,:,i);
            rot_blender(i,:)=-rad2deg(tr2rpy(H_blender(:,:,i)'));
        end
        PLOT=false;
        if (PLOT==true)
            p=p_blender;
            hold on;
            plot3(p(:,1),p(:,2),p(:,3),'.');
            xlabel('x');ylabel('y');zlabel('z');        
            drawnow;
        end
        bodyTable=array2table([p_blender,rot_blender],'VariableNames',join([repmat({body},6,1),{'_x','_y','_z','_rotx','_roty','_rotz'}'],''));    
        allBodyTable=[allBodyTable bodyTable];
    end
        
    headerTable=array2table(fkTable.Header,'VariableNames',{'Header'});
    allBodyTable=[headerTable allBodyTable];
    fkTable=allBodyTable;
end
    
%%



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
