function [ rgbImage ] = makeRGB(image, clim)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    % Convert matrix to grayscale image
    grayImage = mat2gray(image, clim);
    
    % Split grayscale image into channels
    redImage = grayImage;
    greenImage = grayImage;
    blueImage = grayImage;
    
    % Create color image
    rgbImage = cat(3, redImage, greenImage, blueImage);

end

