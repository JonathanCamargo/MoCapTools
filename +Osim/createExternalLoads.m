function extLoadsFileName = createExternalLoads(devices, sides, extLoadsFileName,varargin)
% extLoadsFileName = createExternalLoads(devices, sides, extLoadsFileName)
% 
% createExternalLoads will generate an external loads xml template file for
% OpenSim that has information about which force plates apply forces to
% which feet. Devices should be a cell array of each of the force plate
% names, and sides should be a character vector containing 'r' and 'l'
% indicating whether the device corresponding to that index applies a force
% to the left or right foot. extLoadsFileName is an optional character
% vector indicating the filename that the xml file should be written to. If
% if it is not supplied, the external loads file will be written to a
% random file in the temporary folder. In either case, a path to the xml
% file will be returned. 
% 
% e.g. createExternalLoads({'Left_Force', 'Right_Force'}, 'lr', 'ExternalLoads.xml')
%
%
% Optional Name-Value pairs:
%
% 'RightBody': name of the rigid body to attatch the right side force
% 'LeftBody': name of the rigid body to attatch the Left side force
%

p=inputParser();
p.addParameter('RightBody',[],@ischar);
p.addParameter('LeftBody',[],@ischar);

if (nargin>3 && nargin<7)
    varargin=[extLoadsFileName; varargin(:)];
    clear extLoadsFileName;
end
p.parse(varargin{:});

RightBody=p.Results.RightBody;
LeftBody=p.Results.LeftBody;

if isempty(RightBody)
    RightBody='calcn_r';
end
if isempty(LeftBody)
    LeftBody='calcn_l';
end

%% create new external loads file
if ~exist('extLoadsFileName', 'var')
    extLoadsFileName = [tempname, '.xml'];
end
fh = fopen(extLoadsFileName, 'w');
% initialize the file with some basic data
fprintf(fh, '<OpenSimDocument Version="40000"/>');
fclose(fh);
%% open the new file with xmlread and enter the all the data
dom = xmlread(extLoadsFileName);
openSimDoc = dom.item(0);
extLoads = addChild(openSimDoc, 'ExternalLoads');
extLoads.setAttribute('name', 'externalloads');
objs = addChild(extLoads, 'objects');
for i = 1:length(devices) % add each device as an external force
    objs.appendChild(createExternalForce(devices{i}, sides(i)));
end
addChild(extLoads, 'groups');
addChild(extLoads, 'datafile', 'Unassigned');
addChild(extLoads, 'external_loads_model_kinematics_file');
addChild(extLoads, 'lowpass_cutoff_frequency_for_load_kinematics', '-1');

fprintf('Writing external loads xml file to %s.\n', extLoadsFileName);
xmlwrite(extLoadsFileName, dom);
%% helper functions
    % addChild will add a child of tag name childTagName to element, and
    % set its text content to textContent, if it is supplied
    function newElem = addChild(element, childTagName, textContent)
        newElem = dom.createElement(childTagName);
        element.appendChild(newElem);
        if nargin == 3
            newElem.setTextContent(textContent);
        end
    end

    % createExternalForce creates an element for an external force with the
    % name given in device, that acts on the side given by side
    function extForce = createExternalForce(device, side)
        switch side
            case 'l'
                body=LeftBody;
            case 'r'
                body=RightBody;           
        end
            
        extForce = dom.createElement('ExternalForce');
        extForce.setAttribute('name', [device '_extForce']);
        addChild(extForce, 'applied_to_body', body);
        addChild(extForce, 'force_expressed_in_body', 'ground');
        addChild(extForce, 'point_expressed_in_body', 'ground');
        addChild(extForce, 'force_identifier', [device '_v']);
        addChild(extForce, 'point_identifier', [device '_p']);
        addChild(extForce, 'torque_identifier');
        addChild(extForce, 'data_source_name', 'Unassigned');
    end
end
