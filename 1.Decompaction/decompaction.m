% =========================================================================
clear; clc;

%% 第一步：Generate the test data file.生成测试数据文件 
% The Excel file is named 'input_data.xlsx' or modify the filename variable below.Excel文件名为 'input_data.xlsx' 或修改下方 filename 变量
filename = 'input_data.xlsx';
output_filename = 'output_result.xlsx';
%% 第二步：Reading data and parameter settings.读取数据与参数设置

% Read Excel file.读取Excel文件
opts = detectImportOptions(filename);
opts.VariableNamingRule = 'preserve'; % Keep the original column names.保持原始列名
raw_data = readtable(filename, opts);

% Obtain the reference to the column data.获取列数据的引用 (根据列的位置，A=1, B=2, C=3, D=4, E=5)
% Even if the names are different, as long as the order is correct (A-E), it will be fine.即使列名不一样，只要顺序对(A-E)即可
col_well = raw_data{:, 1};       % A列 Well name 井名
col_layer = raw_data{:, 2};      % B列 Formation 地层名
col_thick = raw_data{:, 3};      % C列 thickness 厚度 (m)
col_phi = raw_data{:, 4};        % D列 porosity 孔隙度 (小数)
col_rho = raw_data{:, 5};        % E列 density 密度

num_rows = height(raw_data);

% Initialize the result array.初始化结果数组
restored_thickness = zeros(num_rows, 1);
restored_amount = zeros(num_rows, 1);
compaction_c = zeros(num_rows, 1); % Record the calculated compaction coefficient for reference.记录计算出的压实系数供参考

% Default initial porosity.默认初始孔隙度
phi_0 = 0.5; 

%% 第三步：Calculate layer by layer to achieve compaction.逐层计算去压实
% Traverse each row, detect changes in well names to reset the cumulative depth count
% 遍历每一行，检测井名变化来重置深度累计

current_well = '';
current_depth_bottom = 0; % Current cumulative bottom boundary depth.当前累积底界深度

fprintf('正在计算...\n');
fprintf('%-10s %-10s %-10s %-15s %-15s\n', '井名', '地层', '现今厚度', '恢复后厚度', '恢复量');
fprintf('------------------------------------------------------------\n');

for i = 1:num_rows
    this_well = string(col_well(i));
    h_now = col_thick(i);
    phi_now = col_phi(i);
    
    % If the well name changes, reset the depth accumulation (indicating the start of calculating the first layer of the next well)
    % 如果井名发生变化，重置深度累积（说明开始计算下一口井的第一层）
    if ~strcmp(this_well, current_well)
        current_depth_bottom = 0;
        current_well = this_well;
    end
    
    % 1. Calculate the top and bottom burial depths of the current stratum
    % 1. 计算当前地层的顶底埋深
    top_depth = current_depth_bottom;
    current_depth_bottom = current_depth_bottom + h_now; % Update the depth.更新底深
    mid_depth = top_depth + (h_now / 2);
    
    % 2. Calculate the thickness of the skeleton (H_solid) - Conservation quantity
    % 2. 计算骨架厚度 (H_solid) - 守恒量
    h_solid = h_now * (1 - phi_now);
    
    % 3. Reverse calculation of the compaction coefficient c
    % 3. 反推压实系数 c
    % 公式: phi = phi0 * exp(-c * z)  =>  c = -ln(phi/phi0) / z
    if mid_depth > 0 && phi_now > 0
        c_val = -log(phi_now / phi_0) / mid_depth;
    else
        % Prevent division by zero or taking the logarithm of zero, and provide a minimum value or default experience value.
        % 防止除以0或log(0)，给予一个极小值或默认经验值
        c_val = 0.00039; 
    end
    
    % Prevent C from calculating negative numbers
    % 防止 c 算出负数
    if c_val < 1e-6
        c_val = 1e-6; 
    end
    compaction_c(i) = c_val;
    
    % 4. Solve for the original thickness H_original after restoration
    % 4. 求解恢复后的原始厚度 H_original
    % 目标方程：H_orig - (phi0/c)*(1 - exp(-c * H_orig)) - H_solid = 0
    % Define the equation using the objective function
    % 使用目标函数定义方程
    decompaction_eq = @(h_orig) h_orig - (phi_0 / c_val) * (1 - exp(-c_val * h_orig)) - h_solid;
    
    % Solve the nonlinear equation, with the initial value guessed as the current thickness
    % 求解非线性方程，初值猜测为现今厚度
    try
        h_restored = fzero(decompaction_eq, h_now * 1.5); % 猜测原始厚度是现在的1.5倍左右
    catch
        % If the solution fails, it is considered that there has been no change.
        % 如果求解失败则认为没有发生变化
        h_restored = h_now;
    end
    
    % 5. Save the results
    % 5. 保存结果
    restored_thickness(i) = h_restored;
    restored_amount(i) = h_restored - h_now;
    fprintf('%-10s %-10s %-10.2f %-15.2f %-15.2f\n', ...
        this_well, string(col_layer(i)), h_now, h_restored, h_restored - h_now);
end

%% 第四步：Output the results to Excel.输出结果到Excel

% Add the calculation results to the original table
% 将计算结果添加到原始表格中
output_table = raw_data;
output_table.Restored_Thickness_m = round(restored_thickness, 2); % Restored_Thickness.恢复后厚度
output_table.Decompacted_Amount_m = round(restored_amount, 2);    % restored_amount.去压实恢复量
output_table.Calc_Compaction_Factor_c = compaction_c;             % Calc_Compaction_Factor_c.计算用的压实系数

% 写入Excel
try
    writetable(output_table, output_filename);
    fprintf('\n------------------------------------------------------------\n');
    fprintf('计算完成！结果已保存至: %s\n', output_filename);
    fprintf('Excel列说明:\n');
    fprintf('  - Restored_Thickness_m: 恢复到沉积初期(去压实后)的地层厚度\n');
    fprintf('  - Decompacted_Amount_m: 地层恢复量 (原始厚度 - 现今厚度)\n');
catch ME
    fprintf('\n写入Excel失败，请检查文件是否被占用。\n错误信息: %s\n', ME.message);
end