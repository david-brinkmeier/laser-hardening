function updateMeshPlot(obj)

h = obj.meshPlot;

if isempty(h) || ~ishandle(h.fig)
    h = struct();
    h.fig = figure('Name','XYZ | Meshplot','Color','w', 'ToolBar', 'auto', 'NumberTitle', 'off');
    h.ax = axes(h.fig,'Box','on', 'FontSize', 11);
    
    h.surf = surface(obj.axisdef.Xgrid_ZY(obj.axisdef.IndexCentroidX),...
                    obj.axisdef.Ygrid_ZY-0*obj.axisdef.resolutionXY,...
                    obj.axisdef.Zgrid_ZY,...
                    ones(obj.axisdef.refSize([3,1])));
    h.surf.FaceColor = 'flat';
    h.surf.FaceAlpha = 0.8;
    h.surf.LineStyle = "none";
                 
    h.patch1 = patch('FaceColor','k','LineStyle','-','FaceAlpha',0.3,'EdgeAlpha',0.0,'Visible','off');
    h.patch2 = patch('FaceColor','r','LineStyle','-','FaceAlpha',0.5,'EdgeAlpha',0.0,'Visible','off');
    h.patch3 = patch('FaceColor','m','LineStyle','-','FaceAlpha',0.7,'EdgeAlpha',0.0,'Visible','off');
    
    colormap(h.ax, 'parula')
    box(h.ax,'on')
    grid(h.ax, 'on')
    h.ax.ZDir = 'reverse';
    view(h.ax, 3)
    daspect(h.ax,[1,1,1])
    
    h.title = title(h.ax, 'placeholder');
    h.xlabel = xlabel(h.ax, sprintf('x in %s',obj.results.plotsettings.units));
    h.ylabel = ylabel(h.ax, sprintf('y in %s',obj.results.plotsettings.units));
    h.zlabel = zlabel(h.ax, sprintf('z in %s',obj.results.plotsettings.units));
end

titlestr = cell(3,1);

if obj.results.tCrit_a_POI.temp_reached
    h.surf.XData = obj.axisdef.Xgrid_ZY(obj.results.tCrit_a_POI.xIndex);
    h.surf.CData = obj.results.tCrit_a_POI.cSectionZY_log;
    h.patch1.Faces = obj.results.tCrit_a_POI.mesh.faces;
    h.patch1.Vertices = obj.results.tCrit_a_POI.mesh.verts;
    h.patch1.Visible = 'on';
    h.surf.Visible = 'on';
    
    titlestr{1} = sprintf('Hardening depth %.3g %s, area %.3g %s^{2}',...
                          obj.results.tCrit_a_POI.depth, obj.results.plotsettings.units,...
                          obj.results.tCrit_a_POI.area, obj.results.plotsettings.units);
else
    h.patch1.Visible = 'off';
    h.surf.Visible = 'off';
end

if obj.results.tMelt_POI.temp_reached
    h.patch2.Faces = obj.results.tMelt_POI.mesh.faces;
    h.patch2.Vertices = obj.results.tMelt_POI.mesh.verts;
    h.patch2.Visible = 'on';
    
    titlestr{2} = sprintf('Melt depth %.3g %s, area %.3g %s^{2}',...
                          obj.results.tMelt_POI.depth, obj.results.plotsettings.units,...
                          obj.results.tMelt_POI.area, obj.results.plotsettings.units);
else
    h.patch2.Visible = 'off';
end

if obj.results.tMelted_POI.temp_reached
    h.patch3.Faces = obj.results.tMelted_POI.mesh.faces;
    h.patch3.Vertices = obj.results.tMelted_POI.mesh.verts;
    h.patch3.Visible = 'on';
    
    titlestr{3} = sprintf('Melted depth %.3g %s, area %.3g %s^{2}',...
                          obj.results.tMelted_POI.depth, obj.results.plotsettings.units,...
                          obj.results.tMelted_POI.area, obj.results.plotsettings.units);
else
    h.patch3.Visible = 'off';
end

h.title.String = titlestr;

if strcmp(obj.limitsType,'static') && obj.results.tCrit_a_POI.temp_reached
    xlim(h.ax, obj.results.axDef.xaxis(obj.results.heatDistrib.validRangeX))
    ylim(h.ax, obj.results.axDef.yaxis(obj.results.heatDistrib.validRangeY))
    zlim(h.ax, obj.results.axDef.zaxis([1,end]))
elseif strcmp(obj.limitsType,'dynamic') && obj.results.tCrit_a_POI.temp_reached
    xlim(h.ax, [min(obj.results.tCrit_a_POI.mesh.verts(:,1)), max(obj.results.tCrit_a_POI.mesh.verts(:,1))] + obj.results.axDef.resolutionXY * [-2,2])
    ylim(h.ax, [min(obj.results.tCrit_a_POI.mesh.verts(:,2)), max(obj.results.tCrit_a_POI.mesh.verts(:,2))] + obj.results.axDef.resolutionXY * [-2,2])
    zlim(h.ax, [min(obj.results.tCrit_a_POI.mesh.verts(:,3)), max(obj.results.tCrit_a_POI.mesh.verts(:,3)) + 2*obj.results.axDef.resolutionXY])
end

obj.meshPlot = h;

end

