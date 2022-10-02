function gaitData=GaitCycleFromFP(fpData,varargin)
% Generate gait cycle based on forceplate heel strikes
% gaitData=gaitCycleFromFP(fpData,OPTIONS)
% Options:
% 'ForcePlate' forceplate name (default: Treadmill_R)
% 'Direction' forcedirection for segmenting (default: vy)
% 'Filter' include a lowpass filter to the fpData (default: false)
% 'ToeOff' (false)/true Compute toe-off instead of heel strike
narginchk(1,5);

p = inputParser;
p.addParameter('ForcePlate','Treadmill_R');
p.addParameter('Direction','vy');
p.addParameter('Filter',false);
p.addParameter('ToeOff',false,@islogical);
p.parse(varargin{:});
fpName = p.Results.ForcePlate;
fpDirection=p.Results.Direction;
Filter=p.Results.Filter;
ToeOff=p.Results.ToeOff;

if ToeOff
    gaitName=[fpName '_Off'];
else
    gaitName=[fpName '_Strike'];
end

fpCol=[fpName '_' fpDirection];

%%
%%% Apply Filter
fpData = Osim.interpret(fpData, 'MOT', 'table');
a=diff(fpData.Header);
if (max(a)-min(a))>1E-10
    error('Data are not uniformly sampled');
end
FS=1/mean(a);

filteredFpData=fpData;
if Filter==true
    df0 = designfilt('lowpassiir','FilterOrder',10,'Halfpowerfrequency',10,'SampleRate',FS,'DesignMethod','butter');    
    filteredFpData{:,2:end}=filtfilt(df0,fpData{:,2:end});    
end
    

% Force threshold 
MinForce=25;
MaxForce=100;
x=filteredFpData.(fpCol);
xdigital=digitalSchmittTrigger(x,'Vlow',MinForce,'Vhigh',MaxForce);
heelStrikeEvents=(([0; diff(xdigital)])==1);
toeOffEvents=(([0; diff(xdigital)])==-1);

if ToeOff
    events=toeOffEvents;
else
    events=heelStrikeEvents;
end

% Gait cycle is on LOCS
LOCS=find(events);
gait=zeros(size(fpData,1),1);
for i=1:(numel(LOCS)-1)       
    gait(LOCS(i):LOCS(i+1)-1)=linspace(0,100,LOCS(i+1)-LOCS(i));    
end    
gaitData=table(fpData.Header,gait,'VariableNames',{'Header',gaitName});

end