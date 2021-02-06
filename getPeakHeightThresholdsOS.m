function [ peakHeightThresholds ] = getPeakHeightThresholdsOS(timeBase, trace, useDefaultFlag)

%GETPEAKTHRESHOLDSOS Gets threshold for minimum peak height
%   [ threshold ] = getPeakHeightThresholdsOS(timeBase, trace, 
%   useDefaultFlag) asks the user to select a minimum height for automated 
%   peak identification on trace or uses default

if nargin < 3
    useDefaultFlag = 0;
end

figure(134);
clf(134);
set(134, 'Position', [0 0 1920 1030]);
colors = [{'b'} {'g'} {'r'} {'k'}];

    
plot(timeBase, trace, '-x');
grid on;
grid minor;
xlabel('Time (seconds)')
ylabel('Magnitude')
title(['Trace']);

default = (max(trace) - (min(trace)))/4 + min(trace);
      
    % Get threshold from user
    if useDefaultFlag == 0
        peakHeightThresholds = str2double( ...
            inputdlg('Input an amplitude above which there are only peaks', ...
            'threshold', 1, {num2str(default)}));
    
    % otherwise calculate  default
    else if useDefaultFlag == 1
        peakHeightThresholds = default; 
    end
% end

close(134);

end
