%Shoulder Simulation Video Function
function result = ShoulderVid(cycles, newFile, expFile)

% sysPrefix = '/usr/local/bin/';
sysPrefix = '';

%Checking the initial number of videos in the file
expFile = ['Shoulder-Day-' num2str(newFile)];
cd(expFile);
cmd = 'dir /A:D /B | find /c /v ""';
[status,val] = system(cmd);
val = str2num(val(1,1));
cd ..;

%Creating the template to name the videos
videoName = ['Shoulder' num2str(newFile) '-Cycle' num2str(cycles)];

%Recording 7 second videos
cmd =  [sysPrefix 'Debut -record -file ' videoName];
system(cmd);

pause(7)

cmd = [sysPrefix 'Debut -stop'];
system(cmd);

%Checking to see if it worked

cd(expFile);
cmd = 'dir /A:D /B | find /c /v ""';
[status,val] = system(cmd);
val2 = str2num(val(1,1));

if (val2-val)
    result = 1;
else
    result = 0;
end

%Returning to the Shoulder-Files folder
cd ..

trash = clipExtractB(videoName,cycles,expFile);

end

