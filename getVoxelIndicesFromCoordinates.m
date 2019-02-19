function [i,j,k] = getVoxelIndicesFromCoordinates(x, y, z, imagePosition, imageOrientation, pixelSpacing, centreOfSliceSeparation)
%[i,j,k] = getVoxelIndicesFromCoordinates(x, y, z, imagePosition, imageOrientation, pixelSpacing, centreOfSliceSeparation)
%
% function takes in a DICOM volume's orientation/positions metadata and
% returns the volume indices (i,j,k) at position (x,y,z), where even
% indices are in the middle of a voxel.
% - x,y,z: may be n-dimensional matrices, resulting in n-dimensional i,j,k
% matrices being returned (e.g. supports "meshgrid")
% - imagePosition: Direct values of the "ImagePositionPatient" DICOM field
% from the top (most +z or superior) slice
% - imageOrientation: Direct values of the "ImageOrientationPatient" DICOM
% field from any slice (it is assumed all slices are parallel)
% - pixelSpacing: Direct values of the "PixelSpacing" DICOM field from any
% slice (it is assumed all slices have the same pixel spacing)
% - centreOfSliceSeparation: This value represents the distance (in mm)
% from the centre of a voxel in one slice to the centre of the voxel
% directly above/below it in another slice. NOTE: this may or may not be
% the same as the "SliceThickness" DICOM field since slices may not be
% directly adjacent to one another. It is recommended instead to subtract
% the "ImagePositionPatient" vectors from two known adjacent slices and
% take the norm (and probably round to avoid errors). Another method is to
% use differences in the "SliceLocation" fields, if they exist. It is also 
% assumed that all slices are of an equal thickness and distance apart


% find z-direction component
n = cross(imageOrientation(1:3), imageOrientation(4:6));

% calculate x,y,z coordinates
i = ( imageOrientation(1).*(x-imagePosition(1)) + imageOrientation(2).*(y-imagePosition(2)) + imageOrientation(3).*(z-imagePosition(3)) ) ./ pixelSpacing(1);
j = ( imageOrientation(4).*(x-imagePosition(1)) + imageOrientation(5).*(y-imagePosition(2)) + imageOrientation(6).*(z-imagePosition(3)) ) ./ pixelSpacing(2);
k = ( n(1).*(x-imagePosition(1)) + n(2).*(y-imagePosition(2)) + n(3).*(z-imagePosition(3)) ) ./ centreOfSliceSeparation;

end

