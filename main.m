clc
close all
clearvars

%% INFO

% Calculation is based on formulas from "H. E. Cline and T. R. Anthony"
% "Heat treating and melting material with a scanning laser or electron beam"
% https://doi.org/10.1063/1.324261
% Eq. (5) and Eq. (6). Note that Eq. (6) has multiple errors.
%
% Correct variant of Eq. (6) can be found in 
% H.S. Carslaw, J.C. Jaeger, Conduction of Heat in Solids (Oxford University Press, Oxford, 1959)
% p. 267, Eq. (1).
%
% Key formulas are implemented in method "getGAUSSKernel" and "getPTKernel" of class "heatSim".
% The heatkernels are normalized variants of the temperature distribution, by applying the scalar prefactor "heatScale"
% the actual temperature distribution results which can be analyzed.
% The formulas are expressed slightly differently for more convenient numerical implementation.
% 
% Basic algorithm is: 
% Temperature Distribution = (Intensity) x (HeatScale*HeatKernel) where x is convolution operator.
% Intensity in turn is normalized(HeatDistribution x Gaussian spread)

addpath(genpath('!dependencies'))

%% SETUP SIMULATION
% init heat sim
hsim = heatSim();

% init material, e.g. known material cf53
hsim.material = material('cf53');
% else init e.g. 
% hsim.material = material('myMaterial');
% (and set thermophysical properties!)

% set lateral resolution
hsim.simopts.resolutionXY = 10e-6;
% set lateral simulation domain in SI units
hsim.simopts.xrange = [-2600,2200]*1e-6; % in vfeed direction
hsim.simopts.yrange = 2400*1e-6; % perpendicular to feed direction

% set vertical resolution (depth) in SI units (only used if zrange only defines start/end boundary)
hsim.simopts.resolutionZ = 5e-6;
%hsim.zrange = [0,30]*1e-6; % e.g. evaluate surface and another position
hsim.simopts.zrange = [0:3:45,50:10:500]*1e-6; % explicitly define all positions

% if material is not half-infinite, define material thickness using zboundary (applies mirror sources)
% hsim.simopts.zBoundary = 200e-6;

% select simulation algorithm, "point" or "gaussian". "point" is
% recommended for speed, singularities are avoided by using area heat sources where necessary
% hsim.simopts.heatSourceType = 'point';

% specifify feed rates in SI units, i.e. m/s.
hsim.simopts.vfeed = [1,5,10,50,100,500,1000,2000]*1e-3;

%% Calculate Heatkernels
hsim = hsim.calcKernels;

info = whos('hsim');
fprintf('Required size: %.2g Gb\n',info.bytes * 1e-9)

%% configure heat source and evaluate

% ///
% this is the main code section where inputs are modified and results are
% evaluated! Changing only the laser power is numerically most efficient
% because the result is only a scaled temperature field which needs to be
% analyzed. This is fast if a normalized temperature field exists from a
% previous iteration using the same Intensity distribution and feed rate.
% ///

% select a heat distribution: "default", "rectangular", "tophat", "ring", "brightline", "custom"
% hsim.heatDistrib.type = 'default'; % point source / gaussian
% hsim.heatDistrib.type = 'rectangular'; % rectangular tophat
hsim.heatDistrib.type = 'tophat'; % round tophat
% hsim.heatDistrib.type = 'ring'; %
% hsim.heatDistrib.type = 'brightline'; % inner ring + outer ring section w/ adjustable relative power distribution

% Adjust settings for built-in heat distributions
% hsim.heatDistrib.width = hsim.heatDistrib.resolutionXY*85; % rectangular
% hsim.heatDistrib.height = hsim.heatDistrib.resolutionXY*45; % rectangular
hsim.heatDistrib.radius = 1000/2*1e-6; % tophat, ring, brightline r1
% hsim.heatDistrib.radius2 = 600/2*1e-6; % brightline r2
% hsim.heatDistrib.brightL_relPwr = 1.5; % brightline relative power distribution

% heat is always spread out over some gaussian width, gaussian_w0 = 0 means actual point source
% w0 refers to ISO11146 / LASER Definition of beam radius
hsim.heatDistrib.gaussian_w0 = 3*hsim.heatDistrib.resolutionXY;

% set irradiated power in W
hsim.simopts.power = 300;

% select feed rate using index
hsim.simopts.index = 3;

% update the result!
hsim = hsim.updateResult();

% and plot
% plot settings upon first call use defaults, just run this code section twice
if exist('plt','var')
    % limitsType affects meshPlot
    % plt.limitsType = 'static';
    plt.limitsType = 'dynamic';
    
    % adjust colorbar limits based on min/max temp for z ~= 0 / surface
    plt.caxisType = 'static';
%     plt.caxisType = 'dynamic';
    
    % show actual gradient ("dynamic") or only evaluate "is greater than crit cooling rate or not?!"
    plt.gradType = 'dynamic';
%     plt.gradType = 'logical';
    
    plt = hsimGUI(hsim.results, hsim.simopts, plt);
else
    plt = hsimGUI(hsim.results, hsim.simopts);
end
