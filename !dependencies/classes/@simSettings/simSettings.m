classdef simSettings
    
    properties
        heatSourceType  (1,:) char          % point or gaussian; point yields singularities at surface
        
        xrange          (1,2) double        % start and end, in m
        yrange          (1,1) double        % symmetric about zero, in m
        zrange          (1,:) double        % start and end, in m OR vector explicitly defining positions
        zBoundary       (1,1) double        % if < inf then material thickness is limited -> add mirror heat source!
        resolutionXY    (1,1) double        % in m
        resolutionZ     (1,1) double        % in m
        vfeed           (:,1) double        % vfeed vector
        power           (1,1) double        % power in W
    end
    
    properties (Dependent, GetAccess = public)
        index               (1,1) uint32    % selected vfeed index
        
        xaxis               (1,:) double
        yaxis               (1,:) double
        zaxis               (1,:) double
        centerX             (1,1) double
        centerY             (1,1) double
        
        heatSourceZpos      (1,:) double
    end
    
    properties (SetAccess = private)
        identifier          (1,:) char
        report              (1,1) logical
    end
    
    properties (Access = private)
        index_prv           (1,1) uint32
    end
    
    methods
        
        function obj = simSettings()
           obj.heatSourceType = 'point';
           obj.report = false;
           
           obj.power = 1;
           obj.xrange = [-200,100]*1e-6;
           obj.yrange = 100*1e-6;
           obj.zrange = 0*1e-6;
           obj.zBoundary = inf;
           obj.resolutionXY = 5e-6;
           obj.resolutionZ = 5e-6;
           obj.vfeed = 0.5;
           obj.index = 1;
           
           obj.report = true;
        end
        
        function obj = set.index(obj,val)
           if val < 1
               val = 1;
           elseif val > length(obj.vfeed)
               val = length(obj.vfeed);
           end
           obj.index_prv = val;
        end
        
        function val = get.index(obj)
            val = obj.index_prv;
        end
        
        function val = get.heatSourceZpos(obj)
           if isfinite(obj.zBoundary)
               % surface heat source + its mirror about zBoundary
               val = [0,2*obj.zBoundary];
           else
               % only surface heating
               val = 0;
           end
        end
        
        function obj = set.heatSourceType(obj,val)
            val = lower(val);
            allowed = {'point','gaussian'};
            if ~ismember(val,allowed)
                warning('Invalid type, using "point".')
                fprintf('Allowed types are:\n')
                fprintf('"%s"\n',allowed{:})
                val = 'point';
            end
            
            if ~isequal(obj.heatSourceType,val)
                obj.heatSourceType = val;
                obj = obj.updateID();
            end
        end

        function obj = set.xrange(obj,val)
            if ~isequal(obj.xrange,val) 
                obj.xrange = val;
                obj = obj.updateID();
            end
        end
        
        function obj = set.yrange(obj,val)
            val = abs(val);
            if ~isequal(obj.yrange,val)
                obj.yrange = abs(val);
                obj = obj.updateID();
            end
        end
        
        function obj = set.zrange(obj,val)
            if ~isequal(obj.zrange,val)
                obj.zrange = val;
                obj = obj.updateID();
            end
        end
        
        function val = get.zrange(obj)
            val = obj.zrange(obj.zrange < obj.zBoundary);
        end
        
        function obj = set.vfeed(obj,val)
            val = unique(abs(val));
            if ~isequal(obj.vfeed,val)
                obj.vfeed = val;
                obj = obj.updateID();
            end
        end
        
        function obj = set.resolutionXY(obj,val)
            if isfinite(val) && ~isequal(obj.resolutionXY,val)
                obj.resolutionXY = abs(val);
                obj = obj.updateID();
            end
        end
        
        function obj = set.resolutionZ(obj,val)
            if isfinite(val) && ~isequal(obj.resolutionZ,val)
                obj.resolutionZ = abs(val);
                obj = obj.updateID();
            end
        end
        
        function val = get.xaxis(obj)
            val = obj.xrange(1):obj.resolutionXY:obj.xrange(2);
            val(abs(val) < eps) = 0;
            if ~bitget(length(val),1)
                % then length iseven, add one more
                val = [val,val(end)+obj.resolutionXY];
            end
        end
        
        function val = get.yaxis(obj)
            val = -obj.yrange:obj.resolutionXY:obj.yrange;
            if ~bitget(length(val),1)
                % then length iseven, add one more
                val = [val,val(end)+obj.resolutionXY];
            end
        end
        
        function val = get.zaxis(obj)
            if length(obj.zrange) == 2
                val = obj.zrange(1):obj.resolutionZ:obj.zrange(2);
            else
                % user provided z-vector specifying positions
                val = unique(obj.zrange);
            end
        end
        
        function val = get.centerY(obj)
           val = (length(obj.yaxis)+1)/2;
        end
        
        function val = get.centerX(obj)
            val = (length(obj.xaxis)+1)/2;
        end
        
        function obj = updateID(obj)
           obj.identifier = char(java.util.UUID.randomUUID);
           obj.reportSimDomain()
        end
        
        function reportSimDomain(obj)
            clc
            if obj.report && ~isempty(obj.xaxis) && ~isempty(obj.xaxis) && ~isempty(obj.xaxis)
                fprintf('Simulation domain is XYZ = %i*%i*%i @ %i feedrates.\n',...
                        length(obj.xaxis),length(obj.yaxis),length(obj.zaxis),length(obj.vfeed))
            end
        end
        
    end
    
end

