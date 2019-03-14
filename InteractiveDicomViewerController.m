classdef InteractiveDicomViewerController < matlab.mixin.Copyable
    %InteractiveDicomViewerController
    
    
    % *********************************************************************   ORDERING: 1 Abstract        X.1 Public       X.X.1 Not Constant
    % *                            PROPERTIES                             *             2 Not Abstract -> X.2 Protected -> X.X.2 Constant
    % *********************************************************************                               X.3 Private
    
    properties(Constant)
        dAutoScrollInterframePause_s = 0.05
        
        chAutoZoomWideLabel = 'Wide'
        chAutoZoomTightLabel = 'Tight'
        dTightZoomLevelMultiplier = 4 % 4 times the largest contour diameter
        
        dFalseMouseClickBuffer_s = 0.25
        chLeftMouseClickLabel = 'normal'
        chRightMouseClickLabel = 'normal'
        
        bDefaultCentreOnContourCentroid = true % false will centre on image volume
    end
    
    properties (SetAccess = private)
        % class objects
        oDicomImageVolume = DicomImageVolume.empty        
        
        c1oDicomContours = {}
        c1oInteractiveImagingPlanes = {} % cell array of InteractiveImagingPlane objects
        
        % hotkeys
        chAutoZoomToggleHotkey = 'equal'
        chAutoScrollHotkey = 'subtract'
        
        % UI state flags
        bCtrlKeyPressedDown = false
        
        bLeftMouseButtonDown = false
        bRightMouseButtonDown = false
        
        dContourIndexToCentreOn = 1
        
        % handles to UI elements
        hFigureHandle = []
        
        hAutoScrollButtonHandle = []
        hAutoZoomSwitchHandle = []
        
        hWindowLevelMinEditFieldHandle = []
        hWindowLevelMaxEditFieldHandle = []
        
        hWindowLevelWindowEditFieldHandle = []
        hWindowLevelLevelEditFieldHandle = []
        
    end
    
    methods (Access = public)
        
        function obj = InteractiveDicomViewerController(c1oInteractiveImagingPlanes, hFigureHandle, varargin)
            %obj = InteractiveDicomViewerController(c1oInteractiveImagingPlanes, hFigureHandle, varargin)
            
            % set interactive imaging planes
            obj.c1oInteractiveImagingPlanes = c1oInteractiveImagingPlanes;
            
            
            % set some figure handle properities
            obj.hFigureHandle = hFigureHandle;
            obj.hFigureHandle.DoubleBuffer = 'off';
            obj.hFigureHandle.Interruptible = 'on';
            obj.hFigureHandle.BusyAction = 'cancel';
            
            % if given, set window/level & min/max handles
            hWindowHandle = [];
            hLevelHandle = [];
            
            hMinHandle = [];
            hMaxHandle = [];
            
            for dVarIndex=1:2:length(varargin)
                switch varargin{dVarIndex}
                    case 'WindowLevelWindowEditFieldHandle'
                        hWindowHandle = varargin{dVarIndex+1};
                    case 'WindowLevelLevelEditFieldHandle'
                        hLevelHandle = varargin{dVarIndex+1};
                    case 'WindowLevelMinEditFieldHandle'
                        obj.hWindowLevelMinEditFieldHandle = varargin{dVarIndex+1};
                    case 'WindowLevelMaxEditFieldHandle'
                        obj.hWindowLevelMaxEditFieldHandle = varargin{dVarIndex+1};
                    case 'AutoScrollButtonHandle'
                        obj.hAutoScrollButtonHandle = varargin{dVarIndex+1};
                    case 'AutoZoomSwitchHandle'
                        obj.hAutoZoomSwitchHandle = varargin{dVarIndex+1};
                    case 'AutoScrollHotkey'
                        obj.chAutoScrollHotkey = varargin{dVarIndex+1};
                    case 'AutoZoomHotkey'    
                        obj.chAutoZoomToggleHotkey = varargin{dVarIndex+1};        
                    otherwise
                        error(...
                            'InterativeDicomViewerController:Constructor:InvalidNameValuePair',...
                            ['Invalid parameter name ', varargin{dVarIndex}]);                        
                end
            end
            
            % set window/level handles
            if ~isempty(hWindowHandle) && ~isempty(hLevelHandle)
                obj.hWindowLevelWindowEditFieldHandle = hWindowHandle;
                obj.hWindowLevelLevelEditFieldHandle = hLevelHandle;
            elseif ~isempty(hWindowHandle) || ~isempty(hLevelHandle)
                error(...
                    'InteractiveDicomViewerController:Constructor:InvalidParameters',...
                    'Both a window and level edit field handle must be given');
            end
            
            % set min/max handles
            if ~isempty(hMinHandle) && ~isempty(hMaxHandle)
                obj.hWindowLevelMinEditFieldHandle = hMinHandle;
                obj.hWindowLevelMaxEditFieldHandle = hMaxHandle;
            elseif ~isempty(hMinHandle) || ~isempty(hMaxHandle)
                error(...
                    'InteractiveDicomViewerController:Constructor:InvalidParameters',...
                    'Both a window/level min and max edit field handle must be given');
            end            
        end
        
        function setNewHandlesAndHotkeys(obj, varargin)
            %obj = NewClass(input1, input2)
            %
            % SYNTAX:
            %  setNewHandlesAndHotkeys(__, 'FigureHandle', hFigureHandle)
            %  setNewHandlesAndHotkeys(__, 'InteractiveImagingPlanes', c1oInteractiveImagingPlanes)
            %  setNewHandlesAndHotkeys(__, 'WindowEditFieldHandle', hWindowLevelWindowEditFieldHandle)
            %  setNewHandlesAndHotkeys(__, 'LevelEditFieldHandle', hWindowLevelLevelEditFieldHandle)
            %  setNewHandlesAndHotkeys(__, 'MinEditFieldHandle', hWindowLevelMinEditFieldHandle)
            %  setNewHandlesAndHotkeys(__, 'MaxEditFieldHandle', hWindowLevelMaxditFieldHandle)
            %  setNewHandlesAndHotkeys(__, 'AutoScrollButtonHandle', hAutoScrollButtonHandle)
            %  setNewHandlesAndHotkeys(__, 'AutoZoomSwitchHandle', hAutoZoomSwitchHandle)
            %  setNewHandlesAndHotkeys(__, 'AutoScrollHotkey', hAutoScrollHotkey)
            %  setNewHandlesAndHotkeys(__, 'AutoZoomHotkey' , hAutoZoomHotkey)
            %
            % DESCRIPTION:
            %  Constructor for NewClass
            %
            % INPUT ARGUMENTS:
            %  input1: What input1 is
            %
            % OUTPUTS ARGUMENTS:
            %  None
                        
            for dVarIndex=1:2:length(varargin)
                switch varargin{dVarIndex}
                    case 'FigureHandle'
                        obj.hFigureHandle = varargin{dVarIndex+1};
                    case 'InteractiveImagingPlanes'
                        c1oInteractiveImagingPlanes = varargin{dVarIndex+1};
                        
                        for dPlaneIndex=1:length(obj.c1oInteractiveImagingPlanes)
                            obj.c1oInteractiveImagingPlanes{dPlaneIndex}.setNewHandlesAndTargetPlaneUnitVectors(c1oInteractiveImagingPlanes{dPlaneIndex});
                        end
                    case 'WindowLevelWindowEditFieldHandle'
                        obj.hWindowLevelWindowEditFieldHandle = varargin{dVarIndex+1};
                    case 'WindowLevelLevelEditFieldHandle'
                        obj.hWindowLevelLevelEditFieldHandle = varargin{dVarIndex+1};
                    case 'WindowLevelMinEditFieldHandle'
                        obj.hWindowLevelMinEditFieldHandle = varargin{dVarIndex+1};
                    case 'WindowLevelMaxEditFieldHandle'
                        obj.hWindowLevelMaxEditFieldHandle = varargin{dVarIndex+1}; 
                    case 'AutoScrollButtonHandle'
                        obj.hAutoScrollButtonHandle = varargin{dVarIndex+1};
                    case 'AutoZoomSwitchHandle'
                        obj.hAutoZoomSwitchHandle = varargin{dVarIndex+1};
                    case 'AutoScrollHotkey'
                        obj.chAutoScrollHotkey = varargin{dVarIndex+1};
                    case 'AutoZoomHotkey'    
                        obj.chAutoZoomToggleHotkey = varargin{dVarIndex+1};  
                    otherwise
                        error(...
                            'InterativeDicomViewerController:setNewHandle:InvalidNameValuePair',...
                            ['Invalid parameter name ', varargin{dVarIndex}]);                        
                end
            end
        end
        
        function updateInteractiveImagingPlanes(obj)
            %[] = setInteractiveImagingPlanes(obj)            
            for dPlaneIndex=1:length(obj.c1oInteractiveImagingPlanes)
                obj.c1oInteractiveImagingPlanes{dPlaneIndex}.updateFullAxis(obj.oDicomImageVolume);
            end 
            
            % Draw contour
            obj.updateContoursForImagingPlanes();
            
            % Draw slice locations
            obj.updateSliceLocationsForImagingPlanes();            
        end
        
        function [] = setDicomImageVolume(obj, oDicomImageVolume)
            obj.oDicomImageVolume = oDicomImageVolume;
        end
        
        function oImageVolume = getDicomImageVolume(obj)
            oImageVolume = obj.oDicomImageVolume;
        end
        
        function [] = setDicomContours(obj, c1oDicomContours)
            obj.c1oDicomContours = c1oDicomContours;
        end
        
        function [] = setDefaultImagingPlaneValues(obj)
            %[] = ContourValidation_setDefaultImagingPlaneValue(app)
            if ~obj.bDefaultCentreOnContourCentroid || obj.getNumberOfContours() == 0
                centreCoords_mm = obj.oDicomImageVolume.getCentreCoordsOfVolume();
            else                
                centreCoords_mm = obj.getContourToCentreOn().getContourCentroid();
            end
            
            for dPlaneIndex=1:length(obj.c1oInteractiveImagingPlanes)
                obj.c1oInteractiveImagingPlanes{dPlaneIndex}.setDefaultValues(obj.oDicomImageVolume, centreCoords_mm);                               
            end 
        end
        
        
        % >>>>>>>>>>>>>>>>>>>>> GUI CALLBACKS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        
        function [] = autoScrollContouredSlicesButtonPushed(obj)
            %[] = autoScrollContouredSlicesButtonPushed(obj)
            
            dDimensionNumber = DicomContour.getPredominatePolygonDimensionNumber(obj.c1oDicomContours);
            
            c1oImagingPlanes = obj.c1oInteractiveImagingPlanes;
            
            oImagingPlane = [];
            
            for dPlaneIndex=1:length(c1oImagingPlanes)
                if c1oImagingPlanes{dPlaneIndex}.dPlaneDimensionNumber == dDimensionNumber
                    oImagingPlane = c1oImagingPlanes{dPlaneIndex};
                end
            end
            
            if ~isempty(oImagingPlane)                
                [dMinIndex,dMaxIndex] = DicomContour.getMinMaxSliceIndices(obj.c1oDicomContours, dDimensionNumber);
                
                dIndices = dMinIndex:1:dMaxIndex;
                
                if oImagingPlane.bSliceFlipRequired
                    dIndices = oImagingPlane.dVolumeNumSlices + 1 - dIndices;
                end
                
                dIndices = [dIndices,fliplr(dIndices)];
                
                for dPlaneIndex=dIndices
                    oImagingPlane.oSliceLocationSpinnerHandle.Value = dPlaneIndex;
                    oImagingPlane.setSliceToSpinnerValue(obj.oDicomImageVolume, obj.c1oDicomContours);
                    
                    obj.updateSliceLocations();
                    
                    drawnow;                    
                    pause(obj.dAutoScrollInterframePause_s);
                end
            end
        end
        
        function [] = autoZoomSwitchValueChanged(obj)
            %[] = autoZoomSwitchValueChanged(obj)
            
            if strcmp(obj.hAutoZoomSwitchHandle.Value, obj.chAutoZoomWideLabel)
                for dPlaneIndex=1:length(obj.c1oInteractiveImagingPlanes)
                    obj.c1oInteractiveImagingPlanes{dPlaneIndex}.setFieldOfViewToMax(obj.oDicomImageVolume);
                end
            elseif strcmp(obj.hAutoZoomSwitchHandle.Value, obj.chAutoZoomTightLabel)
                dFieldOfView_mm = obj.dTightZoomLevelMultiplier * DicomContour.getMaxIndexToIndexDistanceFromContours(obj.c1oDicomContours);
                                
                for dPlaneIndex=1:length(obj.c1oInteractiveImagingPlanes)
                    obj.c1oInteractiveImagingPlanes{dPlaneIndex}.setFieldOfViewToValue(dFieldOfView_mm, obj.oDicomImageVolume);
                end
            else
                error('Invalid Auto Zoom Switch value');
            end            
        end

        function [] = sliceLocationSpinnerValueChanged(obj, oSpinnerHandle)
            oImagingPlane = [];
            
            for dPlaneIndex=1:length(obj.c1oInteractiveImagingPlanes)
                if obj.c1oInteractiveImagingPlanes{dPlaneIndex}.isSpinnerHandleEqual(oSpinnerHandle)
                    oImagingPlane = obj.c1oInteractiveImagingPlanes{dPlaneIndex};
                    break;
                end                
            end   
            
            if isempty(oImagingPlane)
                error('No Interactive Imaging Plane for given spinner handle');
            else            
                oImagingPlane.setSliceIndexToSpinnerValue();
                
                oImagingPlane.setImage(obj.oDicomImageVolume);
                oImagingPlane.drawContours(obj.c1oDicomContours);  
                
                obj.updateSliceLocationsForImagingPlanes();
            end
        end
        
        function [] = figureWindowButtonDown(obj, oEvent)
            %[] = figureWindowButtonDown(obj, event)
            
            switch oEvent.Source.SelectionType
                case obj.chLeftMouseClickLabel
                    obj.bLeftMouseButtonDown = true;
                    
                    pause(obj.dFalseMouseClickBuffer_s); % prevents quick clicks from being registered
                    
                    while obj.bLeftMouseButtonDown
                        c1oAxesHandles = obj.getAxesHandles();
                        c1oImagingPlanes = obj.c1oInteractiveImagingPlanes;
                        
                        dSelectedIndex = obj.findAppObjectMouseIsOver(obj.hFigureHandle, c1oAxesHandles);
                        
                        if dSelectedIndex ~= 0 % is over an axis
                            interactivePlane = c1oImagingPlanes{dSelectedIndex};
                            
                            [dMin,dMax] = interactivePlane.getThresholdMinMaxFromMouse(obj.hFigureHandle.CurrentPoint, obj.oDicomImageVolume);
                            
                            obj.oDicomImageVolume.setWindowLevelFromMinMax(dMin, dMax);
                            
                            obj.updateWindowLevelForImagingPlanes();
                            obj.updateWindowLevelForControls();
                        end
                        
                        drawnow;
                    end
                case obj.chRightMouseClickLabel
                    obj.rightMouseButtonDown = true;
            end            
        end
        
        function [] = figureWindowButtonMotion(obj)
            % [] = figureWindowButtonMotion(obj)
        end
        
        function [] = figureWindowButtonUp(obj)
            %[] = figureWindowButtonUp(obj)
            
            drawnow; % needed to interupt click & drag callbacks
            obj.bLeftMouseButtonDown = false;
            obj.bRightMouseButtonDown = false;
        end
        
        function bEventOccurred = figureKeyRelease(obj, event)
            %bEventOccurred = figureKeyRelease(obj, event)
            
            key = event.Key;
            bEventOccurred = true;
            
            switch key
                case 'control'
                    obj.bCtrlKeyPressedDown = false;
                case obj.chAutoZoomToggleHotkey
                    obj.toggleAutoZoomSwitch();
                case obj.chAutoScrollHotkey
                    obj.autoScrollContouredSlicesButtonPushed();
                otherwise
                    bEventOccurred = false;
            end            
        end
        
        function [] = uiFigureWindowScrollWheel(obj, oEvent)
            %[] = uiFigureWindowScrollWheel(obj, event)
            
            %verticalScrollAmount = event.VerticalScrollAmount;
            dVerticalScrollCount = oEvent.VerticalScrollCount;
            
            c1oAxesHandles = obj.getAxesHandles();
            c1oInteractivePlanes = obj.c1oInteractiveImagingPlanes;
            
            dSelectedIndex = obj.findAppObjectMouseIsOver(obj.hFigureHandle, c1oAxesHandles);
            
            if dSelectedIndex ~= 0 % is over an axis
                oInteractivePlane = c1oInteractivePlanes{dSelectedIndex};
                
                if obj.bCtrlKeyPressedDown % zooming
                    if dVerticalScrollCount == 1
                        % zoom out
                        oInteractivePlane.zoomOut(obj.oDicomImageVolume);
                    else
                        % zoom in
                        oInteractivePlane.zoomIn(obj.oDicomImageVolume);
                    end
                else % slice select
                    if dVerticalScrollCount == 1
                        % slice select down
                        oInteractivePlane.decrementSlice(obj.oDicomImageVolume, obj.c1oDicomContours);
                    else
                        % slice select up
                        oInteractivePlane.incrementSlice(obj.oDicomImageVolume, obj.c1oDicomContours);
                    end
                    
                    obj.updateSliceLocations();
                end
            end            
        end
        
        function [] = minMaxEditFieldValueChanged(obj)
            %[] = minMaxEditFieldValueChanged(obj)            
            obj.oDicomImageVolume.setWindowLevelFromMinMax(obj.hWindowLevelMinEditFieldHandle.Value, obj.hWindowLevelMaxEditFieldHandle.Value);
            
            obj.updateWindowLevelForImagingPlanes();
            obj.updateWindowLevelForControls();
        end
        
        function [] = windowLevelEditFieldValueChanged(obj)
            %[] = windowLevelEditFieldValueChanged(obj)   
            obj.oDicomImageVolume.setWindowLevelFromWindowLevel(obj.hWindowLevelWindowEditFieldHandle.Value, obj.hWindowLevelLevelEditFieldHandle.Value);
            
            obj.updateWindowLevelForImagingPlanes();
            obj.updateWindowLevelForControls();          
        end

        function [] = figureKeyPress(obj, event)
            key = event.Key;
            
            if strcmp(key, 'control')
                 obj.bCtrlKeyPressedDown = true;
            end
        end
    end
    
    
    
    % *********************************************************************   ORDERING: 1 Abstract     -> X.1 Not Static 
    % *                        PROTECTED METHODS                          *             2 Not Abstract    X.2 Static
    % *********************************************************************
    
    methods (Access = protected)
        
        function cpObj = copyElement(obj)
            cpObj = copyElement@matlab.mixin.Copyable(obj);
            
            cpObj.oDicomImageVolume = copy(cpObj.oDicomImageVolume);
            
            for dPlaneIndex=1:length(cpObj.c1oInteractiveImagingPlanes)
                cpObj.c1oInteractiveImagingPlanes{dPlaneIndex} = copy(cpObj.c1oInteractiveImagingPlanes{dPlaneIndex});
            end
            
            for dContourIndex=1:length(cpObj.c1oDicomContours)
                cpObj.c1oDicomContours{dContourIndex} = copy(cpObj.c1oDicomContours{dContourIndex});
            end
        end 
    end
    
    
    
    % *********************************************************************   ORDERING: 1 Abstract     -> X.1 Not Static
    % *                         PRIVATE METHODS                           *             2 Not Abstract    X.2 Static
    % *********************************************************************
    
    methods (Access = private)
        
        
        function toggleAutoZoomSwitch(obj)
            %toggleAutoZoomSwitch(obj)            
            if strcmp(obj.hAutoZoomSwitchHandle.Value, obj.chAutoZoomWideLabel)
                obj.hAutoZoomSwitchHandle.Value = obj.chAutoZoomTightLabel;
            else
                obj.hAutoZoomSwitchHandle.Value = obj.chAutoZoomWideLabel;
            end
            
            obj.autoZoomSwitchValueChanged();            
        end
        
        function dNumContours = getNumberOfContours(obj)
            dNumContours = length(obj.c1oDicomContours);
        end
        
        function oContour = getContourToCentreOn(obj)
            oContour = obj.c1oDicomContours{obj.dContourIndexToCentreOn};
        end
        
        function updateContoursForImagingPlanes(obj)
            %[] = drawContours(obj)
            for dPlaneIndex=1:length(obj.c1oInteractiveImagingPlanes)
                obj.c1oInteractiveImagingPlanes{dPlaneIndex}.drawContours(obj.c1oDicomContours);
            end  
        end
        
        function [] = updateWindowLevelForImagingPlanes(obj)
            %[] = updateDisplayThesholds(obj)
            for dPlaneIndex=1:length(obj.c1oInteractiveImagingPlanes)
                [dMin, dMax] = obj.oDicomImageVolume.getMinMaxFromWindowLevel();
                
                obj.c1oInteractiveImagingPlanes{dPlaneIndex}.setThreshold(dMin, dMax);
            end 
        end
        
        function updateWindowLevelForControls(obj)
            
            if ~isempty(obj.hWindowLevelMinEditFieldHandle) && ~isempty(obj.hWindowLevelMaxEditFieldHandle)
                [dMin, dMax] = obj.oDicomImageVolume.getMinMaxFromWindowLevel();
                
                obj.hWindowLevelMinEditFieldHandle.Value = dMin;
                obj.hWindowLevelMaxEditFieldHandle.Value = dMax;
            end
            
            if ~isempty(obj.hWindowLevelWindowEditFieldHandle) && ~isempty(obj.hWindowLevelLevelEditFieldHandle)
                [dWindow, dLevel] = obj.oDicomImageVolume.getWindowLevel();
                
                obj.hWindowLevelWindowEditFieldHandle.Value = dWindow;
                obj.hWindowLevelLevelEditFieldHandle.Value = dLevel;
            end
        end
        
        function c1oAxesHandles = getAxesHandles(obj)
            dNumPlanes = length(obj.c1oInteractiveImagingPlanes);
            c1oAxesHandles = cell(dNumPlanes,1);
            
            for dPlaneIndex=1:dNumPlanes
                c1oAxesHandles{dPlaneIndex} = obj.c1oInteractiveImagingPlanes{dPlaneIndex}.getAxesHandle();
            end  
        end
        
        function [] = updateSliceLocations(obj)
            %updateSliceLocations(obj)
            
            dNumImagingPlanes = length(obj.c1oInteractiveImagingPlanes);
            
            for dPlaneIndex=1:dNumImagingPlanes
                vbPlaneSelect = true(dNumImagingPlanes,1);
                vbPlaneSelect(dPlaneIndex) = false;
                
                obj.c1oInteractiveImagingPlanes{dPlaneIndex}.updateSliceLocations(obj.c1oInteractiveImagingPlanes(vbPlaneSelect));
            end            
        end
        
        function [] = updateSliceLocationsForImagingPlanes(obj)
            %drawSliceLocations(obj)
            
            dNumImagingPlanes = length(obj.c1oInteractiveImagingPlanes);
            
            for dPlaneIndex=1:dNumImagingPlanes
                vbPlaneSelect = true(dNumImagingPlanes,1);
                vbPlaneSelect(dPlaneIndex) = false;
                
                obj.c1oInteractiveImagingPlanes{dPlaneIndex}.drawSliceLocations(obj.c1oInteractiveImagingPlanes(vbPlaneSelect));
            end            
        end
    end
    
    
    methods (Access = private, Static = true)
        
        function dSelectedIndex = findAppObjectMouseIsOver(hFigureHandle, c1oAppObjects)
            %object = findAppObjectMouseIsOver(appObjects)
            
            vdMousePosition = get(0, 'PointerLocation');
            
            dSelectedIndex = 0;
            
            for dObjectIndex=1:length(c1oAppObjects)
                if InteractiveDicomViewerController.isMouseOverAppObject(hFigureHandle, c1oAppObjects{dObjectIndex}, vdMousePosition)
                    dSelectedIndex = dObjectIndex;
                    break;
                end
            end
        end
        
        function bBool = isMouseOverAppObject(hFigureHandle, oAppObjectHandle, vdMouseAbsolutePosition)
            vdAppAbsolutePosition = hFigureHandle.Position;
            vdObjectRelativePosition = oAppObjectHandle.Position;
            
            objectAbsolutePosition = vdObjectRelativePosition + [vdAppAbsolutePosition(1:2), 0, 0];
            
            bBool = vdMouseAbsolutePosition(1) >= objectAbsolutePosition(1) && vdMouseAbsolutePosition(1) <= (objectAbsolutePosition(1) + objectAbsolutePosition(3)) && vdMouseAbsolutePosition(2) >= objectAbsolutePosition(2) && vdMouseAbsolutePosition(2) <= (objectAbsolutePosition(2) + objectAbsolutePosition(4));
        end
    end
end