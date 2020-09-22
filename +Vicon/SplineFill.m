function [markerData,err] = SplineFill(markerData, markerToFill, t0, t1,varargin)
% [markerData,err] = SplineFill(markerData, markerToFill, t0, t1)
%
% Spline fills a gap between frames t0 and t1 in a marker whose name
% is given in markerToFill. The marker data should be provided as
% a struct of nx3 arrays in markerData. Missing marker data should be
% represented with NaN, as opposed to zeros. 
% e.g.
% newMarkerData = SplineFill(markerData, 'BadMarker', t0,t1);
% 
% Update for 08/20 Includes a safeguard that prevents filling when the two
% points of the gaps are not connecting by iterpolation. In that case the
% markerData is not affected and err=true.
%
% For more details see +Vicon/SplineFill
% See also Vicon


    p=inputParser();
    p.addParameter('MaxError',40,@isnumeric); %[mm]
    p.parse(varargin{:});
    MAXERROR=p.Results.MaxError;

    x=markerData.(markerToFill);
    header=x.Header;
    t0_idx=find(header==t0,1);
    t1_idx=find(header==t1,1);
    
    t = header;
    framesToKeep = all(~isnan(x.Variables),2);
    y = x{framesToKeep,2:end};
    t = t(framesToKeep);
    
    a=interp1(t,y,(t0:t1),'pchip');    
    
    %Safeguard do not spline fill if there is a sudden jump from t0 to t1    
    erForward=inf; erBackward=inf;
    locs=t<t0;
    if sum(locs)>3  
        b=interp1(t(locs),y(locs,:),t1,'linear','extrap');
        erForward=norm((a(end,:)-b),2);
        %{
        Topics.plot(markerData,markerToFill); hold on;
        plot(t0:t1,a(:,1));plot(t0:t1,a(:,2));plot(t0:t1,a(:,3));
        plot(t1,b(1),'bx'); plot(t1,b(2),'rx'); plot(t1,b(3),'yx');        
        %}
    else
        locs=t>t1;
        if sum(locs)>3  
            b=interp1(t(locs),y(locs,:),t0,'linear','extrap');
            erBackward=norm((a(end,:)-b),2);
            %{
            Topics.plot(markerData,markerToFill); hold on;
            plot(t0,b(1),'bx'); plot(t0,b(2),'rx'); plot(t0,b(3),'gx');     
            %}
        end
    end
    
    
    
    %%
    
    if (erForward<MAXERROR) || (erBackward<MAXERROR)
        err=false;
    else
        err=true;
        return;
    end
    
        
    x{t0_idx:t1_idx,2:end}=a;
    markerData.(markerToFill)=x;
end
