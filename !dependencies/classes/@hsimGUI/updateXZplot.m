function updateXZplot(obj)

h = obj.XZplot;
titlestr = sprintf('XZ @ Y = %.3g %s', obj.yPosSelected, obj.results.plotsettings.units);
cSection = obj.results.CrossSectionZX(obj.yIndexSelected);

if isempty(h) || ~ishandle(h.fig)
    h = struct();
    h.fig = figure('Name','XZ | Temperature','Color','w', 'ToolBar', 'auto', 'NumberTitle', 'off');
    h.ax = axes(h.fig,'Box','on', 'FontSize', 11);
    
    h.surf = surface(h.ax, obj.axisdef.Xgrid_ZX, obj.axisdef.Zgrid_ZX, cSection);
    
    view(h.ax, 2)
    shading(h.ax, 'interp')
    axis(h.ax, 'image')
    h.ax.YDir = 'reverse';
    colormap(h.ax, 'jet')
    
    h.title = title(h.ax, titlestr);
    h.xlabel = xlabel(h.ax, sprintf('x in %s',obj.results.plotsettings.units));
    h.ylabel = ylabel(h.ax, sprintf('z in %s',obj.results.plotsettings.units));
else
    h.title.String = titlestr;
    h.surf.ZData = cSection;
    h.surf.CData = cSection;
end

caxis(h.ax,obj.caxisLims);

obj.XZplot = h;
end

