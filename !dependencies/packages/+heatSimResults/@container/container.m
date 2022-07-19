classdef container
        
    properties (SetAccess = private)
        plotsettings           heatSimResults.plotSettings
        axDef                  axisDef
        material               material
        
        vfeed            (1,1) double
        heatDistrib            heatInputs
        laserPowerIn     (1,1) double
        timestep         (1,1) double % timestep dx/dt! derived from feedrate and x-resolution
        Tmax             (1,1) double
        
        tempField_YXZ               (:,:,:) double % in SI units / K
        gradient_dxdt_TempField_YXZ (:,:,:) double % cooling rate in X-dir in K/s
        
        tCrit_a_POI            heatSimResults.isothermOfInterest
        tMelt_POI              heatSimResults.isothermOfInterest
        tMelted_POI            heatSimResults.isothermOfInterest
    end
        
    properties (SetAccess = private, Hidden)
    end
    
    properties (Dependent)
    end
    
    properties (Dependent, GetAccess = private)
    end
    
    methods
        function obj = container(hsim)
            if ~isa(hsim,'heatSim')
                error('heatSimResults must be called with input of class heatSim.')
            end
            obj.material = hsim.material;
            obj.plotsettings = hsim.plotsettings;
            obj.axDef = hsim.axisdef;
            
            obj.tCrit_a_POI = heatSimResults.isothermOfInterest(obj.axDef,obj.plotsettings);
            obj.tMelt_POI = heatSimResults.isothermOfInterest(obj.axDef,obj.plotsettings);
            obj.tMelted_POI = heatSimResults.isothermOfInterest(obj.axDef,obj.plotsettings);
        end
        
        function obj = update(obj,hsim,tempField_YXZ)
            if ~isa(hsim,'heatSim')
                error('heatSimResults must be called with input of class heatSim.')
            end
            if ~isequal(obj.axDef.refSize, size(tempField_YXZ,1:3))
                error('Temperature Field does not match kernel referecen array size.')
            end
            obj.tempField_YXZ = tempField_YXZ;
            obj.heatDistrib = hsim.heatDistrib;
            obj.vfeed = hsim.simopts.vfeed(hsim.simopts.index);
            obj.laserPowerIn = hsim.simopts.power;
            obj.Tmax = max(tempField_YXZ(:));
            obj.timestep = obj.axDef.resolutionXY_SI / obj.vfeed;
            
            % cooling rate dx/dt; finite diff forward difference
            obj.gradient_dxdt_TempField_YXZ = -(cat(2,tempField_YXZ(:,2:end,:), tempField_YXZ(:,end,:)) - tempField_YXZ) ./ obj.timestep;
            
            if isfinite(obj.material.tCrit_a)
                obj.tCrit_a_POI = obj.tCrit_a_POI.makeAnalysis(tempField_YXZ,...
                                                               obj.material.tCrit_a,...
                                                               obj.heatDistrib.validRangeX,...
                                                               obj.heatDistrib.validRangeY);
            end
            
            if isfinite(obj.material.tMelt)
                obj.tMelt_POI = obj.tCrit_a_POI.makeAnalysis(tempField_YXZ,...
                                                             obj.material.tMelt,...
                                                             obj.heatDistrib.validRangeX,...
                                                             obj.heatDistrib.validRangeY);
            end
            
            if isfinite(obj.material.tMelted)
                obj.tMelted_POI = obj.tCrit_a_POI.makeAnalysis(tempField_YXZ,...
                                                               obj.material.tMelted,...
                                                               obj.heatDistrib.validRangeX,...
                                                               obj.heatDistrib.validRangeY);
            end
        end
        
        function crossSection = CrossSectionZY_grad_dxdt(obj,idx,threshold)
            if idx < 1
                idx = 1;
            elseif idx > obj.axDef.refSize(2)
                idx = obj.axDef.refSize(2);
            end
            crossSection = obj.gradient_dxdt_TempField_YXZ(:,idx,:);
            crossSection = reshape(crossSection,obj.axDef.refSize([1,3])).';
            
            if nargin > 2
                nanPos = isnan(crossSection);
                crossSection = double(crossSection <= threshold);
                crossSection(nanPos) = nan;
            end
        end
        
        function crossSection = CrossSectionZY(obj,idx,threshold)
            if idx < 1
                idx = 1;
            elseif idx > obj.axDef.refSize(2)
                idx = obj.axDef.refSize(2);
            end
            crossSection = obj.tempField_YXZ(:,idx,:);
            crossSection = reshape(crossSection,obj.axDef.refSize([1,3])).';
            
            if nargin > 2
                crossSection = crossSection >= threshold;
            end
        end
        
        function crossSection = CrossSectionZX(obj,idx,threshold)
            if idx < 1
                idx = 1;
            elseif idx > obj.axDef.refSize(1)
                idx = obj.axDef.refSize(1);
            end
            crossSection = obj.tempField_YXZ(idx,:,:);
            crossSection = reshape(crossSection,obj.axDef.refSize([2,3])).';
            
            if nargin > 2
                crossSection = crossSection >= threshold;
            end
        end
        
    end

end

