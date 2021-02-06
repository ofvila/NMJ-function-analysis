function outputDirectory = createOutputDirectory(dataDirectory, subdirectory, itemName)

%CREATEOUTPUTDIRECTORY Create output directory
% 
%   createOutputDirectory(dataDirectory, subdirectory, itemName) creates a
%   subdirectory within the dataDirectory for outputs if the subdirectory
%   does not yet exist, and then adds an individual folder within the
%   subdirectory for the item.  All inputs are strings.

if (7 ~= exist([dataDirectory filesep subdirectory], 'dir'))
    mkdir([dataDirectory filesep subdirectory filesep]);
end

if (7 ~= exist([dataDirectory filesep subdirectory filesep itemName filesep], 'dir'))
    mkdir([dataDirectory filesep subdirectory filesep itemName filesep]);
end

outputDirectory = [dataDirectory filesep subdirectory filesep itemName filesep];

end
