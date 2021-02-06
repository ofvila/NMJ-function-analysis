
dataDirectory = 'Directory';

overrideMovieFlag = 1;
warning('off');
echo off;
%% Get videos
list = {};
list = recursiveMovieSearch(dataDirectory, list);

%% Set parallel processing parameters

% Figure out computer memory
[user system] = memory;
memorySystem = system.PhysicalMemory.Total;

% If we are on a system with 64GB memory
if memorySystem > 5e+10
    poolSize = 6;
% Otherwise
else
    poolSize = 2;
end

% Start parallel pool
delete(gcp('nocreate'));
poolID = parpool(poolSize);

%% Make movies

% Construct ParforProgressbar object and parameters:
ppm = ParforProgressbar(length(list),'title','Movie Analysis Progress');
pauseTime = 60/length(list);

parfor i = 1:length(list);  
%     try
        % Run analysis function
        OSMovie(list{i, 1}, list{i, 2}, overrideMovieFlag);

% Progress Bar Update
pause(pauseTime);
ppm.increment();

end

% Delete the progress handle
delete(ppm);


% End parallel pool
delete(poolID);