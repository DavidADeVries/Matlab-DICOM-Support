classdef InteractiveImagingPlane < matlab.mixin.Copyable
    %InteractiveImagingPlane
    
    properties (Access = private)
        oAxesHandle
        oAxesLabelHandle = []
        oSliceLocationSpinnerHandle = []
        
        oFieldOfViewGeometry = FieldOfViewGeometry.empty
        
        chAxesTitle = ''
        
        c1c1oPlotHandles = {}
        c1oSliceLocationHandles = {}
        
        % >>>>>>>>>>>>>>>>>> PLANE UNIT VECTORS <<<<<<<<<<<<<<<<<<<<<<<<<<<
        
        % target plane normal unit vectors
        vdTargetPlaneNormalUnitVector % [1 0 0] for Sagittal, [0 1 0] for Coronal, [0 0 1] for axial
        vdTargetPlaneRowUnitVector
        vdTargetPlaneColUnitVector
        
        bAdjustPlaneUnitVectorsToMatchVolume = true
        
        
        
        % >>>>>>>>>>>>>>>>>> FOV REFERENCE PLANE <<<<<<<<<<<<<<<<<<<<<<<<<<
        
                
        dAxisWidth
        dAxisHeight
        
        % check if flip is required
        bSliceFlipRequired = false
        bRowFlipRequired = false
        bColFlipRequired = false
        
        vbPlaneDimensionMask % [1 0 0], [0 1 0], [0 0 1], if plane is running through row, cols or slices (respectively)
        dPlaneDimensionNumber
        dPlanePixelSpacing_mm 
        dVolumeNumSlices
        
        vbRowDimensionMask
        dRowDimensionNumber
        dRowPixelSpacing_mm
        dVolumeNumRows
        
        vbColDimensionMask
        dColDimensionNumber
        dColPixelSpacing_mm
        dVolumeNumCols
        
        dCurrentSliceIndex
        dMinSliceIndex
        dMaxSliceIndex
        
        dSliceIndexIncrement = 1
        
        dCurrentFieldOfView_mm
        dMinFieldOfView_mm
        dMaxFieldOfView_mm
        
        dFieldOfViewIncrement_mm
        
    end
    
    methods (Access = public)
        
        function obj = InteractiveImagingPlane(oAxesHandle, vdTargetPlaneNormalUnitVector, vdTargetPlaneRowUnitVector, vdTargetPlaneColUnitVector, varargin)
            %obj = InteractiveImagingPlane(oAxesHandle, vdTargetPlaneNormalUnitVector, vdTargetPlaneRowUnitVector, vdTargetPlaneColUnitVector, varargin)
                        
            obj.oAxesHandle = oAxesHandle;
            
            vdPos = oAxesHandle.Position;
            
            obj.dAxisWidth = vdPos(3);
            obj.dAxisHeight = vdPos(4);
            
            obj.vdTargetPlaneNormalUnitVector = vdTargetPlaneNormalUnitVector; 
            obj.vdTargetPlaneRowUnitVector = vdTargetPlaneRowUnitVector;
            obj.vdTargetPlaneColUnitVector = vdTargetPlaneColUnitVector;
            
            colormap(obj.oAxesHandle, 'gray');
            obj.oAxesHandle.Color = [0 0 0]; % black background
            
            for dVarIndex=1:2:length(varargin)
                switch varargin{dVarIndex}
                    case 'AxesLabelHandle'
                        obj.oAxesLabelHandle = varargin{dVarIndex+1};
                    case 'AxesTitle'
                        obj.chAxesTitle = varargin{dVarIndex+1};
                    case 'SliceLocationSpinnerHandle'
                        obj.oSliceLocationSpinnerHandle = varargin{dVarIndex+1};
                    case 'MatchPlaneToNearestVolumePlane'
                        obj.bAdjustPlaneUnitVectorsToMatchVolume = varargin{dVarIndex+1};
                    otherwise
                        error(...
                            'InterativeImagingPlane:Constructor:InvalidNameValuePair',...
                            ['Invalid parameter name ', varargin{dVarIndex}]);
                end
            end
        end
        
        function setNewHandlesAndTargetPlaneUnitVectors(obj, oNewInteractiveImagingPlane)
            obj.chAxesTitle = oNewInteractiveImagingPlane.chAxesTitle;
            
            obj.oAxesHandle = oNewInteractiveImagingPlane.oAxesHandle;
            obj.oAxesLabelHandle = oNewInteractiveImagingPlane.oAxesLabelHandle;
            obj.oSliceLocationSpinnerHandle = oNewInteractiveImagingPlane.oSliceLocationSpinnerHandle;
            
            obj.vdTargetPlaneNormalUnitVector = oNewInteractiveImagingPlane.vdTargetPlaneNormalUnitVector; 
            obj.vdTargetPlaneRowUnitVector = oNewInteractiveImagingPlane.vdTargetPlaneRowUnitVector;
            obj.vdTargetPlaneColUnitVector = oNewInteractiveImagingPlane.vdTargetPlaneColUnitVector;
        end
        
        function [] = setDefaultValues(obj, oDicomImageVolume, vdFieldOfViewCentreCoords_mm)            
            % get unit vectors of volume indes directions
            [vdRowUnitVector, vdColUnitVector, vdSliceUnitVector] = oDicomImageVolume.getVolumeUnitVectors();
            vdPixelSpacingVector_mm = oDicomImageVolume.getPixelSpacingVector;
            
            m2dUnitVectors = [vdRowUnitVector; vdColUnitVector; vdSliceUnitVector];
            
            % find slice unit vector
            vdTargetPlaneNormalDotProducts = dot(m2dUnitVectors, repmat(obj.vdTargetPlaneNormalUnitVector, 3, 1), 2);
            
            [~,dClosestMatchIndex] = max(abs(vdTargetPlaneNormalDotProducts));
            
            obj.dPlaneDimensionNumber = dClosestMatchIndex;
            obj.vbPlaneDimensionMask = false(1,3);
            obj.vbPlaneDimensionMask(dClosestMatchIndex) = true;
            obj.dPlanePixelSpacing_mm = vdPixelSpacingVector_mm(dClosestMatchIndex);
            obj.dVolumeNumSlices = oDicomImageVolume.vdVolumeDimensions(dClosestMatchIndex);
            
            obj.bSliceFlipRequired = vdTargetPlaneNormalDotProducts(dClosestMatchIndex) < 0;
             
            if obj.bAdjustPlaneUnitVectorsToMatchVolume
                if obj.bSliceFlipRequired
                    vdPlaneNormalUnitVector = -m2dUnitVectors(dClosestMatchIndex,:);
                else
                    vdPlaneNormalUnitVector = m2dUnitVectors(dClosestMatchIndex,:);
                end
            else
                if obj.bSliceFlipRequired
                    vdPlaneNormalUnitVector = -obj.vdTargetPlaneNormalUnitVector;
                else
                    vdPlaneNormalUnitVector = obj.vdTargetPlaneNormalUnitVector;
                end
            end
            
            % find row unit vector
            vdTargetPlaneRowDotProducts = dot(m2dUnitVectors, repmat(obj.vdTargetPlaneRowUnitVector, 3, 1), 2);
            
            [~,dClosestMatchIndex] = max(abs(vdTargetPlaneRowDotProducts));
            
            obj.dRowDimensionNumber = dClosestMatchIndex;
            obj.vbRowDimensionMask = false(1,3);
            obj.vbRowDimensionMask(dClosestMatchIndex) = true;
            obj.dRowPixelSpacing_mm = vdPixelSpacingVector_mm(dClosestMatchIndex);
            obj.dVolumeNumRows = oDicomImageVolume.vdVolumeDimensions(dClosestMatchIndex);
            
            obj.bRowFlipRequired = vdTargetPlaneRowDotProducts(dClosestMatchIndex) > 0;
                         
            if obj.bAdjustPlaneUnitVectorsToMatchVolume
                if obj.bRowFlipRequired
                    vdPlaneRowUnitVector = m2dUnitVectors(dClosestMatchIndex,:);
                else
                    vdPlaneRowUnitVector = -m2dUnitVectors(dClosestMatchIndex,:);
                end
            else
                if obj.bRowFlipRequired
                    vdPlaneRowUnitVector = obj.vdTargetPlaneNormalUnitVector;
                else
                    vdPlaneRowUnitVector = -obj.vdTargetPlaneNormalUnitVector;
                end
            end
            
            % find col unit vector
            vdTargetPlaneColDotProducts = dot(m2dUnitVectors, repmat(obj.vdTargetPlaneColUnitVector, 3, 1), 2);
            
            [~,dClosestMatchIndex] = max(abs(vdTargetPlaneColDotProducts));
            
            obj.dColDimensionNumber = dClosestMatchIndex;
            obj.vbColDimensionMask = false(1,3);
            obj.vbColDimensionMask(dClosestMatchIndex) = true;  
            obj.dColPixelSpacing_mm = vdPixelSpacingVector_mm(dClosestMatchIndex);
            obj.dVolumeNumCols = oDicomImageVolume.vdVolumeDimensions(dClosestMatchIndex);
            
            obj.bColFlipRequired = vdTargetPlaneColDotProducts(dClosestMatchIndex) < 0;
                         
            if obj.bAdjustPlaneUnitVectorsToMatchVolume
                if obj.bColFlipRequired
                    vdPlaneColUnitVector = -m2dUnitVectors(dClosestMatchIndex,:);
                else
                    vdPlaneColUnitVector = m2dUnitVectors(dClosestMatchIndex,:);
                end
            else
                if obj.bColFlipRequired
                    vdPlaneColUnitVector = -obj.vdTargetPlaneNormalUnitVector;
                else
                    vdPlaneColUnitVector = obj.vdTargetPlaneNormalUnitVector;
                end
            end   
            
            % set unit vectors into the slice labels
            obj.setUnitVectorsInAxisLabels();
            
            % FOV values / slice index
            
            %vdFieldOfViewCentreCoords_mm
            
            if obj.bAdjustPlaneUnitVectorsToMatchVolume % make sure plane starts in the centre of a volume slice
                [dI,dJ,dK] = oDicomImageVolume.getVoxelIndicesFromCoordinates(...
                    vdFieldOfViewCentreCoords_mm(1), vdFieldOfViewCentreCoords_mm(2), vdFieldOfViewCentreCoords_mm(3));
                
                % get centre of voxels
                dI = floor(dI)+0.5;
                dJ = floor(dJ)+0.5;
                dK = floor(dK)+0.5;
                
                % get centre of FOV coords in mm
                [dX_mm,dY_mm,dZ_mm] = oDicomImageVolume.getCoordinatesFromVoxelIndices(dI, dJ, dK);
                
                vdFieldOfViewCentreCoords_mm = [dX_mm, dY_mm, dZ_mm];
            end
            
            vdReferencePlaneOrigin_mm = [0 0 0];
            obj.oFieldOfViewGeometry = FieldOfViewGeometry(vdPlaneRowUnitVector, vdPlaneColUnitVector, vdReferencePlaneOrigin_mm, vdFieldOfViewCentreCoords_mm);
            
            obj.oFieldOfViewGeometry.setFieldOfViewWidthHeightToFitVolume(oDicomImageVolume, obj.dAxisWidth, obj.dAxisHeight);
            
% % %             
% % %             % get slice index bounds
% % %             obj.dMinSliceIndex = 1;
% % %             obj.dMaxSliceIndex = oDicomImageVolume.vdVolumeDimensions(obj.vbPlaneDimensionMask);
% % %             
% % %             obj.oSliceLocationSpinnerHandle.Limits = [obj.dMinSliceIndex, obj.dMaxSliceIndex];
% % %             
% % %             % from the centre view of field coords, find centre of 1st
% % %             % slice for the plane
% % %             [vdI,vdJ,vdK] = oDicomImageVolume.getVoxelIndicesFromCoordinates(...
% % %                 vdFieldOfViewCentreCoords_mm(1), vdFieldOfViewCentreCoords_mm(2), vdFieldOfViewCentreCoords_mm(3));
% % %             
% % %             m2dFieldOfViewCentreIndices = [vdI,vdJ,vdK];
% % %             
% % %             if obj.bSliceFlipRequired
% % %                 obj.dCurrentSliceIndex = obj.dMaxSliceIndex - floor(m2dFieldOfViewCentreIndices(obj.dPlaneDimensionNumber)) + 1;    
% % %             else
% % %                 obj.dCurrentSliceIndex = floor(m2dFieldOfViewCentreIndices(obj.dPlaneDimensionNumber));    
% % %             end
% % %             
% % %             
% % %             % set slice index to 1 to find FOV centre coords in 1st slice
% % %             m2dFieldOfViewCentreIndices(obj.dPlaneDimensionNumber) = 1;
% % %             
% % %             if obj.bRowFlipRequired
% % %                 m2dFieldOfViewCentreIndices(obj.dRowDimensionNumber) = obj.dVolumeNumRows - m2dFieldOfViewCentreIndices(obj.dRowDimensionNumber) + 1;
% % %             end
% % %             
% % %             if obj.bColFlipRequired
% % %                 m2dFieldOfViewCentreIndices(obj.dColDimensionNumber) = obj.dVolumeNumCols - m2dFieldOfViewCentreIndices(obj.dColDimensionNumber) + 1;
% % %             end
% % %             
% % %             m2dFieldOfViewCentreIndices = floor(m2dFieldOfViewCentreIndices);
% % %             
% % %             obj.vdFirstSliceFieldOfViewCentreIndices = m2dFieldOfViewCentreIndices;
% % %             
% % %             [vdX,vdY,vdZ] = oDicomImageVolume.getCoordinatesFromVoxelIndices(...
% % %                 m2dFieldOfViewCentreIndices(1), m2dFieldOfViewCentreIndices(2), m2dFieldOfViewCentreIndices(3));
% % %             
% % %             obj.vdFirstSliceFieldOfViewCentreCoords_mm = [vdX,vdY,vdZ];
% % %             
% % %             % set FOV size and bounds
% % %             obj.dMaxFieldOfView_mm = max(...
% % %                 obj.dVolumeNumRows .* obj.dRowPixelSpacing_mm,...
% % %                 obj.dVolumeNumCols .* obj.dColPixelSpacing_mm);
% % %             
% % %             obj.dCurrentFieldOfView_mm = obj.dMaxFieldOfView_mm;
% % %             
% % %             obj.dMinFieldOfView_mm = min(obj.dRowPixelSpacing_mm, obj.dColPixelSpacing_mm);
% % %                         
% % %             obj.dFieldOfViewIncrement_mm = floor(min(obj.dVolumeNumRows,obj.dVolumeNumCols)/25)*min(obj.dRowPixelSpacing_mm, obj.dColPixelSpacing_mm);
        end
        
        function [] = zoomIn(obj, oDicomImageVolume)
            obj.dCurrentFieldOfView_mm = max(obj.dMinFieldOfView_mm, obj.dCurrentFieldOfView_mm - obj.dFieldOfViewIncrement_mm);
            
            obj.setAxisLimits(oDicomImageVolume);
        end
        
        function [] = zoomOut(obj, oDicomImageVolume)
            obj.dCurrentFieldOfView_mm = min(obj.dMaxFieldOfView_mm, obj.dCurrentFieldOfView_mm + obj.dFieldOfViewIncrement_mm);
            
            obj.setAxisLimits(oDicomImageVolume);
        end
        
        function [] = incrementSlice(obj, oDicomImageVolume, c1oDicomContours)
            obj.dCurrentSliceIndex = min(obj.dMaxSliceIndex, obj.dCurrentSliceIndex + obj.dSliceIndexIncrement);
            
            obj.setImage(oDicomImageVolume);
            obj.drawContours(c1oDicomContours);
            
            obj.setSliceLocationSpinnerValue();
        end        
        
        function [] = decrementSlice(obj, oDicomImageVolume, c1oDicomContours)
            obj.dCurrentSliceIndex = max(obj.dMinSliceIndex, obj.dCurrentSliceIndex - obj.dSliceIndexIncrement);
            
            obj.setImage(oDicomImageVolume);
            obj.drawContours(c1oDicomContours);
            
            obj.setSliceLocationSpinnerValue();
        end
        
        function bBool = isSpinnerHandleEqual(obj, oSpinnerHandle)
            bBool = obj.oSliceLocationSpinnerHandle == oSpinnerHandle;
        end
        
        function setSliceLocationSpinnerValue(obj)
            if ~isempty(obj.oSliceLocationSpinnerHandle)
                obj.oSliceLocationSpinnerHandle.Value = obj.dCurrentSliceIndex;
            end
        end
        
        function oHandle = getAxesHandle(obj)
            oHandle = obj.oAxesHandle;
        end
        
        function setSliceIndexToSpinnerValue(obj)
            dSpinnerValue = obj.oSliceLocationSpinnerHandle.Value;
            
            if dSpinnerValue < obj.dMinSliceIndex
                dSpinnerValue = obj.dMinSliceIndex;
            elseif dSpinnerValue > obj.dMaxSliceIndex
                dSpinnerValue = obj.dMaxSliceIndex;
            end
            
            obj.dCurrentSliceIndex = dSpinnerValue;          
            
            obj.setSliceLocationSpinnerValue();
        end
        
        function setFullAxis(obj, oDicomImageVolume)
            obj.deletePlottedObjects();
            
            [m2dSlice, vdRowData, vdColData, vdRowLim, vdColLim] =...
                oDicomImageVolume.getSlice(obj);
            
            if ~isempty(obj.oImageHandle)
                delete(obj.oImageHandle);
            end
            
            obj.oImageHandle = imagesc(obj.oAxesHandle,...
                'XData', vdColData, 'YData', vdRowData,...
                'CData', m2dSlice);
            obj.oAxesHandle.NextPlot = 'add';
            
            [dMin, dMax] = oDicomImageVolume.getThresholdMinMax();
            obj.setThreshold(dMin, dMax);
                 
            xlim(obj.oAxesHandle, vdColLim);
            ylim(obj.oAxesHandle, vdRowLim);            
            
            obj.setSliceLocationSpinnerValue();
        end
        
        function setAxisLimits(obj, oDicomImageVolume)
            [vdRowLim, vdColLim] = oDicomImageVolume.getRowAndColumnLimits(obj);
                        
            obj.oAxesHandle.XLim = vdColLim;
            obj.oAxesHandle.YLim = vdRowLim;
        end
        
        function [] = setThreshold(obj, dMin, dMax)
            obj.oAxesHandle.CLim = [dMin, dMax];
        end
        
        function setImage(obj, oDicomImageVolume)            
            obj.deletePlottedObjects();
            
            m2dSlice = oDicomImageVolume.getSliceOnly(obj);
            
            obj.oImageHandle.CData = m2dSlice;  
        end
        
        function [dMin,dMax] = getThresholdMinMaxFromMouse(obj, cdMousePosition, oDicomImageVolume)
            vdPosVector = getNormalizedPositionVectorFromObjectCorner(obj.oAxesHandle, cdMousePosition);
                        
            vdPosVector(vdPosVector>1) = 1;
            vdPosVector(vdPosVector<0) = 0;
            
            dLevel = vdPosVector(2)*oDicomImageVolume.dMaxWindow + oDicomImageVolume.dMinLevel;
            dWindow = vdPosVector(1)*oDicomImageVolume.dMaxWindow;
            
            [dMin, dMax] = DicomImageVolume.getMinMaxFromWindowLevel(dWindow, dLevel);
        end
        
        function dSliceIndex = getCurrentSliceIndex(obj)
            if obj.bSliceFlipRequired
                dSliceIndex = obj.dVolumeNumSlices + 1 - obj.dCurrentSliceIndex;
            else
                dSliceIndex = obj.dCurrentSliceIndex;
            end
        end
        
        function [vdTopLeftIndices, vdBotRightIndices] = getCurrentFieldOfViewIndices(obj, oDicomImageVolume)
            vdFirstSliceFieldOfViewCentreIndices = obj.vdFirstSliceFieldOfViewCentreIndices;
            vdFirstSliceFieldOfViewCentreIndices(obj.dPlaneDimensionNumber) = obj.dCurrentSliceIndex;
            
            [vdX,vdY,vdZ] = oDicomImageVolume.getCoordinatesFromVoxelIndices(...
                vdFirstSliceFieldOfViewCentreIndices(1), vdFirstSliceFieldOfViewCentreIndices(2), vdFirstSliceFieldOfViewCentreIndices(3));
            
            m2dCurrentFOVCentreCoords = [vdX,vdY,vdZ];
            
            vdTopLeftCoords = m2dCurrentFOVCentreCoords - (obj.dCurrentFieldOfView_mm/2).*(obj.vdPlaneRowUnitVector+obj.vdPlaneColUnitVector);
            vdBotRightCoords = m2dCurrentFOVCentreCoords + (obj.dCurrentFieldOfView_mm/2).*(obj.vdPlaneRowUnitVector+obj.vdPlaneColUnitVector);
            
            m2dCoords = [vdTopLeftCoords; vdBotRightCoords];
            
            [vdI,vdJ,vdK] = oDicomImageVolume.getVoxelIndicesFromCoordinates(...
                m2dCoords(:,1), m2dCoords(:,2), m2dCoords(:,3));
            
            vdTopLeftIndices = [vdI(1), vdJ(1), vdK(1)];
            vdBotRightIndices = [vdI(2), vdJ(2), vdK(2)];
        end
        
        function [] = setUnitVectorsInAxisLabels(obj)
            chLabel = [obj.chAxesTitle, ' [', num2str(obj.vdPlaneNormalUnitVector(1)), ', ', num2str(obj.vdPlaneNormalUnitVector(2)), ', ', num2str(obj.vdPlaneNormalUnitVector(3)), ']'];
            
            obj.oAxesLabelHandle.Text = chLabel;
        end
        
        function [] = drawContours(obj, c1oDicomContours)
            dNumContours = length(c1oDicomContours);
            c1c1oPlotHandles = cell(dNumContours,1);
            
            for dContourIndex = 1:dNumContours
                c1c1oPlotHandles{dContourIndex} = ...
                    obj.drawContour(c1oDicomContours{dContourIndex});
            end
            
            obj.c1c1oPlotHandles = c1c1oPlotHandles;
        end
        
        function [] = deletePlottedObjects(obj)
            for dContourIndex=1:length(obj.c1c1oPlotHandles)
                c1oContourPlotHandles = obj.c1c1oPlotHandles{dContourIndex};
                
                for dPolygonIndex=1:length(c1oContourPlotHandles)
                    delete(c1oContourPlotHandles{dPolygonIndex});
                end
            end
            
            obj.c1c1oPlotHandles = {};
        end
        
        function [] = deleteSliceLocations(obj)
            for dSliceLocationIndex=1:length(obj.c1oSliceLocationHandles)
                delete(obj.c1oSliceLocationHandles{dSliceLocationIndex});
            end
            
            obj.c1oSliceLocationHandles = {};
        end
        
        function [] = drawSliceLocations(obj, c1oInteractivePlaneObjects)
            obj.deleteSliceLocations();
            
            dNumPlanes = length(c1oInteractivePlaneObjects);
            c1oSliceLocationHandles = cell(dNumPlanes,1);
            
            for dPlaneIndex=1:dNumPlanes
                [vdRowVals, vdColVals] = getSliceLocationCoords(obj, c1oInteractivePlaneObjects{dPlaneIndex});
                
                c1oSliceLocationHandles{dPlaneIndex} = ...
                    plot(obj.oAxesHandle, vdColVals, vdRowVals,'-','Color', [1 1 0]);
            end
            
            obj.c1oSliceLocationHandles = c1oSliceLocationHandles;
        end
        
        function [] = updateSliceLocations(obj, c1oInteractivePlaneObjects)            
            dNumPlanes = length(c1oInteractivePlaneObjects);
            
            for dPlaneIndex=1:dNumPlanes
                [vdRowVals, vdColVals] = getSliceLocationCoords(obj, c1oInteractivePlaneObjects{dPlaneIndex});
                
                obj.c1oSliceLocationHandles{dPlaneIndex}.XData = vdColVals;
                obj.c1oSliceLocationHandles{dPlaneIndex}.YData = vdRowVals;
            end
        end
        
% % % %         function [] = matchExistingPlane(obj, existPlaneObject)
% % % %             obj.vdPlaneNormalUnitVector = existPlaneObject.vdPlaneNormalUnitVector;
% % % %             obj.vdPlaneRowUnitVector = existPlaneObject.vdPlaneRowUnitVector;
% % % %             obj.vdPlaneColUnitVector = existPlaneObject.vdPlaneColUnitVector;
% % % %             
% % % %             obj.bSliceFlipRequired = existPlaneObject.bSliceFlipRequired;
% % % %             obj.bRowFlipRequired = existPlaneObject.bRowFlipRequired;
% % % %             obj.bColFlipRequired = existPlaneObject.bColFlipRequired;
% % % %             
% % % %             obj.vbPlaneDimensionMask = existPlaneObject.vbPlaneDimensionMask;
% % % %             obj.dPlaneDimensionNumber = existPlaneObject.dPlaneDimensionNumber;
% % % %             obj.dPlanePixelSpacing_mm = existPlaneObject.dPlanePixelSpacing_mm;
% % % %             obj.dVolumeNumSlices = existPlaneObject.dVolumeNumSlices;
% % % %             
% % % %             obj.vbRowDimensionMask = existPlaneObject.vbRowDimensionMask;
% % % %             obj.dRowDimensionNumber = existPlaneObject.dRowDimensionNumber;
% % % %             obj.dRowPixelSpacing_mm = existPlaneObject.dRowPixelSpacing_mm;
% % % %             obj.dVolumeNumRows = existPlaneObject.dVolumeNumRows;
% % % %             
% % % %             obj.vbColDimensionMask = existPlaneObject.vbColDimensionMask;
% % % %             obj.dColDimensionNumber = existPlaneObject.dColDimensionNumber;
% % % %             obj.dColPixelSpacing_mm = existPlaneObject.dColPixelSpacing_mm;
% % % %             obj.dVolumeNumCols = existPlaneObject.dVolumeNumCols;
% % % %             
% % % %             obj.dCurrentSliceIndex = existPlaneObject.dCurrentSliceIndex;
% % % %             obj.dMinSliceIndex = existPlaneObject.dMinSliceIndex;
% % % %             obj.dMaxSliceIndex = existPlaneObject.dMaxSliceIndex;
% % % %             
% % % %             obj.dSliceIndexIncrement = existPlaneObject.dSliceIndexIncrement;
% % % %             
% % % %             obj.dCurrentFieldOfView_mm = existPlaneObject.dCurrentFieldOfView_mm ;
% % % %             obj.dMinFieldOfView_mm = existPlaneObject.dMinFieldOfView_mm;
% % % %             obj.dMaxFieldOfView_mm = existPlaneObject.dMaxFieldOfView_mm;
% % % %             
% % % %             obj.dFieldOfViewIncrement_mm = existPlaneObject.dFieldOfViewIncrement_mm;
% % % %             
% % % %             obj.vdFirstSliceFieldOfViewCentreCoords_mm = existPlaneObject.vdFirstSliceFieldOfViewCentreCoords_mm ;
% % % %             obj.vdFirstSliceFieldOfViewCentreIndices = existPlaneObject.vdFirstSliceFieldOfViewCentreIndices;
% % % %         end
        
        function [] = setFieldOfViewToMax(obj, oDicomImageVolume)
            obj.dCurrentFieldOfView_mm = obj.dMaxFieldOfView_mm;
            
            obj.setAxisLimits(oDicomImageVolume);
        end
        
        function [] = setFieldOfViewToValue(obj, dFieldOfView_mm, oDicomImageVolume)
            dNumIncrements = round((obj.dMaxFieldOfView_mm - dFieldOfView_mm) ./ obj.dFieldOfViewIncrement_mm);
            
            obj.dCurrentFieldOfView_mm = obj.dMaxFieldOfView_mm - dNumIncrements .* obj.dFieldOfViewIncrement_mm;
            
            obj.setAxisLimits(oDicomImageVolume);
        end
    end
    
    methods(Access = private)
        function c1oPlotHandles = drawContour(obj, oDicomContour)
            c1m2dPolygonVertexIndices = oDicomContour.getPolygonIndicesWithinImagingPlane(obj);
            
            dNumPolygons = length(c1m2dPolygonVertexIndices);
            
            if dNumPolygons ~= 0 % render the polygons!
                vbRowMask = obj.vbRowDimensionMask;
                vbRowMask(obj.dPlaneDimensionNumber) = [];
                
                vbColMask = obj.vbColDimensionMask;
                vbColMask(obj.dPlaneDimensionNumber) = [];
                
                c1oPlotHandles = cell(dNumPolygons,1);
                
                for dPolygonIndex=1:dNumPolygons
                    m2dIndices = c1m2dPolygonVertexIndices{dPolygonIndex};
                    
                    m2dRowIndices = [m2dIndices(:,vbRowMask);m2dIndices(1,vbRowMask)];
                    m2dColIndices = [m2dIndices(:,vbColMask);m2dIndices(1,vbColMask)];
                    
                    if obj.bRowFlipRequired
                        m2dRowIndices = obj.dVolumeNumRows - m2dRowIndices + 1;
                    end
                    
                    if obj.bColFlipRequired
                        m2dColIndices = obj.dVolumeNumCols - m2dColIndices + 1;
                    end
                    
                    c1oPlotHandles{dPolygonIndex} = plot(obj.oAxesHandle,m2dColIndices,m2dRowIndices,'-','Color',oDicomContour.vdContourColour_rgb);
                end
            else % look for any points within the current slice and render those (unconnected)
                m2dPointIndices = oDicomContour.getAnyIndicesWithinImagingPlane(obj);
                
                vbRowMask = obj.vbRowDimensionMask;
                vbColMask = obj.vbColDimensionMask;
                
                m2dRowIndices = m2dPointIndices(:,vbRowMask);
                m2dColIndices = m2dPointIndices(:,vbColMask);
                
                if obj.bRowFlipRequired
                    m2dRowIndices = obj.dVolumeNumRows - m2dRowIndices + 1;
                end
                
                if obj.bColFlipRequired
                    m2dColIndices = obj.dVolumeNumCols - m2dColIndices + 1;
                end
                
                c1oPlotHandles = {plot(obj.oAxesHandle,m2dColIndices,m2dRowIndices,'.','Color',oDicomContour.vdContourColour_rgb)};
            end
        end
    end
end

% ** HELPER FUNCTIONS **
function [vdRowVals, vdColVals] = getSliceLocationCoords(obj, oSliceBeingDrawnPlane)
    if oSliceBeingDrawnPlane.dPlaneDimensionNumber == obj.dRowDimensionNumber
        if obj.bRowFlipRequired == oSliceBeingDrawnPlane.bSliceFlipRequired
            dSliceIndex = oSliceBeingDrawnPlane.dCurrentSliceIndex;
        else
            dSliceIndex = oSliceBeingDrawnPlane.dMaxSliceIndex - oSliceBeingDrawnPlane.dCurrentSliceIndex + 1;
        end

        vdRowVals = repmat(dSliceIndex, 1, 2);
        vdColVals = [1, obj.dVolumeNumCols];
    elseif oSliceBeingDrawnPlane.dPlaneDimensionNumber == obj.dColDimensionNumber
        if obj.bColFlipRequired == oSliceBeingDrawnPlane.bSliceFlipRequired
            dSliceIndex = oSliceBeingDrawnPlane.dCurrentSliceIndex;
        else
            dSliceIndex = oSliceBeingDrawnPlane.dMaxSliceIndex - oSliceBeingDrawnPlane.dCurrentSliceIndex + 1;
        end

        vdRowVals = [1, obj.dVolumeNumRows];
        vdColVals = repmat(dSliceIndex, 1, 2);
    else
        error('Non-orthogonal planes!');
    end
end

function vdPosVector = getNormalizedPositionVectorFromObjectCorner(obj, vdMousePosition)
% returns position vector [x,y], where [0.5 0.5] is the centre [0 0] is
% the lower left corner and [1 1] is the upper right corner. >1 is
% outside the object

dX = obj.Position(1);
dY = obj.Position(2);
dW = obj.Position(3);
dH = obj.Position(4);

vdPosVector = (vdMousePosition - [dX,dY]) ./ [dW,dH];
end