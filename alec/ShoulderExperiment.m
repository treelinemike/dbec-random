%Composite Shoulder Experiment

%Commands to run Matlab from thayer network

%>ssh f002t74@babylon1.thayer.dartmouth.edu
%matlab -nodisplay -nosplash -nodesktop -r "try, run ('ShoulderExperiment.m'); end; quit"


%Opening video capture program.
%sysPrefix = '/usr/local/bin/';

%cmd = 'osascript -e ''tell app "Debut" to activate''';
%system(cmd);

sysPrefix = '';

%Setting up video formatting
cmd = [sysPrefix 'Debut -sound off'];
system(cmd)
cmd = [sysPrefix 'Debut -format avi'];
system(cmd)

%Navigating to the appropriate directory

% cd ..
% cd ..
cd C:\Users\f00439p\Desktop\Shoulder-Files\ 
%Desktop/Shoulder-Files

%Creating an output folder for the videos

cmd = 'dir /A:D /B | find /c /v ""';
[status,val] = system(cmd);
Num = str2num(val(1,1));

newFile = Num;

expFile = ['Shoulder-Day-' num2str(newFile)];
mkdir(expFile);

%Setting output of Debut video to correct folder
cmd = [sysPrefix 'Debut -videodir C:\Users\f00439p\Desktop\Shoulder-Files\' expFile];
system(cmd);


%Function call

cyclesa = 0:50:24000;
cyclesb = 26000:2000:50000;
cyclesc = 55000:1000:100000;

cycles = [cyclesa cyclesb cyclesc];

freq = 2; %Frequency in Hz

AugCycles = [0 cycles(1:end-1)];

time = (cycles-AugCycles)/freq;
time = [time(2:end) 0];

l = 1;

for temp = cycles
    
working = ShoulderVid(temp, newFile)

tic
pause(time(l)-7)
l=l+1;

toc
end

%Restoring the path to the default Matlab path 
cd ..
cd ..
cd Documents/MATLAB
