classdef plotSettings < handle
    
    properties
        units            (1,:) char
    end
    
    properties (Dependent)
        units_scale       (1,1) double
    end
    
    methods
        
        function obj = plotSettings()
            obj.units = 'µm';
        end
        
        function set.units(obj,val)
            val = lower(val);
            allowed = {'m','mm','µm'};
            if ismember(val,allowed)
                obj.units = val;
            else
                warning('Units must be [m,mm,µm]. Defaulting to µm.')
                obj.units = 'µm';
            end
        end
        
        function val = get.units_scale(obj)
            switch obj.units
                case 'm'
                    val = 1;
                case 'mm'
                    val = 1e3;
                case 'µm'
                    val = 1e6;
            end
        end
    end
end

