function viewIKError(errorTable, surfacePlot,varargin)
% Osim.viewIKError(errorTable)
% Osim.viewIKError(errorTable, surfacePlot)
% viewIKError plots the error output of Osim.IK in a format that is more
% easily understandable. surfacePlot is a logical value that determines
% whether the data should be plotted in a 3D surface plot that shows all
% the data (surfacePlot = true), or whether the data should be condensed
% over the markers and plotted in 2D (surfacePlot = false, default).

    if ~exist('surfacePlot', 'var')
        surfacePlot = false;
    end
    if ~surfacePlot
        data = errorTable{:, 2:end};
        % exclude nan values when calculating rms
        rmsError = sqrt(nanmean(data.^2, 2)); %rms(data, 2);
        maxError = max(data, [], 2);
        hold on;
        plot(errorTable.Header, maxError);
        plot(errorTable.Header, rmsError);
        legend('Max', 'RMS');
        xlabel('Time (s)');
        ylabel('Marker error (m)');
        title('Inverse Kinematics Marker Errors');
    else
        e = errorTable(:, 2:end);
        surface(1:width(e), errorTable.Header, e.Variables, 'EdgeColor', 'none')
        set(gca, 'XTick', 1:width(e));
        labels = e.Properties.VariableNames';
        %try % come up with compact label names for KB_LowerBody marker set
        %    beg = cellfun(@(l) {l([1 3 4])}, labels);
        %    r = cellfun(@(l) {l([2 5:end])}, labels);
        %    fourthLetter = cellfun(@(l) {l(find(l == '_', 1, 'last') + 1)}, r);
        %    labels = upper(join([beg, fourthLetter], ''));
        %catch 
        %    labels = cellfun(@(x){x(1:min(4, end))}, labels);
        %end
        set(gca, 'XTickLabel', labels)
        xlabel('Marker'); xtickangle(45); set(gca, 'TickLabelInterpreter', 'none')
        ylabel('Time (s)');
        zlabel('Marker Error (m)');
        title('Inverse Kinematics Marker Errors');
        view(-20, 30);
    end
end
