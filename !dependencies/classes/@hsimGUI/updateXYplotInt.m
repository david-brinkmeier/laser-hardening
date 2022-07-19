function updateXYplotInt(obj)

h = obj.XYplotInt;

switch obj.results.heatDistrib.type
    case 'default'
        titlestr = sprintf('P_{in} = %.3g W. Gaussian. r_{gauss} = %.3g %s',...
            obj.results.laserPowerIn,...
            obj.results.heatDistrib.gaussian_w0 * obj.results.plotsettings.units_scale,...
            obj.results.plotsettings.units);
    case 'rectangular'
        titlestr = sprintf('P_{in} = %.3g W. Rectangular. w = %.3g %s, h = %.3g %s, r_{gauss} = %.3g %s',...
            obj.results.laserPowerIn,...
            obj.results.heatDistrib.width * obj.results.plotsettings.units_scale,...
            obj.results.plotsettings.units,...
            obj.results.heatDistrib.height * obj.results.plotsettings.units_scale,...
            obj.results.plotsettings.units,...
            obj.results.heatDistrib.gaussian_w0 * obj.results.plotsettings.units_scale,...
            obj.results.plotsettings.units);
    case 'tophat'
        titlestr = sprintf('P_{in} = %.3g W. Tophat. r_{tophat} = %.3g %s, r_{gauss} = %.3g %s',...
            obj.results.laserPowerIn,...
            obj.results.heatDistrib.radius * obj.results.plotsettings.units_scale,...
            obj.results.plotsettings.units,...
            obj.results.heatDistrib.gaussian_w0 * obj.results.plotsettings.units_scale,...
            obj.results.plotsettings.units);
    case 'ring'
        titlestr = sprintf('P_{in} = %.3g W. Ring. r_{ring} = %.3g %s, r_{gauss} = %.3g %s',...
            obj.results.laserPowerIn,...
            obj.results.heatDistrib.radius * obj.results.plotsettings.units_scale, obj.results.plotsettings.units,...
            obj.results.heatDistrib.gaussian_w0 * obj.results.plotsettings.units_scale, obj.results.plotsettings.units);
    case 'brightline'
        radii = sort([obj.results.heatDistrib.radius, obj.results.heatDistrib.radius2]);        
        titlestr = {sprintf('P_{in} = %.3g W. BrightLine. P_{2}/P_{1} = %.2g.',...
            obj.results.laserPowerIn, obj.results.heatDistrib.brightL_relPwr),...
            sprintf('r_{2} = %.3g %s, r_{1} = %.3g %s, r_{gauss} = %.3g %s',...
            radii(2) * obj.results.plotsettings.units_scale, obj.results.plotsettings.units,...
            radii(1) * obj.results.plotsettings.units_scale, obj.results.plotsettings.units,...
            obj.results.heatDistrib.gaussian_w0 * obj.results.plotsettings.units_scale,...
            obj.results.plotsettings.units)};
    case 'custom'
        titlestr = sprintf('P_{in} = %.3g W. Custom. r_{gauss} = %.3g %s',...
            obj.results.laserPowerIn,...
            obj.results.heatDistrib.gaussian_w0 * obj.results.plotsettings.units_scale,...
            obj.results.plotsettings.units);
    otherwise
        titlestr = 'undefined / unknown';
end


if isempty(h) || ~ishandle(h.fig)
    h = struct();
    h.fig = figure('Name','XY | Intensity','Color','w', 'ToolBar', 'auto', 'NumberTitle', 'off');
    h.ax = axes(h.fig,'Box','on', 'FontSize', 11);
    
    h.surf = surface(h.ax, obj.axisdef.xaxis - obj.axisdef.xaxis(obj.results.heatDistrib.centerX),...
                           obj.axisdef.yaxis,...
                           obj.results.laserPowerIn .* obj.results.heatDistrib.intensity_Wcm2);
    
    view(h.ax, 2)
    shading(h.ax, 'interp')
    axis(h.ax, 'image')
    colormap(h.ax, 'parula')
    cbar = colorbar(h.ax);
    ylabel(cbar, 'Irradiated Intensity in W/cm²', 'FontSize', 11);
    
    h.xlabel = xlabel(h.ax, sprintf('x in %s',obj.results.plotsettings.units));
    h.ylabel = ylabel(h.ax, sprintf('y in %s',obj.results.plotsettings.units));
else
    h.title.String = titlestr;
    h.surf.CData = obj.results.heatDistrib.intensity;
end


h.surf.CData = obj.results.laserPowerIn .* obj.results.heatDistrib.intensity_Wcm2;
h.title = title(h.ax, titlestr);

xlim(h.ax,obj.axisdef.xaxis(obj.results.heatDistrib.validRangeX) - obj.axisdef.xaxis(obj.results.heatDistrib.centerX))
ylim(h.ax,obj.axisdef.yaxis(obj.results.heatDistrib.validRangeY))

obj.XYplotInt = h;

end