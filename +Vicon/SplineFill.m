function markerData = SplineFill(markerData, markerToFill, t0, t1)
% markerData = SplineFill(markerData, markerToFill, t0, t1)
%
% Spline fills a gap between frames t0 and t1 in a marker whose name
% is given in markerToFill. The marker data should be provided as
% a struct of nx3 arrays in markerData. Missing marker data should be
% represented with NaN, as opposed to zeros.
%
% e.g.
% newMarkerData = Vicon.SplineFill(markerData, 'BadMarker', t0,t1);
%
%
% For more details see +Vicon/SplineFill.m
% See also Vicon

    x=markerData.(markerToFill);
    t = 1:length(x);
    framesToKeep = all(~isnan(x),2);
    y = x(framesToKeep,:);
    t = t(framesToKeep);
    a=interp1(t,y,(t0:t1),'pchip');
    x(t0:t1,:)=a;
    markerData.(markerToFill)=x;
end
