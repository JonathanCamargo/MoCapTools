function [] = plotMarkers(FileName)


%% Settings
dbstop if error;
close all;

%% Load TRC file
TRCdata = Osim.readTRC(FileName);
Headers = TRCdata.Properties.VariableNames;
NewHeaders = cell(size(Headers));
ToRep = {'_x','_y','_z'};
for i = 1:length(Headers)
    NewHeaders{i} = replace(Headers{i}, ToRep, '');
end

Markers = unique(NewHeaders);
Strings2Del = {'Header','Time'};
Markers(contains(Markers,Strings2Del)) = [];

%% Plot first row
MkrSz = 20;
FntSz = 6;
h = figure('Position',[100 100 900 800]);
hold on; grid on;

for i = 1:length(Markers)
    Inds = contains(Headers, Markers{i});
    pos = table2array(TRCdata(1, Inds));
    plot3(pos(1), pos(2), pos(3),'.', 'MarkerSize', MkrSz);
    text(pos(1), pos(2), pos(3), Markers{i}, 'FontSize', FntSz);
end

axis equal;
title(FileName);
saveas(h, [FileName(1:end-4) '.png']);   
    
end