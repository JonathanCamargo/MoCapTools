# Automated Gap Filling and Tools for Motion Capture by the Sensor-Fusion team from EPIC lab @GeorgiaTech
 
If you find this code useful, please consider citing:
 ```
  @article{doi:10.1080/10255842.2020.1789971,
    author = { Jonathan   Camargo  and  Aditya   Ramanathan  and  Noel   Csomay-Shanklin  and  Aaron   Young },
    title = {Automated gap-filling for marker-based biomechanical motion capture data},
    journal = {Computer Methods in Biomechanics and Biomedical Engineering},
    publisher = {Taylor & Francis},
    doi = {10.1080/10255842.2020.1789971},
    note ={PMID: 32654510},
    URL = {https://doi.org/10.1080/10255842.2020.1789971}
  }
```
[Read the paper here](https://www.tandfonline.com/doi/abs/10.1080/10255842.2020.1789971?journalCode=gcmb20) 

### Purpose of this repo
This repository contains different tools to ease the MoCap analysis, including programmatically running OpenSim, and automatically gap-filling of data.

## Setting up this repo
In order to properly set up this repo, please make sure you have OpenSim downloaded and installed (http://simtk.org/frs/index.php?group_id=91), then run install.m to bind OpenSim to MATLAB, and to add this repo to your MATLAB path. For examples on how to use different functions in this repo, see +Osim/examples/example.m and +Vicon/examples/example.m

### Purpose of the Sensor-Fusion subteam
Our team is part of the EPIC lab at Georgia Institute of Technology (www.epic.gatech.edu) focuses on instrumentation with wearable sensors, including IMU, goniometers, pressure sensors and a novel epidermal flexible emg.  We are interested in analyzing the information carried by these sensors to develop intent recognition algorithms and gait state estimation using machine learning techniques. During Fall, we are setting up a full data collection system including motion capture and force plates in our terrain park that includes ramps, stairs and ground level walking. This will allow to study the biomechanics of ambulation for different conditions and get a better background for the development of controllers for our assistive devices.

### Contributing to this repo
Please feel free to clone this repo and add whatever functionality you see fit. When adding code, please try to maintain the overall file structure outlined below.  

### Documentation
All of the files within this repo should be well documented through the Matlab runtime environment. In order to read the documentation, type `help` in the Matlab command window followed by the name of any file. If the file does not contain documentation *please* feel free to include and request a pull. Brief documentation for an entire package can be seen by typing `help Vicon` or `help Osim` into the command line, which pulls documentation from each function in the package folder. 

### Getting started
Check the examples inside the +Vicon folder and inside the +Osim folder

### Who do I talk to?
If there are any questions regarding this repo, please contact:
* Jonathan Camargo: jon-cama@gatech.edu
* Aditya Ramanathan: aramanathan31@gatech.edu
* Noel Csomay-Shanklin: noelcs@gatech.edu

### External Code/Software
* All C3D file I/O is handled by Biomechanical ToolKit thanks to (https://github.com/Biomechanical-ToolKit/BTKCore/tree/master/Documentation/Wrapping/Matlab/btk)
* Calculation of inverse kinematics and inverse dynamics is handled by OpenSim (https://opensim.stanford.edu/)
### Tree structure of related directories 
<pre>
./..  
├── +Osim /                   Package to group all the OpenSim related functions, including inverse kinematics and inverse dynamics
├── +Vicon /                  Package to group all the Vicon related functions, including iterative gap-filling and C3D file I/O
├── extlib /                  Third-party libraries, including BTK
├── lib /                     common utilities that do not fit in classes (general)
├── functionSignatures.json / JSON used by MATLAB to suggest inputs to functions via tab-completion
├── install.m /               Script to set up tools required for this repo
└── README.md  

</pre>
