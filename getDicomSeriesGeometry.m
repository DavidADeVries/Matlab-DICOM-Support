function [volumeDimensions, imagePosition, imageOrientation, pixelSpacing, centreOfSliceSeparation] = getDicomSeriesGeometry(dicomSeriesDir)
%[volumeDimensions, imagePosition, imageOrientation, pixelSpacing, centreOfSliceSeparation] = getDicomSeriesGeometry(dicomSeriesDir)
%   Detailed explanation goes here

entries = dir(dicomSeriesDir);

dicomMetadata = {};
filenames = {};
numSlices = 0;

for i=1:length(entries)
    filename = entries(i).name;
    
    if length(filename) >= 4 && strcmp(filename(end-3:end), '.dcm')
        numSlices = numSlices + 1;
        
        dicomMetadata{numSlices} = dicominfo([dicomSeriesDir, '\', filename]);
        filenames{numSlices} = filename;
    end
end

% choose the first slice as the reference slice (it may not be the first
% slice, but that'll be figured out in time)
refMetadata = dicomMetadata{1};

%refImagePosition = refMetadata.ImagePositionPatient;
refImageOrientation = refMetadata.ImageOrientationPatient;

n = cross(refImageOrientation(1:3), refImageOrientation(4:6));

sliceLocations = zeros(numSlices,1);

for i=1:numSlices
    sliceLocations(i) = dot(dicomMetadata{i}.ImagePositionPatient, n);
end

[sortedSliceLocations, sortIndex] = sort(sliceLocations, 'ascend');

topSliceMetadata = dicomMetadata{sortIndex(1)};

centreOfSliceSeparation = round(sortedSliceLocations(2) - sortedSliceLocations(1), 3); % rounded to correct for rounding in DICOM

volumeDimensions = double([topSliceMetadata.Height, topSliceMetadata.Width, numSlices]);
imagePosition = topSliceMetadata.ImagePositionPatient;
imageOrientation = topSliceMetadata.ImageOrientationPatient;
pixelSpacing = topSliceMetadata.PixelSpacing;

end

