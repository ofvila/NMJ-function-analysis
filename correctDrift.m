function [correctedTrace] = correctDrift(timeBase, trace, ...
    outputDirectory, scanName)
%CORRECTDRIFT Removes baseline drift
%   
%   correctDrift(timeBase, trace, outputDirectory, scanName)
%   corrects for drift in the trace by fitting a 6th-order polynomial to
%   the trace and then subtracting it from the signal.  It plots the
%   resulting polynomial and drift-corrected trace for validation.

outputName = extractBefore(scanName,'.');
   % Correct for drift
    if size(timeBase) ~= size (trace)
            timeBase = timeBase';
    end
    
    driftPolynomial = polyfit(timeBase, trace, 6);
    driftSignal = polyval(driftPolynomial, timeBase);
    correctedTrace = trace - driftSignal;
    correctedTrace = correctedTrace + ...
        driftPolynomial(size(driftPolynomial, 2));
   
    figure;
    title(['Drift Removal']);
    
    subplot(2, 1, 1);
    hold on;
    plot(timeBase, trace);
    plot(timeBase, driftSignal);
    xlabel('Time (seconds)', 'FontSize', 10)
    ylabel('Magnitude', 'FontSize', 10)
    graphTitle =  strrep(outputName,'_',' ');
    title(['Original trace and drift correction for ' graphTitle], 'FontSize', 10);
        
    subplot(2, 1, 2);
    plot(timeBase, correctedTrace);
    xlabel('Time (seconds)', 'FontSize', 10)
    ylabel('Magnitude', 'FontSize', 10)
    title(['Drift-corrected trace for ' graphTitle ], 'FontSize', 10);
    
    % Save plots
    set(gcf, 'Position', [0 0 1920 1030]);
    set(gcf, 'PaperUnits', 'centimeters');
    set(gcf, 'PaperPosition', [0 0 45  30]);
   
    saveas(gcf, [outputDirectory outputName '_Trace_Drift_Correction'  '.fig'], 'fig');
    saveas(gcf, [outputDirectory outputName '_Trace_Drift_Correction'  '.jpg'], 'jpeg');
    
    close all;

end