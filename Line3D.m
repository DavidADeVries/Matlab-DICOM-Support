classdef Line3D
    %UNTITLED5 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private, Constant = true)
        dMatrixInversionConditionNumberBound = 25
        
        dPointOnLineTolerance = 1E-10
    end
    
    properties (Access = private)
        vdOrigin
        vdUnitVector
        vdLineBounds
    end
    
    methods (Access = public)
        function obj = Line3D(vdOrigin, vdUnitVector, vdLineBounds)
            %obj = Line3D(vdOrigin, vdUnitVector, vdLineBounds)
            
            obj.vdOrigin = vdOrigin;
            obj.vdUnitVector = vdUnitVector ./ norm(vdUnitVector);
            
            if vdLineBounds(1) > vdLineBounds(2)
                error(...
                    'Line3D:Constructor:InvalidParameters',...
                    'Line Bounds must be given in increasing order');
            else                
                obj.vdLineBounds = vdLineBounds;
            end
        end
        
        function vdUnitVector = getUnitVector(obj)
            vdUnitVector = obj.vdUnitVector;
        end
        
        function vdOrigin = getOrigin(obj)
            vdOrigin = obj.vdOrigin;
        end
        
        function bBool = isPointWithinBounds(obj, vdPoint)
            dDistanceAlongLine = obj.getPointCoordsOnPlane(vdPoint);
            
            if isempty(dDistanceAlongLine)
                error(...
                    'Line3D:isPointWithinBounds:InvalidPoint',...
                    'The given point was not on the line');
            else
                bBool = isPointWithinBoundsByDistanceAlongLine(dDistanceAlongLine);
            end
        end
        
        function bBool = isPointWithinBoundsByDistanceAlongLine(obj, dDistanceAlongLine)
            bBool = ...
                ( obj.vdLineBounds(1) - dDistanceAlongLine <= obj.dPointOnLineTolerance &&...
                -obj.dPointOnLineTolerance <= obj.vdLineBounds(2) - dDistanceAlongLine );
        end
    end
    
    methods (Access = private)
       
        function dDistanceAlongLine = getPointCoordsOnPlane(obj, vdPoint)
            m2dSystemMatrix = obj.vdUnitVector';
            
            if cond(m2dSystemMatrix) > obj.dMatrixInversionConditionNumberBound % ill-conditioned, so most likely the point was not on the plane
                dDistanceAlongLine = [];
            else
                vdSystemVector = vdPoint' - obj.vdOrigin';
                
                vdSolutionVector = m2dSystemMatrix \ vdSystemVector;
                
                vdSystemVectorValidate = m2dSystemMatrix * vdSolutionVector;
                
                if any(abs(vdSystemVector - vdSystemVectorValidate) > obj.dPointOnLineTolerance) % point was not on the plane
                    dDistanceAlongLine = [];
                else
                    dDistanceAlongLine = vdSolutionVector(1);
                end
            end
        end
    end
end

