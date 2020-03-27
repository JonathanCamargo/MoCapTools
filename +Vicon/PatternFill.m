function markerData = PatternFill(markerData, markerToFill, donor, t0, t1)
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
% newMarkerData = Vicon.PatternFill(markerData, 'BadMarker', 'GoodMarker', 499, 701)

    assert(isstruct(markerData), 'GapFill:BadInput', 'Marker data must be provided as a struct of trajectories.')
    % identify best donor based on which is closest
    if iscell(donor)
        % remove invalid donors with no data in the gap
        goodDonorMask = ~cellfun(@(d) all(all(isnan(markerData.(d)(t0+1:t1-1, :)))), donor);
        donor = donor(goodDonorMask);
        if isempty(donor)
            error('GapFill:NoDonors', 'No valid donors.')
        end
        startDists = cellfun(@(d) norm(markerData.(d)(t0, :) - markerData.(markerToFill)(t0, :)), donor);
        endDists = cellfun(@(d) norm(markerData.(d)(t1, :) - markerData.(markerToFill)(t1, :)), donor);
        dists = (startDists + endDists)/2;
        [~, bestDonorIdx] = min(dists);
        donor = donor{bestDonorIdx};
    end
    traj = patternFill(markerData.(markerToFill), markerData.(donor), t0, t1);
    markerData.(markerToFill) = traj;
end
