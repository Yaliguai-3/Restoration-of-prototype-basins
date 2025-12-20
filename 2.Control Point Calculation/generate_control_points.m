%% MATLAB Code: Control Point Generator v8 (Corrected Logic)
% 功能：严格遵循用户指定的几何恢复逻辑
%   1. 盆地宽度随 Te 等比缩放 (W = 215 * k)
%   2. 井位距边界距离保持现今值不变 (d = 36)
%   3. 去缩短处理对上述两者同时生效 ( / (1-Rate) )
%
% 输入文件结构 (A-I列):
%   Row 2: 独立坐标系 (Bound=0, L2=36, ..., Depo=215, Width=215)
%   Row 3: Te=23 参考 (Te=23, Depo=410)
%   Row 4+: 目标数据 (Te=50~65, 只需填 Depocenter)
%
% 输出: Output_Calculated_Points.xlsx

clear; clc;

% --- 1. 文件设置 ---
input_file = 'Input_Control_Points.xlsx';
output_file = 'Output_Calculated_Points.xlsx';

if ~isfile(input_file)
    error(['找不到文件: ', input_file]);
end

% --- 2. 读取数据 ---
% 使用 readmatrix 读取纯数值，避免表头问题
try
    raw_data = readmatrix(input_file);
catch
    error('读取 Excel 失败。');
end

% --- 3. 提取关键参考值 ---

% [A] 提取第二行：独立坐标系参考
% 逻辑：找 Boundary (第3列) == 0 的行
local_idx = find(raw_data(:, 3) == 0, 1);
if isempty(local_idx)
    error('错误：未找到 Boundary(第3列)=0 的独立坐标参考行。');
end

% 提取"井位距边界的距离" (固定值: 36, 70, 80, 178)
% 对应列 D(4), E(5), F(6), G(7)
local_Wells_Dist = raw_data(local_idx, 4:7); 

% 提取"参考盆地宽度" (固定值: 215)
% 对应列 I(9)
local_Basin_Width = raw_data(local_idx, 9);

% [B] 提取第三行：Te=23 全局参考
% 逻辑：找 Te (第2列) == 23 的行
ref_idx = find(raw_data(:, 2) == 23, 1);
if isempty(ref_idx)
    error('错误：未找到 Te(第2列)=23 的参考行。');
end

% 提取"参考沉积中心" (值: 410)
% 对应列 H(8)
ref_Global_Depo = raw_data(ref_idx, 8);

fprintf('--- 参数检查 ---\n');
fprintf('1. 井位距边界固定距离 (D-G列): %s\n', num2str(local_Wells_Dist));
fprintf('2. Te=23 原始盆地宽度 (I列): %.2f\n', local_Basin_Width);
fprintf('3. Te=23 参考沉积中心 (H列): %.2f\n', ref_Global_Depo);
fprintf('----------------\n');

% --- 4. 提取目标计算行 ---
% 逻辑：Te >= 50
target_mask = raw_data(:, 2) >= 50;
target_indices = find(target_mask);

if isempty(target_indices)
    error('未找到 Te >= 50 的数据行。');
end

target_Tes = raw_data(target_indices, 2);      % Col B (2)
target_Depos = raw_data(target_indices, 8);    % Col H (8)

% 排序
[target_Tes, sort_idx] = sort(target_Tes);
target_Depos = target_Depos(sort_idx);

if any(isnan(target_Depos))
    error('错误：目标行的 Depocenter (H列) 存在空值。');
end

% --- 5. 核心计算循环 ---
rates = 0 : 0.01 : 0.10; % 去缩短率
num_rows = length(rates) * length(target_Tes);
results = zeros(num_rows, 9); % 9列输出
row_idx = 1;

fprintf('开始计算... (井位距离不随Te缩放，仅随Rate缩放)\n');

for r = 1:length(rates)
    current_Rate = rates(r);
    
    % 计算还原因子 ( 1 / 0.99 )
    if current_Rate == 1
        restore_factor = 0; % 防止除以0，虽不常见
    else
        restore_factor = 1 / (1 - current_Rate);
    end
    
    for t = 1:length(target_Tes)
        current_Te = target_Tes(t);
        current_Depo = target_Depos(t); % 沉积中心 (锚点)
        
        % [Step 1] 计算当前 Te 下的物理参数 (0% 状态)
        % 缩放系数 k
        scale_k = current_Depo / ref_Global_Depo;
        
        % 0% 状态下的盆地宽度 (缩放)
        width_0 = local_Basin_Width * scale_k;
        
        % 0% 状态下的井位距离 (不缩放!! 保持 36, 70...)
        wells_dist_0 = local_Wells_Dist; 
        
        % [Step 2] 执行去缩短 (应用 restore_factor)
        % "沉积中心到边界距离由 J4/0.99 得到"
        width_restored = width_0 * restore_factor;
        
        % "独立控制点也进行缩放 (D2/0.99)"
        wells_dist_restored = wells_dist_0 * restore_factor;
        
        % [Step 3] 计算绝对坐标
        % 锚定 Depocenter，推算边界
        current_Boundary = current_Depo - width_restored;
        
        % 推算井位 (边界 + 距离)
        final_Wells = current_Boundary + wells_dist_restored;
        
        % [Step 4] 存入结果
        % A:Rate, B:Te, C:Bound, D-G:Wells, H:Depo, I:Width
        results(row_idx, 1) = current_Rate;
        results(row_idx, 2) = current_Te;
        results(row_idx, 3) = current_Boundary;
        results(row_idx, 4:7) = final_Wells;
        results(row_idx, 8) = current_Depo;
        results(row_idx, 9) = width_restored; % 记录计算出的宽度
        
        row_idx = row_idx + 1;
    end
end

% --- 6. 导出 ---
var_names = {'Rate', 'Te', 'Boundary', 'L2', 'L62', 'J105', 'Q1', 'Depocenter', 'Calc_Width'};
out_table = array2table(results, 'VariableNames', var_names);
writetable(out_table, output_file);

fprintf('计算完成！文件已保存至: %s\n', output_file);
fprintf('验证提示: Rate=0, Te=50 时, L2 应约为 Boundary + 36\n');