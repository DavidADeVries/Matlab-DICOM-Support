classdef Plane3D
    %UNTITLED6 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private, Constant = true)
        dMatrixInversionConditionNumberBound = 25
        
        dPointOnPlaneTolerance = 1E-10
    end
    
    properties (SetAccess = private)
        vdPlaneOrigin
        
        vdPlaneRowUnitVector
        vdPlaneColUnitVector
        
        vdPlaneRowBounds
        vdPlaneColBounds
    end
    
    methods (Access = public)
        function obj = Plane3D(vdPlaneOrigin, vdPlaneRowUnitVector, vdPlaneColUnitVector, vdPlaneRowBounds, vdPlaneColBounds)
            %obj = Plane3D(vdPlaneOrigin, vdPlaneRowUnitVector, vdPlaneColUnitVector, vdPlaneRowBounds, vdPlaneColBounds)
            
            obj.vdPlaneOrigin = vdPlaneOrigin;
            
            obj.vdPlaneRowUnitVector = vdPlaneRowUnitVector;
            obj.vdPlaneColUnitVector = vdPlaneColUnitVector;
            
            obj.vdPlaneRowBounds = vdPlaneRowBounds;
            obj.vdPlaneColBounds = vdPlaneColBounds;
        end
        
        function [vdIntersectionPoint, dIntersectionPointRowCoord, dIntersectionPointColCoord, dDistanceAlongLineToIntersectionPoint] = findIntersectionWithLine(obj, oLine3D)
        
            % O: Plane origin
            % R: Plane row unit vector
            % C: Plane col unit vector
            % N: Line unit vector
            % M: Line origin
            %
            % Plane described by:   P = O + aR + bC
            % Line described by: L = M + dN
            %
            % Finding intersection gives:
            % 1: O(1) + aR(1) + bC(1) = M(1)+ dN(1)
            % 2: O(2) + aR(2) + bC(2) = M(2)+ dN(2)
            % 3: O(3) + aR(3) + bC(3) = M(3)+ dN(3)
            %
            % Solving for a,b, and d with a SOLE:
            %
            % R(1) C(1) -N(1)      a       M(1) - O(1)
            % R(2) C(2) -N(2)  X   b   =   M(2) - O(2)
            % R(3) C(3) -N(3)      d       M(3) - O(3)
            %
            % a,b can then be used to find intersection point
            % d can be used to find distance along line to plane
            % intersection point
            
            
            m2dSystemMatrix = [obj.vdPlaneRowUnitVector', obj.vdPlaneColUnitVector', -oLine3D.getUnitVector()'];
            
            if cond(m2dSystemMatrix) > obj.dMatrixInversionConditionNumberBound % ill-conditioned, so most likely the plane and line are parallel and so don't intersect
                vdIntersectionPoint = [];
                dIntersectionPointRowCoord = [];
                dIntersectionPointColCoord = [];
                dDistanceAlongLineToIntersectionPoint = [];
            else
                vdSystemVector = oLine3D.getOrigin()' - obj.vdPlaneOrigin';
                
                vdSolution = m2dSystemMatrix \ vdSystemVector;
                
                dIntersectionPointRowCoord = vdSolution(1);
                dIntersectionPointColCoord = vdSolution(2);
                dDistanceAlongLineToIntersectionPoint = vdSolution(3);
                
                vdIntersectionPoint = obj.vdPlaneOrigin +...
                    dIntersectionPointRowCoord.*obj.vdPlaneRowUnitVector +...
                    dIntersectionPointColCoord.*obj.vdPlaneColUnitVector;
                
                if ~( obj.isPointWithinBoundsByRowAndColCoords(dIntersectionPointRowCoord, dIntersectionPointColCoord) &&...
                        oLine3D.isPointWithinBoundsByDistanceAlongLine(dDistanceAlongLineToIntersectionPoint) )
                    vdIntersectionPoint = [];
                    dDistanceAlongLineToIntersectionPoint = [];
                end
            end
        end
        
        function bBool = isPointWithinBounds(obj, vdPoint)
            [dRowCoord, dColCoord] = obj.getPointCoordsOnPlane(vdPoint);
            
            if isempty(dRowCoord)
                error(...
                    'Plane3D:isPointWithinBounds:InvalidPoint',...
                    'The given point was not on the plane');
            else
                bBool = isPointWithinBoundsByRowAndColCoords(obj, dRowCoord, dColCoord);
            end
        end
        
        function vdNormalUnitVector = getPlaneNormalUnitVector(obj)
            vdNormalVector = cross(obj.vdPlaneRowUnitVector, obj.vdPlaneColUnitVector);
            vdNormalUnitVector = vdNormalVector ./ norm(vdNormalVector);
        end
        
        function vdOrigin = getOrigin(obj)
            vdOrigin = obj.vdPlaneOrigin;
        end
        
        function vdRowUnitVector = getRowUnitVector(obj)
            vdRowUnitVector = obj.vdPlaneRowUnitVector;
        end
        
        function vdColUnitVector = getColUnitVector(obj)
            vdColUnitVector = obj.vdPlaneColUnitVector;
        end
    end
    
    methods (Access = private)
                
        function [dRowCoord, dColCoord] = getPointCoordsOnPlane(obj, vdPoint)
            m2dSystemMatrix = [obj.vdPlaneRowUnitVector', obj.vdPlaneColUnitVector'];
            
            if cond(m2dSystemMatrix) > obj.dMatrixInversionConditionNumberBound % ill-conditioned, so most likely the point was not on the plane
                dRowCoord = [];
                dColCoord = [];
            else
                vdSystemVector = vdPoint' - obj.vdPlaneOrigin';
                
                vdSolutionVector = m2dSystemMatrix \ vdSystemVector;
                
                vdSystemVectorValidate = m2dSystemMatrix * vdSolutionVector;
                
                if any(abs(vdSystemVector - vdSystemVectorValidate) > obj.dPointOnPlaneTolerance) % point was not on the plane
                    dRowCoord = [];
                    dColCoord = [];
                else
                    dRowCoord = vdSolutionVector(1);
                    dColCoord = vdSolutionVector(2);
                end
            end
        end
                
        function bBool = isPointWithinBoundsByRowAndColCoords(obj, dRowCoord, dColCoord)
            bBool = ...
                ( obj.vdPlaneRowBounds(1) - dRowCoord <= obj.dPointOnPlaneTolerance &&...
                -obj.dPointOnPlaneTolerance <= obj.vdPlaneRowBounds(2) - dRowCoord ) &&...
                ( obj.vdPlaneColBounds(1) - dColCoord <= obj.dPointOnPlaneTolerance &&...
                -obj.dPointOnPlaneTolerance <= obj.vdPlaneColBounds(2) - dColCoord);
        end
    end
end

