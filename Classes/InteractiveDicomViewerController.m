classdef InteractiveDicomViewerController < matlab.mixin.Copyable
    %InteractiveDicomViewerController
    
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
        oDicomImageVolume = DicomImageVolume.empty        
        c1oDicomContours = {}
        c1oInteractiveImagingPlanes = {} % cell array of InteractiveImagingPlane objects
        
        bCtrlKeyPressedDown = false
        
        bLeftMouseButtonDown = false
        bRightMouseButtonDown = false
        
        dContourIndexToCentreOn = 1
        
        oFigureHandle = []
        
        oAutoScrollButtonHandle = []
        oAutoZoomSwitchHandle = []
        
        oThresholdMinEditFieldHandle = []
        oThresholdMaxEditFieldHandle = []
        
        oThresholdWindowEditFieldHandle = []
        oThresholdLevelEditFieldHandle = []
        
    end
    
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
    
    methods
        function obj = InteractiveDicomViewerController(c1oInteractiveImagingPlanes, oFigureHandle, oWindowHandle, oLevelHandle, oMinHandle, oMaxHandle)
            %obj = InteractiveDicomViewerController(c1oInteractiveImagingPlanes, oFigureHandle, oWindowHandle, oLevelHandle, oMinHandle, oMaxHandle)
            obj.c1oInteractiveImagingPlanes = c1oInteractiveImagingPlanes;
            
            for dPlaneIndex=1:length(obj.c1oInteractiveImagingPlanes)
                obj.c1oInteractiveImagingPlanes{dPlaneIndex}.setWindowLevelHandles(oWindowHandle, oLevelHandle, oMinHandle, oMaxHandle);
            end
            
            obj.oThresholdMinEditFieldHandle = oMinHandle;
            obj.oThresholdMaxEditFieldHandle = oMaxHandle;
            
            obj.oThresholdWindowEditFieldHandle = oWindowHandle;
            obj.oThresholdLevelEditFieldHandle = oLevelHandle;
            
            obj.oFigureHandle = oFigureHandle;
            obj.oFigureHandle.DoubleBuffer = 'off';
            obj.oFigureHandle.Interruptible = 'on';
            obj.oFigureHandle.BusyAction = 'cancel';
        end
        
        function [] = setNewHandles(obj, c1oNewInteractiveImagingPlanes, oNewWindowEditField, oNewLevelEditField, oNewMinEditField, oNewMaxEditField)
            for dPlaneIndex=1:length(obj.c1oInteractiveImagingPlanes)
                obj.c1oInteractiveImagingPlanes{dPlaneIndex}.setNewHandles(c1oNewInteractiveImagingPlanes{dPlaneIndex});
            end
            
            obj.oThresholdMinEditFieldHandle = oNewMinEditField;
            obj.oThresholdMaxEditFieldHandle = oNewMaxEditField;
            
            obj.oThresholdWindowEditFieldHandle = oNewWindowEditField;
            obj.oThresholdLevelEditFieldHandle = oNewLevelEditField;
            
            for dPlaneIndex=1:length(obj.c1oInteractiveImagingPlanes)
                obj.c1oInteractiveImagingPlanes{dPlaneIndex}.setWindowHandles(...
                    oNewWindowEditField, oNewLevelEditField, oNewMinEditField, oNewMaxEditField);
            end
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
        
        function [] = setDefaultThreshold(obj)
            obj.oDicomImageVolume.setDefaultThreshold(obj);
        end
        
        function dNumContours = getNumberOfContours(obj)
            dNumContours = length(obj.c1oDicomContours);
        end
        
        function oContour = getContourToCentreOn(obj)
            oContour = obj.c1oDicomContours{obj.dContourIndexToCentreOn};
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
        
        function [] = autoScrollContouredSlicesButtonPushed(obj)
            %[] = autoScrollContouredSlicesButtonPushed(obj)
            
            dDimensionNumber = DicomContours.getPredominatePolygonDimensionNumber(obj.c1oDicomContours);
            
            c1oImagingPlanes = obj. c1oInteractiveImagingPlanes;
            
            oImagingPlane = [];
            
            for dPlaneIndex=1:length(c1oImagingPlanes)
                if c1oImagingPlanes{dPlaneIndex}.planeDimensionNumber == dDimensionNumber
                    oImagingPlane = c1oImagingPlanes{dPlaneIndex};
                end
            end
            
            if ~isempty(oImagingPlane)                
                dIndices = DicomContours.getPolygonSliceIndicesFromMinToMax(obj.c1oDicomContours, dDimensionNumber);
                
                if oImagingPlane.sliceFlipRequired
                    dIndices = oImagingPlane.volumeNumSlices + 1 - dIndices;
                end
                
                dIndices = [dIndices,fliplr(dIndices)];
                
                for dPlaneIndex=dIndices
                    oImagingPlane.sliceLocationSpinnerHandle.Value = dPlaneIndex;
                    oImagingPlane.setSliceToSpinnerValue(app.currentVolume, contour);
                    
                    obj.updateSliceLocations();
                    
                    drawnow;                    
                    pause(IteractiveDicomViewerController.dAutoScrollInterframePause_s);
                end
            end
        end
        
        function [] = autoZoomSwitchValueChanged(obj)
            %[] = autoZoomSwitchValueChanged(obj)
            
            if strcmp(obj.oAutoZoomSwitchHandle.Value, obj.chAutoZoomWideLabel)
                for dPlaneIndex=1:length(obj.c1oInteractiveImagingPlanes)
                    obj.c1oInteractiveImagingPlanes{dPlaneIndex}.setFieldOfViewToMax(obj.oDicomImageVolume);
                end
            elseif strcmp(obj.oAutoZoomSwitchHandle.Value, obj.chAutoZoomTightLabel)
                dFieldOfView_mm = obj.dTightZoomLevelMultiplier * DicomContour.getMaxIndexToIndexDistanceFromContours(obj.c1oDicomContours);
                                
                for dPlaneIndex=1:length(obj.c1oInteractiveImagingPlanes)
                    obj.c1oInteractiveImagingPlanes{dPlaneIndex}.setFieldOfViewToValue(dFieldOfView_mm, obj.oDicomImageVolume);
                end
            else
                error('Invalid Auto Zoom Switch value');
            end            
        end
        
        function [] = toggleAutoZoomSwitch(obj)
            %[] = toggleAutoZoomSwitch(obj)            
            if strcmp(obj.oAutoZoomSwitchHandle.Value, obj.chAutoZoomWideLabel)
                obj.oAutoZoomSwitchHandle.Value = obj.chAutoZoomTightLabel;
            else
                obj.oAutoZoomSwitchHandle.Value = obj.chAutoZoomWideLabel;
            end
            
            obj.autoZoomSwitchValueChanged();            
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
        
        function [] = drawSliceLocations(obj)
            %drawSliceLocations(obj)
            
            dNumImagingPlanes = length(obj.c1oInteractiveImagingPlanes);
            
            for dPlaneIndex=1:dNumImagingPlanes
                vbPlaneSelect = true(dNumImagingPlanes,1);
                vbPlaneSelect(dPlaneIndex) = false;
                
                obj.c1oInteractiveImagingPlanes{dPlaneIndex}.drawSliceLocations(obj.c1oInteractiveImagingPlanes(vbPlaneSelect));
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
                oImagingPlane.setSliceToSpinnerValue(...
                    obj.oDicomImageVolume, obj.c1oDicomContours);
                
                obj.updateSliceLocations();
            end
        end
        
        function [] = drawContours(obj)
            %[] = drawContours(obj)
            for dPlaneIndex=1:length(obj.c1oInteractiveImagingPlanes)
                obj.c1oInteractiveImagingPlanes{dPlaneIndex}.drawContours(obj.c1oDicomContours);
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
                        
                        dSelectedIndex = obj.findAppObjectMouseIsOver(obj.oFigureHandle, c1oAxesHandles);
                        
                        if dSelectedIndex ~= 0 % is over an axis
                            interactivePlane = c1oImagingPlanes{dSelectedIndex};
                            
                            interactivePlane.updateThresholdFromMouse(obj.oFigureHandle.CurrentPoint, obj.currentVolume);
                            
                            obj.updateDisplayThesholds();
                        end
                        
                        drawnow;
                    end
                case obj.chRightMouseClickLabel
                    obj.rightMouseButtonDown = true;
            end            
        end
        
        function c1oAxesHandles = getAxesHandles(obj)
            dNumPlanes = length(obj.c1oInteractiveImagingPlanes);
            c1oAxesHandles = cell(dNumPlanes,1);
            
            for dPlaneIndex=1:length(dNumPlanes)
                c1oAxesHandles{dPlaneIndex} = obj.c1oInteractiveImagingPlanes{dPlaneIndex}.getAxesHandle();
            end  
        end
        
        function [] = updateDisplayThesholds(obj)
            %[] = updateDisplayThesholds(obj)
            for dPlaneIndex=1:length(obj.c1oInteractiveImagingPlanes)
                obj.c1oInteractiveImagingPlanes{dPlaneIndex}.setThreshold();
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
        
        function bEventOccurred = figureWindowKeyRelease(obj, event)
            %bEventOccurred = figureWindowKeyRelease(obj, event)
            
            key = event.Key;
            bEventOccurred = true;
            
            switch key
                case 'control'
                    obj.ctrlKeyPressedDown = false;
                case 'add'
                    obj.toggleAutoZoomSwitch();
                case 'equal'
                    obj.toggleAutoZoomSwitch();
                case 'subtract'
                    obj.AutoScrollContouredSlicesButtonPushed();
                otherwise
                    bEventOccurred = false;
            end            
        end
        
        function [] = setInteractiveImagingPlanes(obj)
            %[] = setInteractiveImagingPlanes(obj)            
            for dPlaneIndex=1:length(obj.c1oInteractiveImagingPlanes)
                obj.c1oInteractiveImagingPlanes{dPlaneIndex}.setFullAxis(obj.oDicomImageVolume);
            end 
            
            % Draw contour
            obj.drawContours();
            
            % Draw slice locations
            obj.drawSliceLocations();            
        end
        
        function [] = uiFigureWindowScrollWheel(obj, oEvent)
            %[] = uiFigureWindowScrollWheel(obj, event)
            
            %verticalScrollAmount = event.VerticalScrollAmount;
            dVerticalScrollCount = oEvent.VerticalScrollCount;
            
            c1oAxesHandles = obj.getAxesHandles;
            c1oInteractivePlanes = obj.c1oInteractiveImagingPlanes;
            
            dSelectedIndex = obj.findAppObjectMouseIsOver(obj.oFigureHandle, c1oAxesHandles);
            
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
            obj.oDicomImageVolume.updateDisplayThresholdsFromMinMaxChange(obj);            
            obj.updateDisplayThesholds();            
        end
        
        function [] = windowLevelEditFieldValueChanged(obj)
            %[] = windowLevelEditFieldValueChanged(obj)
            
            obj.oDicomImageVolume.updateDisplayThresholdsFromWindowLevelChange(obj);            
            obj.updateDisplayThesholds();            
        end

        function [] = figureKeyPress(obj, event)
            key = event.Key;
            
            if strcmp(key, 'control')
                 obj.bCtrlKeyPressedDown = true;
            end
        end
    end
    
    methods (Static) 
        function dSelectedIndex = findAppObjectMouseIsOver(oFigureHandle, c1oAppObjects)
            %object = findAppObjectMouseIsOver(appObjects)
            
            vdMousePosition = get(0, 'PointerLocation');
            
            dSelectedIndex = 0;
            
            for dObjectIndex=1:length(c1oAppObjects)
                if isMouseOverAppObject(oFigureHandle, c1oAppObjects{dObjectIndex}, vdMousePosition)
                    dSelectedIndex = dObjectIndex;
                    break;
                end
            end
        end
    end
end

% ** HELPER FUNCTIONS **
function bBool = isMouseOverAppObject(oFigureHandle, oAppObjectHandle, vdMouseAbsolutePosition)
vdAppAbsolutePosition = oFigureHandle.Position;
vdObjectRelativePosition = oAppObjectHandle.Position;

objectAbsolutePosition = vdObjectRelativePosition + [vdAppAbsolutePosition(1:2), 0, 0];

bBool = vdMouseAbsolutePosition(1) >= objectAbsolutePosition(1) && vdMouseAbsolutePosition(1) <= (objectAbsolutePosition(1) + objectAbsolutePosition(3)) && vdMouseAbsolutePosition(2) >= objectAbsolutePosition(2) && vdMouseAbsolutePosition(2) <= (objectAbsolutePosition(2) + objectAbsolutePosition(4));
end
