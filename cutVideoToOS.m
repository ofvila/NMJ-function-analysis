function [info, movieStack, stimulationIndices, realStimulationIndices,stimulationTrace ] = ...
    cutVideoToOS(info, movieStack, ...
    stimulationIndices,realStimulationIndices, stimulationTrace,outputDirectory, scanName)

%CUTVIDEOTOOS Syncs movie and stimulation
%
%   [info, movieStack, stimulationIndices, stimulationTrace] = 
%   cutVideoToOS(info, movieStack, movieStack, 
%   stimulationIndices, stimulationTrace, outputdirectory, scanName) will 
%   search the movieStack for when the light turns on and cut the movie to 
%   start 300 frames afterwards.  It will cut the movie to end one second 
%   after the last stimulation pulse, which is extracted from the 
%   stimulationIndices.  It adjusts the info variable to account for the 
%   new parameters, and also adjusts the stimulationIndices and the 
%   stimulationTrace to line up with the new movieStack.

% get just one intensity trace
intensityTrace = getIntensityTrace(info, movieStack, ...
    outputDirectory, scanName);

% take derivative to use find peak function
intensityDerivativeTrace = diff(intensityTrace);

% get threshold for peak
peakHeightThreshold = max(intensityDerivativeTrace)/2;

% find time when light turns on
[peaks locs] = findpeaks(intensityDerivativeTrace, 'MinPeakHeight', ...
    peakHeightThreshold);

% plot derivative trace and mark time when light turns on
figure;
plot(intensityDerivativeTrace, '-x');
hold on;
plot(locs, intensityDerivativeTrace(locs, 1),'rx', 'MarkerSize', 15);
pause(0.1);

% set startSyncFrame to the frame corresponding to when the light turns on
startSyncFrame = locs(1);

% wait for light to turn on fully
lightPauseLength = 0.3*info.frameRate;

% set startMovieFrame to the frame corresponding to when the light is
% already on
startMovieFrame = startSyncFrame + lightPauseLength;

% cut movie to end one second after the last stimulation pulse
endMovieFrame = round(startSyncFrame + stimulationIndices(size(stimulationIndices, 2)) + 1*info.frameRate);

% if for some reason the user does not take a long enough movie
if endMovieFrame > size(movieStack, 3);
    endMovieFrame = size(movieStack, 3); 
end

% continue to cut movie to end one second after the last stimulation pulse
movieStack = movieStack(:, :, startMovieFrame:endMovieFrame);
info.numFrames = size(movieStack, 3);
info.timeBase = (1 : (info.numFrames)) ./ info.frameRate;

% cut stimulationTrace to match video
stimulationTrace = stimulationTrace(lightPauseLength:lightPauseLength + info.numFrames - 1);
stimulationIndices = stimulationIndices - lightPauseLength;
realStimulationIndices = realStimulationIndices - lightPauseLength;
% again, if the user does not take a long enough movie, need to edit
% stimulationIndices
brokenIndices = find(stimulationIndices > info.numFrames);

if ~isempty(brokenIndices)
    stimulationIndices = stimulationIndices(1:brokenIndices(1) - 1);
end


close all;

end