clear; clc;

% --- Define the file name.定义文件名  ---
file_ctrl_points = 'Corrected_Control_Points.xlsx';   % 控制点位置，results calculated by“generate_control_points.m”计算结果
file_model_data  = 'Model_Calculation_Data.xlsx';     % 模型挠曲数据，results calculated by“3.2D Flexure Simulation”计算结果
file_uplift      = 'Uplift_Flexure_Params.xlsx';      % Height of the orogenic belt.造山带隆升高度
file_output      = 'Post_Process_Results.xlsx';       % Output.输出结果

% If the old output file exists, delete it first.如果旧的输出文件存在，先删除
if exist(file_output, 'file')
    delete(file_output);
end

% Control point constant is placed on the second row.（C-G）控制点常数放第二行 (对应C-G列)
row2_constants = [-1.0725, -1.32152, -1.39137, -2.03107, -2.13189]; 

% Extract the reference sedimentary center for column H.提取计算H列的基准沉积中心 (G2的值)
const_depocenter = row2_constants(5); 

% Extract the target values (taking the absolute value) used for calculating RMSE
% 提取用于计算RMSE的目标值 (取绝对值)
rmse_targets = abs(row2_constants);

%% 1. Read the input data.读取所有输入数据
fprintf('正在读取输入文件...\n');

% 1.1 Read the control point table.读取控制点表
T1_raw = readmatrix(file_ctrl_points, 'NumHeaderLines', 1);
col_A = T1_raw(:, 1);          % rate.恢复率
col_B = round(T1_raw(:, 2));   % Te (取整)Round off
col_CG = round(T1_raw(:, 3:7));% X值 (取整)Round off
data_ctrl = [col_A, col_B, col_CG];

% 1.2 Read the elevation parameter table.读取隆升高度参数表
T_uplift_raw = readmatrix(file_uplift, 'NumHeaderLines', 1);
if ~isempty(T_uplift_raw)
    T_uplift_raw(:, 1) = round(T_uplift_raw(:, 1)); 
end

%% Start the loop processing.开始循环处理 Te50 - Te65，adjusted according to the actual situation.可以根据实际调整
te_start = 50;
te_end = 65;

fprintf('开始处理数据...\n');

for te_val = te_start:te_end
    sheet_name = sprintf('Te%d', te_val);
    fprintf('正在处理 Sheet: %s ... ', sheet_name);
    
    %% 2. filter the data.筛选数据
    idx_T1 = find(data_ctrl(:, 2) == te_val);
    current_ctrl_data = data_ctrl(idx_T1, :);
    
    if isempty(current_ctrl_data)
        fprintf('跳过 (表1无数据)\n');
        continue;
    end
    
    if ~isempty(T_uplift_raw)
        idx_uplift = find(T_uplift_raw(:, 1) == te_val);
        current_uplift_data = T_uplift_raw(idx_uplift, :);
    else
        current_uplift_data = [];
    end
    
    %% 3. Read the model data.读取模型数据
    try
        opts = detectImportOptions(file_model_data, 'Sheet', sheet_name, 'PreserveVariableNames', true);
        opts.DataRange = 'A1'; 
        T2_raw = readmatrix(file_model_data, opts);
        
        load_mags_all = T2_raw(2, 2:end);
        valid_lm_indices = find(load_mags_all >= 1e13 & load_mags_all <= 5.4e13);
        valid_load_mags = load_mags_all(valid_lm_indices);
        
        if isempty(valid_load_mags)
            fprintf('跳过 (无有效Load)\n');
            continue;
        end
        
        x_axis_T2 = T2_raw(3:end, 1);
        valid_rows_mask = ~isnan(x_axis_T2);
        x_axis_T2 = round(x_axis_T2(valid_rows_mask)); 
        
        y_data_T2 = T2_raw(3:end, valid_lm_indices + 1);
        y_data_T2 = y_data_T2(valid_rows_mask, :);
        
    catch ME
        fprintf('出错: %s\n', ME.message);
        continue;
    end
    
    %% 4. Data matching.数据匹配
    base_data = [];
    num_rec_rates = size(current_ctrl_data, 1);
    
    for i = 1:num_rec_rates
        rec_rate = current_ctrl_data(i, 1);
        target_xs = current_ctrl_data(i, 3:7); 
        
        for j = 1:length(valid_load_mags)
            lm_val = valid_load_mags(j);
            current_y_curve = y_data_T2(:, j);
            
            % Match Y value.核心匹配 Y值
            extracted_ys = interp1(x_axis_T2, current_y_curve, target_xs, 'nearest');
            
            % Match Wmax and H.匹配 Wmax 和 H
            uplift_row_idx = -1;
            if ~isempty(current_uplift_data)
                [min_diff, closest_idx] = min(abs(current_uplift_data(:, 2) - lm_val));
                if min_diff < 1e8 
                    uplift_row_idx = closest_idx;
                end
            end
            
            if uplift_row_idx > 0
                val_Wmax = current_uplift_data(uplift_row_idx, 3);
                val_H    = current_uplift_data(uplift_row_idx, 4);
            else
                val_Wmax = NaN;
                val_H    = NaN;
            end
            
            row_vals = [rec_rate, lm_val, extracted_ys, val_Wmax, val_H];
            base_data = [base_data; row_vals];
        end
    end
    
    if isempty(base_data)
        continue;
    end

    %% 5. Calculate.计算 (平移、反转、RMSE、GOF)
    
    cols_C_to_G = base_data(:, 3:7);
    col_Wmax    = base_data(:, 8);
    col_H_uplift= base_data(:, 9); 
    
    % H列: 平移量
    col_depo_vals = cols_C_to_G(:, 5); 
    col_shift_H = const_depocenter - col_depo_vals;
    
    % I列: 空
    col_I = nan(size(base_data, 1), 1);
    
    % J-N列: 平移后
    cols_J_to_N = cols_C_to_G + col_shift_H;
    
    % O列: 空
    col_O = nan(size(base_data, 1), 1);
    
    % P-T列: 反转
    cols_P_to_T = cols_J_to_N * (-1);
    
    % U列: RMSE
    diff_sq = (rmse_targets - cols_P_to_T) .^ 2;
    col_U = sqrt(sum(diff_sq, 2) / 5);
    
    % --- 新增 X列: GOF (1 - RMSE) ---
    col_X = 1 - col_U;
    
    %% 6. Combine the final matrix.组合最终矩阵 (A-X列)
    % 顺序: A-G, H, I, J-N, O, P-T, U, V, W, X
    final_matrix = [base_data(:, 1:7), col_shift_H, col_I, cols_J_to_N, col_O, cols_P_to_T, col_U, col_Wmax, col_H_uplift, col_X];
    
    %% 7. In-file.写入文件
    % Header
    h_main = {'Recovery Rate', 'N (Load Mag)', 'L2', 'L62', 'J105', 'Q1', 'Depocenter'};
    h_H    = {'Depocenter Offset'}; 
    h_I    = {''};
    h_JN   = {'L2_Shift', 'L62_Shift', 'J105_Shift', 'Q1_Shift', 'Depo_Shift'};
    h_O    = {''};
    h_PT   = {'-L2', '-L62', '-J105', '-Q1', '-Depo'};
    h_U    = {'RMSE'};
    h_VW   = {'Wmax (km)', 'H (km)'};
    h_X    = {'GOF'}; % 新增
    
    full_header = [h_main, h_H, h_I, h_JN, h_O, h_PT, h_U, h_VW, h_X];
    
    % Row 2 (Constants)
    row2_cell = cell(1, length(full_header));
    for k = 1:5, row2_cell{2+k} = row2_constants(k); end
    
    % Data
    data_cell = num2cell(final_matrix);
    output_cell = [full_header; row2_cell; data_cell];
    
    writecell(output_cell, file_output, 'Sheet', sheet_name);
    fprintf('完成\n');
end

fprintf('\n所有处理完成！结果已保存至: %s\n', file_output);