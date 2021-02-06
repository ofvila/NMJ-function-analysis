function [stimulationIndices, stimulationTrace, realStimulationIndices] = getOSProtocol(info, numSteps, startFrequency, endFrequency)
%GETOSPROTOCOL Recreates the Arduino ramp stimulation protocol
%from initial parameters
%
%   [stimulationIndices, stimulationTrace] =
%   getRampStimulationProtocol(info, numSteps, startFrequency,
%   endFrequency) takes the start and end stimulation frequencies as well
%   as the number of total pulses to traverse the range, and returns a
%   vector stimulationIndices storing the frames corresponding to the
%   beginnings of each pulse, as well as a stimulationTrace set to 1 for
%   the duration of each pulse and 0 elsewhere with the same length as the 
%   movieStack corresponding to the info variable.  By default, this
%   program assumes that the initial pause between turning the red light on
%   and starting the blinking blue pulses is 5 seconds.  It also assumes
%   that stimulation pulses are 100ms.
%   Real stimulation indices stores the real float values when the
%   stimulation is taking place

% Arduino waits 5 seconds after turning on light before starting 
% stimulation
startPauseLength = 5;
startRampFrame = 1 + info.frameRate*startPauseLength;

% stimulation pulses are 50ms
pulseLength = (0.05*info.frameRate);

% Get ready for dynamic update
ddFrequency = (startFrequency - endFrequency)/numSteps;
dynamicFrequency = startFrequency;    

% create stimulation trace
stimulationTrace = zeros(size(info.timeBase));

% get indices for stimulation relative to beginning of ramp and create
% stimulation trace
frameCounter = startRampFrame;
for i = 1:numSteps
   
    % get next stimulation pulse start frame
    stimulationIndices(i) = (frameCounter);
    realStimulationIndices(i) = frameCounter;
    % pulses are 50ms
    stimulationTrace(stimulationIndices(i):(stimulationIndices(i) + pulseLength)) = 1;
    
    % update frameCounter based on current frequency
    
    dynamicFrames = info.frameRate/dynamicFrequency;
    frameCounter = frameCounter + dynamicFrames;
    
    % update frequency
    dynamicFrequency = dynamicFrequency - ddFrequency;
    
end

end

