classdef DicomImageVolume < matlab.mixin.Copyable
    %DicomImageVolume
    
    properties (SetAccess = private)
        m3xVolumeData % 3D matrix of data
        
        oDicomImageVolumeGeometry = DicomImageVolumeGeometry.empty        
        oImageWindowLevel = ImageWindowLevel.empty
        
        vdFieldOfViewCentreCoords_mm = []
    end
    
    methods (Access = public)
        function obj = DicomImageVolume(chDicomSeriesDir, varargin)
            %obj = DicomImageVolume(chDicomSeriesDir, varargin)
            %
            % SYNTAX:
            %  obj = DicomImageVolume(chDicomSeriesDir)
            %  obj = DicomImageVolume(chDicomSeriesDir, 'Verbose', true)
            %
            % DESCRIPTION:
            %  Constructor for NewClass
            %
            % INPUT ARGUMENTS:
            %  input1: What input1 is
            %  input2: What input2 is. If input2's description is very, very
            %         long wrap it with tabs to align the second line, and
            %         then the third line will automatically be in line
            %
            % OUTPUTS ARGUMENTS:
            %  obj: Constructed object
            
            [oDicomImageVolumeGeometry, m3xVolumeData] = DicomImageVolumeGeometry(chDicomSeriesDir, 'LoadGeometryOnly', false, varargin{:});
            
            obj.oDicomImageVolumeGeometry = oDicomImageVolumeGeometry;
            obj.oImageWindowLevel = ImageWindowLevel(m3xVolumeData);
            
            obj.m3xVolumeData = m3xVolumeData;
        end
        
        function setWindowLevelFromMinMax(obj, dMin, dMax)
            obj.oImageWindowLevel.setFromMinMaxValues(dMin, dMax);
        end
        
        function setWindowLevelFromWindowLevel(obj, dWindow, dLevel)
            obj.oImageWindowLevel.setFromWindowLevelValues(dWindow, dLevel);
        end
        
        function [dMin, dMax] = getMinMaxFromWindowLevel(obj)
            [dMin, dMax] = obj.oImageWindowLevel.getMinMaxValues();
        end
        
        function c1oBoundingLines = getVolumeBoundingLines(obj)
            c1oBoundingLines = obj.oDicomImageVolumeGeometry.getVolumeBoundingLines();
        end
        
        function vdCentreCoords_mm = getCentreCoordsOfVolume(obj)
            vdCentreCoords_mm = obj.oDicomImageVolumeGeometry.getCentreCoordsOfVolume();
        end
    end
       
    
    methods (Access = private)
        
        function [vdI,vdJ,vdK] = getVoxelIndicesFromCoordinates(obj, vdX, vdY, vdZ)
            % switch j and i to get from DICOM's (c,r,s) to MATLAB (r,c,s)
            [vdJ,vdI,vdK] = obj.oDicomImageVolumeGeometry.getVoxelIndicesFromCoordinates(vdX, vdY, vdZ);
            
            % plus 1 to get from DICOM indices starting at 0 into MATLAB's starting at 1
            vdI = vdI + 1;
            vdJ = vdJ + 1;
            vdK = vdK + 1;
        end
        
        function [vdX,vdY,vdZ] = getCoordinatesFromVoxelIndices(obj, vdI, vdJ, vdK)
            [vdX,vdY,vdZ] = obj.oDicomImageVolumeGeometry.getCoordinatesFromVoxelIndices(vdJ-1, vdI-1, vdK-1); % minus 1 to get into DICOM indices starting at 0 instead of MATLAB's 1, switch i and j to go from DICOM (c,r,s) to MATLAB (r,c,s)
        end
        
        function [dSagittalDim, dCoronalDim, dAxialDim] = getPlaneDimensions(obj)
            [~,dRowDim] = max(obj.vdImageOrientation(1:3));
            [~,dColDim] = max(obj.vdImageOrientation(4:6));
            
            vdPossibleDims = 1:3;
            
            dSliceDim = vdPossibleDims(vdPossibleDims ~= dRowDim & vdPossibleDims ~= dColDim);
            
            vdVolumeDims = [dRowDim, dColDim, dSliceDim]; % 1 is for x, 2 is for y, 3 is z
            
            % now transform these into which index for each plane
            vdPossibleIndices = 1:3;
            
            dSagittalDim = vdPossibleIndices(vdVolumeDims == 1);
            dCoronalDim = vdPossibleIndices(vdVolumeDims == 2);
            dAxialDim = vdPossibleIndices(vdVolumeDims == 1);
        end
        
        function [m2iSlice, vdRowData, vdColData, vdRowBounds, vdColBounds] = getSlice(obj, oPlaneObject)
            
            dSliceIndex = oPlaneObject.getCurrentSliceIndex();
            
            [vdTopLeftIndices, vdBotRightIndices] = oPlaneObject.getCurrentFieldOfViewIndices(obj);
                        
            vdRowBounds = [vdBotRightIndices(oPlaneObject.dRowDimensionNumber), vdTopLeftIndices(oPlaneObject.dRowDimensionNumber)];
            vdColBounds = [vdTopLeftIndices(oPlaneObject.dColDimensionNumber), vdBotRightIndices(oPlaneObject.dColDimensionNumber)];
            
            % check if any flips are needed
            if oPlaneObject.bRowFlipRequired
                vdRowBounds = fliplr(vdRowBounds);
            end
            
            if oPlaneObject.bColFlipRequired
                vdColBounds = fliplr(vdColBounds);
            end       
            % get slice
            c1vdSliceSelectionIndices = cell(3,1);
            
            c1vdSliceSelectionIndices{oPlaneObject.dPlaneDimensionNumber} = dSliceIndex;
            c1vdSliceSelectionIndices{oPlaneObject.dRowDimensionNumber} = 1:oPlaneObject.dVolumeNumRows;
            c1vdSliceSelectionIndices{oPlaneObject.dColDimensionNumber} = 1:oPlaneObject.dVolumeNumCols;
            
            m2iSlice = squeeze(obj.m3iVolumeData(c1vdSliceSelectionIndices{1},c1vdSliceSelectionIndices{2},c1vdSliceSelectionIndices{3}));
                        
            if oPlaneObject.bRowFlipRequired
                m2iSlice = flipud(m2iSlice);
            end
            
            if oPlaneObject.bColFlipRequired
                m2iSlice = fliplr(m2iSlice);
            end
            
            vdDims = size(m2iSlice);
            
            vdRowData = [1,vdDims(1)];
            vdColData = [1,vdDims(2)];
        end
        
        function m2iSlice = getSliceOnly(obj, oPlaneObject)
            dSliceIndex = oPlaneObject.getCurrentSliceIndex();
            
            c1vdSliceSelectionIndices = cell(3,1);
            
            c1vdSliceSelectionIndices{oPlaneObject.dPlaneDimensionNumber} = dSliceIndex;
            c1vdSliceSelectionIndices{oPlaneObject.dRowDimensionNumber} = 1:oPlaneObject.dVolumeNumRows;
            c1vdSliceSelectionIndices{oPlaneObject.dColDimensionNumber} = 1:oPlaneObject.dVolumeNumCols;
            
            m2iSlice = squeeze(obj.m3iVolumeData(c1vdSliceSelectionIndices{1},c1vdSliceSelectionIndices{2},c1vdSliceSelectionIndices{3}));
            
            if oPlaneObject.bRowFlipRequired
                m2iSlice = flipud(m2iSlice);
            end
            
            if oPlaneObject.bColFlipRequired
                m2iSlice = fliplr(m2iSlice);
            end
        end
        
        function [vdRowBounds, vdColBounds] = getRowAndColumnLimits(obj, oPlaneObject)
            [vdTopLeftIndices, vdBotRightIndices] = oPlaneObject.getCurrentFieldOfViewIndices(obj);
                        
            vdRowBounds = [vdBotRightIndices(oPlaneObject.dRowDimensionNumber), vdTopLeftIndices(oPlaneObject.dRowDimensionNumber)];
            vdColBounds = [vdTopLeftIndices(oPlaneObject.dColDimensionNumber), vdBotRightIndices(oPlaneObject.dColDimensionNumber)];
            
            % check if any flips are needed
            if vdRowBounds(1) > vdRowBounds(2)
                vdRowBounds = fliplr(vdRowBounds);
            end
            
            if vdColBounds(1) > vdColBounds(2)
                vdColBounds = fliplr(vdColBounds);
            end              
        end
        
        function setDefaultThreshold(obj, oControllerObject)
            viVolumeVector = obj.m3iVolumeData(:);
            
            dMinAll = double(min(viVolumeVector));            
            dMaxAll = double(max(viVolumeVector));
            
            dDarkCutoff = (dMaxAll - dMinAll) / 25;
            
            dAboveCutoffMean = double(mean(viVolumeVector(viVolumeVector > dDarkCutoff)));
            
            dLevel = dAboveCutoffMean + dDarkCutoff;
            
            dWindowLow = dDarkCutoff * 1.5;
            dWindowHigh = dLevel + (dLevel - dWindowLow);
            
            dWindow = round(dWindowHigh - dWindowLow);
            dLevel = round(dLevel);
            
            [dMin, dMax] = obj.getMinMaxFromWindowLevel(dWindow, dLevel);            
            obj.updateDisplayThresholdsFromMinMaxValues(oControllerObject, dMin, dMax);
        end
        
        function [dRowPixelSpacing_mm, dColPixelSpacing_mm] = getPixelSpacingForPlane(obj, vdPlaneNormalUnitVector)
            [dRowDim, dColDim] = obj.getRowAndColumnDimensionsForPlane(vdPlaneNormalUnitVector);
            
            vdPixelSpacingVector_mm = obj.getPixelSpacingVector();
            
            dRowPixelSpacing_mm = vdPixelSpacingVector_mm(dRowDim);
            dColPixelSpacing_mm = vdPixelSpacingVector_mm(dColDim);
        end
        
        function [dNumRows, dNumCols] = getSliceDimensionsForPlane(obj, vdPlaneNormalUnitVector)
            [vRowDim, vColDim] = obj.getRowAndColumnDimensionsForPlane(vdPlaneNormalUnitVector);
            
            dNumRows = obj.vdVolumeDimensions(vRowDim);
            dNumCols = obj.vdVolumeDimensions(vColDim);
        end
        
        function [dRowDim, dColDim] = getRowAndColumnDimensionsForPlane(obj, vdPlaneNormalUnitVector)
            vdIndexUnitVector = obj.getVoxelIndexUnitVector();
            
            dDotProd = round(dot(vdIndexUnitVector,vdPlaneNormalUnitVector));
            
            vdDims = 1:3;
            
            vdDimsForPlane = vdDims(dDotProd ~= 0);
            
            dColDim = vdDimsForPlane(1);
            dRowDim = vdDimsForPlane(2);
        end
        
        function vdPixelSpacingVector = getPixelSpacingVector(obj)
            vdPixelSpacingVector = [obj.vdInPlanePixelSpacing_mm, obj.dCentreOfSliceSeparation_mm];
        end
        
        function vdIndexUnitVector = getVoxelIndexUnitVector(obj)
            [dX,dY,dZ] = obj.getCoordinatesFromVoxelIndices(2,2,2);
            
            vdIndexUnitVector = [dX,dY,dZ];
        end
        
        function vbDimMask = getPlaneIndexDimensionMask(obj, vdPlaneNormalUnitVector)
            [vdRowUnitVector, vdColUnitVector, vdSliceUnitVector] = obj.getVolumeUnitVectors();
            
            m2dVectors = [vdRowUnitVector; vdColUnitVector; vdSliceUnitVector];
            
            vdDotProducts = dot(m2dVectors, repmat(vdPlaneNormalUnitVector, 3, 1), 2);
            
            % dot product of unit vector with plane's normal will be 0
            % unless aligned.
            % round just to tidy up any floating point errors
            vbDimMask = logical(round(vdDotProducts'));
        end
        
        function [vdRowUnitVector, vdColUnitVector, vdSliceUnitVector] = getVolumeUnitVectors(obj)
            vdRowUnitVector = obj.vdImageOrientation(4:6);
            vdColUnitVector = obj.vdImageOrientation(1:3);
            
            vdSliceUnitVector = cross(vdColUnitVector, vdRowUnitVector);
        end
        
        function [dMin, dMax] = getThresholdMinMax(obj)
            dMin = obj.dThresholdMin;
            dMax = obj.dThresholdMax;
        end
        
        function [dWindow, dLevel] = getThresholdWindowLevel(obj)
            [dWindow, dLevel] = obj.getWindowLevelFromMinMax(obj.dThresholdMin, obj.dThresholdMax);            
        end
        
        function updateDisplayThresholdsFromWindowLevelChange(obj, oControllerObj)
            dWindow = oControllerObj.oThresholdWindowEditFieldHandle.Value;
            dLevel = oControllerObj.oThresholdLevelEditFieldHandle.Value;
            
            [dMin, dMax] = DicomImageVolume.getMinMaxFromWindowLevel(dWindow, dLevel);
                
            obj.dThresholdMin = dMin;
            obj.dThresholdMax = dMax;
            
            if ~isempty(oControllerObj.oThresholdMinEditFieldHandle) && ~isempty(oControllerObj.oThresholdMaxEditFieldHandle)
                oControllerObj.oThresholdMinEditFieldHandle.Value = dMin;
                oControllerObj.oThresholdMaxEditFieldHandle.Value = dMax;
            end
        end 
                
        function updateDisplayThresholdsFromMinMaxChange(obj, oControllerObj)
            dMin = oControllerObj.oThresholdMinEditFieldHandle.Value;
            dMax = oControllerObj.oThresholdMaxEditFieldHandle.Value;
            
            obj.dThresholdMin = dMin;
            obj.dThresholdMax = dMax;
            
            if ~isempty(oControllerObj.oThresholdWindowEditFieldHandle) && ~isempty(oControllerObj.oThresholdLevelEditFieldHandle)
                [dWindow, dLevel] = DicomImageVolume.getWindowLevelFromMinMax(dMin, dMax);
                
                oControllerObj.oThresholdWindowEditFieldHandle.Value = dWindow;
                oControllerObj.oThresholdLevelEditFieldHandle.Value = dLevel;
            end
        end 
                
        function updateDisplayThresholdsFromMinMaxValues(obj, oControllerObj, dMin, dMax)
            obj.dThresholdMin = dMin;
            obj.dThresholdMax = dMax;
            
            if ~isempty(oControllerObj.oThresholdMinEditFieldHandle) && ~isempty(oControllerObj.oThresholdMaxEditFieldHandle)
                oControllerObj.oThresholdMinEditFieldHandle.Value = dMin;
                oControllerObj.oThresholdMaxEditFieldHandle.Value = dMax;
            end
            
            if ~isempty(oControllerObj.oThresholdWindowEditFieldHandle) && ~isempty(oControllerObj.oThresholdLevelEditFieldHandle)
                [dWindow, dLevel] = DicomImageVolume.getWindowLevelFromMinMax(dMin, dMax);
                
                oControllerObj.oThresholdWindowEditFieldHandle.Value = dWindow;
                oControllerObj.oThresholdLevelEditFieldHandle.Value = dLevel;
            end
        end 
    end
end

