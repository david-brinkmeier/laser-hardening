classdef heatInputs < handle
    % defines heat input array / distribution
    
    properties (SetAccess = protected)
        refSize         (1,2) double    % array size
        resolutionXY    (1,1) double    % lateral resolution
        Xgrid           (:,:) double
        Ygrid           (:,:) double
        centerX         (1,1) double
        centerY         (1,1) double
        
        gaussian_profile    (:,:) double
        validConvolution    (:,:) double
        validRangeX         (1,2) double
        validRangeY         (1,2) double
        
        identifier      (1,:) char
    end
    
    properties (Dependent) 
       heatInputsArray  (:,:) double
       intensity        (:,:) double
       intensity_Wcm2   (:,:) double % 1W / cm²; must be multiplied with actual irradiated power!
       
       xaxis            (1,:) double % for plotting
       yaxis            (1,:) double % for plotting
       
       % user interface below
       userArray       (:,:) double    % for custom heat distributions
       type            (1,:) char      % default, tophat, rectangular, custom
       xOffset         (1,1) int32     % shifts heat distribution vertically
       width           (1,1) double    % applies to rectangular
       height          (1,1) double    % applies to rectangular
       radius          (1,1) double    % applies to tophat / disc and ring and brightline inner radius
       radius2         (1,1) double    % applies to brightline outer radius
       brightL_relPwr  (1,1) double    % relative intensity of "outer ring section" vs inner ring. Equal to "tophat" for brightL_relInt = 1;
       gaussian_w0     (1,1) double    % heatDistrib convolves w/ gaussian of this size (optional)
    end
    
    properties (Access = private)
       isReady              (1,1) logical
       
       userArray_prv        (:,:) double
       type_prv             (1,:) char
       xOffset_prv          (1,1) int32
       width_prv            (1,1) double
       height_prv           (1,1) double
       radius_prv           (1,1) double
       radius2_prv          (1,1) double
       brightL_relPwr_prv   (1,1) double
       gaussian_w0_prv      (1,1) double
       
       heatInputsArrayInternal (:,:) double
    end
    
    methods
        function obj = heatInputs(hsim)
            if ~isa(hsim,'heatSim')
                error('heatInputs must be initialized with input of class heatSim.')
            end
            obj.isReady = false;
            obj.type = 'default';
            obj.brightL_relPwr = 2;
            obj.xOffset = 0;
            
            obj.refSize = hsim.axisdef.refSize(1:2);
            obj.resolutionXY = hsim.axisdef.resolutionXY_SI;
            obj.centerX = hsim.simopts.centerX;
            obj.centerY = hsim.simopts.centerY;

            obj.Xgrid = hsim.axisdef.Xgrid_YXZ_SI(:,:,1) - hsim.axisdef.xaxis_SI(obj.centerX);
            obj.Ygrid = hsim.axisdef.Ygrid_YXZ_SI(:,:,1);
            
            obj.isReady = true;
            obj.gaussian_w0 = obj.resolutionXY;
            obj.updateHeatDistrib();
        end
        
        function set.userArray(obj,val)
            lastArray = obj.userArray_prv;
            val = abs(double(val));
            [szy,szx] = size(val);
            if ~isequal([szy,szx], obj.refSize)
                warning('User array is of size X = %i, Y = %i, but simulation domain requires array of size X = %i, Y = %i. Ignoring user array, defaulting to Point/Gaussian.',obj.refSize(2),obj.refSize(1),szx,szy)
                obj.userArray_prv = nan;
            else
                if sum(val(:)) > 0
                    obj.userArray_prv = val;
                else
                    warning('User array does not contain energy.')
                    obj.userArray_prv = nan;
                end
            end
            
            if ~isequal(lastArray, obj.userArray)
                obj.updateHeatDistrib();
            end
        end
        
        function val = get.userArray(obj)
            val = obj.userArray_prv;
        end
        
        function set.type(obj,val)
           val = lower(val);
           allowed = {'default','rectangular','tophat','ring','brightline','custom'};
            if ~ismember(val,allowed)
                warning('Invalid type, using "default".')
                fprintf('Allowed types are:\n')
                fprintf('"%s"\n',allowed{:})
                val = 'default';
            end
            
            if ~isequal(val,obj.type)
                obj.type_prv = val;
                obj.updateHeatDistrib();
            end
        end
        
        function val = get.type(obj)
            val = obj.type_prv;
        end
        
        function set.width(obj,val)
            val = round(val/obj.resolutionXY) * obj.resolutionXY;
            if val < obj.resolutionXY
                warning('width must be at least one domain unit (XY resolution). Limiting.')
                val = obj.resolutionXY;
            end
            
            maxSize = obj.resolutionXY * ((obj.refSize(2)-1)/2);
            if val > maxSize
                warning('width must not exceed half horizontal domain size. Limiting.')
                val = maxSize;
            end
            
            if ~isequal(val,obj.width)
                obj.width_prv = val;
                obj.updateHeatDistrib();
            end
        end
        
        function val = get.width(obj)
            val = obj.width_prv;
        end
        
        function set.height(obj,val)
            val = round(val/obj.resolutionXY) * obj.resolutionXY;
            if val < obj.resolutionXY
                warning('width must be at least one domain unit (XY resolution). Limiting.')
                val = obj.resolutionXY;
            end
            
            % enforce that height corresponds to odd number of vertical pixels
            val = (2*floor((val/obj.resolutionXY)/2)+1) * obj.resolutionXY;
            
            maxSize = obj.resolutionXY * (1+((obj.refSize(1)-1)/2));
            if val > maxSize
                warning('height must not exceed half vertical domain size. Limiting.')
                val = maxSize;
            end
            
            if ~isequal(obj.height,val)
                obj.height_prv = val;
                obj.updateHeatDistrib();
            end
        end
        
        function val = get.height(obj)
            val = obj.height_prv;
        end
        
        function set.radius(obj,val)
            % disk radius for round tophat
            maxSize = obj.resolutionXY * (1+((obj.refSize(1)-1)/4));
            if val > maxSize
                warning('disk / tophat / brightline radius must not exceed quarter vertical domain size. Limiting.')
                val = maxSize;
            end
            
            if ~isequal(obj.radius,val)
                obj.radius_prv = val;
                obj.updateHeatDistrib();
            end
        end
        
        function val = get.radius(obj)
           val = obj.radius_prv; 
        end
        
        function set.radius2(obj,val)
            % disk radius for round tophat
            maxSize = obj.resolutionXY * (1+((obj.refSize(1)-1)/4));
            if val > maxSize
                warning('disk / tophat / brightline radius must not exceed quarter vertical domain size. Limiting.')
                val = maxSize;
            end
            
            if ~isequal(obj.radius2,val)
                obj.radius2_prv = val;
                obj.updateHeatDistrib();
            end
        end
        
        function val = get.radius2(obj)
           val = obj.radius2_prv; 
        end
        
        function set.brightL_relPwr(obj,val)
            val = abs(val);
            if val > 1e6
                val = 1e6;
            end
            
            if ~isequal(obj.brightL_relPwr,val)
                obj.brightL_relPwr_prv = val;
                obj.updateHeatDistrib();
            end
        end
        
        function val = get.brightL_relPwr(obj)
           val = obj.brightL_relPwr_prv; 
        end
        
        function set.xOffset(obj,val)
           val = round(val);
           maxOffset = (obj.refSize(2)-1)/2 - ceil(obj.gaussian_w0/obj.resolutionXY);
           if abs(val) > maxOffset
               warning('xOffset exceeds boundaries. Limiting.')
               val = sign(val)*maxOffset;
           end
           val = int32(val);
           
           if ~isequal(obj.xOffset,val)
               obj.xOffset_prv = int32(val);
               obj.updateHeatDistrib();
           end
        end
        
        function val = get.xOffset(obj)
           val = obj.xOffset_prv; 
        end
        
        function val = get.xaxis(obj)
           val = obj.Xgrid(1,:);
        end
        
        function val = get.yaxis(obj)
           val = obj.Ygrid(:,1).';
        end
        
        function val = get.heatInputsArray(obj)
           val = obj.heatInputsArrayInternal; 
        end
        
        function val = get.intensity(obj)
            val = conv2(obj.heatInputsArray,obj.gaussian_profile,'same');
        end
        
        function val = get.intensity_Wcm2(obj)
           val = obj.intensity ./ ((obj.resolutionXY*100)^2); % in W/cm². Must be multiplied with actual irradiated / incident power!
        end
        
        function set.gaussian_w0(obj,val)
            val = abs(val);
            if val == 0
                val = eps;
            end
            maxSz = (obj.refSize(1)-1)/2 * obj.resolutionXY;
            if val > maxSz
                warning('Gaussian w0 must not exceed half vertical domain size. Limiting to half domain size.')
                val = maxSz;
            end
            
            if ~isequal(obj.gaussian_w0,val)
                obj.gaussian_w0_prv = val;
                obj.updateGaussian();
            end
        end
        
        function val = get.gaussian_w0(obj)
            val = obj.gaussian_w0_prv;
        end
        
        function updateHeatDistrib(obj)
            if ~obj.isReady
                return
            end
            
            hDistrib = zeros(obj.refSize);
            
            switch obj.type
                case 'default'
                   hDistrib(obj.centerY,obj.centerX + obj.xOffset) = 1;
                   
                case 'rectangular'
                    widthPx = obj.width/obj.resolutionXY;
                    xRange = (obj.centerX + obj.xOffset - widthPx + 1) : (obj.centerX + obj.xOffset);
                    
                    heightPx = obj.height/obj.resolutionXY - 1;
                    yRange = (obj.centerY - heightPx/2) : (obj.centerY + heightPx/2);
                    
                    hDistrib(yRange,xRange) = 1;
                    
                case 'tophat'
                    hDistrib = double((obj.Xgrid - double(obj.xOffset)*obj.resolutionXY).^2 +...
                                      (obj.Ygrid - 0).^2 ...
                                       <= obj.radius^2);
                                   
                case 'brightline'
                    radii = sort([obj.radius, obj.radius2]);
                    if radii(2) < radii(1)+obj.resolutionXY
                        radii(2) = radii(1)+obj.resolutionXY;
                    end

                    inner = (obj.Xgrid - double(obj.xOffset)*obj.resolutionXY).^2 +...
                            (obj.Ygrid - 0).^2 ...
                            <= radii(1)^2;
                    outer = (obj.Xgrid - double(obj.xOffset)*obj.resolutionXY).^2 +...
                            (obj.Ygrid - 0).^2 ...
                            <= radii(2)^2;
                    outer = double(outer & ~inner);
                    outer = outer / (sum(outer(:)) / sum(inner(:)));
                    % outer and inner now contain equal energy
                        
                    hDistrib = outer.*obj.brightL_relPwr + double(inner);
                                   
                case 'ring'
                    hDistrib = (obj.Xgrid - double(obj.xOffset)*obj.resolutionXY).^2 + (obj.Ygrid - 0).^2;
                    hDistrib = (hDistrib >= (obj.radius-obj.resolutionXY).^2) & (hDistrib <= (obj.radius+obj.resolutionXY).^2);
                    
                case 'custom'
                    if ~isequal(size(obj.userArray),obj.refSize) || (sum(obj.userArray(:)) == 0)
                        obj.type = 'default';
                        hDistrib(obj.centerY,obj.centerX + obj.xOffset) = 1;
                    else
                        hDistrib = obj.userArray;
                    end
                    
            end
            
            hDistrib = hDistrib ./ sum(hDistrib(:)); % conserve energy
            obj.heatInputsArrayInternal = hDistrib;
            obj.updateValidField(); % update range where conv yields valid results
            obj.updateID();
        end
        
        function updateGaussian(obj)
            % generates rotationally symmetric gaussian to be convolved w/ heatDistrib
            % w0 = 2*sigma / laser iso11146 definition
            profile = exp(-2*((sqrt(obj.Xgrid(:,:,1).^2 + obj.Ygrid(:,:,1).^2)).^2 ./ obj.gaussian_w0^2));
            profile(profile < max(profile(:))/100) = 0; % roundoff errs -> 0
            obj.gaussian_profile = profile./sum(profile(:)); % conserve energy
            obj.updateValidField(); % update range where conv yields valid results
            obj.updateID();
        end
        
        function updateValidField(obj)
            % this helper array determines where the convolved temperature
            % field yields valid values (i.e. zones where convolved
            % fields overlap)
            if isempty(obj.heatInputsArray)
                return
            end
            
            validX = sum(obj.intensity,1);
            firstValidX = find(validX,1,'last') - obj.centerX + 1;
            if firstValidX < 1, firstValidX = 1; end
            lastValidX = obj.centerX + find(validX,1,'first') - 1;
            if lastValidX > obj.refSize(2), lastValidX = obj.refSize(2); end
            obj.validRangeX = [firstValidX,lastValidX];
            
            validY = sum(obj.intensity,2);
            firstValidY = find(validY,1,'last') - obj.centerY + 1;
            if firstValidY < 1, firstValidY = 1; end
            lastValidY = obj.centerY + find(validY,1,'first') - 1;
            if lastValidY > obj.refSize(1), lastValidY = obj.refSize(1); end
            obj.validRangeY = [firstValidY,lastValidY];
            
            %fprintf('first validX %i, last validX %i\n',firstValidX,lastValidX)
            %fprintf('first validY %i, last validY %i\n',firstValidY,lastValidY)
            
            validField = nan(obj.refSize);
            validField(obj.validRangeY(1):obj.validRangeY(2), obj.validRangeX(1):obj.validRangeX(2)) = 1;
            obj.validConvolution = validField;
        end
        
        function updateID(obj)
            obj.identifier = char(java.util.UUID.randomUUID);
        end
        
    end
end











