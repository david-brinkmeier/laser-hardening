classdef axisDef < handle
    
    properties (SetAccess = private, GetAccess = public)
        dA             (:,:,:) double % array specifying "pixel" cross sections in SI units (XYres * Zres)
        
        IndexCentroidX   (1,1) double % derived from xaxis
        IndexCentroidY   (1,1) double % derived from yaxis
        refSize          (1,:) double % reference array size
    
        xaxis_SI         (1,:) double % in SI units / m
        Xgrid_YXZ_SI   (:,:,:) double % in SI units / m
        Xgrid_ZX_SI      (:,:) double % in SI units / m
        
        yaxis_SI         (1,:) double % in SI units / m
        Ygrid_YXZ_SI   (:,:,:) double % in SI units / m
        Ygrid_ZY_SI      (:,:) double % in SI units / m
        
        zaxis_SI         (1,:) double % in SI units / m
        Zgrid_YXZ_SI   (:,:,:) double % in SI units / m
        Zgrid_ZX_SI      (:,:) double % in SI units / m
        Zgrid_ZY_SI      (:,:) double % in SI units / m
        
        resolutionXY_SI     (1,1) double % in SI units / m
        resolutionZ_SI      (1,1) double % in SI units / m
    end
    
    properties (Dependent)
        xaxis             (1,:) double % in "units"
        Xgrid_YXZ       (:,:,:) double % in "units"
        Xgrid_ZX          (1,:) double % in "units"
        % note: Xgrid_ZY is just constant X val; get via method
        
        yaxis             (1,:) double % in "units"
        Ygrid_YXZ       (:,:,:) double % in "units"
        Ygrid_ZY          (1,:) double % in "units"
        % note: Ygrid_ZX is just constant X val; get via method
        
        zaxis             (1,:) double % in "units"
        Zgrid_YXZ       (:,:,:) double % in "units"
        Zgrid_ZX          (1,:) double % in "units"
        Zgrid_ZY          (1,:) double % in "units"
        
        resolutionXY      (1,1) double % in "units"
        resolutionZ       (1,1) double % in "units"
    end
    
    properties (SetAccess = protected, GetAccess = protected)
       settings                 heatSimResults.plotSettings 
    end
    
    properties (Dependent, GetAccess = private)
        units_scale
    end
    
    methods
        function obj = axisDef(simOpts,plotSettings)
            if ~isa(simOpts,'simSettings')
                error('simOpts must be called with input of class simSettings.')
            end
            if ~isa(plotSettings,'heatSimResults.plotSettings')
                error('axisDef must be called with input of class heatSimResults.plotSettings.')
            end
            obj.settings = plotSettings;
            
            obj.xaxis_SI = simOpts.xaxis;
            obj.yaxis_SI = simOpts.yaxis;
            obj.zaxis_SI = simOpts.zaxis;
            
            obj.refSize = [length(obj.yaxis_SI), length(obj.xaxis_SI), length(obj.zaxis_SI)];
            
            [obj.Xgrid_YXZ_SI,obj.Ygrid_YXZ_SI,obj.Zgrid_YXZ_SI] = meshgrid(obj.xaxis_SI,obj.yaxis_SI,obj.zaxis_SI);

            % extract appropriate grids for ZX and ZY cross sections
            obj.Xgrid_ZX_SI = permute(obj.Xgrid_YXZ_SI(1,:,:),[3,2,1]);
            obj.Ygrid_ZY_SI = permute(obj.Ygrid_YXZ_SI(:,1,:),[3,1,2]);
            obj.Zgrid_ZX_SI = permute(obj.Zgrid_YXZ_SI(1,:,:),[3,2,1]);
            obj.Zgrid_ZY_SI = permute(obj.Zgrid_YXZ_SI(:,1,:),[3,1,2]);
            
            obj.resolutionXY_SI = simOpts.resolutionXY;
            obj.resolutionZ_SI = simOpts.resolutionZ;
            
            [~,obj.IndexCentroidX] = min(abs(obj.xaxis_SI));
            [~,obj.IndexCentroidY] = min(abs(obj.yaxis_SI));
            
            if obj.refSize(3) > 1
                obj.dA = (obj.resolutionXY_SI*ones(obj.refSize(1:2))) .* reshape(obj.fdiff1D(obj.zaxis_SI),[1,1,obj.refSize(3)]);
            end
        end
        
        function val = get.units_scale(obj)
           val = obj.settings.units_scale; 
        end
        
        function val = get.resolutionXY(obj)
            val = obj.resolutionXY_SI*obj.units_scale;
        end
        
        function val = get.resolutionZ(obj)
            val = obj.resolutionZ_SI*obj.units_scale;
        end
        
        function val = get.xaxis(obj)
           val = obj.xaxis_SI * obj.units_scale;
        end
        
        function val = get.yaxis(obj)
           val = obj.yaxis_SI * obj.units_scale;
        end
        
        function val = get.zaxis(obj)
           val = obj.zaxis_SI * obj.units_scale;
        end
        
        function val = get.Xgrid_YXZ(obj)
           val = obj.Xgrid_YXZ_SI * obj.units_scale;
        end
        
        function val = get.Xgrid_ZX(obj)
           val = obj.Xgrid_ZX_SI * obj.units_scale;
        end
        
        function grid = Xgrid_ZY(obj,index)
            grid = obj.xaxis(index) * ones(obj.refSize([3,1]));
        end
        
        function val = get.Ygrid_YXZ(obj)
            val = obj.Ygrid_YXZ_SI * obj.units_scale;
        end
        
        function grid = Ygrid_ZX(obj,index)
            grid = obj.yaxis(index) * ones(obj.refSize([3,2]));
        end
        
        function val = get.Ygrid_ZY(obj)
           val = obj.Ygrid_ZY_SI * obj.units_scale;
        end
        
        function val = get.Zgrid_YXZ(obj)
           val = obj.Zgrid_YXZ_SI * obj.units_scale;
        end
        
        function val = get.Zgrid_ZX(obj)
           val = obj.Zgrid_ZX_SI * obj.units_scale;
        end
        
        function val = get.Zgrid_ZY(obj)
           val = obj.Zgrid_ZY_SI * obj.units_scale;
        end

    end
    
    methods (Static)
        function grad = fdiff1D(vect)
           % forward difference of vector
           grad = [diff(vect), vect(end)-vect(end-1)];
        end
    end
    
end

