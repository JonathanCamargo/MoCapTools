function out=getSticks(vskFile)
% Get sticks from vsk model file
% returns a cell array with the sticks where first two columns are markers and 
% third column is the color.
% out=Vicon.model.getSticks(vskFile)

modelFile=vskFile;


doc=xmlread(modelFile);

sticks = doc.getElementsByTagName('Stick');

marker1Names=cell(sticks.getLength,1);
marker2Names=cell(sticks.getLength,1);
colorcitos=cell(sticks.getLength,1);

for i=0:sticks.getLength-1
    stick=sticks.item(i);
    marker1Name=stick.getAttribute('MARKER1');
    marker2Name=stick.getAttribute('MARKER2');
    % Warning replace . to _ to make it consistent with matlab field
    % indexing.
    marker1Name=strrep(char(marker1Name),'.','_');
    marker2Name=strrep(char(marker2Name),'.','_');
    marker1Names{i+1}=marker1Name;
    marker2Names{i+1}=marker2Name;
    
    rgb1=stick.getAttribute('RGB1');
    rgb2=stick.getAttribute('RGB2'); %Not sure why it has two colors if both are equal pick 1 for now.
    
    colorcitos{i+1}=str2double(strsplit(rgb1.toCharArray'))/255;    
    
end

out=[marker1Names marker2Names colorcitos];