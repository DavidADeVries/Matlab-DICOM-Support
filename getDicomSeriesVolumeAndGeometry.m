function [volume, volumeDimensions, imagePosition, imageOrientation, pixelSpacing, centreOfSliceSeparation] = getDicomSeriesVolumeAndGeometry(dicomSeriesDir, varargin)
%[volume, volumeDimensions, imagePosition, imageOrientation, pixelSpacing, centreOfSliceSeparation] = getDicomSeriesVolumeAndGeometry(dicomSeriesDir)
%   Detailed explanation goes here

if nargin == 3
    if strcmp(varargin{1}, 'Verbose')
        verbose = varargin{2};
    else
        error(['Invalid parameter name: ', varargin{1}]);
    end
else
    verbose = false;
end

if verbose
    progressHandle = waitbar(0,'Loading DICOM Series...','WindowStyle','modal');
end

entries = dir(dicomSeriesDir);

dicomMetadata = {};
filenames = {};
numSlices = 0;

numEntries = length(entries);

for i=1:numEntries
    filename = entries(i).name;
    
    if length(filename) >= 4 && strcmp(filename(end-3:end), '.dcm')
        numSlices = numSlices + 1;
        
        dicomMetadata{numSlices} = dicominfo([dicomSeriesDir, '\', filename]);
        filenames{numSlices} = filename;
        
        if verbose
            waitbar(0.7 * (i/numEntries), progressHandle);
        end
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

centreOfSliceSeparation = round(sortedSliceLocations(2) - sortedSliceLocations(1),5);

volumeDimensions = double([topSliceMetadata.Height, topSliceMetadata.Width, numSlices]);
imagePosition = topSliceMetadata.ImagePositionPatient';
imageOrientation = topSliceMetadata.ImageOrientationPatient';
pixelSpacing = topSliceMetadata.PixelSpacing';

% construct volume
volume = zeros(volumeDimensions,'uint16');

for i=1:numSlices
    if verbose
        waitbar(0.7 + 0.3* (i/numSlices), progressHandle);
    end
    
    volume(:,:,i) = dicomread([dicomSeriesDir, '\', filenames{sortIndex(i)}]);
end

if verbose
    delete(progressHandle);
end

end

