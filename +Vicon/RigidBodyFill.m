function markersData = RigidBodyFill(markersData, markerToFill, donors, t0, t1,varargin)
% markerData = RigidBodyFill(markerData, markerToFill, donors, t0, t1)
%
% RigidBodyFill fills a gap between frames (headers) t0 and t1 in a marker whose name
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
% newMarkerData = RigidBodyFill(markerData, 'BadMarker', {'M1', 'M2', 'M3', 'M4'}, 499, 701)
%
% Options (defaults):
% 'FW' true/(false) Use fw algorithm to reduce constraints (less accuracy but less restrictions)
% For more details see +Vicon/private/rigidBodyFill.m

p=inputParser();
p.addParameter('FW',false,@islogical);
p.parse(varargin{:});

FW=p.Results.FW;

    assert(iscellstr(donors), 'GapFill:BadInput', 'Donors must be provided as a cell array of character vectors.');
    assert(isstruct(markersData), 'GapFill:BadInput', 'Marker data must be provided as a struct of trajectories.');
    assert(numel(donors)>2,'GapFill:BadInput', 'Not enough donors provided for RigidBodyFill');
    donorData = cellfun(@(n) {markersData.(n)}, donors);
    donorData = cellfun(@(n) {n{:,2:end}},donorData);    
    markerData=markersData.(markerToFill);
    %Find index corresponding to t0 and t1 header
    header=markerData.Header;
    t0_idx=find(header==t0,1);
    t1_idx=find(header==t1,1);
	if FW
		traj = rigidBodyFillFW(markerData{:,2:end}, donorData, t0_idx, t1_idx);
	else
		traj = rigidBodyFill(markerData{:,2:end}, donorData, t0_idx, t1_idx);
	end
    z=markersData.(markerToFill);
    z{t0_idx:t1_idx,2:end}=traj(t0_idx:t1_idx,:);
    markersData.(markerToFill)=z;    
end
