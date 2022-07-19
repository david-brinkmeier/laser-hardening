classdef material
    
    properties
        name                (1,:) char   % name
        rho                 (1,1) double % density [kg/m³]
        lambda              (1,1) double % heat conductivity [W/m*K]
        cp                  (1,1) double % specific heat capacity [J/kg*K]
        hs                  (1,1) double % melt enthalpy in J/kg
        
        absorptivity        (1,1) double % laser absorptivity - 0 to 1
        tCrit_a             (1,1) double % e.g. hardening temperature
        tCrit_b             (1,1) double % placeholder for 2nd temp of interest
        tMelt               (1,1) double % melt temperature
        critCoolingRate     (1,1) double
    end
    
    properties (SetAccess = protected)
        identifier          (1,:) char
    end
    
    properties (Dependent)
        kappa               (1,1) double % thermal diffusivity [m²/s]
        tMelted             (1,1) double % tMelt + hs / cp --> beyond this temperature / energy actual melt is expected
    end
    
    methods
        
        function obj = material(name)
           if ischar(name) || isstring(name)
               obj = obj.knownMaterial(name);
           else
               obj = obj.knownMaterial('placeholder');
           end
           obj = obj.updateID();
        end
        
        function val = get.kappa(obj)
            val = obj.lambda/(obj.rho*obj.cp);
        end
        
        function val = get.tMelted(obj)
            val = obj.tMelt + obj.hs/obj.cp;
        end
        
        function obj = set.name(obj,val)
           if ischar(val) || isstring(val)
               obj.name = char(val);
           end
        end
        
        function obj = set.rho(obj,val)
           if ~isequal(obj.rho,val)
              obj.rho = val;
              obj = obj.updateID();
           end
        end
        
        function obj = set.lambda(obj,val)
           if ~isequal(obj.lambda,val)
              obj.lambda = val;
              obj = obj.updateID();
           end
        end
        
        function obj = set.cp(obj,val)
           if ~isequal(obj.cp,val)
              obj.cp = val;
              obj = obj.updateID();
           end
        end
        
        function obj = set.hs(obj,val)
           if ~isequal(obj.hs,val)
              obj.hs = val;
              obj = obj.updateID();
           end
        end
        
        function obj = set.absorptivity(obj,val)
            if (0 <= val) && (val <= 1)
                obj.absorptivity = val;
            else
                error('Absorptivity must be in range 0 to 1.')
            end
        end
        
        function obj = set.tCrit_a(obj,val)
            obj.tCrit_a = abs(val);
        end
        
        function obj = set.tCrit_b(obj,val)
            obj.tCrit_b = abs(val);
        end
        
        function obj = set.tMelt(obj,val)
            obj.tMelt = abs(val);
        end
        
        function obj = knownMaterial(obj,name)
            switch lower(name)
                case 'cf53'
                    obj.name = 'cf53';
                    obj.rho = 7830;
                    obj.lambda = 45;
                    obj.cp = 452;
                    obj.absorptivity = 0.4;
                    obj.tCrit_a = 996;
                    obj.tCrit_b = nan;
                    obj.tMelt = 1700;
                    obj.critCoolingRate = -260; 
                    obj.hs = 268e3;
                otherwise
                    obj.name = name;
                    obj.rho = nan;
                    obj.lambda = nan;
                    obj.cp = nan;
                    obj.absorptivity = 1;
                    obj.tCrit_a = nan;
                    obj.tCrit_b = nan;
                    obj.tMelt = nan;
                    obj.critCoolingRate = nan;
                    obj.hs = nan;
            end
        end
        
        function obj = updateID(obj)
            obj.identifier = char(java.util.UUID.randomUUID);
        end
        
    end
    
end

