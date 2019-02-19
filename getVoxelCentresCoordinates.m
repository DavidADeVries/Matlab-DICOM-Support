function [x,y,z] = getVoxelCentresCoordinates(volumeDimensions, imagePosition, imageOrientation, pixelSpacing, centreOfSliceSeparation)
%[x,y,z] = getVoxelCentresCoordinates(volumeDimensions, imagePosition, imageOrientation, pixelSpacing, centreOfSliceSeparation)
%  returns the 3D coordinates of the centre of all the voxels within a
%  volume within three separate 3D matrices (x,y,z)

[i,j,k] = meshgrid(...
    0:1:volumeDimensions(1)-1,...
    0:1:volumeDimensions(2)-1,...
    0:1:volumeDimensions(3)-1);

[x,y,z] = getCoordinatesFromVoxelIndices(i, j, k, imagePosition, imageOrientation, pixelSpacing, centreOfSliceSeparation);

end

