
function matchPulsesToOSContractions(outputDirectory, scanName, info, ...
    stimulationTrace, stimulationIndices,realStimulationIndices, contractilityTrace, peaks, ...
    locs, widths, peakMin,maxMatchLength)
%MATCHPULSESTOOSCONTRACTIONS Pairs stimulation pulses with contractions,
%calculates statistics, and visualizes the data
%
%   matchPulsesToOSContractions(outputDirectory, scanName, info,
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
%   This function also creates a .avi of the stimulation protocol, with the
%   tissue plotted against the traces in real-time.

outputName = extractBefore(scanName,'.');
locsCopy = locs;
peakMinCopy = peakMin;
% Default is all contractions are untriggered
contractionMatch = zeros(size(locs));

% Default is all pulses are ineffective
pulseMatch = zeros(size(stimulationIndices))';

% Run through pulse data
for i = 1:size(stimulationIndices, 2)
    
    % find contractions that start (so minima) in the matchLenght interval after the
    % pulse
    beginingIndex = find(peakMin > (stimulationIndices(i)-10)& peakMin< (stimulationIndices(i)+ maxMatchLength * info.frameRate),1);
  
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
    expectedRandomFractionTriggeredTrace(stimulationIndices(i):stimulationIndices(i)...
        + maxMatchLength*info.frameRate) = 1;
    
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
score = (fractionEffective- expectedRandomFractionEffective )/...
    (1-expectedRandomFractionEffective);
if score <= 0
    score = 0.0000001;
end

%% Visualize data
figureHandle = figure;

%% Visualize time course of contractions vs pulses
% plot traces
hold on;
stimulationTraceMultiplier = 0.5*max(contractilityTrace(:))/max(stimulationTrace(:));
stimulationTrace = stimulationTrace * stimulationTraceMultiplier;
p1 = plot(info.timeBase, stimulationTrace, 'b');
p2 = plot(info.timeBase, contractilityTrace, 'k');

% Initialize plot handles and legendStrings for legend
plots = [p1, p2];
legendStrings = cellstr('Light Stimulation Trace');
legendStrings = cat(2, legendStrings, 'Contractile Activity Trace');

currentAxis = axis;

% Mark triggered and untriggered contractions
if size(triggeredContractions, 1) > 0
    
    p3 = plot(info.timeBase(triggeredContractions), ...
        contractilityTrace(triggeredContractions, 1),'gx', 'MarkerSize', 15);
    plots = cat(2, plots, p3);
    legendStrings = cat(2, legendStrings,'Triggered Contractions');
    
end

if size(untriggeredContractions, 1) > 0
    p4 = plot(info.timeBase(untriggeredContractions), ...
        contractilityTrace(untriggeredContractions, 1),'rx', 'MarkerSize', 15);
    plots = cat(2, plots, p4);
    legendStrings = cat(2, legendStrings,'Untriggered Contractions');
    
end


if size(peakMinCopy, 1) > 0
    p5 = plot(info.timeBase(peakMinCopy), contractilityTrace(peakMinCopy),'bo', 'MarkerSize', 10);
    plots = cat(2, plots, p5);
    legendStrings = cat(2, legendStrings,'Minima');
    
end
axis([info.timeBase(1) info.timeBase(end) ...
    min(min(stimulationTrace), min(contractilityTrace)) ...
    max(max(stimulationTrace), max(contractilityTrace))]);

% Mark effective and ineffective light pulses
currentAxis = axis;
if size(effectivePulses, 2) > 0
    for i = 1:size(effectivePulses, 2)
        p6 = plot([info.timeBase(round(effectivePulses(i))) ...
            info.timeBase(round(effectivePulses(i)))], currentAxis(3:4), '-g');
    end
    
%     Add plot handles and legendStrings for legend
    plots = cat(2, plots, p6);
    legendStrings = cat(2, legendStrings, 'Effective Pulses');
end

if size(ineffectivePulses, 2) > 0
    for i = 1:size(ineffectivePulses, 2)
        p7 = plot([info.timeBase(round(ineffectivePulses(i))) ...
            info.timeBase(round(ineffectivePulses(i)))], currentAxis(3:4), '-r');
    end
    
    % Add plot handles and legendStrings for legend
    plots = cat(2, plots, p7);
    legendStrings = cat(2, legendStrings, 'Ineffective Pulses');
end

xlabel('Time (s)');
ylabel('Magnitude (a.u.)');
graphTitle =  strrep(scanName,'_',' ');
title(graphTitle);
l = legend(plots, legendStrings, 'location', 'northeastoutside');
l.FontSize = 20;

%% Format figure
formatFigure(figureHandle);

saveas(figureHandle, [outputDirectory outputName '_DataSummary.jpg'], ...
    'jpeg');
saveas(figureHandle, [outputDirectory outputName '_DataSummary.fig'], ...
    'fig');

close all;

%% Save excel file

outputTitle = cat(2, ...
    {'triggeredContractions'},{'untriggeredContractions'}, {'totalContractions'}, ...
    {'total pulses'}, {'fraction eff pulses'}, {'random eff pulses'}, {'score'});
outputVariable = cat(2, {numTriggered}, { numUntriggered}, ...
    {totalContractions}, {totalPulses},{fractionEffective} ,...
    {expectedRandomFractionEffective}, {score});

if ispc
    
    excelOutputPath = [outputDirectory outputName '_results' '.xlsx'];    
    excelOutput = cat(1, outputTitle, outputVariable);
    xlswrite(excelOutputPath, excelOutput, 1, 'A1');
    
elseif isunix
    
    excelOutputPath = [outputDirectory outputName '_results' '.xls'];
    
    javaaddpath('jxl.jar');
    javaaddpath('MXL.jar');
    
    import mymxl.*;
    import jxl.*;
    
    output = cat(1, outputTitle, outputVariable);
    xlwrite(excelOutputPath, output, 'Output');
    
end

matOutputPath = [outputDirectory outputName '_results' '.mat'];
matOutput = cat(1, outputTitle, outputVariable);
save(matOutputPath, 'matOutput', '-v7.3');

end