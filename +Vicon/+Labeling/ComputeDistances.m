function [distancesMatrix,lnames]=ComputeDistances(allmarkers)
% Find the distance between every marker to every other marker. Returns an 
% N-by-N matrix with the distance.
% distancesMatrix=Label_ComputeDistances(allmarkers);

[allnames,umarkers,unames,lmarkers,lnames]=Vicon.MarkerCategories(allmarkers);

 nframes=size(allmarkers.(lnames{1}),1);
    lmarkerstbl=Osim.interpret(lmarkers,'TRC');
    distance=zeros(numel(lnames),numel(lnames),nframes);
    for i=1:nframes
        x=lmarkerstbl{i,2:end};
        x=reshape(x,3,numel(lnames))';
        distance(:,:,i)=GetDistance(x,x);    
    end
    M=nanmean(distance,3);      
    distancesMatrix=M;
end

%% % HELPER FUNCTIONS%%%%
function distance=GetDistance(x,y)
% For a matrix x (NxM) and a matrix y (QxM) compute
% the distance in Rm between each sample in N vs each sample in Q.

%%
[xi,yi]=ndgrid(1:size(x,1),1:size(y,1));
X=x(xi(:),:);
Y=y(yi(:),:);
distance=vecnorm((X-Y),2,2);
distance=reshape(distance,size(x,1),size(y,1));
end