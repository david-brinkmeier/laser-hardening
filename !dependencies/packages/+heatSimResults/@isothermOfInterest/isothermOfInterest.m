classdef isothermOfInterest
    
    properties (SetAccess = private, GetAccess = public)
        temp_reached    (1,1) logical
        xIndex          (1,1) double  % x "position/index" where cross section is encountered
        cSectionZY      (:,:) double  % cross section temperature field
        cSectionZY_log  (:,:) double  % logical cross section where t > t_threshold
    end
    
    properties (SetAccess = private, GetAccess = protected)
        plotsettings          heatSimResults.plotSettings
        axDef                 axisDef
    end
    
    properties (SetAccess = private, GetAccess = private)
        mesh_SI               struct % in SI units / m
        depth_SI        (1,1) double % in SI units / m
        area_SI         (1,1) double % in SI units / m²
    end
    
    properties (Dependent)
        mesh                  struct % struct of faces, vertices, colors
        depth           (1,1) double % in "units"
        area            (1,1) double % in "units^2"
    end
    
    methods
        
        function obj = isothermOfInterest(axDef,plotsettings)
            obj.axDef = axDef;
            obj.plotsettings = plotsettings;
            obj.temp_reached = false;
        end
        
        function val = get.mesh(obj)
           val = obj.mesh_SI;
           val.verts = val.verts * obj.plotsettings.units_scale;
           val.colors = val.colors * obj.plotsettings.units_scale;
        end
        
        function val = get.depth(obj)
           val = obj.depth_SI * obj.plotsettings.units_scale; 
        end
        
        function val = get.area(obj)
           val = obj.area_SI * obj.plotsettings.units_scale^2;  
        end
        
        function obj = makeAnalysis(obj,tempField_YXZ,tempThreshold,validRangeX,validRangeY)            
            % init
            obj.mesh_SI = struct('faces',[],'verts',[],'colors',[]);
            obj.depth_SI = nan;
            obj.area_SI = nan;
            obj.xIndex = nan;
            obj.cSectionZY = nan;
            obj.cSectionZY_log = nan;
            
            % continue if temp is reached and array is 3D
            obj.temp_reached = max(tempField_YXZ(:)) >= tempThreshold;
            
            if obj.temp_reached && (obj.axDef.refSize(3) > 1)
                % logical array where temp exceeds melt temp
                logArr = tempField_YXZ >= tempThreshold;
                obj.depth_SI = max(obj.axDef.Zgrid_YXZ_SI(logArr));
                
                % check if simulation domain boundaries are exceeded
                if obj.depth_SI == max(obj.axDef.zaxis_SI)
                    warning('Depth where T >= %.0f K exceeds simulation domain boundaries. Increase z-depth for accurate results!',tempThreshold)
                end
                if any(ismember([min(obj.axDef.Xgrid_YXZ_SI(logArr)), max(obj.axDef.Xgrid_YXZ_SI(logArr))], obj.axDef.xaxis_SI(validRangeX)))
                    warning('Width where T >= %.0f K exceeds simulation domain boundaries in X direction. Increase x-boundaries for accurate results!',tempThreshold)
                end
                if any(ismember([min(obj.axDef.Ygrid_YXZ_SI(logArr)), max(obj.axDef.Ygrid_YXZ_SI(logArr))], obj.axDef.yaxis_SI(validRangeY)))
                    warning('Width where T >= %.0f K exceeds simulation domain boundaries in Y direction. Increase y-boundaries for accurate results!',tempThreshold)
                end
                
                % look for maximum YZ cross section area
                
                % old implementation: cannot handle nonlinear z-vector
                %totalArea = sum(logArr,[1,3]); % cross section integral over Y and Z where cond. is met
                %[maxArea,idx] = max(totalArea); % x-location where maximum melt area is encountered
                %obj.xIdxMelt = idx;
                %obj.areaMelt_SI = maxArea * (obj.resolutionXY_SI * obj.resolutionZ_SI);
                
                % new implementation:
                % sum elementary area elements over two dimensions to determine area, works with nonlinear spaced zaxis
                totalArea = sum(logArr .* obj.axDef.dA,[1,3]);
                [obj.area_SI,obj.xIndex] = max(totalArea);
                
                % extract cross section of temperature fields and logical cross section
                obj.cSectionZY = obj.CrossSectionZY(tempField_YXZ,obj.xIndex);
                obj.cSectionZY_log = obj.CrossSectionZY(tempField_YXZ,obj.xIndex,tempThreshold);
                
                % generate isosurface mesh
                [obj.mesh_SI.faces,obj.mesh_SI.verts,obj.mesh_SI.colors] = isosurface(obj.axDef.Xgrid_YXZ_SI,...
                    obj.axDef.Ygrid_YXZ_SI,...
                    obj.axDef.Zgrid_YXZ_SI,...
                    tempField_YXZ,...
                    tempThreshold,...
                    obj.axDef.Zgrid_YXZ_SI);
            end
            
        end
        
        function crossSection = CrossSectionZY(obj,tempField_YXZ,idx,tempThreshold)
            if idx < 1
                idx = 1;
            elseif idx > obj.axDef.refSize(2)
                idx = obj.axDef.refSize(2);
            end
            crossSection = tempField_YXZ(:,idx,:);
            crossSection = reshape(crossSection,obj.axDef.refSize([1,3])).';
            
            if nargin > 3
                crossSection = crossSection >= tempThreshold;
            end
        end
        
        function crossSection = CrossSectionZX(obj,tempField_YXZ,idx,tempThreshold)
            if idx < 1
                idx = 1;
            elseif idx > obj.axDef.refSize(1)
                idx = obj.axDef.refSize(1);
            end
            crossSection = tempField_YXZ(idx,:,:);
            crossSection = reshape(crossSection,obj.axDef.refSize([2,3])).';
            
            if nargin > 3
                crossSection = crossSection >= tempThreshold;
            end
        end
        
    end
    
end

