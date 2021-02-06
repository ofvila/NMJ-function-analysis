function [ rgbImage ] = drawBlueBlinker(image, clim)
%DRAWBLUEBLINKER adds a blue square to the top-left corner of the image
%   drawBlueBlinker(image, clim) adds a blue 40x40 pixel square to the
%   top-left corner of the image, which can be either color or grayscale, 
%   and returns it as a color image.    

    % if image is a color image
    if size(image, 3) == 3
        
        rgbImage = image;
        
        % Overlay blinker onto image
        rowMin = 10;
        rowMax = 50;
        columnMin = 10;
        columnMax = 50;
        rgbImage(rowMin:rowMax, columnMin:columnMax, 3) = 1;
        
    else
    
        % Convert matrix to grayscale image
        grayImage = mat2gray(image, clim);
        
        % Split grayscale image into channels
        redImage = grayImage;
        greenImage = grayImage;
        blueImage = grayImage;
        
        % Overlay blinker onto image
        rowMin = 10;
        rowMax = 50;
        columnMin = 10;
        columnMax = 50;
        
        redImage(rowMin:rowMax, columnMin:columnMax) = 0;
        greenImage(rowMin:rowMax, columnMin:columnMax) = 0;
        blueImage(rowMin:rowMax, columnMin:columnMax) = 1;
        
        % Create color image
        rgbImage = cat(3, redImage, greenImage, blueImage);
        
    end

end

