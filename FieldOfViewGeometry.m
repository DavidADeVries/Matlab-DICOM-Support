classdef FieldOfViewGeometry < handle
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        vdCurrentPlaneDistanceAlongFovCentreVector_mm
        
        dFovWidth_mm % cols
        dFovHeight_mm % rows
        
        oImagePlane_mm = Plane3D.empty
        
        oReferencePlane_mm = Plane3D.empty
        oFovCentreLine_mm = Line3D.empty
    end
    
    methods (Access = public)
        function obj = FieldOfViewGeometry(vdPlaneRowVector, vdPlaneColVector, vdReferencePlaneOrigin_mm, vdFovCentrePoint_mm)
            %obj = FieldOfViewGeometry(vdPlaneRowUnitVector, vdPlaneColUnitVector, vdReferencePlaneOrigin_mm, vdFovCentrePoint_mm)
            
            vdPlaneRowUnitVector = vdPlaneRowVector ./ norm(vdPlaneRowVector);
            vdPlaneColUnitVector = vdPlaneColVector ./ norm(vdPlaneColVector);
            
            % create current image plane (what is being viewed) and the
            % reference plane to which the FOV and image plane are measured
            % relative to
            obj.oImagePlane_mm = Plane3D(vdFovCentrePoint_mm, vdPlaneRowUnitVector, vdPlaneColUnitVector, [-Inf,Inf], [-Inf,Inf]);
            obj.oReferencePlane_mm = Plane3D(vdReferencePlaneOrigin_mm, vdPlaneRowUnitVector, vdPlaneColUnitVector, [-Inf,Inf], [-Inf,Inf]);
            
            % create line object running through the FOV Centre and along
            % the reference/image plane normal
            oLineFromFovCentrePoint = Line3D(vdFovCentrePoint_mm, obj.oReferencePlane_mm.getPlaneNormalUnitVector(), [-Inf,Inf]);
            
            % find intersection point with the reference plane
            [vdFovCentreVectorReferencePlaneIntersectionPoint_mm, vdCurrentPlaneDistanceAlongFovCentreVector_mm] = obj.oReferencePlane_mm.findIntersectionWithLine(oLineFromFovCentrePoint); 
                        
            % record intersection data:
            obj.vdCurrentPlaneDistanceAlongFovCentreVector_mm = vdCurrentPlaneDistanceAlongFovCentreVector_mm;
            
            obj.oFovCentreLine_mm = Line3D(vdFovCentreVectorReferencePlaneIntersectionPoint_mm, obj.oReferencePlane_mm.getPlaneNormalUnitVector(), [-Inf,Inf]);
        end
        
        function setFieldOfViewWidthHeightToFitVolume(obj, oDicomImageVolume, dAxisWidth, dAxisHeight)
            c1oVolumeBoundingLines_mm = oDicomImageVolume.getVolumeBoundingLines();
            
            dMaxRowCoord_mm = -Inf;
            dMaxColCoord_mm = -Inf;
            
            % find intersection between reference plane and each volume
            % bounding line to find the min/max row/col coords
            for dBoundingLineIndex=1:length(c1oVolumeBoundingLines_mm)
                [vdIntersectionPoint, dIntersectionPointRowCoord, dIntersectionPointColCoord, dDistanceAlongLineToIntersectionPoint] =...
                    obj.oReferencePlane_mm.findIntersectionWithLine(c1oVolumeBoundingLines_mm{dBoundingLineIndex});
                
                if ~isempty(vdIntersectionPoint) % intersection occurred
                    dMaxRowCoord_mm = max(dMaxRowCoord_mm, abs(dIntersectionPointRowCoord));
                    dMaxColCoord_mm = max(dMaxColCoord_mm, abs(dIntersectionPointColCoord));
                end
            end
            
            % find & set FOV
            dAxisAspectRatio = dAxisWidth / dAxisHeight;
            dMaxFovAspectRatio = dMaxColCoord_mm / dMaxRowCoord_mm;
            
            if dAxisAspectRatio < dMaxFovAspectRatio % more "widescreen"/"landscape" than the axis (e.g. width of image will fill the axis, height will not)
                obj.dFovWidth_mm = 2*dMaxColCoord_mm; % need to multiple by 2 since dMaxColCoord_mm was from the CENTRE of the FOV
                obj.dFovHeight_mm = obj.dFovWidth_mm * (dAxisHeight / dAxisWidth);
            elseif dAxisAspectRatio > dMaxFovAspectRatio % more "4:3"/"portrait" than the axis (e.g. height of the image will fill the axis, width will not)
                obj.dFovHeight_mm = 2*dMaxRowCoord_mm;
                obj.dFovWidth_mm = obj.dFovHeight_mm * (dAxisWidth / dAxisHeight);
            else % axis aspect ratio is equal to 
                obj.dFovWidth_mm = 2*dMaxColCoord_mm;
                obj.dFovHeight_mm = 2*dMaxRowCoord_mm;
            end
        end
    end
    
    methods (Access = private)
        
    end
end

