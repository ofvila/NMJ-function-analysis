function barGraph2var(dataDirectory)

%BARGRAPHT2VAR Creates bar graphs for data divided by two
%sample labels
% 
%   The function is called as: 
%
%   barGraph2var(dataDirectory)
% %   
%   The first two columns of this spreadsheet should contain the labels, 
%   i.e. "2Hz Stimulation" or "Control" in one column and "Day 0" or 
%   "Day 7" in the other.  This column can be automatically created 
%   (through options selected when using the compileData function) or can 
%   be manually inserted into the spreadsheet.  The top row of the
%   spreadsheet is assumed to be titles for each column and is not
%   considered in the analysis.
%
%   A menu will then allow you to choose which graph you wish to produce.
%   Graphs will be stored in the Figures directory created within the
%   dataDirectory.
%
%   This function requires the barweb and barwebpair libraries to be part 
%   of the Matlab search path.  These are available for download at: 
%   https://www.mathworks.com/matlabcentral/fileexchange/10803-barweb--bargraph-with-error-bars-
%   https://www.mathworks.com/matlabcentral/fileexchange/27494-barwebpairs--pair-bars-within-groups-and-between-groups-

%% Create figures directory

figuresDirectory = createSubdirectory(dataDirectory, 'Figures');

%% Get compiled data

% set data file
compiledData = [dataDirectory filesep 'Compiled Data.xlsx'];

% read data
[num, txt, raw] = xlsread(compiledData);
% number of indices
numIndices = 2;

% pick assay here
choice = menu('Choose an assay', txt{1, numIndices + 1:end});
assay = txt{1, choice + numIndices};
assay = strrep(assay, '(', '\(');
assay = strrep(assay, ')', '\)');

% initialize assay index
assayIndex = 0;

% find assay index
for i = 1:size(txt, 2)
    if regexp(txt{1, i}, assay)
        assayIndex = i;
        break
    end
end

% total number of samples
numSamples = size(num, 1);

% store size of matrix
matrixSize = zeros(1, numIndices);

% map indices
indicesMap = cell(1, numIndices);

% find size of matrix
for i = 1:numIndices
    
    indexColumn = raw(2:end, i);
    if isnumeric(indexColumn{1})
        
        matrixSize(i) = size(unique([indexColumn{:}]), 2);
        indicesMap{i} = unique([indexColumn{:}]);
        
    elseif iscellstr(indexColumn)
    
        matrixSize(i) = size(unique(indexColumn), 1);
        indicesMap{i} = unique(indexColumn);
        
    end
                        
end


% pre-allocate matrix
dataMatrix = zeros([matrixSize numSamples]);

% accounting variables
currentIndexCounter = zeros(matrixSize(1), matrixSize(2));


% populate dataMatrix
for sample = 1:numSamples
    
    % find indices
    indices = raw(sample + 1, 1:numIndices);
    
    % map indices into dataMatrix indices
    mappedIndices = zeros(size(indices));
    for indexID = 1:numIndices
        
        if isnumeric(indices{indexID})
        
            mappedIndices(indexID) = ...
                find(indicesMap{indexID} == indices{indexID});
        
        elseif ischar(indices{indexID})
            
          mappedIndices(indexID) = ...
                find(strcmp(indicesMap{indexID}, indices{indexID}));
            
        end
        
    end
    
    % handle accounting
    currentIndexCounter(mappedIndices(1), mappedIndices(2)) = ...
        currentIndexCounter(mappedIndices(1), mappedIndices(2)) + 1;
       
    % add sample to matrix
    mappedIndicesCell = num2cell(mappedIndices);
    dataMatrix(mappedIndicesCell{:}, ...
        currentIndexCounter(mappedIndices(1), mappedIndices(2))) = ...
        raw{sample + 1, assayIndex};       
    
end

% Get rid of bad data
dataMatrix(find(dataMatrix == 0)) = NaN;



%% 2-factor Anova
anovaResponse = raw(2:numSamples,assayIndex);
anovaResponse = cell2mat(anovaResponse');
anovaTime = raw(2:numSamples,1)';

anovaTime = cell2mat(anovaTime); %if first parametr is text you need to innactivate this line
anovaCondition = txt(2:numSamples,2)';

[p,tbl,stats]=anovan(anovaResponse,{anovaCondition,anovaTime },'varnames',{'treatment' 'time'});

xlswrite([figuresDirectory filesep  'anova.xlsx'], p, 1, 'A1');
close all;

% post-hoc

[results,means,h, gnames] = multcompare(stats,'CType','hsd');

xlswrite([figuresDirectory filesep  'Tukey.xlsx'], results, 1, 'A1');
xlswrite([figuresDirectory filesep  'names.xlsx'], gnames, 1, 'A1');

close all;

[results2,means2] = multcompare(stats,'Dimension',[1 2],'CType', 'bonferroni');

xlswrite([figuresDirectory filesep  'Bonferroni.xlsx'], results2, 1, 'A1');
close all;

%% Find means and errors

% Pre-allocate means
meanMatrix = zeros(matrixSize);
semMatrix = zeros(matrixSize);
sampleSizeMatrix = zeros(matrixSize);

% Populate averages
for timePoint = 1:length(indicesMap{1})
    
    for indexNumber = 1:length(indicesMap{2})
                  
            meanMatrix(timePoint, indexNumber) = ...
                nanmean(dataMatrix(timePoint, ...
                indexNumber, :));
        
             sampleSizeMatrix(timePoint, ...
                 indexNumber) = ...
                sum(~isnan(dataMatrix(timePoint, ...
                indexNumber, :)));
            
            semMatrix(timePoint, indexNumber) = ...
                nanstd(dataMatrix(timePoint, ...
                indexNumber, :)) / ...
                sqrt(sampleSizeMatrix(timePoint, ...
                indexNumber));

    end
        
end



%% Plot means, SEM
close all;

% create new figure;
figureHandle = figure;
hold all;

% label groups
if isnumeric(indicesMap{1})
    groupNames = cellstr(num2str(transpose(indicesMap{1})));
    for i = 1:length(groupNames)   
        groupNames{i} = [txt{1, 1} ' ' groupNames{i} ];
    end
else
    groupNames = cellstr(transpose(indicesMap{1}));
end

% title
title = upper( ['ANOVA F = ' num2str(p(1))]);

% plot graph

handles = barweb(meanMatrix, semMatrix, [], upper(groupNames), title, [], ...
    upper(txt{1, assayIndex}), 'Jet', 'y', [], 2, []);

% legend
if isnumeric(indicesMap{2})
    plotLegend = cell(length(indicesMap{2}), 1);    
    for i = 1:length(indicesMap{2})        
        plotLegend{i} = [   num2str(indicesMap{2}(i)) ' ' txt{1, 2}];
    end    
else    
    plotLegend = cellstr(indicesMap{2});
end
handles.legend = legend(upper(plotLegend), 'location', 'BestOutside');

% resize and clean up figure
formatFigure(figureHandle);

% save figure
saveas(figureHandle, [figuresDirectory filesep upper(txt{1, assayIndex}) ...
    ' BAR GRAPH VARIABLE 1.png'], 'png');
saveas(figureHandle, [figuresDirectory filesep upper(txt{1, assayIndex}) ...
    ' BAR GRAPH VARIABLE 1.fig'], 'fig');

close all;
%% Focus on Label 2
close all;
figureHandle = figure;
hold all;

% label groups
if isnumeric(indicesMap{2})
    groupNames = cell(length(indicesMap{2}), 1);    
    for i = 1:length(indicesMap{2})        
        groupNames{i} = [num2str(indicesMap{2}(i)) ' ' txt{1, 2}];
    end    
else    
    groupNames = cellstr(indicesMap{2});
end
for i = 1:length(groupNames)
    groupNames{i} = groupNames{i};
end

% title
title = upper( ['ANOVA p= ' num2str(p(2))]);

% plot graph
handles = barweb(meanMatrix', semMatrix', [], upper(groupNames), title, [], ...
    upper(txt{1, assayIndex}), 'Jet', 'y', [], 2, []);

% legend
if isnumeric(indicesMap{1})
    plotLegend = cellstr(num2str(transpose(indicesMap{1})));
    for i = 1:length(plotLegend)    
        plotLegend{i} = [plotLegend{i} ' ' txt{1, 1}];
    end
else
    plotLegend = cellstr(transpose(indicesMap{1}));
end

handles.legend = legend(upper(plotLegend), 'location', 'BestOutside');


formatFigure(figureHandle);

% save figure
saveas(figureHandle, [figuresDirectory filesep upper(txt{1, assayIndex}) ...
    ' BAR GRAPH VARIABLE 2.png'], 'png');
saveas(figureHandle, [figuresDirectory filesep upper(txt{1, assayIndex}) ...
    ' BAR GRAPH VARIABLE 2.fig'], 'fig');


close all;
