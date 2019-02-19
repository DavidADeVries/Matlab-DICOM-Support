function [x,y,z] = getVoxelVerticesCoordinates(volumeDimensions, imagePosition, imageOrientation, pixelSpacing, centreOfSliceSeparation)
%[x,y,z] = getVoxelVerticesCoordinates(volumeDimensions, imagePosition, imageOrientation, pixelSpacing, centreOfSliceSeparation)
%  returns the 3D coordinates of the vertices of all the voxels within a
%  volume within three separate 3D matrices (x,y,z). Each of these matrices
%  will therefore be the same dimensions as volumeDimensions, plus 1 in
%  each dimension (n+1 vertices for n voxels)

[i,j,k] = meshgrid(...
    -0.5:1:volumeDimensions(1)-1+0.5,...
    -0.5:1:volumeDimensions(2)-1+0.5,...
    -0.5:1:volumeDimensions(3)-1+0.5);

[x,y,z] = getCoordinatesFromVoxelIndices(i, j, k, imagePosition, imageOrientation, pixelSpacing, centreOfSliceSeparation);

end

