function [intensityTrace] = getIntensityTrace(info, ...
    movieStack, outputDirectory, scanName, doNotCorrectDriftFlag)
%GETINTENSITYTRACE Returns traces quantifying changes in light intensity
% 
%   [intensityTrace] = getIntensityTrace(numROIs, ROIs, info, 
%   movieStack, outputDirectory, scanName, doNotCorrectDriftFlag) returns
%   traces that quantify the summed intensity in every given region of 
%   interest in the movieStack.  The doNotCorrectDriftFlag can be set to 1
%   to stop drift correction.

if nargin < 7
    
    doNotCorrectDriftFlag = 0;
    
end
    % Create trace
    temp = mean(mean(movieStack));
    intensityTrace = squeeze(temp);
    
    if ~doNotCorrectDriftFlag
      
        % Correct for drift
        intensityTrace = correctDrift(info.timeBase, ...
            intensityTrace, outputDirectory, scanName);
        
    end
    
% end

end

