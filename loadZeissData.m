function [info, movieStack] = loadZeissData(dataDirectory, scanName)

%LOADANDORDATA Loads Zeiss camera video data
%
%   [info, movieStack] = loadZeissData(dataDirectory, scanName)loads the 
%   scanName video in the dataDirectory.  It returns the loaded movie and
%   an info file.

% read bioformats data

data = bfopen([dataDirectory filesep scanName]);

% create info structure
info = struct ;

% set camera
info.camera = 'Zeiss' ;

% Set maximum image size in pixels
info.xMaxSize = 2048;
info.yMaxSize = 2048;

% Get magnification
if regexpi(scanName, '40x');    
    info.magnification = 40;
    info.axismm = 0.4428;
elseif regexpi(scanName, '20x');
    info.magnification = 20;    
    info.axismm = 0.7897;
elseif regexpi(scanName, '10x');
    info.magnification = 10;
    info.axismm = 1.5693;
elseif regexpi(scanName, '4x');
    info.magnification = 4;
    info.axismm = 3.3099;
elseif regexpi(scanName, '2x');
    info.magnification = 2;
    info.axismm = 6.7270;
elseif (~isempty(regexpi(scanName, '1-5x')) || ...
        ~isempty(regexpi(scanName, '1-25x')) || ...
        ~isempty(regexpi(scanName, '1.25x')))
    info.magnification = 1.25;
    info.axismm = 10.6482;
end

% Get metadata
metadata = data{1,2};

% Get bin size
binningString = metadata.get('Global Experiment|AcquisitionBlock|AcquisitionModeSetup|Camera|Binning #1');
info.binSize = str2double(binningString(1:1));

% Get exposure time and frame rate
info.frameRate = str2num(metadata.get('Global HardwareSetting|ParameterCollection|FrameRate #1'));
 
if (info.binSize * size(data{1, 1}{1}, 1) == 2048);
   
    maxFrameRate = 101.73;
    if info.frameRate > maxFrameRate;
        info.frameRate = maxFrameRate;
    end
    
end
   
% Get number of images in movie
info.numFrames = size(data{1, 1}, 1);

% Get stack of images this data set
movieStack = zeros(size(data{1, 1}{1}, 1), size(data{1, 1}{1}, 2), ...
        info.numFrames, 'uint16');

% Calculate timebase
info.timeBase = (1 : (info.numFrames)) ./ info.frameRate;

% load dat
for frameIdx = 1 : info.numFrames
           
    % read in image
    movieStack(:, :, frameIdx) = data{1, 1}{frameIdx};
   
end

clear data;

end


