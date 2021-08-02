function plot(vskFile,varargin)
% Plot the vsk in 3d 
% plot(vskFile,trc)
% plot(vskFile,trc,sticks)

istableorstruct=@(x)(istable(x) || isstruct(x));
p=inputParser();
p.addRequired('trc',istableorstruct);
p.addOptional('sticks',{},@iscell);
p.parse(varargin{:});

trc=p.Results.trc;
markers=Osim.interpret(trc,'TRC','struct');
sticks=p.Results.sticks;
washold=ishold;

if isempty(sticks)
    sticks=Vicon.model.getSticks(vskFile);
end

markerNames=fieldnames(markers);
%plot each marker and add a label
for i=1:numel(markerNames)
    markerName=markerNames{i};
    marker=markers.(markerName);
    plot3(marker.x,marker.y,marker.z,'o'); hold on;
    text(marker.x,marker.y,marker.z,markerName,'FontSize',8);
end

%plot the body segments
for i = 1:size(sticks,1)
    marker1=sticks{i,1};
    marker2=sticks{i,2};
    colorcito=sticks{i,3};
    if mean(colorcito)>0.9
        colorcito=[0.5,0.5,0.5];
    end
    m1=markers.(marker1);
    m2=markers.(marker2);
    plot3([m1.x;m2.x],[m1.y;m2.y],[m1.z;m2.z],'Color',colorcito); hold on;
end


if ~washold
    hold off;
end



end
