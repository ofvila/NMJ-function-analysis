function [list] = recursiveMovieSearch(dataDirectory, list);

% Get items in the directory
items = dir(dataDirectory);

% use info.txt,  .nd2 or .czi to recognize movies
index1 = '_info.txt';
index2 = '.nd2';
index3 ='.czi';

%% Find videos
for i = 1:length(items)
    
    currentItem = items(i);
    itemName = currentItem.name;
    
    % Ignore recycle bin
    if (regexp(itemName, ['\$' '(.)*']));
        
    % Run function recursively through subdirectory
    elseif (currentItem.isdir)
        if (~strcmp(itemName, '.') && ~strcmp(itemName, '..') ...
                && ~strcmp(itemName, 'Flags'));
            subdirectory = [dataDirectory '\' itemName];
            list = recursiveMovieSearch(subdirectory, list);
        end
        
    % Otherwise if a Pike movie is found
    elseif regexp(itemName, ['(.)*' index1 '(.)*'])
        
        % input file path information
        dataDirectory = [dataDirectory '\..'];
        cellArrayCurrentFileStems = regexp(itemName, ...
            ['(.)*' index1 '(.)*'], 'tokens');
        scanName = [cellArrayCurrentFileStems{1}{1}];
                
        % add to list
        filePath = [{dataDirectory} {scanName}];
        list = cat(1, list, filePath);
        
        % Otherwise if a .nd2 movie is found
    elseif regexp(itemName, ['(.)*' index2 '$']);
        
        % input file path information
        scanName = itemName;
        
        % add to list
        filePath = [{dataDirectory} {scanName}];
        list = cat(1, list, filePath);
        
        elseif regexp(itemName, ['(.)*' index3 '$']);
        
        % input file path information
        scanName = itemName;
        
        % add to list
        filePath = [{dataDirectory} {scanName}];
        list = cat(1, list, filePath);
    end
end