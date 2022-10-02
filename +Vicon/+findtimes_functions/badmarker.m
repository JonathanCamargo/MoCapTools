function isbad=badmarker(tbl)
% For a marker table determine frames where the marker is bad by comparing the
% trajectory to such of a smooth trajectory.

%% Smooth and find initial bad points to eliminate

% Smooth once and eliminate worst points for the marker
markerdata=tbl;
header=markerdata.Header;

% Sections with high deviation from smooth trayectory are errors
smoothprops={500,'moving'};
smoothedtbl=array2table([header smooth(markerdata.x,smoothprops{:}) smooth(markerdata.y,smoothprops{:}) smooth(markerdata.z,smoothprops{:})],'VariableNames',markerdata.Properties.VariableNames);


% Bad values are when error is > threshold and is changing rapidly
distanceerror=vecnorm(smoothedtbl{:,2:end}-markerdata{:,2:end},2,2);
diffError=[0; diff(distanceerror)];
errorThreshold=50;
errorHighThreshold=100; 
isbad=(((abs(diffError)>25) & (distanceerror>errorThreshold)))| (distanceerror>errorHighThreshold);

modmarker=markerdata;
modmarker{isbad,2:end}=nan;

%{ 
%PLOT
section=struct('marker',markerdata);
modsection=struct('marker',modmarker);
figure();
Topics.plot(section,'marker'); hold on;
Topics.plot(modsection,'marker'); hold off;
figure(3);
plot(header,distanceerror); 
hold on;
%}

%% Re run smooth with the eliminated data

smoothprops={500,'moving'};
m1=modmarker;
smoothedtbl=array2table([header smooth(m1.x,smoothprops{:}) smooth(m1.y,smoothprops{:}) smooth(m1.z,smoothprops{:})],'VariableNames',m1.Properties.VariableNames);

% Bad values are when error is changing rapidly meaning that marker is
% going crazy. Or when markers exceed a fixed high threshold.
distanceerror=vecnorm(smoothedtbl{:,2:end}-markerdata{:,2:end},2,2);
diffError=gradient(distanceerror);

errorThreshold=50;
isbad=(abs(diffError)>20) | (distanceerror>errorThreshold);


%{ 
%PLOT 
modmarker=markerdata;
modmarker{isbad,2:end}=nan;
section=struct('marker',markerdata);
smoothed=struct('marker',smoothedtbl);
modsection=struct('marker',modmarker);
figure();
Topics.plot(section,'marker','LineSpec',{'r'}); hold on;
Topics.plot(smoothed,'marker','LineSpec',{'g'}); hold on;
Topics.plot(modsection,'marker','LineSpec',{'b*'}); hold off;
figure(3);
plot(header,distanceerror); 
hold on;
%}



end