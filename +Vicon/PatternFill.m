function markersData = PatternFill(markersData, markerToFill, donor, t0, t1,varargin)
% newMarkerData = PatternFill(markerData, markerToFill, donor, t0, t1)
%
% PatternFill fills a gap between frames t0 and t1 in a marker whose name
% is given in markerToFill using the marker whose name is provided in donor
% as a template to pattern off of, following Vicon's Pattern Fill feature.
% The starting frame t0 should be the last frame before the gap starts, and
% t1 should be the first frame after the gap ends. The marker data should
% be provided as a struct of nx3 arrays in markerData. Missing marker
% data should be represented with NaN, as opposed to zeros. 
%
% Ex. For a marker 'BadMarker' with a gap between frames 500-700 (where all
% of these frames are missing data for 'BadMarker'), to be filled using the
% marker 'GoodMarker', given data in markerData: 
% newMarkerData = PatternFill(markerData, 'BadMarker', 'GoodMarker', 499, 701)
%
% Options (defaults):
% 'FW' true/(false) Use fw algorithm to reduce constraints (less accuracy but less restrictions)

p=inputParser();
p.addParameter('FW',false,@islogical);
p.parse(varargin{:});

FW=p.Results.FW;

    assert(isstruct(markersData), 'GapFill:BadInput', 'Marker data must be provided as a struct of trajectories.')
    % identify best donor based on which is closest
    markerData=markersData.(markerToFill); 
    header=markerData.Header;
    t0_idx=find(header==t0,1);
    t1_idx=find(header==t1,1);
    if iscell(donor)
        % remove invalid donors with no data in the gap        
        goodDonorMask = ~cellfun(@(d) all(all(isnan(markersData.(d){t0_idx+1:t1_idx-1, 2:end}))), donor);
        donor = donor(goodDonorMask);
        if isempty(donor)
            error('GapFill:NoDonors', 'No valid donors.')
        end
        startDists = cellfun(@(d) norm(markersData.(d){t0_idx, 2:end} - markersData.(markerToFill){t0_idx, 2:end}), donor);
        endDists = cellfun(@(d) norm(markersData.(d){t1_idx, 2:end} - markersData.(markerToFill){t1_idx, 2:end}), donor);
        dists = (startDists + endDists)/2;
        [~, bestDonorIdx] = min(dists);
        donor = donor{bestDonorIdx};
    end
	if FW
		traj = patternFillFW(markersData.(markerToFill){:,2:end}, markersData.(donor){:,2:end}, t0_idx, t1_idx);
	else
		traj = patternFill(markersData.(markerToFill){:,2:end}, markersData.(donor){:,2:end}, t0_idx, t1_idx);
	end
    z=markersData.(markerToFill);
    z{t0_idx:t1_idx,2:end}=traj(t0_idx:t1_idx,:);
    markersData.(markerToFill)=z;        
end
