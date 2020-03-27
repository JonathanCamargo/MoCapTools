function x=digitalSchmittTrigger(x,varargin)
%% For an analog sampled digital signal transform to digital using
% Schmitt Trigger diode behavior. 
% x=digitalSchmittTrigger(x,OPTIONAL)
% If x is a matrix rows are the samples and columns independent channels
% Options:
% 'Vlow':low voltage threshold
% 'Vhigh':high voltage threshold


p=inputParser;
p.addOptional('Vlow',[]);
p.addOptional('Vhigh',[]);
p.parse(varargin{:});

vlow=p.Results.Vlow;
vhigh=p.Results.Vhigh;

if isempty(vlow)
    vlow=0.25*max(x);
elseif (numel(vlow)==1)
     vlow=repmat(vlow,size(x,2),1);
end

if isempty(vhigh)
    vhigh=0.75*max(x);
else
    vhigh=repmat(vhigh,size(x,2),1);
end

    if size(x,2) >1 && size(x,1)>1
        for i=1:size(x,2)
            x(:,i)=digitalSchmittTrigger_vector(x(:,i),vlow(i),vhigh(i));
        end
    else
        x=digitalSchmittTrigger_vector(x,vlow,vhigh);
    end
end

    function x=digitalSchmittTrigger_vector(x,vlt,vht)
            VMAX=max(x);
            VMIN=min(x);
            if (VMAX<1 || VMIN>0.25)
                error('Signal has wrong range: %f V,\n setting to 0 V',VMAX-VMIN);            
            end
            
          
            LOW=vlt; HIGH=vht;
            if x(1)<HIGH
                state=false;
            else
                state=true;
            end
            for i=1:numel(x)
                %{
                if x(i)<=LOW && state==false
                    x(i)=0;
                elseif x(i)<LOW && state==true
                    x(i)=0; state=false;
                elseif x(i)>HIGH && state==false
                    x(i)=VMAX; state=true;
                elseif x(i)>=HIGH && state==true
                    x(i)=VMAX; state=true;
                elseif x(i)>LOW && state==false
                    x(i)=0; state=false;                    
                elseif x(i)<HIGH && state==true
                    x(i)=VMAX; state=true;
                elseif x(i)
                end
                %}
                 if state==false
                     if x(i)>=HIGH
                        x(i)=true;
                     else
                         x(i)=false;
                     end
                 elseif x(i)<=LOW
                        x(i)=false;
                 else
                     x(i)=true;
                 end
                 state=x(i);
            end
    end