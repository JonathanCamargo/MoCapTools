function [bestView,limitsX,limitsY,limitsZ,v]=bestView(trc)
    % [bestView,mincoords,maxcoords,v]=bestView(trc)
    % For a marker table find the best View angles for the viewport
    trc=Osim.interpret(trc,'TRC','table');
    x=trc{:,2:end}';
    x=reshape(x,3,[])';        
    mincoords=min(x);
    maxcoords=max(x);
    limitsX=[mincoords(1) maxcoords(1)];
    limitsY=[mincoords(2) maxcoords(2)];
    limitsZ=[mincoords(3) maxcoords(3)];
    v=pca(x);
    bestView=(0*v(:,2)+1*v(:,3));
end