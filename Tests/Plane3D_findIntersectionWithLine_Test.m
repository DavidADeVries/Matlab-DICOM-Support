classdef Plane3D_findIntersectionWithLine_Test < matlab.unittest.TestCase
    %Plane3D_findIntersectionWithLine_Test
    %
    % Unit tests for: Plane3D.findIntersectionWithLine
    
    
    % *********************************************************************
    % *                            PROPERTIES                             *
    % *********************************************************************
    
    properties
    end
    
    
    
    % *********************************************************************
    % *                 PER CLASS SETUP/TEADOWN METHODS                   *
    % *********************************************************************
        
    methods (TestClassSetup) % Called ONCE before All tests
    end
    
    
    methods (TestClassTeardown) % Called ONCE after All tests
    end
    
    
    
    % *********************************************************************
    % *               PER TEST CASE SETUP/TEADOWN METHODS                 *
    % *********************************************************************
        
    methods (TestMethodSetup) % Called before EACH test
    end
    
    
    methods (TestMethodTeardown) % Called after EACH tests
    end
    
    
    
    % *********************************************************************
    % *                            TEST CASES                             *
    % *********************************************************************
        
    methods (Test)
        
        function testIntersection_InfiniteLineWithInfinitePlane_Perp_Above(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-Inf, Inf], [-Inf, Inf]);
            oLine = Line3D([0 0 1], [0 0 1], [-Inf, Inf]);
            
            [vdIntersectionPoint, dIntersectionPointRowCoord, dIntersectionPointColCoord, dDistanceAlongLineToIntersectionPoint] = oPlane.findIntersectionWithLine(oLine);
            
            verifyEqual(testCase, vdIntersectionPoint, [0 0 0]);
            verifyEqual(testCase, dDistanceAlongLineToIntersectionPoint, -1);
        end
        
        function testIntersection_InfiniteLineWithInfinitePlane_Perp_Below(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-Inf, Inf], [-Inf, Inf]);
            oLine = Line3D([0 0 -1], [0 0 1], [-Inf, Inf]);
            
            [vdIntersectionPoint, dIntersectionPointRowCoord, dIntersectionPointColCoord, dDistanceAlongLineToIntersectionPoint] = oPlane.findIntersectionWithLine(oLine);
            
            verifyEqual(testCase, vdIntersectionPoint, [0 0 0]);
            verifyEqual(testCase, dDistanceAlongLineToIntersectionPoint, 1);
        end
        
        function testIntersection_InfiniteLineWithInfinitePlane_Tilted_Above(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-Inf, Inf], [-Inf, Inf]);
            oLine = Line3D([0 0 2], [0 1 1], [-Inf, Inf]);
            
            [vdIntersectionPoint, dIntersectionPointRowCoord, dIntersectionPointColCoord, dDistanceAlongLineToIntersectionPoint] = oPlane.findIntersectionWithLine(oLine);
            
            verifyEqual(testCase, vdIntersectionPoint, [0 -2 0]);
            verifyEqual(testCase, dDistanceAlongLineToIntersectionPoint, -sqrt(8));
        end
        
        function testIntersection_InfiniteLineWithInfinitePlane_Tilted_Below(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-Inf, Inf], [-Inf, Inf]);
            oLine = Line3D([0 0 -2], [0 1 1], [-Inf, Inf]);
            
            [vdIntersectionPoint, dIntersectionPointRowCoord, dIntersectionPointColCoord, dDistanceAlongLineToIntersectionPoint] = oPlane.findIntersectionWithLine(oLine);
            
            verifyEqual(testCase, vdIntersectionPoint, [0 2 0]);
            verifyEqual(testCase, dDistanceAlongLineToIntersectionPoint, sqrt(8));
        end
        
        function testIntersection_BoundedLineWithInfinitePlane_Perp_Above(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-Inf, Inf], [-Inf, Inf]);
            oLine = Line3D([0 0 1], [0 0 1], [-1, 0]);
            
            [vdIntersectionPoint, dIntersectionPointRowCoord, dIntersectionPointColCoord, dDistanceAlongLineToIntersectionPoint] = oPlane.findIntersectionWithLine(oLine);
            
            verifyEqual(testCase, vdIntersectionPoint, [0 0 0]);
            verifyEqual(testCase, dDistanceAlongLineToIntersectionPoint, -1);
        end
        
        function testIntersection_BoundedLineWithInfinitePlane_Perp_Below(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-Inf, Inf], [-Inf, Inf]);
            oLine = Line3D([0 0 -1], [0 0 1], [0, 1]);
            
            [vdIntersectionPoint, dIntersectionPointRowCoord, dIntersectionPointColCoord, dDistanceAlongLineToIntersectionPoint] = oPlane.findIntersectionWithLine(oLine);
            
            verifyEqual(testCase, vdIntersectionPoint, [0 0 0]);
            verifyEqual(testCase, dDistanceAlongLineToIntersectionPoint, 1);
        end
        
        function testIntersection_BoundedLineWithInfinitePlane_Tilted_Above(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-Inf, Inf], [-Inf, Inf]);
            oLine = Line3D([0 0 2], [0 1 1], [-sqrt(8), 0]);
            
            [vdIntersectionPoint, dIntersectionPointRowCoord, dIntersectionPointColCoord, dDistanceAlongLineToIntersectionPoint] = oPlane.findIntersectionWithLine(oLine);
            
            verifyEqual(testCase, vdIntersectionPoint, [0 -2 0]);
            verifyEqual(testCase, dDistanceAlongLineToIntersectionPoint, -sqrt(8));
        end
        
        function testIntersection_BoundedLineWithInfinitePlane_Tilted_Below(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-Inf, Inf], [-Inf, Inf]);
            oLine = Line3D([0 0 -2], [0 1 1], [0, sqrt(8)]);
            
            [vdIntersectionPoint, dIntersectionPointRowCoord, dIntersectionPointColCoord, dDistanceAlongLineToIntersectionPoint] = oPlane.findIntersectionWithLine(oLine);
            
            verifyEqual(testCase, vdIntersectionPoint, [0 2 0]);
            verifyEqual(testCase, dDistanceAlongLineToIntersectionPoint, sqrt(8));
        end
        
        function testIntersection_InfiniteLineWithBoundedPlane_Perp_Above(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-1, 1], [-1, 1]);
            oLine = Line3D([0 1 1], [0 0 1], [-Inf, Inf]);
            
            [vdIntersectionPoint, dIntersectionPointRowCoord, dIntersectionPointColCoord, dDistanceAlongLineToIntersectionPoint] = oPlane.findIntersectionWithLine(oLine);
            
            verifyEqual(testCase, vdIntersectionPoint, [0 1 0]);
            verifyEqual(testCase, dDistanceAlongLineToIntersectionPoint, -1);
        end
        
        function testIntersection_InfiniteLineWithBoundedPlane_Perp_Below(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-1, 1], [-1, 1]);
            oLine = Line3D([0 1 -1], [0 0 1], [-Inf, Inf]);
            
            [vdIntersectionPoint, dIntersectionPointRowCoord, dIntersectionPointColCoord, dDistanceAlongLineToIntersectionPoint] = oPlane.findIntersectionWithLine(oLine);
            
            verifyEqual(testCase, vdIntersectionPoint, [0 1 0]);
            verifyEqual(testCase, dDistanceAlongLineToIntersectionPoint, 1);
        end
        
        function testIntersection_InfiniteLineWithBoundedPlane_Tilted_Above(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-2, 2], [-2, 2]);
            oLine = Line3D([0 0 2], [0 1 1], [-Inf, Inf]);
            
            [vdIntersectionPoint, dIntersectionPointRowCoord, dIntersectionPointColCoord, dDistanceAlongLineToIntersectionPoint] = oPlane.findIntersectionWithLine(oLine);
            
            verifyEqual(testCase, vdIntersectionPoint, [0 -2 0]);
            verifyEqual(testCase, dDistanceAlongLineToIntersectionPoint, -sqrt(8));
        end
        
        function testIntersection_InfiniteLineWithBoundedPlane_Tilted_Below(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-2, 2], [-2, 2]);
            oLine = Line3D([0 0 -2], [0 1 1], [-Inf, Inf]);
            
            [vdIntersectionPoint, dIntersectionPointRowCoord, dIntersectionPointColCoord, dDistanceAlongLineToIntersectionPoint] = oPlane.findIntersectionWithLine(oLine);
            
            verifyEqual(testCase, vdIntersectionPoint, [0 2 0]);
            verifyEqual(testCase, dDistanceAlongLineToIntersectionPoint, sqrt(8));
        end
        
        function testIntersection_InfiniteLineWithBoundedPlane_Tilted_AboveSqrt(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-2, 2], [-2, 2]);
            oLine = Line3D([0 0 sqrt(2)], [0 1 1], [-Inf, Inf]);
            
            [vdIntersectionPoint, dIntersectionPointRowCoord, dIntersectionPointColCoord, dDistanceAlongLineToIntersectionPoint] = oPlane.findIntersectionWithLine(oLine);
            
            verifyEqual(testCase, vdIntersectionPoint, [0 -sqrt(2) 0]);
        end
        
        function testIntersection_InfiniteLineWithBoundedPlane_Tilted_BelowSqrt(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-2, 2], [-2, 2]);
            oLine = Line3D([0 0 -sqrt(2)], [0 1 1], [-Inf, Inf]);
            
            [vdIntersectionPoint, dIntersectionPointRowCoord, dIntersectionPointColCoord, dDistanceAlongLineToIntersectionPoint] = oPlane.findIntersectionWithLine(oLine);
            
            verifyEqual(testCase, vdIntersectionPoint, [0 sqrt(2) 0]);
        end
        
        % >>>>>>>>>>>>>>>>>>>>> NO INTERSECTION <<<<<<<<<<<<<<<<<<<<<<<<<<<
        
        function testNoIntersection_LineToShortToReachPlane(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-5, 5], [-5, 5]);
            oLine = Line3D([0 0 1], [0 0 1], [-0.9, Inf]);
            
            [vdIntersectionPoint, dIntersectionPointRowCoord, dIntersectionPointColCoord, dDistanceAlongLineToIntersectionPoint] = oPlane.findIntersectionWithLine(oLine);
            
            verifyEmpty(testCase, vdIntersectionPoint);
        end 
        
        function testNoIntersection_LineMissedPlane_Quad1(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-5, 5], [-5, 5]);
            oLine = Line3D([6 6 0], [0 0 1], [-Inf, Inf]);
            
            [vdIntersectionPoint, dIntersectionPointRowCoord, dIntersectionPointColCoord, dDistanceAlongLineToIntersectionPoint] = oPlane.findIntersectionWithLine(oLine);
            
            verifyEmpty(testCase, vdIntersectionPoint);
        end 
        
        function testNoIntersection_LineMissedPlane_Quad2(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-5, 5], [-5, 5]);
            oLine = Line3D([-6 6 0], [0 0 1], [-Inf, Inf]);
            
            [vdIntersectionPoint, dIntersectionPointRowCoord, dIntersectionPointColCoord, dDistanceAlongLineToIntersectionPoint] = oPlane.findIntersectionWithLine(oLine);
            
            verifyEmpty(testCase, vdIntersectionPoint);
        end 
        
        function testNoIntersection_LineMissedPlane_Quad3(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-5, 5], [-5, 5]);
            oLine = Line3D([-6 -6 0], [0 0 1], [-Inf, Inf]);
            
            [vdIntersectionPoint, dIntersectionPointRowCoord, dIntersectionPointColCoord, dDistanceAlongLineToIntersectionPoint] = oPlane.findIntersectionWithLine(oLine);
            
            verifyEmpty(testCase, vdIntersectionPoint);
        end
        
        function testNoIntersection_LineMissedPlane_Quad4(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-5, 5], [-5, 5]);
            oLine = Line3D([6 -6 0], [0 0 1], [-Inf, Inf]);
            
            [vdIntersectionPoint, dIntersectionPointRowCoord, dIntersectionPointColCoord, dDistanceAlongLineToIntersectionPoint] = oPlane.findIntersectionWithLine(oLine);
            
            verifyEmpty(testCase, vdIntersectionPoint);
        end
        
        function testNoIntersection_LineParallelToPlane(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-Inf, Inf], [-Inf, Inf]);
            oLine = Line3D([0 0 1], [1 0 0], [-Inf, Inf]);
            
            [vdIntersectionPoint, dIntersectionPointRowCoord, dIntersectionPointColCoord, dDistanceAlongLineToIntersectionPoint] = oPlane.findIntersectionWithLine(oLine);
            
            verifyEmpty(testCase, vdIntersectionPoint);
        end    
    end    
    
    
    
    % *********************************************************************
    % *                         HELPER FUNCTIONS                          *
    % *********************************************************************
    
    methods (Static = true)        
    end
end

