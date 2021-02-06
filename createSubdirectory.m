function subdirectory = createSubdirectory(dataDirectory, subdirectoryName)

%CREATESUBDIRECTORY Creates a new subdirectory
% 
%   createSubdirectory(dataDirectory, subdirectoryName) creates a
%   subdirectory within the dataDirectory if the subdirectory does not yet 
%   exist.  All inputs are strings.  The path to the new subdirectory is 
%   returned as a string.

subdirectory = [dataDirectory filesep subdirectoryName];

if (7 ~= exist(subdirectory, 'dir'))
    mkdir(subdirectory);
end



end
