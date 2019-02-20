classdef DicomContour < handle
    % DicomContour
    
    properties (Constant)
        coordsWithinSliceBound = 1 % 1 voxel index
    end
    
    properties
        polygonCoords = {} % cell array of nx3 double arrays (each array is a co-planar polyline, reshaped DICOM data)
        
        polygonIndices = {} % cell array of nx2 double arrays holding the indices of the voxels that the polygon vertices should be in. The common slice index is not includes. See "polygonPlaneIndices"
        allPolygonIndices = [] % nx3 double array holding all of indices concatenated for easy access
        
        maxIndexToIndexDistance_mm = []
        
        polygonPlaneIndices = [] % nx1 double array holding the common plane indices of each polygon
        polygonPlaneDimensionMask % holds which dimension the plane in from
        polygonPlaneDimensionNumber % holds which dimension the plane in from        
    end
    
    methods
        function obj = ContourValidationContour(contourNumber, roiName, observationLabel, interpretedType, polygonCoords, rtStructFilePath, app)
            %obj = ContourValidationContour(contourNumber, roiName, observationLabel, interpretedType, polygonCoords, rtStructFilePath, app)
            obj.contourNumber = contourNumber;
            
            obj.roiName = roiName;
            obj.observationLabel = observationLabel;
            obj.interpretedType = interpretedType;
            
            obj.polygonCoords = polygonCoords;
            
            obj.rtStructFilePath = rtStructFilePath;
            
            obj.contourValidationResult = ContourValidationResult.createDefault(app);
        end
        
        function centroidCoords = getContourCentroid(obj)
            numCoords = 0;
            numPolygons = length(obj.polygonCoords);
            
            for i=1:numPolygons
                numCoords = numCoords + size(obj.polygonCoords{i},1);
            end
            
            allCoords = zeros(numCoords,3);
            
            insertIndex = 1;
            
            for i=1:numPolygons
                numPolygonCoords = size(obj.polygonCoords{i},1);
                allCoords(insertIndex : insertIndex + numPolygonCoords - 1, :) = obj.polygonCoords{i};
                
                insertIndex = insertIndex + numPolygonCoords;
            end
            
            centroidCoords = mean(allCoords,1);
        end
        
        function dimensionNumber = getPredominatePolygonDimensionNumber(obj)
            dimensionNumber = mode(obj.polygonPlaneDimensionNumber);
        end
        
        function [] = setPolygonIndices(obj, volumeObject)
            numPolygons = length(obj.polygonCoords);
            
            polygonIndices = cell(numPolygons,1);
            polygonPlaneIndices = zeros(numPolygons,1);
            polygonPlaneDimensionMasks = false(numPolygons,3);
            polygonPlaneDimensionNumbers = zeros(numPolygons,1);
            
            totalNumIndices = 0;

            for polyIndex=1:numPolygons
                coords = obj.polygonCoords{polyIndex};
                
                [i,j,k] = volumeObject.getVoxelIndicesFromCoordinates(...
                    coords(:,1), coords(:,2), coords(:,3));
                
                vertexIndices = [i,j,k];
                
                [polygonPlaneDimensionMask, polygonPlaneDimensionNumber] =...
                    findDimensionPlane(vertexIndices);
                
                polygonPlaneDimensionMasks(polyIndex,:) = polygonPlaneDimensionMask;
                polygonPlaneDimensionNumbers(polyIndex) = polygonPlaneDimensionNumber;
                
                polygonIndices{polyIndex} = vertexIndices(:,~polygonPlaneDimensionMask);
                polygonPlaneIndices(polyIndex) = mean(vertexIndices(:,polygonPlaneDimensionMask));                

                totalNumIndices = totalNumIndices + size(coords,1);
            end
            
            allIndices = zeros(totalNumIndices,3);
            insertIndex = 1;

            for i=1:numPolygons
                numIndices = size(polygonIndices{i},1);

                allIndices(insertIndex : insertIndex + numIndices - 1,~polygonPlaneDimensionMasks(i,:)) = polygonIndices{i};
                allIndices(insertIndex : insertIndex + numIndices - 1,polygonPlaneDimensionMasks(i,:)) = polygonPlaneIndices(i);

                insertIndex = insertIndex + numIndices;
            end
            
            obj.polygonIndices = polygonIndices;
            obj.polygonPlaneIndices = polygonPlaneIndices;
            obj.allPolygonIndices = allIndices;
            
            if numPolygons > 0
                if all(polygonPlaneDimensionNumbers == polygonPlaneDimensionNumbers(1))
                    obj.polygonPlaneDimensionMask = polygonPlaneDimensionMasks(1,:);
                    obj.polygonPlaneDimensionNumber = polygonPlaneDimensionNumbers(1);
                else
                    error('Polygons defined in multiple planes!');
                end
            else
                obj.polygonPlaneDimensionMask = polygonPlaneDimensionMasks;
                obj.polygonPlaneDimensionNumber = polygonPlaneDimensionNumbers;
            end
            
            % find maximum distance between ANY two polgon vertex indices
            % (will be used for snapping zoom level)
            
            allIndices_mm = allIndices .* repmat(volumeObject.getPixelSpacingVector, totalNumIndices, 1);
            
            [maxSquaredDistances_mm, ~] = pdist2(allIndices_mm, allIndices_mm, 'squaredeuclidean', 'Largest', 1);
                        
            obj.maxIndexToIndexDistance_mm = sqrt(max(maxSquaredDistances_mm));
        end
        
        function polygonIndices = getPolygonIndicesWithinImagingPlane(obj, imagingPlaneObject)
            planeDimensionNumber = imagingPlaneObject.planeDimensionNumber;
            sliceIndex = imagingPlaneObject.getCurrentSliceIndex();
            
            polygonIndices = {};
            
            if obj.polygonPlaneDimensionNumber == planeDimensionNumber            
                polygonIndices = obj.polygonIndices( ((sliceIndex - 0.5) <= obj.polygonPlaneIndices) & (obj.polygonPlaneIndices <= (sliceIndex + 0.5)) );
            end
        end

        function polygonIndices = getAnyIndicesWithinImagingPlane(obj, imagingPlaneObject)
            planeDimensionNumber = imagingPlaneObject.planeDimensionNumber;
            sliceIndex = imagingPlaneObject.getCurrentSliceIndex();
            
            polygonIndices = obj.allPolygonIndices( ((sliceIndex - 0.5) <= obj.allPolygonIndices(:,planeDimensionNumber)) & (obj.allPolygonIndices(:,planeDimensionNumber) <= (sliceIndex + 0.5)), :);
        end
        
        % ** FUNCTIONS FOR CONTOUR DISPLAY APP **
        function bool = isValidForContourDisplay(obj, contourGroupNumberForDisplay)
            if isempty(obj.contourValidationResult)
                bool = false;
            else
                bool = (obj.contourValidationResult.contourGroupNumber == contourGroupNumberForDisplay);
            end
        end
    end
end


function [polygonPlaneDimensionMask, polygonPlaneDimensionNumber] = findDimensionPlane(vertexIndices)
% closed planar polygons are most often drawn within a single
% plane. % Here we figure out which dimensions doesn't change

% range of the numbers within each dimension
dimRange = (max(vertexIndices,[],1) - min(vertexIndices,[],1));

% if the range of the valus within a dimension varies little
% (or not at all), the contour was most likely drawn in that
% plane
polygonPlaneDimensionMask = dimRange < ContourValidationContour.coordsWithinSliceBound;

if sum(polygonPlaneDimensionMask) == 1 % single plane, good to go!
    cols = 1:3;
    polygonPlaneDimensionNumber = cols(polygonPlaneDimensionMask);
elseif sum(polygonPlaneDimensionMask) > 1
    % choose the col with the least variation as one drawn in
    [~,polygonPlaneDimensionNumber] = min(dimRange);
    
    polygonPlaneDimensionMask = false(1,3);
    
    polygonPlaneDimensionMask(polygonPlaneDimensionNumber) = true;
else % ambiguous as to which plane the coords were drawn in
    error('Invalid polygon coords to find a drawn plane');
end

end