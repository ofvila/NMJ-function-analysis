function[] = rampOSPostAnalysis(dataDirectory, scanName,stimPar, anPar, ...
    overridePostAnalysisFlag)

% Make output directory
outputName = extractBefore(scanName,'.');
outputDirectory = createOutputDirectory(dataDirectory, ...
    'OS_analysis_results', outputName);

flagDirectory = createOutputDirectory(outputDirectory, ...
    'Post Analysis Flags', outputName);

%% Create Trace directory
if (7 ~= exist([outputDirectory filesep 'trace'], 'dir'))
    mkdir([outputDirectory filesep 'trace' filesep]);
end
TraceDirectory = [outputDirectory filesep 'trace' filesep];

%% Check if post analysis has previously been completed

flagFile = fullfile(flagDirectory, 'Post Analysis Flags.mat');

if (2 == exist(flagFile))
    
    load(flagFile);
    
else
    OSPostAnalysisFlag = 0;
    save(flagFile, 'OSPostAnalysisFlag');
    
end

%% Do not rerun on previously processed movies unless directed to

if (OSPostAnalysisFlag == 1)
    if (overridePostAnalysisFlag == 0)
        return;
        
        % if overriden, reset flag to account for potential user termination
        % during processing of this movie
    else
        
        OSPostAnalysisFlag = 0;
        save(flagFile, 'OSPostAnalysisFlag');
        
    end
end

%% Load trace drift correction figure

summaryPath = [outputDirectory outputName '_DataSummary.fig'];
open(summaryPath);

%% Check Analysis
analysis = 1;
choice = questdlg('Is the analysis correct?','Check analysis','Yes', 'No','Yes');

switch choice
    case 'No'
        analysis = 0;    
end
close all;
%% If analysis wasn't satisfactory

reload = 0;
%load parameters
numSteps = stimPar{1};
startFrequency = stimPar{2}; 
endFrequency = stimPar{3};
maxPeakWidth = anPar{6};
minPeakWidth = anPar{7};
maxMatchLength = anPar{8};

while ~analysis
    open(summaryPath);
    problem = str2double(inputdlg(...
        'Change: 0 = nothing, 1 = baseline, 2 = peak threshold, 3 = trace analysis'));
    if problem == 0
        analysis = 1;
    else if problem == 1
            
    % load stimulation and initial analysis parameters  
    baselineTime = anPar{1};
    peakDistance = anPar{2};
    minPeakProminence = anPar{3};
    minMinProminence = anPar{4};
    minMinWidth = anPar{5};

    % reload data and re-do whole analysis
    [info, movieStack] = loadData(dataDirectory, scanName);
    [stimulationIndices, stimulationTrace,realStimulationIndices] = ...
        getOSProtocol(info, numSteps, startFrequency, ...
        endFrequency);

    [cutInfo, cutMovieStack, cutStimulationIndices,cutRealStimulationIndices,...
        cutStimulationTrace] = cutVideoToOS(info, movieStack,stimulationIndices,...
        realStimulationIndices, stimulationTrace, outputDirectory, scanName);

    baseline = 0;

    while ~baseline

    % load movie stack and reanalize movie
    [contractilityTrace, baselineFrameIndex] = ...
        getOSContractilityTrace(cutInfo, cutMovieStack, outputDirectory, scanName, 0);

    peakHeightThresholds = getPeakHeightThresholdsOS(cutInfo.timeBase, contractilityTrace,1);

    open([outputDirectory outputName '_Trace_Drift_Correction.fig']);
    choice = questdlg('Is the baseline correct?','Check baseline','Yes', 'No','Yes');

        switch choice
            case 'Yes'
        baseline = 1;
        end
    end

    % Save new info and finish analysis
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

    [peaks, locs, widths, prominences,locsMin] = analyzeTraceOS(...
        cutInfo.timeBase, contractilityTrace, peakHeightThresholds,...
        peakDistance,minPeakProminence, minMinProminence,...
        minMinWidth, outputDirectory,scanName, maxPeakWidth,...
        minPeakWidth );

    matchPulsesToOSContractions(outputDirectory, scanName, cutInfo, ...
        cutStimulationTrace, cutStimulationIndices,cutRealStimulationIndices,...
        contractilityTrace,peaks, locs, widths,locsMin, maxMatchLength);

else if problem == 2
        % change threshold

        if reload == 0;

        %Reload 1st analysis data
        outputPath = [TraceDirectory outputName 'output.mat'];
        output = load(outputPath);
        output = output.output;
        info = output.info;
        cutInfo = output.cutInfo;
        contractilityTrace = output.Trace;
        cutStimulationTrace = output.cutStimulationTrace;
        cutStimulationIndices = output.cutStimulationIndices;
        cutRealStimulationIndices = output.cutRealStimulationIndices;
        peakDistance = output.peakDistance;
        minPeakProminence = output.minPeakProminence;
        minMinProminence = output.minMinProminence;
        minMinWidth = output.minMinWidth;

        reload = 1;
        end

        %Run getPeakHeighThresholdsOS without default flag so it
        %gets requested to user

        peakHeightThresholds = getPeakHeightThresholdsOS(cutInfo.timeBase, ...
        contractilityTrace);
        % Save new info 
        output.peakHeightThresholds = peakHeightThresholds;
        save(outputPath, 'output', '-v7.3');

        %Run analyce Trace and MatchPulses

        [peaks, locs, widths, prominences,locsMin] = analyzeTraceOS(...
            cutInfo.timeBase, contractilityTrace, peakHeightThresholds,...
            peakDistance,minPeakProminence, minMinProminence,...
            minMinWidth, outputDirectory,scanName, maxPeakWidth,...
            minPeakWidth );

        matchPulsesToOSContractions(outputDirectory, scanName,...
            cutInfo, cutStimulationTrace, cutStimulationIndices,...
            cutRealStimulationIndices, contractilityTrace, ...
            peaks, locs, widths,locsMin,maxMatchLength);

    else if problem == 3

               if reload == 0;
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

                reload = 1;
                 end

                %Run analyceTrace and MatchPulses

                peaksPath = [outputDirectory outputName '_peaks' '.fig'];
                open(peaksPath);

                prompt= {'Peak Distance','Peak Prominence',...
                    'Minim min Prominence', 'Min min Width '};
                title = 'Analysis Parameters';

                %default values

                peakDistance = output.peakDistance;
                minPeakProminence = output.minPeakProminence;
                minMinProminence = output.minMinProminence;
                minMinWidth = output.minMinWidth;

                def = {num2str(peakDistance),num2str(minPeakProminence), ...
                    num2str(minMinProminence),num2str(minMinWidth) };

                answer= inputdlg(prompt, title,[1 40], def);

                peakDistance= str2double(answer{1});
                minPeakProminence= str2double(answer{2});
                minMinProminence= str2double(answer{3});
                minMinWidth= str2double(answer{4});

                [peaks, locs, widths, prominences,locsMin] = ...
                    analyzeTraceOS(cutInfo.timeBase, contractilityTrace,...
                    peakHeightThresholds, peakDistance, minPeakProminence, ...
                    minMinProminence , minMinWidth, outputDirectory, ...
                    scanName, maxPeakWidth, minPeakWidth);

                matchPulsesToOSContractions(outputDirectory, scanName, cutInfo, ...
                    cutStimulationTrace, cutStimulationIndices,...
                    cutRealStimulationIndices, contractilityTrace, ...
                    peaks, locs, widths,locsMin,maxMatchLength);

            % Save new info
                output.peakDistance = peakDistance;
                output.minPeakProminence = minPeakProminence;
                output.minMinProminence = minMinProminence;
                output.minMinWidth = minMinWidth;

                save(outputPath, 'output', '-v7.3');

        else
            problem = str2double( inputdlg(...
                'Change: 0=nothing, 1 = baseline, 2 = peak threshold, 3 = trace analysis'));
        end
                
            end
            
        end
    end
    
end
    
close all;
                

%% Update Flag

OSPostAnalysisFlag = 1;
save(flagFile, 'OSPostAnalysisFlag'); 
