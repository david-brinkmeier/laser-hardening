function updateZYplot(obj)

h = obj.ZYplot;
titlestr = sprintf('ZY @ X = %.3g %s', obj.xPosSelected, obj.results.plotsettings.units);
cSection = obj.results.CrossSectionZY(obj.xIndexSelected);


if isempty(h) || ~ishandle(h.fig)
    h = struct();
    h.fig = figure('Name','ZY | Temperature','Color','w', 'ToolBar', 'auto', 'NumberTitle', 'off');
    h.ax = axes(h.fig,'Box','on', 'FontSize', 11);
    
    h.surf = surface(h.ax, obj.axisdef.Zgrid_ZY, obj.axisdef.Ygrid_ZY, cSection);
    
    view(h.ax, 2)
    shading(h.ax, 'interp')
    axis(h.ax, 'image')
    colormap(h.ax, 'jet')
    
    h.title = title(h.ax, titlestr);
    h.xlabel = xlabel(h.ax, sprintf('z in %s',obj.results.plotsettings.units));
    h.ylabel = ylabel(h.ax, sprintf('y in %s',obj.results.plotsettings.units));
else
    h.title.String = titlestr;
    h.surf.ZData = cSection;
    h.surf.CData = cSection;
end

caxis(h.ax,obj.caxisLims);

obj.ZYplot = h;
end

