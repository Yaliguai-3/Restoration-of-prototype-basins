%% MATLAB Code: Control Point Generator
%   The width of the basin is scaled proportionally according to Te.盆地宽度随 Te 等比缩放 (W = 215 * k)
%
% Input file structure.输入文件结构 (A-I列):
%   Row 2: Control point location.控制点位置 (Bound=0, L2=36, ..., Depo=215, Width=215)
%   Row 3: Te=23 reference.参考 (Te=23, Depo=410)
%   Row 4+: Target data (reducible; here it is written as Te = 50 - 65, just fill in Depocenter)
%   Row 4+: 目标数据 (可替换，此处写入了Te=50~65, 只需填 Depocenter)
% 输出: Output_Calculated_Points.xlsx

clear; clc;

% --- 1. File Settings.文件设置 ---
input_file = 'Input_Control_Points.xlsx';
output_file = 'Output_Calculated_Points.xlsx';

if ~isfile(input_file)
    error(['找不到文件: ', input_file]);
end

% --- 2. Reading data.读取数据 ---
try
    raw_data = readmatrix(input_file);
catch
    error('读取 Excel 失败。');
end

% --- 3. Extract key reference values.提取关键参考值 ---

% [A] Extract control points.提取控制点
% Find the rows where the value in the "Boundary" (the third column) is equal to 0.找 Boundary (第3列) == 0 的行
local_idx = find(raw_data(:, 3) == 0, 1);
if isempty(local_idx)
    error('错误：未找到 Boundary(第3列)=0 的独立坐标参考行。');
end

% Extract "the distance from the well location to the boundary".提取"井位距边界的距离" (fixed value.固定值: 36, 70, 80, 178)
% Corresponding.对应列 D(4), E(5), F(6), G(7)
local_Wells_Dist = raw_data(local_idx, 4:7); 

% Extract "Reference Basin Width".提取"参考盆地宽度" (fixed value.固定值: 215)
% Corresponding.对应列 I(9)
local_Basin_Width = raw_data(local_idx, 9);

% [B] Extract the third row Te=23. Reference.It can be changed according to the actual situation.
% [B] 提取第三行：Te=23 全局参考，可根据实际参数更改
% Te (第2列) == 23 的行
ref_idx = find(raw_data(:, 2) == 23, 1);
if isempty(ref_idx)
    error('错误：未找到 Te(第2列)=23 的参考行。');
end

% Extract "Reference Deposition Center".提取"参考沉积中心" (值: 410)
% Corresponding.对应列 H(8)
ref_Global_Depo = raw_data(ref_idx, 8);

fprintf('--- 参数检查 ---\n');
fprintf('1. 井位距边界固定距离 (D-G列): %s\n', num2str(local_Wells_Dist));
fprintf('2. Te=23 原始盆地宽度 (I列): %.2f\n', local_Basin_Width);
fprintf('3. Te=23 参考沉积中心 (H列): %.2f\n', ref_Global_Depo);
fprintf('----------------\n');

% --- 4. Extract the target calculation row.提取目标计算行 ---
% Te >= 50
target_mask = raw_data(:, 2) >= 50;
target_indices = find(target_mask);

if isempty(target_indices)
    error('未找到 Te >= 50 的数据行。');
end

target_Tes = raw_data(target_indices, 2);      % Col B (2)
target_Depos = raw_data(target_indices, 8);    % Col H (8)

% sort.排序
[target_Tes, sort_idx] = sort(target_Tes);
target_Depos = target_Depos(sort_idx);

if any(isnan(target_Depos))
    error('错误：目标行的 Depocenter (H列) 存在空值。');
end

% --- 5. Core calculation loop.核心计算循环 ---
rates = 0 : 0.01 : 0.10; % Shortening rate.去缩短率
num_rows = length(rates) * length(target_Tes);
results = zeros(num_rows, 9); % Output 9列输出
row_idx = 1;

fprintf('开始计算... (井位距离不随Te缩放，仅随Rate缩放)\n');

for r = 1:length(rates)
    current_Rate = rates(r);
    
    % Calculate the factors of the reason.计算还原因子 ( 1 / 0.99 )
    if current_Rate == 1
        restore_factor = 0; % Prevent division by zero.防止除以0，虽不常见
    else
        restore_factor = 1 / (1 - current_Rate);
    end
    
    for t = 1:length(target_Tes)
        current_Te = target_Tes(t);
        current_Depo = target_Depos(t); % Deposition center (anchor point).沉积中心 (锚点)
        
        % [Step 1] Calculate the physical parameters under the current Te.计算当前 Te 下的物理参数 (0% 状态)
        % 缩放系数 k
        scale_k = current_Depo / ref_Global_Depo;
        
        % The width of the basin.0% 状态下的盆地宽度 (缩放)
        width_0 = local_Basin_Width * scale_k;
        
        % Well location distance.0% 状态下的井位距离 (不缩放!! 保持 36, 70...)
        wells_dist_0 = local_Wells_Dist; 
        
        % [Step 2] shorting.执行去缩短 (应用 restore_factor)
        width_restored = width_0 * restore_factor;
        
        % Independent control points are scaled proportionally.独立控制点也进行缩放 (D2/0.99)
        wells_dist_restored = wells_dist_0 * restore_factor;
        
        % [Step 3] Calculate absolute coordinates.计算绝对坐标
        % Estimate the boundary.锚定 Depocenter，推算边界
        current_Boundary = current_Depo - width_restored;
        
        % Estimation of well location (boundary + distance).推算井位 (边界 + 距离)
        final_Wells = current_Boundary + wells_dist_restored;
        
        % [Step 4] save.存入结果
        % A:Rate, B:Te, C:Bound, D-G:Wells, H:Depo, I:Width
        results(row_idx, 1) = current_Rate;
        results(row_idx, 2) = current_Te;
        results(row_idx, 3) = current_Boundary;
        results(row_idx, 4:7) = final_Wells;
        results(row_idx, 8) = current_Depo;
        results(row_idx, 9) = width_restored; % Record the calculated width.记录计算出的宽度
        
        row_idx = row_idx + 1;
    end
end

% --- 6. Output导出 ---
var_names = {'Rate', 'Te', 'Boundary', 'L2', 'L62', 'J105', 'Q1', 'Depocenter', 'Calc_Width'};
out_table = array2table(results, 'VariableNames', var_names);
writetable(out_table, output_file);

fprintf('计算完成！文件已保存至: %s\n', output_file);