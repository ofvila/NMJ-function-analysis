function [info, movieStack] = loadData(dataDirectory, scanName)

%LOADDATA Loads camera video data
%
%   [info, movieStack] = loadData(dataDirectory, scanName)loads the 
%   scanName video in the dataDirectory.  It returns the loaded movie and 
%   corresponding info file.

% Read Andor data
if (regexp(scanName, '.nd2'));
    
    [info, movieStack] = loadAndorData(dataDirectory, scanName);
    
% Read Zeiss data
elseif (regexp(scanName, '.czi'))
        [info, movieStack] = loadZeissData(dataDirectory, scanName);
    else
    [info, movieStack] = loadPikeData(dataDirectory, scanName);
end
end


