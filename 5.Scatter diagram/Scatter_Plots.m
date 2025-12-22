%% MATLAB Code for Te50-Te65 Scatter Plots
% 功能：读取16个Sheet，绘制4x4散点图，筛选GOF>0.4，高亮最优解
% Function: Read 16 sheets, draw 4x4 scatter plots, filter GOF > 0.4, highlight the optimal solution
% Structure.输入文件结构：
%   Sheet名：Te50, Te51, ..., Te65
%   B列(2): 去缩短率 (Unshortening Rate) -> Y轴
%   E列(5): 隆升高度 (Uplift Height) -> X轴
%   F列(6): GOF -> 颜色

clear; clc; close all;

% --- 1. Parameter参数设置 ---
excelFile = 'Data import.xlsx'; % Input data file name.输入资料文件名
sheetPrefix = 'Te';     % Sheet name prefix.Sheet名前缀
te_start = 50;          % Start起始Te
te_end = 65;            % Eed结束Te
num_plots = 16;         % Total diagrams总图数

% Drawing parameters绘图参数
markerSize = 50;        % Ordinary point size.普通点大小
maxMarkerSize = 100;    % The size of the optimal five-pointed star.最优点五角星大小
subplotRows = 4;
subplotCols = 4;
letters = 'abcdefghijklmnop'; % Used for subgraph numbering.用于子图编号 (a), (b)...

% Create a large canvas.创建大画布
figure('Position', [100, 50, 1400, 1000], 'Color', 'w');

% --- 2. Loop through 16 sheets.循环处理 16 个 Sheet ---
for i = 1:num_plots
    current_Te = te_start + i - 1;
    sheetName = sprintf('%s%d', sheetPrefix, current_Te);
    
    % (1) Read读取数据
    try
        % The data begins from the second row.假设第一行是标题，数据从第二行开始
        data = readtable(excelFile, 'Sheet', sheetName);
    catch
        warning('无法读取 Sheet: %s，跳过。', sheetName);
        continue;
    end
    
    % (2) 提取指定列
    % B列 (第2列): 去缩短率(Unshortening Rate) -> Y
    % E列 (第5列): 隆升高度(Uplift Height) -> X
    % F列 (第6列): GOF -> Color
    if width(data) < 6
        warning('Sheet %s 列数不足，跳过。', sheetName);
        continue;
    end
    
    raw_Y = data{:, 2}; 
    raw_X = data{:, 5};
    raw_C = data{:, 6};
    
    % (3) Data cleaning and filtering.数据清洗与筛选 (GOF >= 0.4)
    % 只要有一个是NaN就去掉，且只保留 GOF >= 0.4（Keep GOF >= 0.4）
    valid_mask = ~isnan(raw_Y) & ~isnan(raw_X) & ~isnan(raw_C) & (raw_C >= 0.4);
    
    X = raw_X(valid_mask);
    Y = raw_Y(valid_mask);
    C = raw_C(valid_mask);
    
    % (4) Create subgraph.创建子图
    subplot(subplotRows, subplotCols, i);
    
    if isempty(X)
        title(sprintf('(%s) Te=%d (No Data)', letters(i), current_Te));
        continue; 
    end
    
    % (5) Draw ordinary scatter plot.绘制普通散点 (GOF 0.4 - 1.0)
    scatter(X, Y, markerSize, C, 'filled');
    hold on;
    
    % (6) Search for and highlight the optimal solution.寻找并高亮最优解 (Max GOF)
    max_gof = max(C);
    % If multiple points reach the maximum value simultaneously, take all of them.
    % 如果有多个点同时达到最大值，取全部
    best_idx = find(C == max_gof);
    
    % Draw a red five-pointed star with a black border..绘制黑色边框的红色五角星
    scatter(X(best_idx), Y(best_idx), maxMarkerSize, 'p', ...
        'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', ...
        'LineWidth', 1.0);
    
    % (7) Chart Title.图表名称
    % 标题: (a) Te=50 (Max fit=0.xxx)
    title_str = sprintf('(%s) Te=%d (Max fit=%.3f)', letters(i), current_Te, max_gof);
    title(title_str, 'FontSize', 10, 'FontWeight', 'bold');
    
    % Label.坐标轴标签 (英文 + 单位)
    xlabel('Uplift Height (km)', 'FontSize', 8);
    ylabel('Unshortening Rate', 'FontSize', 8);
    
    % Adjustment of coordinate axis range.坐标轴范围留白调整 (自动调整略微留白)
    if range(X) == 0
        xlim([min(X)-0.5, max(X)+0.5]);
    else
        xlim([min(X)-0.1*range(X), max(X)+0.1*range(X)]);
    end
    
    % Prevent excessive compression of the Y-axis.Y轴去缩短率通常范围较小 (如 0-0.1)，防止压扁
    if range(Y) == 0
         ylim([min(Y)-0.01, max(Y)+0.01]);
    else
         ylim([min(Y)-0.1*range(Y), max(Y)+0.1*range(Y)]);
    end
    
    grid on;
    box on;
    
    % Uniform color range.统一色标范围 (0.4 到 1)
    caxis([0.4 1]);
    
    hold off;
end

% --- 3. Global setting.全局设置 ---
% Color schemes.设置配色方案 (MATLAB经典 jet: 蓝->红)
colormap(jet);

% 添加全局 Colorbar (放在右侧)
% Position: [left bottom width height]
hBar = colorbar('Position', [0.93 0.15 0.015 0.7]);
hBar.Label.String = 'Goodness of Fit (GOF)';
hBar.Label.FontSize = 11;
hBar.Label.FontWeight = 'bold';

% Adjust the spacing of subgraphs (to prevent label overlap)
% 微调子图间距 (防止标签重叠)
% If you find the text is too cramped, you can manually expand the "figure" window or use "TightInset".
% 如果发现字太挤，可以手动拉大 figure 窗口或者用 TightInset

fprintf('绘图完成！\n');