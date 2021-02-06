function [] = OSMovie(dataDirectory, scanName,...
    overrideMovieFlag)
outputName = extractBefore(scanName,'.');
% Make output directory
warning('off')
outputDirectory = createOutputDirectory(dataDirectory, ...
    'OS_analysis_results', outputName);

mkdir([dataDirectory filesep 'Movies' filesep]);

movieDirectory = [dataDirectory filesep 'Movies' filesep];

movieFlagDirectory = createOutputDirectory(outputDirectory, ...
    'Movie Flags', outputName);

flagDirectory = createOutputDirectory(outputDirectory, ...
    'Post Analysis Flags', outputName);

%% Create Trace directory

TraceDirectory = [outputDirectory filesep 'trace' filesep];

%% Check if movie has previously been completed

movieFlagFile = fullfile(movieFlagDirectory, 'Movie Flags.mat');

if (2 == exist(movieFlagFile));
    
    load(movieFlagFile);
    
else
    movieFlag = 0;
    save(movieFlagFile, 'movieFlag');
end

%% Do not rerun on previously processed movies unless directed to

if (movieFlag == 1)
    if (overrideMovieFlag == 0)
        return;
        
        % if overriden, reset flag to account for potential user termination
        % during processing of this movie
    else
        
        movieFlag = 0;
        save(movieFlagFile, 'movieFlag');
        
    end
end
%% Do not run if post analysis hasn't been performed 
postanalysisFlagFile = fullfile(flagDirectory, 'Post Analysis Flags.mat');

if (2 == exist(postanalysisFlagFile))
    
    load(postanalysisFlagFile);
    
else fprintf('Movie Analysis not completed');
    return;
    
end



%% Load analysis parameters

outputPath = [TraceDirectory outputName 'output.mat'];
output = load(outputPath);
output = output.output;
info = output.info;
cutInfo = output.cutInfo;
contractilityTrace = output.Trace;
cutStimulationTrace = output.cutStimulationTrace;
cutStimulationIndices = output.cutStimulationIndices;
cutRealStimulationIndices = output.cutRealStimulationIndices;
peakHeightThresholds = output.peakHeightThresholds;
peakDistance = output.peakDistance;
minPeakProminence = output.minPeakProminence;
minMinProminence = output.minMinProminence;
minMinWidth = output.minMinWidth;
maxPeakWidth = output.maxPeakWidth;
minPeakWidth = output.minPeakWidth;
maxMatchLength = output.maxMatchLength;

numSteps = output.numSteps;
startFrequency = output.startFrequency;
endFrequency = output.endFrequency;

%% get ramp stimulation protocol
[stimulationIndices, stimulationTrace,realStimulationIndices] = ...
getOSProtocol(info, numSteps, startFrequency,endFrequency);
%% load video dataDirectory

[info, movieStack] = loadData(dataDirectory, scanName);
%% Get timing and cut video

[cutInfo, cutMovieStack, cutStimulationIndices,cutRealStimulationIndices, cutStimulationTrace] = ...
cutVideoToOS(info, movieStack, ...
stimulationIndices,realStimulationIndices, stimulationTrace, outputDirectory, scanName);

%% Analyze trace

[peaks, locs, widths, prominences,peakMin] = analyzeTraceOS(cutInfo.timeBase, ...
contractilityTrace, peakHeightThresholds, peakDistance, ...
minPeakProminence, minMinProminence , minMinWidth, outputDirectory,...
scanName, maxPeakWidth, minPeakWidth );

%% Match contractions and pulses and make movie

matchPulsesToOSContractionsMovie(cutMovieStack,outputDirectory, movieDirectory, scanName, cutInfo, ...
cutStimulationTrace, cutStimulationIndices,cutRealStimulationIndices, contractilityTrace, ...
peaks, locs, widths,peakMin,maxMatchLength);

%% Update Flag

movieFlag = 1;
save(movieFlagFile, 'movieFlag');

end