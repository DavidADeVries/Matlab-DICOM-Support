classdef DicomImageVolumeGeometry
    %DicomCoordinateCalculator
    
    % *********************************************************************   ORDERING: 1 Abstract        X.1 Public       X.X.1 Not Constant
    % *                            PROPERTIES                             *             2 Not Abstract -> X.2 Protected -> X.X.2 Constant
    % *********************************************************************                               X.3 Private
    
    properties (SetAccess = private)
        vdVolumeDimensions
        
        oTopSliceReferencePlane
        
        vdImagePosition_mm
        
        vdSliceRowOrientationVector
        vdSliceColOrientationVector
        
        dRowPixelSpacing_mm
        dColPixelSpacing_mm
        
        dCentreOfSliceSeparation_mm
    end
    
    
    
    % *********************************************************************   ORDERING: 1 Abstract     -> X.1 Not Static 
    % *                          PUBLIC METHODS                           *             2 Not Abstract    X.2 Static
    % *********************************************************************
    
    methods (Access = public)
        
        function [obj, m3xVolume] = DicomImageVolumeGeometry(chDicomSeriesDir, varargin)
            [vdVolumeDimensions, vdImagePosition_mm, vdSliceRowOrientationVector, vdSliceColOrientationVector, dRowPixelSpacing_mm, dColPixelSpacing_mm, dCentreOfSliceSeparation_mm, m3xVolume] =...
                obj.loadDicomSeriesGeometryAndVolumeFromDirectory(chDicomSeriesDir, varargin{:});
            
            obj.oTopSliceReferencePlane = Plane3D(vdImagePosition_mm,...
                vdSliceRowOrientationVector, vdSliceColOrientationVector,...
                [-Inf,Inf], [-Inf,Inf]);
            
            obj.vdVolumeDimensions = vdVolumeDimensions;
            
            obj.dRowPixelSpacing_mm = dRowPixelSpacing_mm;
            obj.dColPixelSpacing_mm = dColPixelSpacing_mm;            
            obj.dCentreOfSliceSeparation_mm = dCentreOfSliceSeparation_mm;
        end
        
        function [vdX_mm, vdY_mm, vdZ_mm] = getCoordinatesFromVoxelIndices(obj, vdI, vdJ, vdK)
            [vdX_mm, vdY_mm, vdZ_mm] = obj.getCoordinatesFromVoxelIndicesCalculator(...
                vdI, vdJ, vdK,...
                obj.oTopSliceReferencePlane.getOrigin(),...
                obj.oTopSliceReferencePlane.getRowUnitVector(), obj.oTopSliceReferencePlane.getColUnitVector(),...
                obj.oTopSliceReferencePlane.getPlaneNormalUnitVector(),...
                obj.dRowPixelSpacing_mm, obj.dColPixelSpacing_mm, obj.dCentreOfSliceSeparation_mm);
        end
        
        function vdCentreCoords_mm = getCentreCoordsOfVolume(obj)
            vdCentreIndices = (obj.vdVolumeDimensions+1) / 2;
            
            [dX_mm,dY_mm,dZ_mm] = obj.getCoordinatesFromVoxelIndices(...
                vdCentreIndices(1), vdCentreIndices(2), vdCentreIndices(3));
            
            vdCentreCoords_mm = [dX_mm,dY_mm,dZ_mm];
        end
        
        function c1oBoundingLines = getVolumeBoundingLines(obj)
            vdVolumeDims = obj.vdVolumeDimensions-0.5;
            dZero = 0-0.5;
            
            vdVolumeCornerIndices = [...
                dZero, dZero, dZero;
                vdVolumeDims(1), dZero, dZero;
                dZero, vdVolumeDims(2), dZero;
                dZero, dZero, vdVolumeDims(3);
                vdVolumeDims(1), vdVolumeDims(2), dZero;
                vdVolumeDims(1), dZero, vdVolumeDims(3);
                dZero, vdVolumeDims(2), vdVolumeDims(3);
                vdVolumeDims(1), vdVolumeDims(2), vdVolumeDims(3)];
            
            [vdX_mm, vdY_mm, vdZ_mm] = obj.getCoordinatesFromVoxelIndices(...
                vdVolumeCornerIndices(:,1), vdVolumeCornerIndices(:,2), vdVolumeCornerIndices(:,3));
            
            vdVolumeCornerCoords = [vdX_mm, vdY_mm, vdZ_mm];
            
            % the 12 lines of the volume running from the 8 vertices
            c1oBoundingLines = {...
                Line3D(vdVolumeCornerCoords(1,:), vdVolumeCornerCoords(2,:)-vdVolumeCornerCoords(1,:), [0, norm(vdVolumeCornerCoords(2,:)-vdVolumeCornerCoords(1,:))]),...
                Line3D(vdVolumeCornerCoords(1,:), vdVolumeCornerCoords(3,:)-vdVolumeCornerCoords(1,:), [0, norm(vdVolumeCornerCoords(3,:)-vdVolumeCornerCoords(1,:))]),...
                Line3D(vdVolumeCornerCoords(1,:), vdVolumeCornerCoords(4,:)-vdVolumeCornerCoords(1,:), [0, norm(vdVolumeCornerCoords(4,:)-vdVolumeCornerCoords(1,:))]),...
                Line3D(vdVolumeCornerCoords(2,:), vdVolumeCornerCoords(5,:)-vdVolumeCornerCoords(2,:), [0, norm(vdVolumeCornerCoords(5,:)-vdVolumeCornerCoords(2,:))]),...
                Line3D(vdVolumeCornerCoords(2,:), vdVolumeCornerCoords(6,:)-vdVolumeCornerCoords(2,:), [0, norm(vdVolumeCornerCoords(6,:)-vdVolumeCornerCoords(2,:))]),...
                Line3D(vdVolumeCornerCoords(3,:), vdVolumeCornerCoords(5,:)-vdVolumeCornerCoords(3,:), [0, norm(vdVolumeCornerCoords(5,:)-vdVolumeCornerCoords(3,:))]),...
                Line3D(vdVolumeCornerCoords(3,:), vdVolumeCornerCoords(7,:)-vdVolumeCornerCoords(3,:), [0, norm(vdVolumeCornerCoords(7,:)-vdVolumeCornerCoords(3,:))]),...
                Line3D(vdVolumeCornerCoords(4,:), vdVolumeCornerCoords(6,:)-vdVolumeCornerCoords(4,:), [0, norm(vdVolumeCornerCoords(6,:)-vdVolumeCornerCoords(4,:))]),...
                Line3D(vdVolumeCornerCoords(4,:), vdVolumeCornerCoords(7,:)-vdVolumeCornerCoords(4,:), [0, norm(vdVolumeCornerCoords(7,:)-vdVolumeCornerCoords(4,:))]),...
                Line3D(vdVolumeCornerCoords(5,:), vdVolumeCornerCoords(8,:)-vdVolumeCornerCoords(5,:), [0, norm(vdVolumeCornerCoords(8,:)-vdVolumeCornerCoords(5,:))]),...
                Line3D(vdVolumeCornerCoords(6,:), vdVolumeCornerCoords(8,:)-vdVolumeCornerCoords(6,:), [0, norm(vdVolumeCornerCoords(8,:)-vdVolumeCornerCoords(6,:))]),...
                Line3D(vdVolumeCornerCoords(7,:), vdVolumeCornerCoords(8,:)-vdVolumeCornerCoords(7,:), [0, norm(vdVolumeCornerCoords(8,:)-vdVolumeCornerCoords(7,:))])};
        end
    end
    
    
    methods (Access = private, Static = true)
        
        function [vdVolumeDimensions, vdImagePosition_mm, vdSliceRowOrientationVector, vdSliceColOrientationVector, dRowPixelSpacing_mm, dColPixelSpacing_mm, dCentreOfSliceSeparation_mm, m3xVolume] = loadDicomSeriesGeometryAndVolumeFromDirectory(chDicomSeriesDir, varargin)
            %[vdVolumeDimensions, vdImagePosition, vdImageOrientation, vdPixelSpacing, vdCentreOfSliceSeparation, m3xVolume] = loadDicomSeriesGeometryAndVolumeFromDirectory(chDicomSeriesDir, varargin)
            %
            % SYNTAX:
            %  [vdVolumeDimensions, vdImagePosition, vdImageOrientation, vdPixelSpacing, vdCentreOfSliceSeparation, m3xVolume] = loadDicomSeriesGeometryAndVolumeFromDirectory(chDicomSeriesDir)
            %  [vdVolumeDimensions, vdImagePosition, vdImageOrientation, vdPixelSpacing, vdCentreOfSliceSeparation, m3xVolume] = loadDicomSeriesGeometryAndVolumeFromDirectory(___, 'Verbose', bVerbose)
            %  [vdVolumeDimensions, vdImagePosition, vdImageOrientation, vdPixelSpacing, vdCentreOfSliceSeparation, ~] = loadDicomSeriesGeometryAndVolumeFromDirectory(___, 'GeometryOnly',bGeometryOnly)
            %
            % DESCRIPTION:
            %  
            %
            % INPUT ARGUMENTS:
            %  input1: What input1 is
            %
            % OUTPUTS ARGUMENTS:
            %  output1: What output1 is
            
            
            % defaults
            bVerbose = false;
            bGeometryOnly = false;
            
            % evaluate name/value pairs
            if nargin > 1
                for dVarIndex=1:2:length(varargin)
                    switch varargin{dVarIndex}
                        case 'Verbose'
                            bVerbose = varargin{dVarIndex+1};
                        case 'LoadGeometryOnly'
                            bGeometryOnly = varargin{dVarIndex+1};
                        otherwise
                            error(...
                                'DicomImageVolumeGeometry:loadDicomSeriesGeometryAndVolume:InvalidParameters',...
                                ['Invalid parameter name: ', varargin{dVarIndex}]);
                    end
                end
            end
            
            % begin loading:
            
            if bVerbose
                hProgressHandle = waitbar(0,'Loading DICOM Series...','WindowStyle','modal');
            end
            
            vStEntries = dir(chDicomSeriesDir);
            
            c1stDicomMetadata = {};
            c1chFilenames = {};
            dNumSlices = 0;
            
            dNumEntries = length(vStEntries);
            
            for dEntryIndex=1:dNumEntries
                chFilename = vStEntries(dEntryIndex).name;
                
                if length(chFilename) >= 4 && strcmp(chFilename(end-3:end), '.dcm')
                    dNumSlices = dNumSlices + 1;
                    
                    c1stDicomMetadata{dNumSlices} = dicominfo(fullfile(chDicomSeriesDir, chFilename));
                    c1chFilenames{dNumSlices} = chFilename;
                    
                    if bVerbose
                        waitbar(0.7 * (dEntryIndex/dNumEntries), hProgressHandle);
                    end
                end
            end
            
            % choose the first slice as the reference slice (it may not be the first
            % slice, but that'll be figured out in time)
            stRefMetadata = c1stDicomMetadata{1};
            
            %refImagePosition = refMetadata.ImagePositionPatient;
            vdRefImageOrientation = stRefMetadata.ImageOrientationPatient;
            
            dN = cross(vdRefImageOrientation(1:3), vdRefImageOrientation(4:6));
            
            vdSliceLocations = zeros(dNumSlices,1);
            
            for dEntryIndex=1:dNumSlices
                vdSliceLocations(dEntryIndex) = dot(c1stDicomMetadata{dEntryIndex}.ImagePositionPatient, dN);
            end
            
            [vdSortedSliceLocations, vdSortIndex] = sort(vdSliceLocations, 'ascend');
            
            stTopSliceMetadata = c1stDicomMetadata{vdSortIndex(1)};
            
            dCentreOfSliceSeparation_mm = round(vdSortedSliceLocations(2) - vdSortedSliceLocations(1), 5);
            
            vdVolumeDimensions = double([stTopSliceMetadata.Height, stTopSliceMetadata.Width, dNumSlices]);
            vdImagePosition_mm = stTopSliceMetadata.ImagePositionPatient';
            vdImageOrientation = stTopSliceMetadata.ImageOrientationPatient';
            vdPixelSpacing_mm = stTopSliceMetadata.PixelSpacing';
            
            vdSliceRowOrientationVector = vdImageOrientation(1:3);
            vdSliceColOrientationVector = vdImageOrientation(4:6);
            
            dRowPixelSpacing_mm = vdPixelSpacing_mm(1);
            dColPixelSpacing_mm = vdPixelSpacing_mm(2);
            
            % construct volume
            if bGeometryOnly
                m3xVolume = [];
            else
                m3xVolume = zeros(vdVolumeDimensions,'uint16');
                
                for dSliceIndex=1:dNumSlices
                    if bVerbose
                        waitbar(0.7 + 0.3* (dSliceIndex/dNumSlices), hProgressHandle);
                    end
                    
                    m3xVolume(:,:,dSliceIndex) = dicomread(fullfile(chDicomSeriesDir, c1chFilenames{vdSortIndex(dSliceIndex)}));
                end
            end
            
            % delete load bar
            if bVerbose
                delete(hProgressHandle);
            end            
        end
        
        function [vdX_mm, vdY_mm, vdZ_mm] = getCoordinatesFromVoxelIndicesCalculator(vdI, vdJ, vdK, vdImagePosition_mm, vdSliceRowOrientationVector, vdSliceColOrientationVector, vdSliceNormalVector, dRowPixelSpacing_mm, dColPixelSpacing_mm, dCentreOfSliceSeparation_mm)
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
                        
            % calculate x,y,z coordinates
            vdX_mm = (vdI.*vdSliceRowOrientationVector(1).*dRowPixelSpacing_mm) + (vdJ.*vdSliceColOrientationVector(1).*dColPixelSpacing_mm) + (vdK.*vdSliceNormalVector(1).*dCentreOfSliceSeparation_mm) + vdImagePosition_mm(1);
            vdY_mm = (vdI.*vdSliceRowOrientationVector(2).*dRowPixelSpacing_mm) + (vdJ.*vdSliceColOrientationVector(2).*dColPixelSpacing_mm) + (vdK.*vdSliceNormalVector(2).*dCentreOfSliceSeparation_mm) + vdImagePosition_mm(2);
            vdZ_mm = (vdI.*vdSliceRowOrientationVector(3).*dRowPixelSpacing_mm) + (vdJ.*vdSliceColOrientationVector(3).*dColPixelSpacing_mm) + (vdK.*vdSliceNormalVector(3).*dCentreOfSliceSeparation_mm) + vdImagePosition_mm(3);            
        end
        
        function [vdI,vdJ,vdK] = getVoxelIndicesFromCoordinates(vdX_mm, vdY_mm, vdZ_mm, vdImagePosition_mm, vdSliceRowOrientationVector, vdSliceColOrientationVector, vdSliceNormalVector, dRowPixelSpacing_mm, dColPixelSpacing_mm, dCentreOfSliceSeparation_mm)
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
            
            % calculate x,y,z coordinates
            vdI = ( vdSliceRowOrientationVector(1).*(vdX_mm-vdImagePosition_mm(1)) + vdSliceRowOrientationVector(2).*(vdY_mm-vdImagePosition_mm(2)) + vdSliceRowOrientationVector(3).*(vdZ_mm-vdImagePosition_mm(3)) ) ./ dRowPixelSpacing_mm;
            vdJ = ( vdSliceColOrientationVector(1).*(vdX_mm-vdImagePosition_mm(1)) + vdSliceColOrientationVector(2).*(vdY_mm-vdImagePosition_mm(2)) + vdSliceColOrientationVector(3).*(vdZ_mm-vdImagePosition_mm(3)) ) ./ dColPixelSpacing_mm;
            vdK = ( vdSliceNormalVector(1)        .*(vdX_mm-vdImagePosition_mm(1)) + vdSliceNormalVector(2)        .*(vdY_mm-vdImagePosition_mm(2)) + vdSliceNormalVector(3)        .*(vdZ_mm-vdImagePosition_mm(3)) ) ./ dCentreOfSliceSeparation_mm;
            
        end
        
        function [vdCentreX_mm, vdCentreY_mm, vdCentreZ_mm, vdVertexX_mm, vdVertexY_mm, vdVertexZ_mm] = getVoxelCentreAndVerticesCoordinatesForDicomSeries(chDicomSeriesDir)
            %[centreX, centreY, centreZ, vertexX, vertexY, vertexZ] = getVoxelCentreAndVerticesCoordinatesForDicomSeries(dicomSeriesDir)
            %   Detailed explanation goes here
            
            % extract volume geometry information
            [vdVolumeDimensions, vdImagePosition_mm, vdSliceRowOrientationVector, vdSliceColOrientationVector, dRowPixelSpacing_mm, dColPixelSpacing_mm, dCentreOfSliceSeparation_mm, ~] = ...
                DIcomImageVolumeGeometry.loadDicomSeriesGeometryAndVolumeFromDirectory(chDicomSeriesDir, 'Verbose', false, 'LoadGeometryOnly', true);
            
            % calculate coordinates based on volume geometry
            [vdCentreX_mm, vdCentreY_mm, vdCentreZ_mm] = getVoxelCentresCoordinates(...
                vdVolumeDimensions, vdImagePosition_mm,...
                vdSliceRowOrientationVector, vdSliceColOrientationVector,...
                dRowPixelSpacing_mm, dColPixelSpacing_mm, dCentreOfSliceSeparation_mm);
            
            [vdVertexX_mm, vdVertexY_mm, vdVertexZ_mm] = getVoxelVerticesCoordinates(...
                vdVolumeDimensions, vdImagePosition_mm,...
                vdSliceRowOrientationVector, vdSliceColOrientationVector,...
                dRowPixelSpacing_mm, dColPixelSpacing_mm, dCentreOfSliceSeparation_mm);            
        end
        
        function [vdX,vdY,vdZ] = getVoxelCentresCoordinates(vdVolumeDimensions, vdImagePosition_mm, vdSliceRowOrientationVector, vdSliceColOrientationVector, dRowPixelSpacing_mm, dColPixelSpacing_mm, dCentreOfSliceSeparation_mm)
            %[x,y,z] = getVoxelCentresCoordinates(volumeDimensions, imagePosition, imageOrientation, pixelSpacing, centreOfSliceSeparation)
            %  returns the 3D coordinates of the centre of all the voxels within a
            %  volume within three separate 3D matrices (x,y,z)
            
            [vdI,vdJ,vdK] = meshgrid(...
                0:1:vdVolumeDimensions(1)-1,...
                0:1:vdVolumeDimensions(2)-1,...
                0:1:vdVolumeDimensions(3)-1);
            
            [vdX,vdY,vdZ] = getCoordinatesFromVoxelIndices(...
                vdI, vdJ, vdK,...
                vdImagePosition_mm,...
                vdSliceRowOrientationVector, vdSliceColOrientationVector, sliceNormalVectorCalculator(vdSliceRowOrientationVector, vdSliceColOrientationVector),...
                dRowPixelSpacing_mm, dColPixelSpacing_mm, dCentreOfSliceSeparation_mm);
            
        end
        
        function [vdX_mm,vdY_mm,vdZ_mm] = getVoxelVerticesCoordinates(vdVolumeDimensions, vdImagePosition_mm, vdSliceRowOrientationVector, vdSliceColOrientationVector, dRowPixelSpacing_mm, dColPixelSpacing_mm, dCentreOfSliceSeparation_mm)
            %[x,y,z] = getVoxelVerticesCoordinates(volumeDimensions, imagePosition, imageOrientation, pixelSpacing, centreOfSliceSeparation)
            %  returns the 3D coordinates of the vertices of all the voxels within a
            %  volume within three separate 3D matrices (x,y,z). Each of these matrices
            %  will therefore be the same dimensions as volumeDimensions, plus 1 in
            %  each dimension (n+1 vertices for n voxels)
            
            [vdI,vdJ,vdK] = meshgrid(...
                -0.5:1:vdVolumeDimensions(1)-1+0.5,...
                -0.5:1:vdVolumeDimensions(2)-1+0.5,...
                -0.5:1:vdVolumeDimensions(3)-1+0.5);
            
            [vdX_mm,vdY_mm,vdZ_mm] = getCoordinatesFromVoxelIndices(...
                vdI, vdJ, vdK,...
                vdImagePosition_mm,...
                vdSliceRowOrientationVector, vdSliceColOrientationVector, sliceNormalVectorCalculator(vdSliceRowOrientationVector, vdSliceColOrientationVector),...
                dRowPixelSpacing_mm, dColPixelSpacing_mm, dCentreOfSliceSeparation_mm);            
        end
    end
end
