function [] = plotIKErrors(Path)

%% Set input files from path

contains(


H = figure('Position',[100 100 900 800]);
hold on; grid on;


%% load model marker data
ModelMkrData = importdata(strcat(IKFolder, '\', IKErrorFile));

Ind = contains(ModelMkrData.colheaders, '_tx');
ModelMkrData.Xdata = ModelMkrData.data(:,Ind);
Ind = contains(ModelMkrData.colheaders, '_ty');
ModelMkrData.Ydata = ModelMkrData.data(:,Ind);
Ind = contains(ModelMkrData.colheaders, '_tz');
ModelMkrData.Zdata = ModelMkrData.data(:,Ind);

Markers = strrep([ModelMkrData.colheaders(Ind)], '_tz','');
Times = Subjects(subj).Trials(trial).TRC.data(:,2);

[StartVal, StartInd] = min(abs(Times - Subjects(subj).Trials(trial).Times.Start_IK));
[EndVal, EndInd] = min(abs(Times - Subjects(subj).Trials(trial).Times.End_IK));

% get IK marker data
for i = 1:length(Markers)
    Ind = find(strcmp(Subjects(subj).Trials(trial).TRC.colheaders(1,:), Markers{i}));
    MarkerData(i).name = Markers{i};
    MarkerData(i).x = Subjects(subj).Trials(trial).TRC.data(StartInd:EndInd,Ind);
    MarkerData(i).y = Subjects(subj).Trials(trial).TRC.data(StartInd:EndInd,Ind+1);
    MarkerData(i).z = Subjects(subj).Trials(trial).TRC.data(StartInd:EndInd,Ind+2);
end

%% plot

L = min([length(ModelMkrData.Zdata), length(MarkerData(1).z)]);

filename = strcat(Subjects(subj).name,'_', Subjects(subj).Trials(trial).name, '_IKMkrErr.gif');

for r = 1:L
    mdl_z = 1000*ModelMkrData.Zdata(r,:);
    mdl_x = 1000*ModelMkrData.Xdata(r,:);
    mdl_y = 1000*ModelMkrData.Ydata(r,:);
    
    for i = 1:length(MarkerData)
        if isempty(MarkerData(i).x)
            continue
        end
        orig_x(i) = MarkerData(i).x(r);
        orig_y(i) = MarkerData(i).y(r);
        orig_z(i) = MarkerData(i).z(r);
    end
    subplot(221);
    m1 = plot3(mdl_z, mdl_x, mdl_y, '.b', 'MarkerSize', MkrSz);
    hold on; grid on;
    m2 = plot3(orig_z, orig_x, orig_y, '.r', 'MarkerSize', MkrSz);
    line([mdl_z(1:28); orig_z], [mdl_x(1:28); orig_x], [mdl_y(1:28); orig_y],'Color','k');
    title(['Frame ' num2str(r)]);
    view([-1400, 1200, 1200]);
    
    axis equal;
    hold off;
    
    subplot(222);
    text(0.2, 0.8, '\bf Model','Color', 'b', 'FontSize',20);
    text(0.2, 0.6, '\bf Original','Color', 'r', 'FontSize',20);
    
    subplot(223);
    plot(mdl_x, mdl_y, '.b', 'MarkerSize', MkrSz);
    hold on; grid on;
    plot(orig_x, orig_y, '.r', 'MarkerSize', MkrSz);
    line([mdl_x(1:28); orig_x], [mdl_y(1:28); orig_y],'Color','k');
    hold off; axis equal;
    title(['Time = ' num2str(ModelMkrData.data(r,1))]);
    
    subplot(224);
    plot(mdl_z, mdl_y, '.b', 'MarkerSize', MkrSz);
    hold on; grid on;
    plot(orig_z, orig_y, '.r', 'MarkerSize', MkrSz);
    line([mdl_z(1:28); orig_z], [mdl_y(1:28); orig_y],'Color','k');
    hold off; axis equal;
    title(['Frame ' num2str(r)]);
    
    % Capture the plot as an image
    frame = getframe(H);
    im = frame2im(frame);
    [imind,cm] = rgb2ind(im,256);
    % Write to the GIF File
    if r == 1
        imwrite(imind,cm,filename,'gif', 'Loopcount',inf);
    else
        imwrite(imind,cm,filename,'gif','WriteMode','append');
    end
    
end

end