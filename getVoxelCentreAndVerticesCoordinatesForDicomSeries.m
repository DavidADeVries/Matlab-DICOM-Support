function [centreX, centreY, centreZ, vertexX, vertexY, vertexZ] = getVoxelCentreAndVerticesCoordinatesForDicomSeries(dicomSeriesDir)
%[centreX, centreY, centreZ, vertexX, vertexY, vertexZ] = getVoxelCentreAndVerticesCoordinatesForDicomSeries(dicomSeriesDir)
%   Detailed explanation goes here

% extract volume geometry information
[~,volumeDimensions, imagePosition, imageOrientation, pixelSpacing, centreOfSliceSeparation] = ...
    getDicomSeriesVolumeAndGeometry(dicomSeriesDir);

% calculate coordinates based on volume geometry
[centreX, centreY, centreZ] = getVoxelCentresCoordinates(...
    volumeDimensions, imagePosition, imageOrientation, pixelSpacing, centreOfSliceSeparation);

[vertexX, vertexY, vertexZ] = getVoxelVerticesCoordinates(...
    volumeDimensions, imagePosition, imageOrientation, pixelSpacing, centreOfSliceSeparation);

end

