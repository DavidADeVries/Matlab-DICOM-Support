classdef DicomImageVolume < matlab.mixin.Copyable
    %DicomImageVolume
    
    properties
        volumeData % 3D matrix of data
        volumeDimensions
        
        imagePosition_mm
        imageOrientation
        
        inPlanePixelSpacing_mm % 1x2 array of spacing of rows, cols
        centreOfSliceSeparation_mm
        
        minLevel
        maxLevel
        
        minWindow = 1
        maxWindow
        
        fieldOfViewCentreCoords_mm = []
    end
    
    methods
        function obj = DicomImageVolume(dicomSeriesDir)
            %obj = ContourValidationImageVolume(dicomSeriesDir)
            [volume, volumeDimensions, imagePosition, imageOrientation, pixelSpacing, centreOfSliceSeparation]...
                = getDicomSeriesVolumeAndGeometry(dicomSeriesDir, 'Verbose', true);
            
            obj.volumeData = volume;
            obj.volumeDimensions = volumeDimensions;
            
            allDimMin = double(min(min(min(volume))));
            allDimMax = double(max(max(max(volume))));
            
            obj.minLevel = allDimMin;
            obj.maxLevel = allDimMax;
            
            obj.maxWindow = allDimMax - allDimMin;
            
            obj.imagePosition_mm = imagePosition;
            obj.imageOrientation = imageOrientation;
            
            obj.inPlanePixelSpacing_mm = pixelSpacing;
            obj.centreOfSliceSeparation_mm = centreOfSliceSeparation;
        end
                
        function [i,j,k] = getVoxelIndicesFromCoordinates(obj, x, y, z)
            % switch j and i to get from DICOM's (c,r,s) to MATLAB (r,c,s)
            [j,i,k] = getVoxelIndicesFromCoordinates(x, y, z,...
                obj.imagePosition_mm, obj.imageOrientation,...
                obj.inPlanePixelSpacing_mm, obj.centreOfSliceSeparation_mm);
            
            % plus 1 to get from DICOM indices starting at 0 into MATLAB's starting at 1
            i = i + 1;
            j = j + 1;
            k = k + 1;
        end
        
        function [x,y,z] = getCoordinatesFromVoxelIndices(obj, i, j, k)
            [x,y,z] = getCoordinatesFromVoxelIndices(j-1, i-1, k-1,... % minus 1 to get into DICOM indices starting at 0 instead of MATLAB's 1, switch i and j to go from DICOM (c,r,s) to MATLAB (r,c,s)
                obj.imagePosition_mm, obj.imageOrientation,...
                obj.inPlanePixelSpacing_mm, obj.centreOfSliceSeparation_mm);
        end
        
        function [sagittalDim, coronalDim, axialDim] = getPlaneDimensions(obj)
            [~,rowDim] = max(obj.imageOrientation(1:3));
            [~,colDim] = max(obj.imageOrientation(4:6));
            
            possibleDims = 1:3;
            
            sliceDim = possibleDims(possibleDims ~= rowDim & possibleDims ~= colDim);
            
            volumeDims = [rowDim, colDim, sliceDim]; % 1 is for x, 2 is for y, 3 is z
            
            % now transform these into which index for each plane
            possibleIndices = 1:3;
            
            sagittalDim = possibleIndices(volumeDims == 1);
            coronalDim = possibleIndices(volumeDims == 2);
            axialDim = possibleIndices(volumeDims == 1);
        end
        
        function [slice, rowData, colData, rowBounds, colBounds] = getSlice(obj, planeObject)
            
            sliceIndex = planeObject.getCurrentSliceIndex();
            
            [topLeftIndices, botRightIndices] = planeObject.getCurrentFieldOfViewIndices(obj);
                        
            rowBounds = [botRightIndices(planeObject.rowDimensionNumber), topLeftIndices(planeObject.rowDimensionNumber)];
            colBounds = [topLeftIndices(planeObject.colDimensionNumber), botRightIndices(planeObject.colDimensionNumber)];
            
            % check if any flips are needed
            if planeObject.rowFlipRequired
                rowBounds = fliplr(rowBounds);
            end
            
            if planeObject.colFlipRequired
                colBounds = fliplr(colBounds);
            end       
            % get slice
            sliceSelectionIndices = cell(3,1);
            
            sliceSelectionIndices{planeObject.planeDimensionNumber} = sliceIndex;
            sliceSelectionIndices{planeObject.rowDimensionNumber} = 1:planeObject.volumeNumRows;
            sliceSelectionIndices{planeObject.colDimensionNumber} = 1:planeObject.volumeNumCols;
            
            slice = squeeze(obj.volumeData(sliceSelectionIndices{1},sliceSelectionIndices{2},sliceSelectionIndices{3}));
                        
            if planeObject.rowFlipRequired
                slice = flipud(slice);
            end
            
            if planeObject.colFlipRequired
                slice = fliplr(slice);
            end
            
            dims = size(slice);
            
            rowData = [1,dims(1)];
            colData = [1,dims(2)];
        end
        
        function slice = getSliceOnly(obj, planeObject)
            sliceIndex = planeObject.getCurrentSliceIndex();
            
            sliceSelectionIndices = cell(3,1);
            
            sliceSelectionIndices{planeObject.planeDimensionNumber} = sliceIndex;
            sliceSelectionIndices{planeObject.rowDimensionNumber} = 1:planeObject.volumeNumRows;
            sliceSelectionIndices{planeObject.colDimensionNumber} = 1:planeObject.volumeNumCols;
            
            slice = squeeze(obj.volumeData(sliceSelectionIndices{1},sliceSelectionIndices{2},sliceSelectionIndices{3}));
            
            if planeObject.rowFlipRequired
                slice = flipud(slice);
            end
            
            if planeObject.colFlipRequired
                slice = fliplr(slice);
            end
        end
        
        function [rowBounds, colBounds] = getRowAndColumnLimits(obj, planeObject)
            [topLeftIndices, botRightIndices] = planeObject.getCurrentFieldOfViewIndices(obj);
                        
            rowBounds = [botRightIndices(planeObject.rowDimensionNumber), topLeftIndices(planeObject.rowDimensionNumber)];
            colBounds = [topLeftIndices(planeObject.colDimensionNumber), botRightIndices(planeObject.colDimensionNumber)];
            
            % check if any flips are needed
            if rowBounds(1) > rowBounds(2)
                rowBounds = fliplr(rowBounds);
            end
            
            if colBounds(1) > colBounds(2)
                colBounds = fliplr(colBounds);
            end              
        end
        
        function [] = setDefaultThreshold(obj, oControllerObject)
            v = obj.volumeData(:);
            
            minAll = double(min(v));            
            maxAll = double(max(v));
            
            darkCutoff = (maxAll - minAll) / 25;
            
            aboveCutoffMean = double(mean(v(v > darkCutoff)));
            
            level = aboveCutoffMean + darkCutoff;
            
            windowLow = darkCutoff * 1.5;
            windowHigh = level + (level - windowLow);
            
            window = round(windowHigh - windowLow);
            level = round(level);
            
            oControllerObject.oThresholdWindowEditFieldHandle.Value = window;
            oControllerObject.oThresholdLevelEditFieldHandle.Value = level;
            
            oControllerObject.oThresholdMinEditFieldHandle.Value = level - window/2;
            oControllerObject.oThresholdMaxEditFieldHandle.Value = level + window/2;
        end
        
        function [rowPixelSpacing_mm, colPixelSpacing_mm] = getPixelSpacingForPlane(obj, planeNormalUnitVector)
            [rowDim, colDim] = obj.getRowAndColumnDimensionsForPlane(planeNormalUnitVector);
            
            pixelSpacingVector_mm = obj.getPixelSpacingVector();
            
            rowPixelSpacing_mm = pixelSpacingVector_mm(rowDim);
            colPixelSpacing_mm = pixelSpacingVector_mm(colDim);
        end
        
        function [numRows, numCols] = getSliceDimensionsForPlane(obj, planeNormalUnitVector)
            [rowDim, colDim] = obj.getRowAndColumnDimensionsForPlane(planeNormalUnitVector);
            
            numRows = obj.volumeDimensions(rowDim);
            numCols = obj.volumeDimensions(colDim);
        end
        
        function [rowDim, colDim] = getRowAndColumnDimensionsForPlane(obj, planeNormalUnitVector)
            indexUnitVector = obj.getVoxelIndexUnitVector();
            
            dotProd = round(dot(indexUnitVector,planeNormalUnitVector));
            
            dims = 1:3;
            
            dimsForPlane = dims(dotProd ~= 0);
            
            colDim = dimsForPlane(1);
            rowDim = dimsForPlane(2);
        end
        
        function pixelSpacingVector = getPixelSpacingVector(obj)
            pixelSpacingVector = [obj.inPlanePixelSpacing_mm, obj.centreOfSliceSeparation_mm];
        end
        
        function indexUnitVector = getVoxelIndexUnitVector(obj)
            [x,y,z] = obj.getCoordinatesFromVoxelIndices(2,2,2);
            
            indexUnitVector = [x,y,z];
        end
        
        function dimMask = getPlaneIndexDimensionMask(obj, planeNormalUnitVector)
            [rowUnitVector, colUnitVector, sliceUnitVector] = obj.getVolumeUnitVectors();
            
            unitVectors = [rowUnitVector; colUnitVector; sliceUnitVector];
            
            dotProducts = dot(unitVectors, repmat(planeNormalUnitVector, 3, 1), 2);
            
            % dot product of unit vector with plane's normal will be 0
            % unless aligned.
            % round just to tidy up any floating point errors
            dimMask = logical(round(dotProducts'));
        end
        
        function [rowUnitVector, colUnitVector, sliceUnitVector] = getVolumeUnitVectors(obj)
            rowUnitVector = obj.imageOrientation(4:6);
            colUnitVector = obj.imageOrientation(1:3);
            
            sliceUnitVector = cross(colUnitVector, rowUnitVector);
        end
        
        function centreCoords_mm = getCentreCoordsOfVolume(obj)
            centreIndices = (obj.volumeDimensions+1) / 2;
            
            [x,y,z] = obj.getCoordinatesFromVoxelIndices(...
                centreIndices(1), centreIndices(2), centreIndices(3));
            
            centreCoords_mm = [x,y,z];
        end
    end
    
    methods (Static)        
        function [] = updateDisplayThresholdsFromWindowLevelChange(oControllerObj)
            window = oControllerObj.oThresholdWindowEditFieldHandle.Value;
            level = oControllerObj.oThresholdLevelEditFieldHandle.Value;
            
            oControllerObj.oThresholdMinEditFieldHandle.Value = level - window/2;
            oControllerObj.oThresholdMaxEditFieldHandle.Value = level + window/2;
        end 
                
        function [] = updateDisplayThresholdsFromMinMaxChange(oControllerObj)
            min = oControllerObj.oThresholdMinEditFieldHandle.Value;
            max = oControllerObj.oThresholdMaxEditFieldHandle.Value;
            
            oControllerObj.oThresholdWindowEditFieldHandle.Value = max - min;
            oControllerObj.oThresholdLevelEditFieldHandle.Value = (min + max)/2;
        end 
    end
end

