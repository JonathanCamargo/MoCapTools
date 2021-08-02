function BlendOsim(trial,osimfile,folder)
% BlendOsim(trial,osimfile,folder)
% Visualize a trial using BlendOsim addon
% This function takes a trial struct and exports the data in csv format to load
% in Blender.

z=trial;
header=z.trc.Header;
z=Topics.interpolate(z,header(1):1/24:header(end));

%% Transform coordinates
% Transform to ViconXYZ coordinates and (m) units. 
% Save markers forceplates and forward kinematics in locrot notation

[~,osimdest]=fileparts(osimfile);
copyfile(osimfile,fullfile(folder,[osimdest '.osim']));

if isfield(z,'trc')
    z.trc{:,2:end}=Vicon.transform(z.trc{:,2:end},'ViconXYZ')/1000;        
end

if isfield(z,'fp')
    z.fp{:,2:end}=Vicon.transform(z.fp{:,2:end},'ViconXYZ'); %Forceplates were saved in (m) already        
end


if isfield(z,'ik')    
    z.fk=Osim.FK(z.ik,osimfile,'OutputType','loc_rot','Transform','zup');
    z.jointfk=Osim.FK(z.ik,osimfile,'ObjectType','Joints','OutputType','loc_rot','Transform','zup');    
end


%% Export as tables
if isfield(z,'trc')    
    z.trc.Header=(1:numel(z.trc.Header))';
    writetable(z.trc,fullfile(folder,[z.info.File '.trc.csv']));
end

if isfield(z,'fp')    
    z.fp.Header=(1:numel(z.fp.Header))';
    writetable(z.fp,fullfile(folder,[z.info.File '.fp.csv']));
end

if isfield(z,'ik')    
    z.fk.Header=(1:numel(z.ik.Header))';
    writetable(z.fk,fullfile(folder,[z.info.File '.fk.csv']));    
end

if isfield(z,'id')
    %Take jointfk and scale the output according to the joint moment    
    z.jointfk.Header=(1:numel(z.jointfk.Header))';
    coordinateNames=cellfun(@(x)(x(1:end-2)),z.jointfk.Properties.VariableNames(2:6:end),'Uni',0);
    idNames=strrep(z.id.Properties.VariableNames(2:end),'_moment','');
    idNames=strrep(idNames,'_force','');
    [~,ididx]=ismember(coordinateNames,idNames);
    z.id=z.id(:,[1 1+ididx]);
    a=repmat(coordinateNames,3,1)'; 
    sufix=repmat({'_scalex','_scaley','_scalez'},numel(coordinateNames),1);
    scaleNames=join([a(:) sufix(:)],'');
    N=numel(coordinateNames);
    idxlocrot=repmat(1:6,N,1)+(0:6:6*N-1)';
    idxscale=(N*6)+[(1:N)' N+(1:N)' 2*N+(1:N)'];
    idx=[idxlocrot idxscale]';
    z.idlocrotscale=[z.jointfk array2table([z.id{:,2:end} z.id{:,2:end} abs(z.id{:,2:end})]/50,'VariableNames',scaleNames)];
    z.idlocrotscale=z.idlocrotscale(:,[1;1+idx(:)]);    
    cols=z.idlocrotscale.Properties.VariableNames;
    cols=cols(~contains(cols,{'pelvis','lumbar','adduction'}));
    z.idlocrotscale=z.idlocrotscale(:,cols);
    writetable(z.idlocrotscale,fullfile(folder,[z.info.File '.id.csv']));            
end


end


