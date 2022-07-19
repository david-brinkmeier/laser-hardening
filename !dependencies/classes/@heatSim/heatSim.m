classdef heatSim
    
    properties
        material              material
        simopts               simSettings
        axisdef               axisDef
        plotsettings          heatSimResults.plotSettings
        heatDistrib           heatInputs    % interface for setting heat Distribution
        results               heatSimResults.container
    end
       
    properties (Dependent, Access = public)
        kernelUpdateRequired        (1,1) logical % if kernels have not been calculated and/or material or simopts has changed
        nTempFieldUpdateRequired    (1,1) logical % if normalizedTempField doesn't exist OR if heatDistrib is changed OR if selected vfeed has changed
    end
    
    properties (Dependent, Access = private)
        heatScale           (1,1) double    % cline-anthony prefactor; depends on power and material props
    end
    
    properties (SetAccess = private, GetAccess = private)
        kernel                  (:,1) cell      % array of kernels, one for each vfeed
        normalizedTempField   (:,:,:) double
        lastVfeed               (1,1) double
        
        identifier_material     (1,:) char      % various unique identifiers are tracked to determine whether some part of calc requires updating
        identifier_simopts      (1,:) char
        identifier_heatDistrib  (1,:) char
    end
      
    methods
        
        function obj = heatSim()
            obj.plotsettings = heatSimResults.plotSettings();
            obj.simopts = simSettings();
            obj.material = material('');
        end
        
        function val = get.kernelUpdateRequired(obj)
           % kernel update is required if kernels are not ready (calculated)
           val = false; 
           if isempty(obj.kernel)
                val = true;
           end
           % or the material has changed
           if ~isequal(obj.identifier_material, obj.material.identifier)
               val = true;
           end
           % or if the simulation domain / options have changed
           if ~isequal(obj.identifier_simopts, obj.simopts.identifier)
               val = true;
           end
        end
        
        function val = get.nTempFieldUpdateRequired(obj)
            val = false;
            % update required if it doesnt exist...
            if isempty(obj.normalizedTempField)
                val = true;
            end
            % kernels must be convolved if heat distrib has changed...
            if ~isequal(obj.identifier_heatDistrib, obj.heatDistrib.identifier)
                val = true; 
            end
            % kernels must be convolved if selected vfeed has changed (different kernels!)
            if ~isequal(obj.lastVfeed, obj.simopts.vfeed(obj.simopts.index))
                val = true;
            end
        end
                        
        function obj = calcKernels(obj)
            % parse some stuff
            vfeed = obj.simopts.vfeed;
            
            % gen grids
            obj.axisdef = axisDef(obj.simopts,obj.plotsettings);
            
            % init heatDistribution (depends on grid specification and simopts)
            obj.heatDistrib = heatInputs(obj);
            
            % init results
            obj.results = heatSimResults.container(obj);
            
            % init kernel cell array
            obj.kernel = cell(length(vfeed),1);
            
            switch obj.simopts.heatSourceType
                % important: mirror sources work with this implementation
                % only about Z!
                % for the XY convolution mirrors about Y would yield
                % "shifting" boundaries which is incorrect 
                % -> intensity distribution would have
                % to be mirrored and then kernel size must be appropriate
                % to reflect increased array size requirements
                
                case 'point'
                    for k = 1:length(vfeed)
                        obj.kernel{k} = obj.getPTKernel(vfeed(k));
                        fprintf('%i\\%i kernels calculated (vfeed = %.3g).\n',k,length(vfeed),vfeed(k));
                    end
                case 'gaussian'
                    for k = 1:length(vfeed)
                        obj.kernel{k} = obj.getGAUSSKernel(vfeed(k));
                        if length(vfeed) > 1
                            fprintf('\n%i\\%i kernels calculated.\n\n',k,length(vfeed));
                        end
                    end
            end
            
            % kernels have been updated...reset normalizedTempField
            obj.normalizedTempField = [];
            
            % save material and simopts identifiert
            obj.identifier_material = obj.material.identifier;
            obj.identifier_simopts = obj.simopts.identifier;
        end
        
        function kernel = getPTKernel(obj,vfeed)
            % set fundamental radius to half resolution, avoids singularities due to pt source
            % only used for a select few "critical" points where problems are expected
            R = obj.simopts.resolutionXY/2;
            
            % but only calc half y domain bc of symmetry for Y = 0 centered sources
            Xgrid_loc = obj.axisdef.Xgrid_YXZ_SI(1:1+(length(obj.simopts.yaxis)-1)/2,:,:);
            Ygrid_loc = obj.axisdef.Ygrid_YXZ_SI(1:1+(length(obj.simopts.yaxis)-1)/2,:,:);
                        
            for j = 1:length(obj.simopts.heatSourceZpos)
                % generate Zgrid for different heat source Z-positions
                Zgrid_loc = obj.axisdef.Zgrid_YXZ_SI(1:1+(length(obj.simopts.yaxis)-1)/2,:,:) - obj.simopts.heatSourceZpos(j);
                radius = sqrt(Xgrid_loc.^2 + Ygrid_loc.^2 + Zgrid_loc.^2);
                
                % calculate kernels
                % todo: rewrite to eliminate vfeed loop using e^ab = (e^a)^b where b is vfeed
                kernel_current = 1./(2*pi.*radius*obj.material.kappa) .* exp((-vfeed.*(radius+Xgrid_loc))./(2*obj.material.kappa));
                
                % are there any positions where singularity due to PT source is expected? calculate these using integral
                criticalIDX = find(radius < 50e-6);
                for i = 1:length(criticalIDX)
                    fun = @(time) 1./(pi*(sqrt(pi*obj.material.kappa.*time)) .* (2*R^2 + 4*obj.material.kappa.*time))...
                        .* exp( -(Zgrid_loc(criticalIDX(i))^2./(4*obj.material.kappa.*time) +...
                        ((Xgrid_loc(criticalIDX(i))+vfeed.*time).^2+Ygrid_loc(criticalIDX(i))^2)./(2*R^2 +...
                        4*obj.material.kappa.*time) ) );
                    kernel_current(criticalIDX(i)) = integral(fun,0,inf);
                end
                
                if j == 1
                    % generate full domain (symmetry)
                    kernel = [kernel_current(:,:,:); flip(kernel_current(1:end-1,:,:),1)];
                else
                    % generate full domain (symmetry) & superimpose
                    kernel = kernel + [kernel_current(:,:,:); flip(kernel_current(1:end-1,:,:),1)];
                end
            end
            
        end
        
        function kernel = getGAUSSKernel(obj,vfeed)
            % set fundamental radius to half resolution, avoids singularities due to pt source
            R = obj.simopts.resolutionXY/2;
            
            % but only calc half y domain bc of symmetry for Y = 0 centered sources
            Xgrid_loc = obj.axisdef.Xgrid_YXZ_SI(1:1+(length(obj.simopts.yaxis)-1)/2,:,:);
            Ygrid_loc = obj.axisdef.Ygrid_YXZ_SI(1:1+(length(obj.simopts.yaxis)-1)/2,:,:);
            
            % number of to-be evaluated positions
            len = numel(Xgrid_loc);
            
            for j = 1:length(obj.simopts.heatSourceZpos)
                % generate Zgrid for different heat source Z-positions
                Zgrid_loc = obj.axisdef.Zgrid_YXZ_SI(1:1+(length(obj.simopts.yaxis)-1)/2,:,:) - obj.simopts.heatSourceZpos(j);
                
                % current kernel linear index
                kernel_current = nan(len,1);
                
                if j == 1
                    fprintf('Calculating kernels for vfeed = %.1f m/s\n',vfeed);
                else
                    fprintf('Calculating kernels [mirror source] for vfeed = %.1f m/s\n',vfeed);
                end
                    
                for i = 1:len
                    fun = @(time) 1./(pi*(sqrt(pi*obj.material.kappa.*time)) .* (2*R^2 + 4*obj.material.kappa.*time))...
                        .* exp( -(Zgrid_loc(i)^2./(4*obj.material.kappa.*time) + ((Xgrid_loc(i)+vfeed.*time).^2+Ygrid_loc(i)^2)./(2*R^2 + 4*obj.material.kappa.*time) ) );
                    kernel_current(i) = integral(fun,0,inf);
                    if ~mod(i,floor(len/15))
                        fprintf('%.1f%%\n',100*i/len);
                    end
                end
                
                % reshape into correct array size
                tmp = reshape(kernel_current,size(Xgrid_loc));
                
                if j == 1
                    % generate full domain (symmetry)
                    kernel = [tmp(:,:,:); flip(tmp(1:end-1,:,:),1)];
                else
                    % % generate full domain (symmetry) & superimpose
                    kernel = kernel + [tmp(:,:,:); flip(tmp(1:end-1,:,:),1)];
                end
                
            end
            
        end
        
        function obj = updateResult(obj)
            % can use old tempField if kernels are ready & heatDistrib haven't changed
            if obj.kernelUpdateRequired
                warning('Kernels have not been calculated or Material or SimOptions have changed. Update/calculate kernels first! Aborting.')
                return
            end
            
            if obj.nTempFieldUpdateRequired
                % init temp field; convolve kernels w/ intensity distrib
                nTempField = nan(size(obj.kernel{obj.simopts.index}));
                for i = 1:length(obj.simopts.zaxis)
                    if exist('inplaceprod','file') == 3
                        nTempField(:,:,i) = conv2fft(obj.heatDistrib.intensity,obj.kernel{obj.simopts.index}(:,:,i),'same')...
                            .* obj.heatDistrib.validConvolution;
                    else
                        nTempField(:,:,i) = conv2(obj.heatDistrib.intensity,obj.kernel{obj.simopts.index}(:,:,i),'same')...
                            .* obj.heatDistrib.validConvolution;
                    end
                end
                obj.identifier_heatDistrib = obj.heatDistrib.identifier;
                obj.lastVfeed = obj.simopts.vfeed(obj.simopts.index);
                obj.normalizedTempField = nTempField;
                finalTempField = obj.normalizedTempField .* obj.heatScale;
            
            else
                % the only thing that has changed is absorbed power, then
                % the previous temperature field scales linearly!
                finalTempField = obj.normalizedTempField .* obj.heatScale;
            end
            
            % analyze data
            obj.results = obj.results.update(obj,finalTempField);
        end
        
        function val = get.heatScale(obj)
            % prefactor / scalar outside the integral of cline-anthony equation
            val = obj.simopts.power * obj.material.absorptivity / (obj.material.rho * obj.material.cp);
        end
        
    end
end
