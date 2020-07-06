expFile = './';
videoName = 'Shoulder2-Cycle0';
clipExtractB_test(videoName,0,expFile)

function output = clipExtractB_test(videoName,cycles,expFile)

cd(expFile)

% options / settings
clipLength = 5.0; % [sec] length of clips to extract
%sysPrefix = '/usr/local/bin/';  % needed for Mac, for some reason?
sysPrefix = ''; % use this on MAK PC

sprintf(videoName)


% get number of frames in file
cmd = [sysPrefix 'ffprobe -v error -select_streams v:0 -show_entries stream=nb_frames -of default=nokey=1:noprint_wrappers=1 ' videoName '.avi'];

sprintf(cmd);
[~,numFramesStr] = system(cmd);
sprintf(numFramesStr);
numFrames = str2num(numFramesStr)

% get framerate
cmd = [sysPrefix, 'ffprobe -v 0 -of csv=p=0 -select_streams v:0 -show_entries stream=r_frame_rate ', videoName, '.avi'];
[~,frameRateStr] = system(cmd)
frameRate = eval(frameRateStr)

% % generate list of frame numbers on which to start extraction
% clipLengthNum = floor(frameRate*clipLength);
% clipLengthStr = constRateTimecode(clipLengthNum,frameRate);
%  % could make this something other than linear, and adjust starting point
% 
% % extract clips
%     startTimecode = constRateTimecode(1,frameRate);
%     cmd = [sysPrefix 'ffmpeg -y -r ' sprintf('%05.2f',frameRate) ' -i ' videoName '.avi' ' -ss 1' ' -t ' clipLengthStr ' ' sprintf('glenoid_cycle%08d.mov',cycles)];
%     system(cmd);
%     
cd ..

output = 1;
end