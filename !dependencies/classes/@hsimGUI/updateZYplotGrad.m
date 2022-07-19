function updateZYplotGrad(obj)

h = obj.ZYplotGrad;

switch obj.gradType
    case 'dynamic'
        cSection = obj.results.CrossSectionZY_grad_dxdt(obj.xIndexSelected);
        caxisLims = 'auto';
        titlestr = {'dT/dt [K/s]', sprintf('ZY @ X = %.3g %s', obj.xPosSelected, obj.results.plotsettings.units)};
        ylabelstr = 'dT/dt [K/s]';
    case 'logical'
        cSection = obj.results.CrossSectionZY_grad_dxdt(obj.xIndexSelected,obj.results.material.critCoolingRate);
        caxisLims = [0,1];
        titlestr = {'dT/dt [K/s] > dT/dt_{crit\_coolrate}', sprintf('ZY @ X = %.3g %s', obj.xPosSelected, obj.results.plotsettings.units)};
        ylabelstr = 'dT/dt [K/s] > dT/dt_{crit\_coolrate}';
end

if isempty(h) || ~ishandle(h.fig)
    h = struct();
    h.fig = figure('Name','ZY | dT/dt','Color','w', 'ToolBar', 'auto', 'NumberTitle', 'off');
    h.ax = axes(h.fig,'Box','on', 'FontSize', 11);
    
    h.surf = surface(h.ax, obj.axisdef.Zgrid_ZY, obj.axisdef.Ygrid_ZY, cSection);
    
    view(h.ax, 2)
    shading(h.ax, 'interp')
    axis(h.ax, 'image')
    colormap(h.ax, 'copper')
    h.cbar = colorbar(h.ax);
    h.cbarLabel = ylabel(h.cbar, ylabelstr, 'FontSize', 11);
    caxis(h.ax,caxisLims)
    
    h.title = title(h.ax, titlestr);
    h.xlabel = xlabel(h.ax, sprintf('z in %s',obj.results.plotsettings.units));
    h.ylabel = ylabel(h.ax, sprintf('y in %s',obj.results.plotsettings.units));
else
    h.surf.ZData = cSection;
    h.surf.CData = cSection;
    h.title.String = titlestr;
    h.cbarLabel.String = ylabelstr;
    caxis(h.ax,caxisLims)
end

obj.ZYplotGrad = h;

end

