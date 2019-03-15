classdef DicomContour < matlab.mixin.Copyable
    % DicomContour
    
    properties (Constant)
        dCoordsWithinSliceBound = 1 % 1 voxel index
        dCoordsWithinSliceTieBound = 0.01
    end
    
    properties
        c1m2dPolygonCoords = {} % cell array of nx3 double arrays (each array is a co-planar polyline, reshaped DICOM data)
        
        c1m2dPolygonIndices = {} % cell array of nx2 double arrays holding the indices of the voxels that the polygon vertices should be in. The common slice index is not includes. See "vdPolygonPlaneIndices"
        m2dAllPolygonIndices = [] % nx3 double array holding all of indices concatenated for easy access
        
        dMaxIndexToIndexDistance_mm = []
        
        vdPolygonPlaneIndices = [] % nx1 double array holding the common plane indices of each polygon
        m2bPolygonPlaneDimensionMask % holds which dimension the plane in from
        vdPolygonPlaneDimensionNumber % holds which dimension the plane in from  
        
        vdContourColour_rgb = [1 0 0];
    end
    
    methods
        function obj = DicomContour(c1m2dPolygonCoords)
            %obj = DicomContour(c1m2dPolygonCoords)
                        
            obj.c1m2dPolygonCoords = c1m2dPolygonCoords;
        end
        
        function vdCentroidCoords = getContourCentroid(obj)
            dNumCoords = 0;
            dNumPolygons = length(obj.c1m2dPolygonCoords);
            
            for dPolygonIndex=1:dNumPolygons
                dNumCoords = dNumCoords + size(obj.c1m2dPolygonCoords{dPolygonIndex},1);
            end
            
            m2dAllCoords = zeros(dNumCoords,3);
            
            dInsertIndex = 1;
            
            for dPolygonIndex=1:dNumPolygons
                dNumPolygonCoords = size(obj.c1m2dPolygonCoords{dPolygonIndex},1);
                m2dAllCoords(dInsertIndex : dInsertIndex + dNumPolygonCoords - 1, :) = obj.c1m2dPolygonCoords{dPolygonIndex};
                
                dInsertIndex = dInsertIndex + dNumPolygonCoords;
            end
            
            vdCentroidCoords = mean(m2dAllCoords,1);
        end
        
        function [] = setPolygonIndices(obj, oDicomImageVolume)
            dNumPolygons = length(obj.c1m2dPolygonCoords);
            
            c1m2dPolygonIndices = cell(dNumPolygons,1);
            vdPolygonPlaneIndices = zeros(dNumPolygons,1);
            m2bPolygonPlaneDimensionMasks = false(dNumPolygons,3);
            vdPolygonPlaneDimensionNumbers = zeros(dNumPolygons,1);
            
            dTotalNumIndices = 0;
            
            vbUndeterminedPolygonPlane = false(dNumPolygons,1);

            for dPolygonIndex=1:dNumPolygons
                m2dCoords = obj.c1m2dPolygonCoords{dPolygonIndex};
                
                [vdI,vdJ,vdK] = oDicomImageVolume.getVoxelIndicesFromCoordinates(...
                    m2dCoords(:,1), m2dCoords(:,2), m2dCoords(:,3));
                
                m2dVertexIndices = [vdI,vdJ,vdK];
                
                [m2bPolygonPlaneDimensionMask, vdPolygonPlaneDimensionNumber] =...
                    findDimensionPlane(m2dVertexIndices);
                
                if isempty(polygonPlaneDimensionMask)
                    vbUndeterminedPolygonPlane(dPolygonIndex) = true;
                else
                    m2bPolygonPlaneDimensionMasks(dPolygonIndex,:) = m2bPolygonPlaneDimensionMask;
                    vdPolygonPlaneDimensionNumbers(dPolygonIndex) = vdPolygonPlaneDimensionNumber;
                    
                    c1m2dPolygonIndices{dPolygonIndex} = m2dVertexIndices(:,~m2bPolygonPlaneDimensionMask);
                    vdPolygonPlaneIndices(dPolygonIndex) = mean(m2dVertexIndices(:,m2bPolygonPlaneDimensionMask));
                end
                
                dTotalNumIndices = dTotalNumIndices + size(m2dCoords,1);
            end
            
            
            % figure out the the undetermined planes
            dMajorityPlaneDimensionNumber = mode(vdpolygonPlaneDimensionNumbers(~vbUndeterminedPolygonPlane));
            
            vbMajorityPlaneDimensionMask = false(1,3);
            vbMajorityPlaneDimensionMask(dMajorityPlaneDimensionNumber) = true;
            
            for dPolygonIndex=1:dNumPolygons
                if bUndeterminedPolygonPlane(dPolygonIndex)
                    m2dCoords = obj.polygonCoords{dPolygonIndex};
                    
                    [vdI,vdJ,vdK] = volumeObject.getVoxelIndicesFromCoordinates(...
                        m2dCoords(:,1), m2dCoords(:,2), m2dCoords(:,3));
                    
                    m2dVertexIndices = [vdI,vdJ,vdK];       
                    
                    m2bPolygonPlaneDimensionMasks(dPolygonIndex,:) = vbMajorityPlaneDimensionMask;
                    vdPolygonPlaneDimensionNumbers(dPolygonIndex) = dMajorityPlaneDimensionNumber;
                    
                    c1m2dPolygonIndices{dPolygonIndex} = m2dVertexIndices(:,~vbMajorityPlaneDimensionMask);
                    vdPolygonPlaneIndices(dPolygonIndex) = mean(m2dVertexIndices(:,vbMajorityPlaneDimensionMask));
                end
            end
            
            
            m2dAllIndices = zeros(dTotalNumIndices,3);
            dInsertIndex = 1;

            for dPolygonIndex=1:dNumPolygons
                dNumIndices = size(c1m2dPolygonIndices{dPolygonIndex},1);

                m2dAllIndices(dInsertIndex : dInsertIndex + dNumIndices - 1, ~m2bPolygonPlaneDimensionMasks(dPolygonIndex,:)) = c1m2dPolygonIndices{dPolygonIndex};
                m2dAllIndices(dInsertIndex : dInsertIndex + dNumIndices - 1, m2bPolygonPlaneDimensionMasks(dPolygonIndex,:)) = vdPolygonPlaneIndices(dPolygonIndex);

                dInsertIndex = dInsertIndex + dNumIndices;
            end
            
            obj.c1m2dPolygonIndices = c1m2dPolygonIndices;
            obj.vdPolygonPlaneIndices = vdPolygonPlaneIndices;
            obj.m2dAllPolygonIndices = m2dAllIndices;
            
            if dNumPolygons > 0
                if all(vdPolygonPlaneDimensionNumbers == vdPolygonPlaneDimensionNumbers(1))
                    obj.m2bPolygonPlaneDimensionMask = m2bPolygonPlaneDimensionMasks(1,:);
                    obj.vdPolygonPlaneDimensionNumber = vdPolygonPlaneDimensionNumbers(1);
                else
                    error('Polygons defined in multiple planes!');
                end
            else
                obj.m2bPolygonPlaneDimensionMask = m2bPolygonPlaneDimensionMasks;
                obj.vdPolygonPlaneDimensionNumber = vdPolygonPlaneDimensionNumbers;
            end
            
            % find maximum distance between ANY two polgon vertex indices
            % (will be used for snapping zoom level)
            
            m2dAllIndices_mm = m2dAllIndices .* repmat(oDicomImageVolume.getPixelSpacingVector(), dTotalNumIndices, 1);
            
            [vdMaxSquaredDistances_mm, ~] = pdist2(m2dAllIndices_mm, m2dAllIndices_mm, 'squaredeuclidean', 'Largest', 1);
                        
            obj.dMaxIndexToIndexDistance_mm = sqrt(max(vdMaxSquaredDistances_mm));
        end
        
        function c1m2dPolygonIndices = getPolygonIndicesWithinImagingPlane(obj, oInteractiveImagingPlane)
            dPlaneDimensionNumber = oInteractiveImagingPlane.dPlaneDimensionNumber;
            dSliceIndex = oInteractiveImagingPlane.getCurrentSliceIndex();
            
            c1m2dPolygonIndices = {};
            
            if obj.vdPolygonPlaneDimensionNumber == dPlaneDimensionNumber            
                c1m2dPolygonIndices = obj.c1m2dPolygonIndices( ((dSliceIndex - 0.5) <= obj.vdPolygonPlaneIndices) & (obj.vdPolygonPlaneIndices <= (dSliceIndex + 0.5)) );
            end
        end

        function c1m2dPolygonIndices = getAnyIndicesWithinImagingPlane(obj, oInteractiveImagingPlane)
            dPlaneDimensionNumber = oInteractiveImagingPlane.dPlaneDimensionNumber;
            dSliceIndex = oInteractiveImagingPlane.getCurrentSliceIndex();
            
            c1m2dPolygonIndices = obj.m2dAllPolygonIndices( ((dSliceIndex - 0.5) <= obj.m2dAllPolygonIndices(:,dPlaneDimensionNumber)) & (obj.m2dAllPolygonIndices(:,dPlaneDimensionNumber) <= (dSliceIndex + 0.5)), :);
        end
        
        function dIndices = getSliceIndicesOfPolygons(obj, dDimensionNumber)
            if obj.vdPolygonPlaneDimensionNumber == dDimensionNumber
                dIndices = obj.vdPolygonPlaneIndices;
            else
                dIndices = [];
            end
        end
        
        % ** FUNCTIONS FOR CONTOUR DISPLAY APP **
        function bBool = isValidForContourDisplay(obj, dContourGroupNumberForDisplay)
            if isempty(obj.contourValidationResult)
                bBool = false;
            else
                bBool = (obj.contourValidationResult.dContourGroupNumber == dContourGroupNumberForDisplay);
            end
        end
    end
    
    methods (Static)
        function dDimensionNumber = getPredominatePolygonDimensionNumber(c1oDicomContours)
            dNumContours = length(c1oDicomContours);
            
            vdPredominateDimensionNumbers = zeros(dNumContours,1);
            
            for dContourIndex=1:dNumContours
            	vdPredominateDimensionNumbers(dContourIndex) =...
                    mode(c1oDicomContours{dContourIndex}.vdPolygonPlaneDimensionNumber);
            end
            
            if all(vdPredominateDimensionNumbers(1) == vdPredominateDimensionNumbers)
                dDimensionNumber = vdPredominateDimensionNumbers(1);
            else
                error(...
                    'DicomContour:getPredominatePolygonDimensionNumber:ContoursInMultipleDimensions',...
                    'Dicom contours are defined in multiple dimensions');
            end
        end
        
        function [dMinIndex,dMaxIndex] = getMinMaxSliceIndices(c1oDicomContours, dDimensionNumber)
            dMinIndex = Inf;
            dMaxIndex = -Inf;
            
            for dContourIndex=1:length(c1oDicomContours)
                dIndices = c1oDicomContours{dContourIndex}.getSliceIndicesOfPolygons(dDimensionNumber);
                
                dMinIndex = min(dMinIndex, min(dIndices));
                dMaxIndex = max(dMaxIndex, max(dIndices));
            end
        end
        
        function dMaxDistance = getMaxIndexToIndexDistanceFromContours(c1oDicomContours)
            dMaxDistance = -Inf;
            
            for dContourIndex=1:length(c1oDicomContours)
                dMaxDistance = max(dMaxDistance, c1oDicomContours{dContourIndex}.dMaxIndexToIndexDistance_mm);
            end
        end
    end
end


function [m2bPolygonPlaneDimensionMask, dPolygonPlaneDimensionNumber] = findDimensionPlane(m2dVertexIndices)
% closed planar polygons are most often drawn within a single
% plane. % Here we figure out which dimensions doesn't change

% range of the numbers within each dimension
vdDimRange = (max(m2dVertexIndices,[],1) - min(m2dVertexIndices,[],1));

% if the range of the valus within a dimension varies little
% (or not at all), the contour was most likely drawn in that
% plane
m2bPolygonPlaneDimensionMask = vdDimRange < DicomContour.dCoordsWithinSliceBound;

if sum(m2bPolygonPlaneDimensionMask) == 1 % single plane, good to go!
    vdCols = 1:3;
    dPolygonPlaneDimensionNumber = vdCols(m2bPolygonPlaneDimensionMask);
elseif sum(m2bPolygonPlaneDimensionMask) > 1
    % choose the col with the least variation as one drawn in
    
    if sum(vdDimRange < DicomContour.dCoordsWithinSliceTieBound) > 1 % too close to tell
        m2bPolygonPlaneDimensionMask = [];
        dPolygonPlaneDimensionNumber = [];
    else
        [~,dPolygonPlaneDimensionNumber] = min(vdDimRange);
        
        m2bPolygonPlaneDimensionMask = false(1,3);
        
        m2bPolygonPlaneDimensionMask(dPolygonPlaneDimensionNumber) = true;
    end
else % ambiguous as to which plane the coords were drawn in
    error('Invalid polygon coords to find a drawn plane');
end

end