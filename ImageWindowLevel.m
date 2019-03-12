classdef ImageWindowLevel < handle
    %ImageWindowLevel
    
    properties
        dWindow
        dLevel
        
        dWindowMin
        dWindowMax
        
        dLevelMin
        dLevelMax
    end
    
    methods (Access = public)
        
        function obj = ImageWindowLevel(m3xVolumeData)
            %UNTITLED3 Construct an instance of this class
            %   Detailed explanation goes here
            dAllDimMin = double(min(m3xVolumeData(:)));
            dAllDimMax = double(max(m3xVolumeData(:)));
            
            obj.dLevelMin = dAllDimMin;
            obj.dLevelMax = dAllDimMax;
            
            obj.dWindowMax = dAllDimMax - dAllDimMin;
            obj.dWindowMin = 1;
        end
        
        function [dWindow, dLevel] = getWindowLevelValues(obj)
            dWindow = obj.dWindow;
            dLevel = obj.dLevel;
        end
        
        function [dMin, dMax] = getMinMaxValues(obj)
            [dMin, dMax] = obj.getMinMaxFromWindowLevel(obj.dWindow, obj.dLevel);
        end
        
        function setFromWindowLevelValues(obj, dWindow, dLevel)
            obj.dWindow = dWindow;
            obj.dLevel = dLevel;
        end
        
        function setFromMinMaxValues(obj, dMin, dMax)
            [dWindow, dLevel] = getWindowLevelFromMinMax(dMin, dMax);
            
            obj.dWindow = dWindow;
            obj.dLevel = dLevel;
        end
    end
    
    
    methods (Access = private, Static = true)
        
        function [dMin, dMax] = getMinMaxFromWindowLevel(dWindow, dLevel)
            dMin = dLevel - dWindow/2;
            dMax = dLevel + dWindow/2;
        end
        
        function [dWindow, dLevel] = getWindowLevelFromMinMax(dMin, dMax)
            dWindow = dMax - dMin;
            dLevel = (dMin + dMax)/2;
        end
    end
end

