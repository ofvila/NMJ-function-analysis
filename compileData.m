function compileData(dataDirectory, numLabels, stringToSearch)
%COMPILEDATA Compiles data from video analysis
%   compileData(dataDirectory, numLabels) is meant to be used
%   in conjunction with contractilityAnalysis and other video processing
%   functions.  It takes all the individual data files generated on a
%   video-by-video basis (stored in dataDirectory)and compiles it into a
%   single excel spreadsheet (outputFile).  This file will be stored in a
%   new folder generated in the dataDirectory named 'Compiled Data'.
%
%   numLabels allows you to determine how to incorporate the title
%   into the spreadsheet.  Take as an example a video titled
%   Isoproterenol_1mM_10x_1.
%
%   numLabels = 1 ==> first column in the spreadsheet will get
%       'Isoproterenol'
%   numLabels = 2 ==> second column in the spreadsheet will also get 1mM
%   numLabels = 3 ==> third column in the spreadsheet will also get 10x
%   ...
%
%   The script only recognizes the underscore character '_' as a separator.
%   If you give the program a value for numLabels > (the number of
%   underscore characters + 1), the program will crash.

%%

if nargin < 3
    stringToSearch = '';
end

%% Create Compiled Data Directory

compiledDataDirectory = createSubdirectory(dataDirectory, 'Compiled Data');
outputFile = [compiledDataDirectory filesep 'Compiled Data.xlsx'];

%%  Get data

% Get folders in directory
folders = dir(dataDirectory);

% Count samples
numSamples = 0;

metaData = {};

% Run through folders (each folder is a sample)
for i = 1: size(folders)
    
    % Get labels for sample
    labels = regexp(folders(i).name, '_', 'split');
    
    % Get files in folder
    files = dir([dataDirectory '\' folders(i).name]);
    % Run through files and extract data from ROI results
    for j = 1: size(files)
                
        % Find results files and extract data
        if ~isempty(regexp(files(j).name, [stringToSearch '\.mat']))
            
            % Increment counter
            numSamples = numSamples + 1;
            
            % Get data
            data = load([dataDirectory '\' folders(i).name ...
                '\' files(j).name]);
            
            % generate metadata
            prefix = {labels{1:numLabels}};
            prefix = repmat(prefix, size(data.matOutput, 1) - 1, 1);
           
      
            % add metadata
            metaData = cat(1, metaData, [prefix data.matOutput(2:end, 1:end)]);

        end
        
    end
    
end

% write to file
xlswrite(outputFile, metaData, 1, ...
    ['A2']);

% Set up title row in spreadsheet
outputTitle = [];

% Add columns to spreadsheet for sample labels
for i = 1:numLabels
    outputTitle = [outputTitle {['Label' num2str(i)]}];
end

% Write titles
outputTitle = [outputTitle data.matOutput(1, 1:end)];
xlswrite(outputFile, outputTitle, 1, 'A1');


