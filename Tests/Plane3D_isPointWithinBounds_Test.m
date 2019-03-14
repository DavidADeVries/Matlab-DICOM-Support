classdef Plane3D_isPointWithinBounds_Test < matlab.unittest.TestCase
    %Plane3D_isPointWithinBounds_Test
    %
    % Unit tests for: Plane3D.isPointWithinBounds
    
    
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
        
        function testUnboundedPlane(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-Inf, Inf], [-Inf, Inf]);
            vdPoint = [4 -5 0];
            
            verifyTrue(testCase, oPlane.isPointWithinBounds(vdPoint));
        end
        
        function testBoundedPlane_ValidPoint_Quad1(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-5, 5], [-5, 5]);
            vdPoint = [2 2 0];
            
            verifyTrue(testCase, oPlane.isPointWithinBounds(vdPoint));
        end
                
        function testBoundedPlane_ValidPoint_Quad2(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-5, 5], [-5, 5]);
            vdPoint = [-2 2 0];
            
            verifyTrue(testCase, oPlane.isPointWithinBounds(vdPoint));
        end
                
        function testBoundedPlane_ValidPoint_Quad3(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-5, 5], [-5, 5]);
            vdPoint = [-2 -2 0];
            
            verifyTrue(testCase, oPlane.isPointWithinBounds(vdPoint));
        end
                
        function testBoundedPlane_ValidPoint_Quad4(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-5, 5], [-5, 5]);
            vdPoint = [2 -2 0];
            
            verifyTrue(testCase, oPlane.isPointWithinBounds(vdPoint));
        end
                
        function testBoundedPlane_ValidPoint_BorderQuad1(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-5, 5], [-5, 5]);
            vdPoint = [5 5 0];
            
            verifyTrue(testCase, oPlane.isPointWithinBounds(vdPoint));
        end
                
        function testBoundedPlane_ValidPoint_BorderQuad2(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-5, 5], [-5, 5]);
            vdPoint = [-5 5 0];
            
            verifyTrue(testCase, oPlane.isPointWithinBounds(vdPoint));
        end
                
        function testBoundedPlane_ValidPoint_BorderQuad3(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-5, 5], [-5, 5]);
            vdPoint = [-5 -5 0];
            
            verifyTrue(testCase, oPlane.isPointWithinBounds(vdPoint));
        end
                
        function testBoundedPlane_ValidPoint_BorderQuad4(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-5, 5], [-5, 5]);
            vdPoint = [5 -5 0];
            
            verifyTrue(testCase, oPlane.isPointWithinBounds(vdPoint));
        end
                
        function testBoundedPlane_InvalidPoint_BorderQuad1(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-5, 5], [-5, 5]);
            vdPoint = [6 6 0];
            
            verifyFalse(testCase, oPlane.isPointWithinBounds(vdPoint));
        end
                
        function testBoundedPlane_InvalidPoint_BorderQuad2(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-5, 5], [-5, 5]);
            vdPoint = [-6 6 0];
            
            verifyFalse(testCase, oPlane.isPointWithinBounds(vdPoint));
        end
                
        function testBoundedPlane_InvalidPoint_BorderQuad3(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-5, 5], [-5, 5]);
            vdPoint = [-6 -6 0];
            
            verifyFalse(testCase, oPlane.isPointWithinBounds(vdPoint));
        end
                
        function testBoundedPlane_InvalidPoint_BorderQuad4(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-5, 5], [-5, 5]);
            vdPoint = [6 -6 0];
            
            verifyFalse(testCase, oPlane.isPointWithinBounds(vdPoint));
        end
        
        function testError_PointNotOnPlane(testCase)
            
            oPlane = Plane3D([0 0 0], [1 0 0], [0 1 0], [-Inf, Inf], [-Inf, Inf]);
            vdPoint = [4 -5 1];
            
            verifyError(testCase, @()oPlane.isPointWithinBounds(vdPoint), 'Plane3D:isPointWithinBounds:InvalidPoint');
        end     
    end    
    
    
    
    % *********************************************************************
    % *                         HELPER FUNCTIONS                          *
    % *********************************************************************
    
    methods (Static = true)        
    end
end

