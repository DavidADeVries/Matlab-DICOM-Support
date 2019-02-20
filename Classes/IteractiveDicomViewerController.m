classdef IteractiveDicomViewerController < handle
    %IteractiveDicomViewerController
    
    properties(Constant)
        dAutoScrollInterframePause_s = 0.05
        
        chAutoZoomWideLabel = 'Wide'
        chAutoZoomTightLabel = 'Tight'
        dTightZoomLevelMultiplier = 4 % 4 times the largest contour diameter
        
        dFalseMouseClickBuffer_s = 0.25
        chLeftMouseClickLabel = 'normal'
        chRightMouseClickLabel = 'normal'
    end
    
    properties (SetAccess = private)
        oDicomImageVolume = DicomImageVolume.empty        
        c1oDicomContours = {}
        
        bCtrlKeyPressedDown = false
        
        bLeftMouseButtonDown = false
        bRightMouseButtonDown = false
        
        oAutoScrollButtonHandle = []
        oAutoZoomSwitchHandle = []
        
        c1oInteractiveImagingPlanes = {} % cell array of InteractiveImagingPlane objects
    end
    
    methods
        function obj = IteractiveDicomViewerController(c1oInteractiveImagingPlanes, windowHandle, levelHandle, minHandle, maxHandle)
            %obj = IteractiveDicomViewerController(c1oInteractiveImagingPlanes, windowHandle, levelHandle, minHandle, maxHandle)
            obj.c1oInteractiveImagingPlanes = c1oInteractiveImagingPlanes;
            
            for dPlaneIndex=1:length(obj.c1oInteractiveImagingPlanes)
                obj.c1oInteractiveImagingPlanes{dPlaneIndex}.setWindowLevelHandles(windowHandle, levelHandle, minHandle, maxHandle);
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
                obj.c1oInteractiveImagingPlanes{dPlaneIndex}.drawPolygons(obj.c1oDicomContours);
            end  
        end
        
        function [] = figureWindowButtonDown(obj, oEvent, oFigureHandle)
            %[] = figureWindowButtonDown(obj, event)
            
            switch oEvent.Source.SelectionType
                case obj.chLeftMouseClickLabel
                    obj.bLeftMouseButtonDown = true;
                    
                    pause(obj.dFalseMouseClickBuffer_s); % prevents quick clicks from being registered
                    
                    while obj.bLeftMouseButtonDown
                        c1oAxesHandles = obj.getAxesHandles();
                        c1oImagingPlanes = obj.c1oInteractiveImagingPlanes;
                        
                        dSelectedIndex = obj.findAppObjectMouseIsOver(oFigureHandle, c1oAxesHandles);
                        
                        if dSelectedIndex ~= 0 % is over an axis
                            interactivePlane = c1oImagingPlanes{dSelectedIndex};
                            
                            interactivePlane.updateThresholdFromMouse(oFigureHandle.CurrentPoint, obj.currentVolume);
                            
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
        
        function [] = figureWindowButtonMotion(obj)
            % [] = figureWindowButtonMotion(obj)
        end
        
        function [] = ContourValidation_FigureWindowButtonUp(obj)
            %[] = ContourValidation_FigureWindowButtonUp(obj)
            
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
    end
end

% ** HELPER FUNCTIONS **
function bBool = isMouseOverAppObject(oFigureHandle, oAppObjectHandle, vdMouseAbsolutePosition)
vdAppAbsolutePosition = oFigureHandle.Position;
vdObjectRelativePosition = oAppObjectHandle.Position;

objectAbsolutePosition = vdObjectRelativePosition + [vdAppAbsolutePosition(1:2), 0, 0];

bBool = vdMouseAbsolutePosition(1) >= objectAbsolutePosition(1) && vdMouseAbsolutePosition(1) <= (objectAbsolutePosition(1) + objectAbsolutePosition(3)) && vdMouseAbsolutePosition(2) >= objectAbsolutePosition(2) && vdMouseAbsolutePosition(2) <= (objectAbsolutePosition(2) + objectAbsolutePosition(4));
end