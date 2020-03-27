function markerData = RigidBodyFill(markerData, markerToFill, donors, t0, t1)
% markerData = RigidBodyFill(markerData, markerToFill, donors, t0, t1)
%
% RigidBodyFill fills a gap between frames t0 and t1 in a marker whose name
% is given in markerToFill using all of the markers whose names are
% provided in donors (at least three) to estimate the position of
% markerToFill, following Vicon's Rigid Body Fill feature. The starting
% frame t0 should be the last frame before the gap starts, and t1 should be
% the first frame after the gap ends. The marker data should be provided as
% a struct of nx3 arrays in markerData. Missing marker data should be
% represented with NaN, as opposed to zeros.
%
% Ex. For a marker 'BadMarker' with a gap between frames 500-700 (where all
% of these frames are missing data for 'BadMarker'), to be filled using the
% markers 'M1', 'M2', 'M3', and 'M4', given data in markerData: 
% newMarkerData = Vicon.RigidBodyFill(markerData, 'BadMarker', {'M1', 'M2', 'M3', 'M4'}, 499, 701)
%
% For more details see +Vicon/private/rigidBodyFill.m

    assert(iscellstr(donors), 'GapFill:BadInput', 'Donors must be provided as a cell array of character vectors.');
    assert(isstruct(markerData), 'GapFill:BadInput', 'Marker data must be provided as a struct of trajectories.')
    donorData = cellfun(@(n) {markerData.(n)}, donors);
    traj = rigidBodyFill(markerData.(markerToFill), donorData, t0, t1);
    markerData.(markerToFill) = traj;
end
