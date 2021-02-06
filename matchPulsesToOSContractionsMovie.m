function matchPulsesToOSContractionsMovie(movieStack, outputDirectory, movieDirectory, scanName, info, ...
    stimulationTrace, stimulationIndices,realStimulationIndices, contractilityTrace, peaks, ...
    locs, widths, peakMin,maxMatchLength)
%MATCHPULSESTOOSCONTRACTIONSMOVIE Pairs stimulation pulses with contractions,
%calculates statistics, and visualizes the data
%
%   matchPulsesToOSContractionsMovie(outputDirectory, scanName, info,
%   stimulationTrace, stimulationIndices, contractilityTrace, peaks, locs,
%   widths) matches pulses and contractions that occur within matchLength
%   seconds of each other.  If multiple contractions occur within
%   matchLength seconds of each other, only the first contraction is
%   assigned to that pulse (the second contraction is considered
%   untriggered).  Since contractions take time to complete, the time where
%   the contraction reaches half the peak prominence is used.  Similarly,
%   if multiple pulses occur within matchLength seconds of a contraction,
%   only the first pulse is matched to the contraction.
%
%   This function plots the stimulation trace against the contractility
%   trace, labels the pulses as effective/ineffective, and labels the
%   contractions as triggered/untriggered.
%
%   This function also plots the cumulative fraction of effective pulses
%   and fraction of triggered contractions as a function of increasing
%   time.  We expect the cumulative fractions to begin dropping as the
%   pacing rate begins to exceed the maximum capture rate of the tissue.
%   Similarly, this function also plots the moving average of effective
%   pulses and fraction of triggered contractions as a function of
%   increasing time.  These values are plotted against the expected
%   fractions if there were no correlation between the pulses and
%   contractions, given that pulses and contractions within matchLength
%   (default is 0.1 seconds) seconds of each other are marked as effective
%   and triggered respectively.
%
%   Finally, it calculates the maximum capture rate as the frequency at
%   which the fraction of effective pulses dips below the expected fraction
%   of effective pulses if there is no correlation.
%
%   This function alsocreates a .avi movie file , with the tissue recording
%   plotted against the traces in real-time and the optical stimulation

%% Match pulses to contractions
outputName = extractBefore(scanName,'.');
locsCopy = locs;

% Default is all contractions are untriggered
contractionMatch = zeros(size(locs));

% Default is all pulses are ineffective
pulseMatch = zeros(size(stimulationIndices))';

% Run through pulse data
for i = 1:size(stimulationIndices, 2)
    
    % find contractions that start in the matchLenght interval after the
    % pulse
    beginingIndex = find(peakMin > (realStimulationIndices(i)-10)& peakMin< (realStimulationIndices(i)+ maxMatchLength * info.frameRate),1);
    
    if (beginingIndex ~= 0)
            %% Find the contraction that follows that pulse
            contractionIndex = find(locsCopy > stimulationIndices(i), 1);
       
            contractionMatch(contractionIndex) = 1;

            % remove contraction from list of contractions that can be matched
            % to pulses
            peakMin(beginingIndex) = -500;
            pulseMatch(i) = 1; 
            
    end
    
end
 

%% Get statistics on triggered and untriggered contractions
triggeredContractions = locs(find(contractionMatch));
numTriggered = size(triggeredContractions, 1);
untriggeredContractions = locs(find(contractionMatch == 0));
numUntriggered = size(untriggeredContractions, 1);
totalContractions= numTriggered + numUntriggered;
fractionTriggered= numTriggered/totalContractions;
cumulativeFractionTriggered = ones(size(stimulationTrace));
for i = 1:size(contractionMatch, 1)
    
    if i < size(contractionMatch, 1)
        cumulativeFractionTriggered(locs(i):locs(i + 1)) = ...
            size(find(contractionMatch(1:i)), 1)/i;
    else
        
        cumulativeFractionTriggered(locs(i):end) = ...
            double(size(find(contractionMatch(1:i)), 1))/double(i);
    end
end

%% Get statistics on expected fraction of contractions that would be labeled
% triggered with no correlation between pulses and contractions
expectedRandomFractionTriggered = ...
    (size(stimulationIndices, 2) * maxMatchLength * info.frameRate) / ...
    info.numFrames;

expectedRandomFractionTriggeredTrace = zeros(size(stimulationTrace));
for i = 1:size(stimulationIndices, 2)
    % Make sure window for labeling triggered contractions for pulse i
    % does not extend past the end of the trace
    maxTriggeredTraceFrame = stimulationIndices(i) + maxMatchLength*info.frameRate;
    if (maxTriggeredTraceFrame < size(expectedRandomFractionTriggeredTrace, 1))
        maxTriggeredTraceFrame = size(expectedRandomFractionTriggeredTrace, 1);
    end
    expectedRandomFractionTriggeredTrace(stimulationIndices(i):stimulationIndices(i) + maxMatchLength*info.frameRate) = 1;
    
end

cumulativeExpectedRandomFractionTriggered = zeros(size(stimulationTrace));
for i = 1:size(stimulationTrace, 2)
    
    cumulativeExpectedRandomFractionTriggered(i) = size(find(expectedRandomFractionTriggeredTrace(1:i)), 2)/i;
    
end

%% Get statistics on effective and ineffective pulses
effectivePulses = stimulationIndices(find(pulseMatch));
numEffective = size(effectivePulses, 2);
ineffectivePulses = stimulationIndices(find(pulseMatch == 0));
numIneffective = size(ineffectivePulses, 2);
totalPulses = numEffective + numIneffective;
fractionEffective = numEffective/totalPulses;
%% Get statistics on expected fraction of pulses that would be labeled
% effective with no correlation between pulses and contractions

expectedRandomFractionEffective = (size(locs, 1) * (maxMatchLength) * ...
    info.frameRate)/info.numFrames;
%% Calculate score
score = (fractionEffective- expectedRandomFractionEffective )/(1-expectedRandomFractionEffective);

%% Visualize data

figureHandle = figure;

%% Create AVI with blinker for light and traces

frameRate = info.frameRate;
frameRateScaleDown = 1;
numFrames = info.numFrames;
frameScaleDown = 2;
lengthScaleDown = 1;

% Set Video Writer
fileName = [scanName '.avi'];
file = [movieDirectory fileName];
format = 'motion JPEG AVI';
videoWriter = VideoWriter(file, format);
videoWriter.FrameRate = frameRate/(frameScaleDown*frameRateScaleDown);
videoWriter.Quality = 50;
open(videoWriter);

% Set frames and time base
videoFrames = numFrames/(lengthScaleDown);
timebase = (0 : videoFrames - 1) ./ frameRate;

% Set color limits
clim = [double(min(min(min(movieStack)))) ...
    double(max(max(max(movieStack))))];

clim(2) = clim(2);

movieStorage = struct('cdata', cell(1,size(movieStack, 3)), ...
    'colormap',  cell(1,size(movieStack, 3)));

for frameID = 1: videoFrames
    
    % Handle frame scale down
    if (mod(frameID, frameScaleDown) == 0)
        
        figureHandle = figure;
        
        subplot(2, 1, 1);
        
        frame = movieStack(:, :, frameID);
        % adjust contrast
        frame = imadjust(frame,[0 0.5],[]);
        
        % Draw blue blinker if necessary
        if stimulationTrace(frameID) > 0
            rgbImage = drawBlueBlinker(frame, clim);
        else
            rgbImage = makeRGB(frame, clim);
        end
        
        % Draw figure
        image(rgbImage);
        axis image;
        title(['Time = ' num2str(timebase(frameID)) 's']);
        hold on;
        caxis([prctile(rgbImage(:), 1) prctile(rgbImage(:), 99)])
        
        % turn off axes labels and ticks
        set(gca, 'XTickLabel', '');
        set(gca, 'Xtick', []);
        set(gca, 'YTickLabel', '');
        set(gca, 'Ytick', []);
        
        % plot raw traces
        subplot(2, 1, 2)
        ylim manual
        hold on;
        p2 = plot(info.timeBase(1:frameID), contractilityTrace(1:frameID), 'k');
        ylim([-100 150])
        plots = p2;

        legendStrings = cellstr('Contractile Trace');

        % Get contractions and pulses displayed so far
        movieTriggeredContractionsMatch = triggeredContractions < frameID;
        movieTriggeredContractions = triggeredContractions(movieTriggeredContractionsMatch);
        movieUntriggeredContractionsMatch = untriggeredContractions < frameID;
        movieUntriggeredContractions = untriggeredContractions(movieUntriggeredContractionsMatch);
        
        movieEffectivePulsesMatch = effectivePulses < frameID;
        movieEffectivePulses = effectivePulses(movieEffectivePulsesMatch);
        movieIneffectivePulsesMatch = ineffectivePulses < frameID;
        movieIneffectivePulses = ineffectivePulses(movieIneffectivePulsesMatch);
        
        % Mark triggered and untriggered contractions
        if size(movieTriggeredContractions, 1) > 0
            
            p3 = plot(info.timeBase(movieTriggeredContractions), ...
                contractilityTrace(movieTriggeredContractions, 1),'gx', 'MarkerSize', 10);
            
            plots = cat(2, plots, p3);
            legendStrings = cat(2, legendStrings,'Triggered Contractions');
            
        end
        
        if size(movieUntriggeredContractions, 1) > 0
            p4 = plot(info.timeBase(movieUntriggeredContractions), ...
                contractilityTrace(movieUntriggeredContractions, 1),'rx', 'MarkerSize', 10);
            
            plots = cat(2, plots, p4);
            legendStrings = cat(2, legendStrings,'Untriggered Contractions');
            
        end
        
        axis([info.timeBase(1) info.timeBase(end) ...
            min(min(stimulationTrace), min(contractilityTrace)) ...
            max(max(stimulationTrace), max(contractilityTrace))]);
        
        % Mark effective and ineffective light pulses
        currentAxis = axis;
        if size(movieEffectivePulses, 2) > 0
            for i = 1:size(movieEffectivePulses, 2)
                p5 = plot([info.timeBase(round(movieEffectivePulses(i))) ...
                    info.timeBase(round(movieEffectivePulses(i)))], currentAxis(3:4), '-g','LineWidth',1);
            end
            
            % Add plot handles and legendStrings for legend
            plots = cat(2, plots, p5);
            legendStrings = cat(2, legendStrings, 'Effective Pulses');
        end
        
        if size(movieIneffectivePulses, 2) > 0
            for i = 1:size(movieIneffectivePulses, 2)
                
                p6 = plot([info.timeBase(round(movieIneffectivePulses(i))) ...
                    info.timeBase(round(movieIneffectivePulses(i)))], currentAxis(3:4), '-r','LineWidth',1);
            end
            
            % Add plot handles and legendStrings for legend
            plots = cat(2, plots, p6);
            legendStrings = cat(2, legendStrings, 'Ineffective Pulses');
            
        end
        
        xlabel('Time(s)');
        ylabel('Magnitude (a.u.)');
        legend(plots, legendStrings, 'location', 'northeast');
        
        formatFigureMovie(figureHandle, [], 14);
        
 % Save to video
 
        currentFrame = getframe(figureHandle);
        writeVideo(videoWriter, currentFrame);
        close(figureHandle);
        
    end

end