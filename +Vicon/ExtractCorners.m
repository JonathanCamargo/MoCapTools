function cornerData = ExtractCorners(c3dFile,varargin)
% ExtractCorners returns a struct where the fieldnames are the forceplates
% and each field contains an nx4 array of point data for the corners.
% cornerData = Vicon.ExtractCorners(c3dFile)
% Optional inputs
% 'CombinedForceplates' - adds another forceplate data (virtual) produced from
% combining other forceplates together.
% 'DeviceNames' - cell array of the devices names that should be used instead.

   narginchk(1,7);
   p = inputParser;      
   addParameter(p,'DeviceNames',{},@(x)iscellstr(x) || isstring(x));
   
   p.parse(varargin{:});
   DeviceNames=p.Results.DeviceNames;
   
   c3dHandle = btkReadAcquisition(c3dFile);
   fpList=btkGetForcePlatforms(c3dHandle);
   firstFrame=btkGetFirstFrame(c3dHandle);
   lastFrame=btkGetLastFrame(c3dHandle);   
   btkCloseAcquisition(c3dHandle);
       
   cornerData=struct();
   
   deviceNames=compose("FP%d", 1:length(fpList));
   
   for fp_idx=1:length(fpList)
        fpProperties=fpList(fp_idx);           
        %Obtain the corners information     
        corners=fpProperties.corners; %(mm)
        corners=reshape(corners,1,12);
        corners=Vicon.transform(corners,'OsimXYZ');      
        a=(ones(3,4).*(1:4))';
        cornerCoordNames=compose('Corners_%d_x,Corners_%d_y,Corners_%d_z',a);
        cornerCoordNames=split(cornerCoordNames,',')';
        cornerCoordNames=cornerCoordNames(:)';
        cornerData.(deviceNames{fp_idx})=array2table([[firstFrame;lastFrame],[corners;corners]],...
            'VariableNames',['Header',cornerCoordNames]);
   end
    
   if ~isempty(DeviceNames)
       assert(numel(DeviceNames)==numel(deviceNames),'wrong size for DeviceNames')
       for i=1:numel(DeviceNames)
           cornerData.(DeviceNames{i})=cornerData.(deviceNames{i});
           cornerData=rmfield(cornerData,deviceNames{i});
       end
   end
end
           
            