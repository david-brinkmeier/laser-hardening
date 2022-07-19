function updateXYplot(obj)

h = obj.XYplot;
titlestr = sprintf('Z = %.3g %s, v_{feed} = %.3g m/s, T_{melt} = %.0f K', obj.axisdef.zaxis(obj.zslice_IDX), obj.results.plotsettings.units, obj.vfeed_current, obj.mat.tMelt);

if isempty(h) || ~ishandle(h.fig)
    h = struct();
    h.fig = figure('Name','XY | Temperature','Color','w', 'ToolBar', 'none', 'NumberTitle', 'off');
    h.ax = axes(h.fig,'Box','on', 'FontSize', 11);
    
    h.surf = surface(h.ax, obj.axisdef.xaxis, obj.axisdef.yaxis, obj.results.tempField_YXZ(:,:,obj.zslice_IDX));
    
    view(h.ax, 2)
    shading(h.ax, 'interp')
    axis(h.ax, 'image')
    colormap(h.ax, 'jet')
    caxis(h.ax,[0,obj.mat.tMelt]);
    
    h.title = title(h.ax, 'init');
    h.xlabel = xlabel(h.ax, sprintf('x in %s',obj.results.plotsettings.units));
    h.ylabel = ylabel(h.ax, sprintf('y in %s',obj.results.plotsettings.units));
    
    h.colorbar = colorbar(h.ax);
    title(h.colorbar, 'Temperature in K')
        
    h.xline = xline(h.ax,obj.xPosSelected,'--w','Label',obj.xPosSelected, 'FontSize', 12);
    h.yline = yline(h.ax,obj.yPosSelected,'--w','Label',obj.yPosSelected, 'FontSize', 12);
else
    h.surf.CData = obj.results.tempField_YXZ(:,:,obj.zslice_IDX);
    h.surf.ZData = obj.results.tempField_YXZ(:,:,obj.zslice_IDX);
    h.xline.Value = obj.xPosSelected;
    h.xline.Label = obj.xPosSelected;
    h.yline.Value = obj.yPosSelected;
    h.yline.Label = obj.yPosSelected;
end

h.title.String = titlestr;
caxis(h.ax,obj.caxisLims);

set(h.fig,'WindowScrollWheelFcn', @obj.mouseWheel);
set(h.fig,'windowbuttonmotionfcn', @(hobj,event) obj.updateMousePosition());
set(h.fig,'windowbuttondownfcn', @obj.recordMousePosition)

obj.XYplot = h;
end