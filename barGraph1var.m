function barGraph1var(dataDirectory)

%BARGRAPH1VAR Creates bar graphs for data divided by one variable
%
%   The function is called as:
%
%   barGraph1var(dataDirectory)
%
%  
%   The first column of this spreadsheet should contain the label, i.e.
%   "2Hz Stimulation" or "Control" etc.  This column can be automatically
%   created (through options selected when using the compileData function)
%   or can be manually inserted.
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
compiledData = [dataDirectory  filesep 'Compiled Data.xlsx'];

% read data
[num, txt, raw] = xlsread(compiledData);

% number of indices
numIndices = 1;

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
size(dataMatrix)
% accounting variables
previousIndices = zeros(size(numIndices));
currentIndexCounter = 0;

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
    if isequal(mappedIndices, previousIndices)
        currentIndexCounter = currentIndexCounter + 1;
    else
        currentIndexCounter = 1;
        previousIndices = mappedIndices;
    end
    
    % add sample to matrix
    mappedIndices = num2cell(mappedIndices);
    dataMatrix(mappedIndices{:}, currentIndexCounter) = raw{sample + 1, assayIndex};
    
end

% Get rid of bad data
dataMatrix(find(dataMatrix == 0)) = NaN;


%% Find means and errors

% Pre-allocate means
meanMatrix = zeros(matrixSize, 1);
semMatrix = zeros(matrixSize, 1);
sampleSizeMatrix = zeros(matrixSize, 1);

% Populate averages
for sampleLabel = 1:length(indicesMap{1})
    
    meanMatrix(sampleLabel) = ...
        nanmean(dataMatrix(sampleLabel, :));
    
    sampleSizeMatrix(sampleLabel) = ...
        sum(~isnan(dataMatrix(sampleLabel, :)));
    
    semMatrix(sampleLabel) = ...
        nanstd(dataMatrix(sampleLabel, :)) / ...
        sqrt(sampleSizeMatrix(sampleLabel));
    
end



xlswrite([figuresDirectory filesep  'MeanSEM.xlsx'], meanMatrix, 1, 'A1');
xlswrite([figuresDirectory filesep  'MeanSEM.xlsx'], semMatrix, 1, 'B1');
close all;
% calculate t statistics for confidence intervals
% see http://onlinestatbook.com/2/estimation/mean.html

% also see http://www.cscu.cornell.edu/news/statnews/Stnews73insert.pdf
% for a discussion of why non-overlapping confidence intervals ==>
% statistical significance but statistical significance =/=>
% non-overlapping confidence intervals

significance = 0.05;
t = (tinv(1-significance/2, sampleSizeMatrix)) .* semMatrix;

%% Calculate statistically significant relationships

numSubgroups = size(dataMatrix, 1);

% Intragroup and intersubgroup
pairsWG = cell(1);

for subgroup1 = 1:numSubgroups
    
    for subgroup2 = subgroup1:numSubgroups
        
        if ~isnan(ttest2(dataMatrix(subgroup1, :), ...
                dataMatrix(subgroup2, :)))
            
            if ttest2(dataMatrix(subgroup1, :), ...
                    dataMatrix(subgroup2, :))
                
                pairsWG{1} = vertcat(pairsWG{1}, ...
                    [subgroup1 subgroup2]);
                
            end
            
        end
        
    end
    
end

%% 1-way Anova
anovaResponse = raw(2:numSamples+1,assayIndex);
anovaResponse = cell2mat(anovaResponse');

anovaTime = raw(2:numSamples+1,1);
anovaTime = cell2mat(anovaTime');

% size(anovaResponse)
% size(anovaTime)

[p,tbl,stats]=anova1(anovaResponse,anovaTime);

xlswrite([figuresDirectory filesep  'anova.xlsx'], p, 1, 'A1');
close all;


%post-hoc

[results,means] = multcompare(stats, 'CType', 'hsd');

xlswrite([figuresDirectory filesep  'Tukey.xlsx'], results, 1, 'A1');
close all;

[results2,means2] = multcompare(stats, 'CType', 'bonferroni');

xlswrite([figuresDirectory filesep  'Bonferroni.xlsx'], results2, 1, 'A1');
% close all;
%% Plot means, SEM and statistically significant results

close all;

% create new figure;
figureHandle = figure;
hold all;

% title
 title = upper( ['ANOVA p=' num2str(p)]);


% plot graph
handles = barweb(meanMatrix, semMatrix, 1, [], title, [], ...
    txt{1, assayIndex}, 'jet', 'y', [], 2, []);

% legend
if isnumeric(indicesMap{1})
    plotLegend = cell(length(indicesMap{1}), 1);
    for i = 1:length(indicesMap{1})
        plotLegend{i} = [num2str(indicesMap{1}(i)) txt{1, 1}];
    end
else
    plotLegend = cellstr(indicesMap{1});
end
handles.legend = legend(plotLegend, 'location', 'BestOutside');

% add statistical significance brackets
barwebpairs(handles, [], pairsWG);

% resize and clean up figure
formatFigure(figureHandle);

% save figure
saveas(figureHandle, [figuresDirectory filesep upper(txt{1, assayIndex}) ...
    ' BAR GRAPH.png'], 'png');
% saveas(figureHandle, [figuresDirectory filesep upper(txt{1, assayIndex}) ...
%     ' BAR GRAPH.eps'], 'epsc');
saveas(figureHandle, [figuresDirectory filesep upper(txt{1, assayIndex}) ...
    ' BAR GRAPH.fig'], 'fig');

close all;
