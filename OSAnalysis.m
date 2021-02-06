function [] = OSAnalysis(dataDirectory, scanName, stimPar,anPar,...
    overrideOSAnalysisFlag)
outputName = extractBefore(scanName,'.');
warning('off')
%% Make output directory
outputDirectory = createOutputDirectory(dataDirectory, ...
    'OS_analysis_results', outputName);

% Flag directory for recursive analysis
flagDirectory = createOutputDirectory(outputDirectory, ...
    'Ramp Flags', outputName);

%% Create Trace directory
if (7 ~= exist([outputDirectory filesep 'trace'], 'dir'))
    mkdir([outputDirectory filesep 'trace' filesep]);
end
TraceDirectory = [outputDirectory filesep 'trace' filesep];

%% Check if preparation has previously been completed

flagFile = fullfile(flagDirectory, 'Ramp Flags.mat');

if (2 == exist(flagFile))
    
    load(flagFile);
    
else
    
    OSAnalysisFlag = 0;
    save(flagFile, 'OSAnalysisFlag');
    
end

%% Do not rerun on previously processed movies unless directed to

if (OSAnalysisFlag == 1)
    if (overrideOSAnalysisFlag == 0)
        return;
        
        % if overriden, reset flag to account for potential user termination
        % during processing of this movie
    else
        
        OSAnalysisFlag = 0;
        save(flagFile, 'OSAnalysisFlag');
        
    end
end

%% load video dataDirectory

[info, movieStack] = loadData(dataDirectory, scanName);

%% Get ramp stimulation protocol

% stimulation frequency parameters
numSteps = stimPar{1};
startFrequency = stimPar{2}; 
endFrequency = stimPar{3}; 

% get ramp stimulation protocol
[stimulationIndices, stimulationTrace,realStimulationIndices] = ...
    getOSProtocol(info, numSteps, startFrequency, ...
    endFrequency);

%% Get timing and cut video

[cutInfo, cutMovieStack, cutStimulationIndices,cutRealStimulationIndices, ...
    cutStimulationTrace] = cutVideoToOS(info,movieStack,...
    stimulationIndices,realStimulationIndices, stimulationTrace,...
    outputDirectory, scanName);

% clear movieStack;

%% Get contractility trace
baselineTime = anPar{1};

% contractility trace
[contractilityTrace, baselineFrameIndex] = ...
    getOSContractilityTrace(cutInfo, cutMovieStack, outputDirectory, ...
    scanName, 0, 1, baselineTime);

%% Get threshold for peaks

peakHeightThresholds = getPeakHeightThresholdsOS(cutInfo.timeBase, ...
    contractilityTrace, 1);
%% Output intensity trace, cutInfo and info file 



peakDistance = anPar{2};
minPeakProminence = anPar{3};
minMinProminence = anPar{4};
minMinWidth = anPar{5};
maxPeakWidth = anPar{6};
minPeakWidth = anPar{7};
maxMatchLength = anPar{8};

output = struct;
output.info = info;
output.cutInfo = cutInfo;
output.Trace = contractilityTrace;
output.cutStimulationTrace = cutStimulationTrace;
output.cutStimulationIndices = cutStimulationIndices;
output.cutRealStimulationIndices = cutRealStimulationIndices;
output.baselineTime = baselineTime;
output.peakHeightThresholds = peakHeightThresholds;
output.numSteps = numSteps;
output.startFrequency = startFrequency;
output.endFrequency = endFrequency;
output.peakDistance = peakDistance;
output.minPeakProminence = minPeakProminence;
output.minMinProminence = minMinProminence;
output.minMinWidth = minMinWidth;
output.maxPeakWidth = maxPeakWidth;
output.minPeakWidth = minPeakWidth;
output.maxMatchLength = maxMatchLength;

matOutputPath = [TraceDirectory outputName 'output.mat'];
save(matOutputPath, 'output', '-v7.3');

%% Analyze trace

[peaks, locs, widths, prominences,peakMin] = analyzeTraceOS(cutInfo.timeBase, ...
contractilityTrace, peakHeightThresholds, peakDistance, ...
minPeakProminence, minMinProminence , minMinWidth, outputDirectory,...
scanName, maxPeakWidth, minPeakWidth );


%% Match contractions and pulses and visualize data
matchPulsesToOSContractions(outputDirectory, scanName, cutInfo, ...
cutStimulationTrace, cutStimulationIndices,cutRealStimulationIndices, contractilityTrace, ...
peaks, locs, widths,peakMin,maxMatchLength);

%% Update Flag

OSAnalysisFlag = 1;
save(flagFile, 'OSAnalysisFlag');

end