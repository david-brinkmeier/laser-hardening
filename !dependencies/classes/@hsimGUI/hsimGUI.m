classdef hsimGUI < handle
    
    properties
        results     heatSimResults.container
        simopts     simSettings
        
        caxisType   (1,:) char % static or dynamic
        limitsType  (1,:) char % static or dynamic
        gradType    (1,:) char % dynamic or logical (logical plots binary vs. critCoolingRate if critCoolingRate is finite)
        
        XYplot      struct
        XYplotInt   struct
        XZplot      struct
        ZYplot      struct
        ZYplotGrad  struct
        meshPlot    struct
    end
    
    properties (Dependent, Access = private)
        vfeed_IDX   double
        zslice_IDX  double
        
        mat
        axisdef
        pwr_in
        vfeed_current
        
        hDistrib
        
        xPosSelected
        yPosSelected
    end
    
    properties (SetAccess = private)
        xIndexSelected
        yIndexSelected
        XYposFIXED      logical
        
        caxisLims       (1,2) double
    end
    
    properties (Access = private)
       vfeed_IDX_internal   double
       zslice_IDX_internal  double
    end
    
    methods
        function obj = hsimGUI(results, simopts, hsimGUI)
            init = true;
            redraw = false;
            
            if nargin > 2
                init = false;
                if ~init &&  ~isequal(simopts.identifier, hsimGUI.simopts.identifier)
                    redraw = true;
                end
            end
            
            obj.results = results;
            obj.simopts = simopts;
    
            if init || redraw
                obj.vfeed_IDX = 1;
                obj.zslice_IDX = 1;
                obj.XYposFIXED = false;
            else
               obj.vfeed_IDX = hsimGUI.vfeed_IDX;
               obj.zslice_IDX = hsimGUI.zslice_IDX;
               obj.XYposFIXED = hsimGUI.XYposFIXED;
               
               obj.XYplot = hsimGUI.XYplot;
               obj.XYplotInt = hsimGUI.XYplotInt;
               obj.XZplot = hsimGUI.XZplot;
               obj.ZYplot = hsimGUI.ZYplot;
               obj.ZYplotGrad = hsimGUI.ZYplotGrad;
               obj.meshPlot = hsimGUI.meshPlot;
               
               obj.caxisType = hsimGUI.caxisType;
               obj.limitsType = hsimGUI.limitsType;
               obj.gradType = hsimGUI.gradType;
            end
            
            obj.updateAllPlots();
            obj.updateMeshPlot();
            
        end
        
        function set.caxisType(obj,val)
            val = lower(val);
            if ismember(val,{'static','dynamic'})
                obj.caxisType = val;
            else
                obj.caxisType = 'static';
            end
        end
        
        function val = get.caxisType(obj)
            if isempty(obj.caxisType)
                val = 'static';
            else
                val = obj.caxisType;
            end
        end
        
        function set.gradType(obj,val)
            val = lower(val);
            if ismember(val,{'dynamic','logical'})
                obj.gradType = val;
            else
                obj.gradType = 'dynamic';
            end
        end
        
        function val = get.gradType(obj)
            if isempty(obj.gradType) || ~isfinite(obj.results.material.critCoolingRate)
                val = 'dynamic';
            else
                val = obj.gradType;
            end
        end
        
        function set.limitsType(obj,val)
            val = lower(val);
            if ismember(val,{'static','dynamic'})
                obj.limitsType = val;
            else
                obj.limitsType = 'static';
            end
        end
        
        function val = get.limitsType(obj)
            if isempty(obj.limitsType)
                val = 'static';
            else
                val = obj.limitsType;
            end
        end
        
        function val = get.xPosSelected(obj)
            val = obj.axisdef.xaxis(obj.xIndexSelected);
        end
        
        function val = get.xIndexSelected(obj)
            if isempty(obj.xIndexSelected)
                val = obj.axisdef.IndexCentroidX;
            else
                val = obj.xIndexSelected;
            end
        end
        
        function val = get.yPosSelected(obj)
            val = obj.axisdef.yaxis(obj.yIndexSelected);
        end
        
        function val = get.yIndexSelected(obj)
            if isempty(obj.yIndexSelected)
                val = obj.axisdef.IndexCentroidY;
            else
                val = obj.yIndexSelected;
            end
        end
        
        function val = get.mat(obj)
            val = obj.results.material;
        end
        
        function val = get.axisdef(obj)
           val = obj.results.axDef; 
        end
        
        function val = get.pwr_in(obj)
           val = obj.results.laserPowerIn; 
        end
        
        function val = get.vfeed_current(obj)
           val = obj.results.vfeed; 
        end
        
        function val = get.vfeed_IDX(obj)
            val = obj.vfeed_IDX_internal;
        end
        
        function set.vfeed_IDX(obj,val)
            maxIDX = length(obj.simopts.vfeed);
            if val > maxIDX
                val = maxIDX;
            end
            
            if val < 1
                val = 1;
            end
                
            obj.vfeed_IDX_internal = val;
        end
        
        function val = get.zslice_IDX(obj)
           val = obj.zslice_IDX_internal; 
        end
        
        function set.zslice_IDX(obj,val)
            maxIDX = obj.axisdef.refSize(3);
            if val > maxIDX
                val = maxIDX;
            end
            
            if val < 1
                val = 1;
            end
            
            maxTempZSlice = max(obj.results.tempField_YXZ(:,:,val),[],'all');
            if (maxTempZSlice > obj.mat.tMelt) || strcmp(obj.caxisType,'static')
                obj.caxisLims = [0,obj.mat.tMelt];
            else
                obj.caxisLims = [0,maxTempZSlice];
            end
            
            obj.zslice_IDX_internal = val;
        end
        
        
        function mouseWheel(obj,~,source)
            index = obj.zslice_IDX;
            if source.VerticalScrollCount > 0
                index = index+1;
            elseif source.VerticalScrollCount < 0
                index = index-1;
            end
            
            lastIDX = obj.zslice_IDX;
            obj.zslice_IDX = index;
            
            if ~isequal(lastIDX,obj.zslice_IDX)
               obj.updateAllPlots();
            end
        end
        
        function updateMousePosition(obj)
            if obj.XYposFIXED
                return
            end
            
            C = obj.XYplot.ax.CurrentPoint; % C(1,1) is X pos, C(1,2) is Y pos
            xPos = C(1,1);
            yPos = C(1,2);
            
            % interpolate from mm to px values
            xIndex = round(interp1(obj.axisdef.xaxis, 1:obj.axisdef.refSize(2), xPos));
            yIndex = round(interp1(obj.axisdef.yaxis, 1:obj.axisdef.refSize(1), yPos));
            
            if ~isfinite(xIndex) || (xIndex < obj.results.heatDistrib.validRangeX(1)) || (xIndex > obj.results.heatDistrib.validRangeX(2))
                xIndex = obj.axisdef.IndexCentroidX;
            end
            
            if ~isfinite(yIndex) || (yIndex < obj.results.heatDistrib.validRangeY(1)) || (yIndex > obj.results.heatDistrib.validRangeY(2))
                yIndex = obj.axisdef.IndexCentroidY;
            end
        
            lastXindex = obj.xIndexSelected;
            lastYindex = obj.yIndexSelected;
            obj.xIndexSelected = xIndex;
            obj.yIndexSelected = yIndex;
            
            if ~isequal(lastXindex, obj.xIndexSelected) || ~isequal(lastYindex, obj.yIndexSelected)
               obj.updateAllPlots();
            end
        end
        
        function recordMousePosition(obj,hobj,~)
            switch hobj.SelectionType
                case 'normal' % left click
                    obj.XYposFIXED = ~obj.XYposFIXED;
                case 'alt' % right click
                    obj.XYposFIXED = true;
                    obj.xIndexSelected = obj.axisdef.IndexCentroidX;
                    obj.yIndexSelected = obj.axisdef.IndexCentroidY;
            end
            obj.updateAllPlots();
        end
        
        function updateAllPlots(obj)
            obj.updateXYplot();
            obj.updateXYplotInt();
            obj.updateXZplot();
            obj.updateZYplot();
            obj.updateZYplotGrad();
            drawnow
        end
        
        % declare external
        updateXYplot(obj)
        updateXYplotInt(obj)
        updateXZplot(obj)
        updateZYplot(obj)
        updateZYplotGrad(obj);
        updateMeshPlot(obj);
    end
end

