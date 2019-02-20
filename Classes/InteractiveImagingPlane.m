classdef InteractiveImagingPlane < handle
    %InteractiveImagingPlane
    
    properties
        axesHandle
        axesLabelHandle
        sliceLocationSpinnerHandle
        
        windowHandle
        levelHandle
        minHandle
        maxHandle
        
        imageHandle
        
        axesTitle
        
        plotHandles = {}
        sliceLocationHandles = {}
        
        targetPlaneNormalUnitVector % [1 0 0] for Sagittal, [0 1 0] for Coronal, [0 0 1] for axial
        targetPlaneRowUnitVector
        targetPlaneColUnitVector
        
        planeNormalUnitVector % [1 0 0] for Sagittal, [0 1 0] for Coronal, [0 0 1] for axial
        planeRowUnitVector
        planeColUnitVector
        
        sliceFlipRequired = false
        rowFlipRequired = false
        colFlipRequired = false
        
        planeDimensionMask % [1 0 0], [0 1 0], [0 0 1], if plane is running through row, cols or slices (respectively)
        planeDimensionNumber
        planePixelSpacing_mm 
        volumeNumSlices
        
        rowDimensionMask
        rowDimensionNumber
        rowPixelSpacing_mm
        volumeNumRows
        
        colDimensionMask
        colDimensionNumber
        colPixelSpacing_mm
        volumeNumCols
        
        currentSliceIndex
        minSliceIndex
        maxSliceIndex
        
        sliceIndexIncrement = 1
        
        currentFieldOfView_mm
        minFieldOfView_mm
        maxFieldOfView_mm
        
        fieldOfViewIncrement_mm
        
        firstSliceFieldOfViewCentreCoords_mm
        firstSliceFieldOfViewCentreIndices
        
    end
    
    methods
        function obj = InteractiveImagingPlane(axesTitle, axesHandle, axesLabelHandle, sliceLocationSpinnerHandle, targetPlaneNormalUnitVector, targetPlaneRowUnitVector, targetPlaneColUnitVector)
            %obj = InteractiveImagingPlane(axesTitle, axesHandle, axesLabelHandle, sliceLocationSpinnerHandle, targetPlaneNormalUnitVector, targetPlaneRowUnitVector, targetPlaneColUnitVector)
            
            obj.axesTitle = axesTitle;
            
            obj.axesHandle = axesHandle;
            obj.axesLabelHandle = axesLabelHandle;
            obj.sliceLocationSpinnerHandle = sliceLocationSpinnerHandle;
            
            obj.targetPlaneNormalUnitVector = targetPlaneNormalUnitVector; 
            obj.targetPlaneRowUnitVector = targetPlaneRowUnitVector;
            obj.targetPlaneColUnitVector = targetPlaneColUnitVector;
            
            colormap(obj.axesHandle, 'gray');
            obj.axesHandle.Color = [0 0 0]; % black background
        end
        
        function [] = setWindowLevelHandles(obj, windowHandle, levelHandle, minHandle, maxHandle)
            obj.windowHandle = windowHandle;
            obj.levelHandle = levelHandle;
            obj.minHandle = minHandle;
            obj.maxHandle = maxHandle;
        end
        
        function [] = zoomIn(obj, volumeObject)
            obj.currentFieldOfView_mm = max(obj.minFieldOfView_mm, obj.currentFieldOfView_mm - obj.fieldOfViewIncrement_mm);
            
            obj.setAxisLimits(volumeObject);
        end
        
        function [] = zoomOut(obj, volumeObject)
            obj.currentFieldOfView_mm = min(obj.maxFieldOfView_mm, obj.currentFieldOfView_mm + obj.fieldOfViewIncrement_mm);
            
            obj.setAxisLimits(volumeObject);
        end
        
        function [] = incrementSlice(obj, volumeObject, contour)
            obj.currentSliceIndex = min(obj.maxSliceIndex, obj.currentSliceIndex + obj.sliceIndexIncrement);
            
            obj.setImage(volumeObject);
            obj.drawPolygons(contour);
            
            obj.sliceLocationSpinnerHandle.Value = obj.currentSliceIndex;
        end        
        
        function [] = decrementSlice(obj, volumeObject, contour)
            obj.currentSliceIndex = max(obj.minSliceIndex, obj.currentSliceIndex - obj.sliceIndexIncrement);
            
            obj.setImage(volumeObject);
            obj.drawPolygons(contour);
            
            obj.sliceLocationSpinnerHandle.Value = obj.currentSliceIndex;
        end
        
        function bBool = isSpinnerHandleEqual(obj, oSpinnerHandle)
            bBool = obj.sliceLocationSpinnerHandle == oSpinnerHandle;
        end
        
        function oHandle = getAxesHandle(obj)
            oHandle = obj.axesHandle;
        end
        
        function [] = setSliceToSpinnerValue(obj, volumeObject, contour)
            spinnerValue = obj.sliceLocationSpinnerHandle.Value;
            
            if spinnerValue < obj.minSliceIndex
                spinnerValue = obj.minSliceIndex;
            elseif spinnerValue > obj.maxSliceIndex
                spinnerValue = obj.maxSliceIndex;
            end
            
            obj.currentSliceIndex = spinnerValue;
            
            obj.setImage(volumeObject);
            obj.drawPolygons(contour);
            
            obj.sliceLocationSpinnerHandle.Value = obj.currentSliceIndex;
        end
        
        function [] = setFullAxis(obj, volumeObject)
            obj.deletePlottedObjects();
            
            [slice, rowData, colData, rowLim, colLim] =...
                volumeObject.getSlice(obj);
            
            if ~isempty(obj.imageHandle)
                delete(obj.imageHandle);
            end
            
            obj.imageHandle = imagesc(obj.axesHandle,...
                'XData', colData, 'YData', rowData,...
                'CData', slice);
            obj.axesHandle.NextPlot = 'add';
            
            obj.setThreshold();
                 
            xlim(obj.axesHandle, colLim);
            ylim(obj.axesHandle, rowLim);
            
            obj.sliceLocationSpinnerHandle.Value = obj.currentSliceIndex;
        end
        
        function [] = setAxisLimits(obj, volumeObject)
            [rowLim, colLim] = volumeObject.getRowAndColumnLimits(obj);
                        
            obj.axesHandle.XLim = colLim;
            obj.axesHandle.YLim = rowLim;
        end
        
        function [] = setThreshold(obj)
            obj.axesHandle.CLim = obj.getThreshold();
        end
        
        function [] = setImage(obj, volumeObject)            
            obj.deletePlottedObjects();
            
            slice = volumeObject.getSliceOnly(obj);
            
            obj.imageHandle.CData = slice;  
        end
        
        function threshold = getThreshold(obj)
            threshold = [obj.minHandle.Value, obj.maxHandle.Value];
        end
        
        function sliceIndex = getCurrentSliceIndex(obj)
            if obj.sliceFlipRequired
                sliceIndex = obj.volumeNumSlices + 1 - obj.currentSliceIndex;
            else
                sliceIndex = obj.currentSliceIndex;
            end
        end
        
        function [topLeftIndices, botRightIndices] = getCurrentFieldOfViewIndices(obj, volumeObject)
            firstSliceFieldOfViewCentreIndices = obj.firstSliceFieldOfViewCentreIndices;
            firstSliceFieldOfViewCentreIndices(obj.planeDimensionNumber) = obj.currentSliceIndex;
            
            [x,y,z] = volumeObject.getCoordinatesFromVoxelIndices(...
                firstSliceFieldOfViewCentreIndices(1), firstSliceFieldOfViewCentreIndices(2), firstSliceFieldOfViewCentreIndices(3));
            
            currentFOVCentreCoords = [x,y,z];
            
            topLeftCoords = currentFOVCentreCoords - (obj.currentFieldOfView_mm/2).*(obj.planeRowUnitVector+obj.planeColUnitVector);
            botRightCoords = currentFOVCentreCoords + (obj.currentFieldOfView_mm/2).*(obj.planeRowUnitVector+obj.planeColUnitVector);
            
            coords = [topLeftCoords; botRightCoords];
            
            [i,j,k] = volumeObject.getVoxelIndicesFromCoordinates(...
                coords(:,1), coords(:,2), coords(:,3));
            
            topLeftIndices = [i(1), j(1), k(1)];
            botRightIndices = [i(2), j(2), k(2)];
        end
        
        function [] = setDefaultValues(obj, volumeObject, fieldOfViewCentreCoords_mm)            
            % get unit vectors of volume indes directions
            [rowUnitVector, colUnitVector, sliceUnitVector] = volumeObject.getVolumeUnitVectors();
            pixelSpacingVector_mm = volumeObject.getPixelSpacingVector;
            
            unitVectors = [rowUnitVector; colUnitVector; sliceUnitVector];
            
            % find slice unit vector
            targetPlaneNormalDotProducts = dot(unitVectors, repmat(obj.targetPlaneNormalUnitVector, 3, 1), 2);
            
            [~,closestMatchIndex] = max(abs(targetPlaneNormalDotProducts));
            
            obj.planeDimensionNumber = closestMatchIndex;
            obj.planeDimensionMask = false(1,3);
            obj.planeDimensionMask(closestMatchIndex) = true;
            obj.planePixelSpacing_mm = pixelSpacingVector_mm(closestMatchIndex);
            obj.volumeNumSlices = volumeObject.volumeDimensions(closestMatchIndex);
            
            if targetPlaneNormalDotProducts(closestMatchIndex) < 0
                obj.sliceFlipRequired = true;
                obj.planeNormalUnitVector = -unitVectors(closestMatchIndex,:);
            else
                obj.sliceFlipRequired = false;
                obj.planeNormalUnitVector = unitVectors(closestMatchIndex,:);
            end
            
            % find row unit vector
            targetPlaneRowDotProducts = dot(unitVectors, repmat(obj.targetPlaneRowUnitVector, 3, 1), 2);
            
            [~,closestMatchIndex] = max(abs(targetPlaneRowDotProducts));
            
            obj.rowDimensionNumber = closestMatchIndex;
            obj.rowDimensionMask = false(1,3);
            obj.rowDimensionMask(closestMatchIndex) = true;
            obj.rowPixelSpacing_mm = pixelSpacingVector_mm(closestMatchIndex);
            obj.volumeNumRows = volumeObject.volumeDimensions(closestMatchIndex);
            
            if targetPlaneRowDotProducts(closestMatchIndex) < 0
                obj.rowFlipRequired = false;
                obj.planeRowUnitVector = -unitVectors(closestMatchIndex,:);
            else
                obj.rowFlipRequired = true;
                obj.planeRowUnitVector = unitVectors(closestMatchIndex,:);
            end
            
            % find col unit vector
            targetPlaneColDotProducts = dot(unitVectors, repmat(obj.targetPlaneColUnitVector, 3, 1), 2);
            
            [~,closestMatchIndex] = max(abs(targetPlaneColDotProducts));
            
            obj.colDimensionNumber = closestMatchIndex;
            obj.colDimensionMask = false(1,3);
            obj.colDimensionMask(closestMatchIndex) = true;  
            obj.colPixelSpacing_mm = pixelSpacingVector_mm(closestMatchIndex);
            obj.volumeNumCols = volumeObject.volumeDimensions(closestMatchIndex);
            
            if targetPlaneColDotProducts(closestMatchIndex) < 0
                obj.colFlipRequired = true;
                obj.planeColUnitVector = -unitVectors(closestMatchIndex,:);
            else
                obj.colFlipRequired = false;
                obj.planeColUnitVector = unitVectors(closestMatchIndex,:);
            end      
            
            % set unit vectors into the slice labels
            obj.setUnitVectorsInAxisLabels();
            
            % get slice index bounds
            obj.minSliceIndex = 1;
            obj.maxSliceIndex = volumeObject.volumeDimensions(obj.planeDimensionMask);
            
            obj.sliceLocationSpinnerHandle.Limits = [obj.minSliceIndex, obj.maxSliceIndex];
            
            % from the centre view of field coords, find centre of 1st
            % slice for the plane
            [i,j,k] = volumeObject.getVoxelIndicesFromCoordinates(...
                fieldOfViewCentreCoords_mm(1), fieldOfViewCentreCoords_mm(2), fieldOfViewCentreCoords_mm(3));
            
            fieldOfViewCentreIndices = [i,j,k];
            
            if obj.sliceFlipRequired
                obj.currentSliceIndex = obj.maxSliceIndex - floor(fieldOfViewCentreIndices(obj.planeDimensionNumber)) + 1;    
            else
                obj.currentSliceIndex = floor(fieldOfViewCentreIndices(obj.planeDimensionNumber));    
            end
            
            
            % set slice index to 1 to find FOV centre coords in 1st slice
            fieldOfViewCentreIndices(obj.planeDimensionNumber) = 1;
            
            if obj.rowFlipRequired
                fieldOfViewCentreIndices(obj.rowDimensionNumber) = obj.volumeNumRows - fieldOfViewCentreIndices(obj.rowDimensionNumber) + 1;
            end
            
            if obj.colFlipRequired
                fieldOfViewCentreIndices(obj.colDimensionNumber) = obj.volumeNumCols - fieldOfViewCentreIndices(obj.colDimensionNumber) + 1;
            end
            
            fieldOfViewCentreIndices = floor(fieldOfViewCentreIndices);
            
            obj.firstSliceFieldOfViewCentreIndices = fieldOfViewCentreIndices;
            
            [x,y,z] = volumeObject.getCoordinatesFromVoxelIndices(...
                fieldOfViewCentreIndices(1), fieldOfViewCentreIndices(2), fieldOfViewCentreIndices(3));
            
            obj.firstSliceFieldOfViewCentreCoords_mm = [x,y,z];
            
            % set FOV size and bounds
            obj.maxFieldOfView_mm = max(...
                obj.volumeNumRows .* obj.rowPixelSpacing_mm,...
                obj.volumeNumCols .* obj.colPixelSpacing_mm);
            
            obj.currentFieldOfView_mm = obj.maxFieldOfView_mm;
            
            obj.minFieldOfView_mm = min(obj.rowPixelSpacing_mm, obj.colPixelSpacing_mm);
                        
            obj.fieldOfViewIncrement_mm = floor(min(obj.volumeNumRows,obj.volumeNumCols)/25)*min(obj.rowPixelSpacing_mm, obj.colPixelSpacing_mm);
        end
        
        function [] = setUnitVectorsInAxisLabels(obj)
            label = [obj.axesTitle, ' [', num2str(obj.planeNormalUnitVector(1)), ', ', num2str(obj.planeNormalUnitVector(2)), ', ', num2str(obj.planeNormalUnitVector(3)), ']'];
            
            obj.axesLabelHandle.Text = label;
        end
        
        function [] = drawPolygons(obj, contour)
            polygonVertexIndices = contour.getPolygonIndicesWithinImagingPlane(obj);
                       
            
            numPolygons = length(polygonVertexIndices);
            
            if numPolygons ~= 0 % render the polygons!
                rowMask = obj.rowDimensionMask;
                rowMask(obj.planeDimensionNumber) = [];
                
                colMask = obj.colDimensionMask;
                colMask(obj.planeDimensionNumber) = [];
                
                plotHandles = cell(numPolygons,1);
                
                for i=1:numPolygons
                    indices = polygonVertexIndices{i};
                    
                    rowIndices = [indices(:,rowMask);indices(1,rowMask)];
                    colIndices = [indices(:,colMask);indices(1,colMask)];
                    
                    if obj.rowFlipRequired
                        rowIndices = obj.volumeNumRows - rowIndices + 1;
                    end
                    
                    if obj.colFlipRequired
                        colIndices = obj.volumeNumCols - colIndices + 1;
                    end
                    
                    plotHandles{i} = plot(obj.axesHandle,colIndices,rowIndices,'-','Color',[1 0 0]);
                end
            else % look for any points within the current slice and render those (unconnected)
                pointIndices = contour.getAnyIndicesWithinImagingPlane(obj);
                
                rowMask = obj.rowDimensionMask;                
                colMask = obj.colDimensionMask;
                
                rowIndices = pointIndices(:,rowMask);
                colIndices = pointIndices(:,colMask);
                
                if obj.rowFlipRequired
                    rowIndices = obj.volumeNumRows - rowIndices + 1;
                end
                
                if obj.colFlipRequired
                    colIndices = obj.volumeNumCols - colIndices + 1;
                end
                
                plotHandles = {plot(obj.axesHandle,colIndices,rowIndices,'.','Color',[1 0 0])};
            end
            
            obj.plotHandles = plotHandles;
        end
        
        function [] = deletePlottedObjects(obj)
            for i=1:length(obj.plotHandles)
                delete(obj.plotHandles{i});
            end
            
            obj.plotHandles = {};
        end
        
        function [] = deleteSliceLocations(obj)
            for i=1:length(obj.sliceLocationHandles)
                delete(obj.sliceLocationHandles{i});
            end
            
            obj.sliceLocationHandles = {};
        end
        
        function [] = drawSliceLocations(obj, planeObjects)
            obj.deleteSliceLocations();
            
            numPlanes = length(planeObjects);
            sliceLocationHandles = cell(numPlanes,1);
            
            for i=1:numPlanes
                [rowVals, colVals] = getSliceLocationCoords(obj, planeObjects{i});
                
                sliceLocationHandles{i} = ...
                    plot(obj.axesHandle, colVals, rowVals,'-','Color', [1 1 0]);
            end
            
            obj.sliceLocationHandles = sliceLocationHandles;
        end
        
        function [] = updateSliceLocations(obj, planeObjects)            
            numPlanes = length(planeObjects);
            
            for i=1:numPlanes
                [rowVals, colVals] = getSliceLocationCoords(obj, planeObjects{i});
                
                obj.sliceLocationHandles{i}.XData = colVals;
                obj.sliceLocationHandles{i}.YData = rowVals;
            end
        end
        
        function [] = updateThresholdFromMouse(obj, mousePosition, volumeObject)
            posVector = getNormalizedPositionVectorFromObjectCorner(obj.axesHandle, mousePosition);
                        
            posVector(posVector>1) = 1;
            posVector(posVector<0) = 0;
            
            newLevel = posVector(2)*volumeObject.maxWindow + volumeObject.minLevel;
            newWindow = posVector(1)*volumeObject.maxWindow;
            
            obj.windowHandle.Value = newWindow;
            obj.levelHandle.Value = newLevel;
            
            obj.minHandle.Value = newLevel - newWindow/2;
            obj.maxHandle.Value = newLevel + newWindow/2;
        end
        
        function [] = matchExistingPlane(obj, existPlaneObject)
            obj.planeNormalUnitVector = existPlaneObject.planeNormalUnitVector;
            obj.planeRowUnitVector = existPlaneObject.planeRowUnitVector;
            obj.planeColUnitVector = existPlaneObject.planeColUnitVector;
            
            obj.sliceFlipRequired = existPlaneObject.sliceFlipRequired;
            obj.rowFlipRequired = existPlaneObject.rowFlipRequired;
            obj.colFlipRequired = existPlaneObject.colFlipRequired;
            
            obj.planeDimensionMask = existPlaneObject.planeDimensionMask;
            obj.planeDimensionNumber = existPlaneObject.planeDimensionNumber;
            obj.planePixelSpacing_mm = existPlaneObject.planePixelSpacing_mm;
            obj.volumeNumSlices = existPlaneObject.volumeNumSlices;
            
            obj.rowDimensionMask = existPlaneObject.rowDimensionMask;
            obj.rowDimensionNumber = existPlaneObject.rowDimensionNumber;
            obj.rowPixelSpacing_mm = existPlaneObject.rowPixelSpacing_mm;
            obj.volumeNumRows = existPlaneObject.volumeNumRows;
            
            obj.colDimensionMask = existPlaneObject.colDimensionMask;
            obj.colDimensionNumber = existPlaneObject.colDimensionNumber;
            obj.colPixelSpacing_mm = existPlaneObject.colPixelSpacing_mm;
            obj.volumeNumCols = existPlaneObject.volumeNumCols;
            
            obj.currentSliceIndex = existPlaneObject.currentSliceIndex;
            obj.minSliceIndex = existPlaneObject.minSliceIndex;
            obj.maxSliceIndex = existPlaneObject.maxSliceIndex;
            
            obj.sliceIndexIncrement = existPlaneObject.sliceIndexIncrement;
            
            obj.currentFieldOfView_mm = existPlaneObject.currentFieldOfView_mm ;
            obj.minFieldOfView_mm = existPlaneObject.minFieldOfView_mm;
            obj.maxFieldOfView_mm = existPlaneObject.maxFieldOfView_mm;
            
            obj.fieldOfViewIncrement_mm = existPlaneObject.fieldOfViewIncrement_mm;
            
            obj.firstSliceFieldOfViewCentreCoords_mm = existPlaneObject.firstSliceFieldOfViewCentreCoords_mm ;
            obj.firstSliceFieldOfViewCentreIndices = existPlaneObject.firstSliceFieldOfViewCentreIndices;
        end
        
        function [] = setFieldOfViewToMax(obj, volumeObject)
            obj.currentFieldOfView_mm = obj.maxFieldOfView_mm;
            
            obj.setAxisLimits(volumeObject);
        end
        
        function [] = setFieldOfViewToValue(obj, fieldOfView_mm, volumeObject)
            numIncrements = round((obj.maxFieldOfView_mm - fieldOfView_mm) ./ obj.fieldOfViewIncrement_mm);
            
            obj.currentFieldOfView_mm = obj.maxFieldOfView_mm - numIncrements .* obj.fieldOfViewIncrement_mm;
            
            obj.setAxisLimits(volumeObject);
        end
    end
end

% ** HELPER FUNCTIONS **
function [rowVals, colVals] = getSliceLocationCoords(obj, sliceBeingDrawnObj)
    if sliceBeingDrawnObj.planeDimensionNumber == obj.rowDimensionNumber
        if obj.rowFlipRequired == sliceBeingDrawnObj.sliceFlipRequired
            sliceIndex = sliceBeingDrawnObj.currentSliceIndex;
        else
            sliceIndex = sliceBeingDrawnObj.maxSliceIndex - sliceBeingDrawnObj.currentSliceIndex + 1;
        end

        rowVals = repmat(sliceIndex, 1, 2);
        colVals = [1, obj.volumeNumCols];
    elseif sliceBeingDrawnObj.planeDimensionNumber == obj.colDimensionNumber
        if obj.colFlipRequired == sliceBeingDrawnObj.sliceFlipRequired
            sliceIndex = sliceBeingDrawnObj.currentSliceIndex;
        else
            sliceIndex = sliceBeingDrawnObj.maxSliceIndex - sliceBeingDrawnObj.currentSliceIndex + 1;
        end

        rowVals = [1, obj.volumeNumRows];
        colVals = repmat(sliceIndex, 1, 2);
    else
        error('Non-orthogonal planes!');
    end
end

function posVector = getNormalizedPositionVectorFromObjectCorner(obj, mousePosition)
% returns position vector [x,y], where [0.5 0.5] is the centre [0 0] is
% the lower left corner and [1 1] is the upper right corner. >1 is
% outside the object

x = obj.Position(1);
y = obj.Position(2);
w = obj.Position(3);
h = obj.Position(4);

posVector = (mousePosition - [x,y]) ./ [w,h];
end