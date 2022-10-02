%% Read the marker data into a table (Header column contains the time in s)
trc=Vicon.C3DtoTRC('SampleFiles\speed_0_5.c3d');
trc{:,2:end}=Vicon.transform(trc{:,2:end},'ViconXYZ'); %transform from Osim (default) to Vicon coordinates

%% Read the forceplate data and location of forceplates
fp=Vicon.C3DtoMOT('SampleFiles\speed_0_5.c3d');
fp{:,2:end}=Vicon.transform(fp{:,2:end},'ViconXYZ'); %transform from Osim (default) to Vicon coordinates
fpLocations=Vicon.ExtractCorners('SampleFiles\speed_0_5.c3d');
fpLocations.FP1{:,2:end}=Vicon.transform(fpLocations.FP1{:,2:end},'ViconXYZ'); %transform from Osim (default) to Vicon coordinates
fpLocations.FP2{:,2:end}=Vicon.transform(fpLocations.FP2{:,2:end},'ViconXYZ'); %transform from Osim (default) to Vicon coordinates

%% Plot as a time series
figure(1);
subplot(1,3,1);
plot(trc.Header,trc.LASIS_x);
xlabel('Time (s)'); ylabel('LASIS_x (mm)');

subplot(1,3,2);
plot(trc.Header,trc.LASIS_y);
xlabel('Time (s)'); ylabel('LASIS_y (mm)');

subplot(1,3,3);
plot(trc.Header,trc.LASIS_z);
xlabel('Time (s)'); ylabel('LASIS_z (mm)');


%% Plot marker trajectory in time and location of forceplates
fp1points=[reshape(fpLocations.FP1{1,2:end},3,4) fpLocations.FP1{1,2:4}'];
fp2points=[reshape(fpLocations.FP2{1,2:end},3,4) fpLocations.FP2{1,2:4}'];

figure(1);
plot3(trc.LASIS_x,trc.LASIS_y,trc.LASIS_z,'b'); hold on;
plot3(trc.RASIS_x,trc.RASIS_y,trc.RASIS_z,'r'); 
plot3(trc.LLKNEE_x,trc.LLKNEE_y,trc.LLKNEE_z,'b'); 
plot3(trc.RLKNEE_x,trc.RLKNEE_y,trc.RLKNEE_z,'r'); 
plot3(trc.LLTOE_x,trc.LLTOE_y,trc.LLTOE_z,'b'); 
plot3(trc.RLTOE_x,trc.RLTOE_y,trc.RLTOE_z,'r'); 
plot3(fp2points(1,:),fp2points(2,:),fp2points(3,:),'b'); 
plot3(fp1points(1,:),fp1points(2,:),fp1points(3,:),'r'); hold off;
xlabel('x (mm)'); ylabel('y (mm)'); zlabel('z (mm)');

%% Plot using vsk
figure(1); clf;
Vicon.model.plot('SampleFiles\TFSubject.vsk',trc(100,:)); hold on;
plot3(fp2points(1,:),fp2points(2,:),fp2points(3,:),'b'); 
plot3(fp1points(1,:),fp1points(2,:),fp1points(3,:),'r'); hold off;
daspect([1 1 1]);