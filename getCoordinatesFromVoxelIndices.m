function [x,y,z] = getCoordinatesFromVoxelIndices(i, j, k, imagePosition, imageOrientation, pixelSpacing, centreOfSliceSeparation)
%[x,y,z] = getCoordinatesFromVoxelIndices(i, j, k, imagePosition, imageOrientation, pixelSpacing, centreOfSliceSeparation)
%
% function takes in a DICOM volume's orientation/positions metadata and
% returns the 3D positions (x,y,z) of voxels at indices (i,j,k)
% - i,j,k: may be speicified as doubles. Integer values represent centre of
% voxels. Integer +/- 0.5 values represent edge/vertices of voxels. i,j,k
% maybe be n-dimensional matrices, resulting in n-dimensional x,y,z
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
x = (i.*imageOrientation(1).*pixelSpacing(1)) + (j.*imageOrientation(4).*pixelSpacing(2)) + (k.*n(1).*centreOfSliceSeparation) + imagePosition(1);
y = (i.*imageOrientation(2).*pixelSpacing(1)) + (j.*imageOrientation(5).*pixelSpacing(2)) + (k.*n(2).*centreOfSliceSeparation) + imagePosition(2);
z = (i.*imageOrientation(3).*pixelSpacing(1)) + (j.*imageOrientation(6).*pixelSpacing(2)) + (k.*n(3).*centreOfSliceSeparation) + imagePosition(3);

end

