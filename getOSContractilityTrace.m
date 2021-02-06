function [contractilityTrace baselineFrameIndex] = ...
    getOSContractilityTrace(info, movieStack, outputDirectory, scanName, ...
    doNotCorrectDriftFlag, useDefaultFlag, defaultBaselineFrame)
%GETOSCONTRACTILITYTRACE Returns traces quantifying contractile motion
%   [contractilityTrace baselineFrameIndex] = getOSContractilityTrace(
%   numFrames, frameRate, timeBase, movieStack, 
%   outputDirectory, scanName, doNotCorrectDriftFlag) analyzes the 
%   contractile motion in every given region of interest in the movieStack 
%   and returns traces that quantify the contractile motion, as well as the
%   index of the baseline frame used for comparison.  The value of the 
%   trace at each frame is determined by the pixel-by-pixel gray level 
%   difference from a baseline frame selected by the user.  This function
%   automatically corrects for baseline drift by calling the correctDrift
%   function (polynomial fit subtraction).

if nargin < 5
    
    doNotCorrectDriftFlag = 0;
    
end

if nargin < 6
   
    useDefaultFlag = 0;
    
end

if nargin < 7
    
    defaultBaselineFrame = 1;
    
end

    dataToAnalyze = cast(movieStack, 'int32');
    
    % get available memory
    arrayStats = whos ('dataToAnalyze');
    arrayMemory = arrayStats.bytes;
    [user system] = memory;
    memorySystem = system.PhysicalMemory.Available;
    
    % calculate maximum array size for calculations
    maxArrayMemoryCalculations = memorySystem/3;
    fraction = maxArrayMemoryCalculations/arrayMemory;
    divisions = ceil(1.0/fraction) + 2;
        
    % calculate initial trace
    for i = 1:divisions
        
        start = floor((i-1)*info.numFrames/divisions) + 1;
        finish = floor(i*info.numFrames/divisions);
        
        dataToCalculate = dataToAnalyze(:, :, start:finish);
        
        globalTimeCourse(start:finish) =  ...
            squeeze( mean( mean(abs(dataToCalculate - ...
            repmat(dataToAnalyze(:, :, 1), [1, 1, (finish - start) + 1])))));
        
    end
    
    % Fix baseline frame discontinuity problem for axis scaling
    globalTimeCourse(1) = globalTimeCourse(2);
    
    figure(230);
    plot(info.timeBase, globalTimeCourse(1:end),'-x');
    title(['Contractility trace' ]);
    set(230, 'Position', [0 0 1920 1030]);
    grid on;
    grid minor;
    options.Resize='on';
    options.WindowStyle='normal';
    options.Interpreter='tex';
    
    % if we are picking the baseline frame
    if ~useDefaultFlag
        
        % Pick baseline frame
        baselineTime = ...
            str2double(inputdlg('input a baseline timepoint (in seconds)', ...
            'baseline time', 1, {'1'}, options));
        baselineFrameIndex = round(baselineTime * info.frameRate);
      
        close(230);
        
        % Calculate final trace
        for i = 1:divisions
            
            start = floor((i-1)*info.numFrames/divisions) + 1;
            finish = floor(i*info.numFrames/divisions);
            
            dataToCalculate = dataToAnalyze(:, :, start:finish);
            
            contractilityTrace(start:finish) =  ...
                squeeze( mean( mean(abs(dataToCalculate - ...
                repmat(dataToAnalyze(:, :, baselineFrameIndex), ...
                [1, 1, (finish - start) + 1])))));
            
        end
        
        % Fix baseline frame discontinuity problem
        contractilityTrace(baselineFrameIndex) = ...
            mean(contractilityTrace([(baselineFrameIndex - 1) ...
            (baselineFrameIndex + 1)]));
        
        if ~doNotCorrectDriftFlag
            
            % Correct for drift
            contractilityTrace(:) = correctDrift(info.timeBase, ...
                contractilityTrace(:), outputDirectory, scanName);
            
        end
        
        close all;
        
    
    % if we are not picking the baseline frame
    else
        
         % Pick baseline frame
        baselineFrameIndex = round(defaultBaselineFrame*info.frameRate);
        
        % Calculate final trace
        for i = 1:divisions
            
            start = floor((i-1)*info.numFrames/divisions) + 1;
            finish = floor(i*info.numFrames/divisions);
            
            dataToCalculate = dataToAnalyze(:, :, start:finish);
            
            contractilityTrace(start:finish) =  ...
                squeeze( mean( mean(abs(dataToCalculate - ...
                repmat(dataToAnalyze(:, :, baselineFrameIndex), ...
                [1, 1, (finish - start) + 1])))));
            
        end
        
        % Fix baseline frame discontinuity problem
        contractilityTrace(baselineFrameIndex) = ...
            mean(contractilityTrace([(baselineFrameIndex - 1) ...
            (baselineFrameIndex + 1)]));
        
        if ~doNotCorrectDriftFlag
            
            % Correct for drift
            contractilityTrace = correctDrift(info.timeBase, ...
                contractilityTrace, outputDirectory, scanName);
            
        end
        
        close all;
        
        
    end
    
    contractilityTrace = contractilityTrace';
end

