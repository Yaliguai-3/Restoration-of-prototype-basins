
function [calcW,calcX]=TAFIPlot2D(data, plotx,loadposdata,color,figurepanel)
%[flexcolor]= calcindex(w,plotx, xmin,spacing,xmax)

% % Read plot position window data
Nxplotmax = getappdata(0,'Nxplotmax');
Nxplotmin = getappdata(0,'Nxplotmin');



%Reading imported flexure and gravity data, and the color used to plot them
%
f_constraint = getappdata(0,'f_constraint');
g_constraint = getappdata(0,'g_constraint');
f_color = getappdata(0,'f_color');
g_color = getappdata(0,'g_color');


%generating new position data
x_new = plotx + loadposdata;

calcX = x_new(fix(Nxplotmin):fix(Nxplotmax))/1000;

%Set calcw to be used with "Data Shift" panel, if needed
setappdata(0,'calcX',calcX);

% If figurepanel variable is 1, plot flexure curve. If figurepanel variable
% is 2, plot gravity curve.
if figurepanel == 1
%     figure;
%     hold on;
%     grid on;
%     set(gca, 'GridLineStyle', '-');
% 
%     % 计算 flexural deflection，并转换单位 (km/km)
     calcW = data(fix(Nxplotmin):fix(Nxplotmax)) / 1000;
     setappdata(0,'calcX',calcX);
%     % 绘制主曲线
%     plot(calcX, calcW, '-k', 'LineWidth', 2, 'Color', color);
%     % 创建数据矩阵
% dataToSave = [calcX(:), calcW(:)]; % 转换为列向量，确保正确存储
% 
% % 指定 Excel 文件名
% filename = 'Flexural_Deflection_Data.xlsx';
% 
% % 指定工作表名称（可选）
% sheet = 'Sheet1';
% 
% % 指定起始单元格（可选）
% range = 'A1';
% 
% % 写入 Excel 文件
% writematrix(dataToSave, filename, 'Sheet', sheet, 'Range', range);
    % 如果有挠曲约束数据，则绘制散点
%     if ~isempty(f_constraint)
%         plot(f_constraint(:,1), f_constraint(:,2), '.', 'Color', f_color, 'MarkerSize', 10);
%     end
% 
%     % 设置坐标轴属性
%     set(gca, 'XaxisLocation', 'origin');
%     set(gca, 'YaxisLocation', 'origin');
%     set(gca, 'YDir', 'reverse'); % 反转 Y 轴方向
%     xlabel('Distance (km)');
%     ylabel('Flexural Deflection (km)');


else
%     figure
%     hold on
%     grid on
%     set(gca, 'GridLineStyle', '-');
    %plot is km/mGal units. Gravity was calculated on the basis of flexural
    % deflection plot window extent. 
    %plot(calcX,data,'LineWidth',2,'Color',color);
    % 创建数据矩阵
% dataToSave = [calcX(:), data(:)]; % 转换为列向量，确保正确存储
% 
% % 指定 Excel 文件名
% filename = 'Flexural_Deflection_Data.xlsx';
% 
% % 指定工作表名称（可选）
% sheet = 'Sheet1';
% 
% % 指定起始单元格（可选）
% range = 'A1';
% 
% % 写入 Excel 文件
% writematrix(dataToSave, filename, 'Sheet', sheet, 'Range', range);
%        if ~isempty(g_constraint)
%             plot(g_constraint(:,1),g_constraint(:,2),'.','Color',g_color);
%         end
%     set(gca,'XaxisLocation','origin');
%     set(gca,'YaxisLocation','origin');
%     ylabel ('Gravity (mGal)');    
    
end