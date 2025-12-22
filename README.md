# 2D Flexural Model Constrained by Stratigraphy and Orogeny
# 受地层与造山约束的二维挠曲模型

## Introduction (项目介绍)

**English:**
This project involves a 2D lithospheric flexural model constrained by stratigraphy and orogenic loads. It is implemented in **MATLAB** and is designed to quantitatively reveal the prototype structure of the basin and its formation mechanism.

**中文:**
这是一个基于 **MATLAB** 实现的、受地层和造山运动约束的二维岩石圈挠曲模型。项目旨在通过定量模拟手段，揭示盆地的原始结构及其形成机制。

---

## Workflow & Features (流程与功能)

The modeling process consists of five main modules. Below are the details for methodology and usage.
本模型主要包含以下五个核心步骤，下文详细说明了方法原理与使用方式。

### 1. Decompaction Correction (去压实矫正)
* **Description / 原理**:
    Restores the original thickness of sedimentary layers by removing the compaction effect based on lithological parameters.
    基于岩性参数去除压实效应，恢复沉积层的原始厚度。

* **Usage / 用法**:
    * **Input**: `input_data.xlsx`
        * Format: Includes data for 4 wells and 3 stratigraphic layers, containing current thickness, porosity, and density parameters.
        * 格式：包含4口井、三套地层的数据，需输入现今地层厚度、孔隙度和密度参数。
    * **Output**: `output_result.xlsx`
        * Contains the calculated decompacted thickness for each layer.
        * 输出每一层的去压实量及恢复后的厚度。

### 2. Control Point Calculation (控制点位置计算)
* **Description / 原理**:
    Calculates the spatial position of basin geometries under different lithospheric flexural rigidities ($T_e$). It utilizes **drilling/well locations** as spatial control points, incorporating coordinates and decompacted thickness.
    推算不同岩石圈挠曲刚度（$T_e$）下的盆地形态。采用**钻井位置**作为空间控制点，结合坐标与去压实后的地层厚度信息进行计算。

* **Usage / 用法**:
    * **Input**: `input_Control_Points.xlsx`
        * Format: Includes the spatial locations of 4 control wells and the depocenter.
        * Operation: The code substitutes these into current spatial positions based on $T_e$. It automatically iterates through a $T_e$ range of **50-65 km** and a shortening rate range of **0-10%**.
        * 格式：包含4口控制井及沉积中心的空间位置。代码会自动计算 $T_e$ 在 50-65 km 以及缩短率在 0-10% 范围内的数值。
    * **Output**: `Output_Calculated_Points.xlsx`
        * Results are output in floating-point format (non-integer) for precision.
        * 结果以浮点数形式（非整数）输出以保留精度。

### 3. 2D Flexural Simulation (二维挠曲模拟)
* **Description / 原理**:
    Performs numerical simulation of lithospheric deflection under vertical loading based on the elastic plate theory.
    基于弹性板理论，对垂直负载下的岩石圈弯曲进行数值模拟。

* **Code Reference & Modification / 代码来源与改进**:
    * **Origin**: Modified from **Jha, S., Harry, D.L., and Schutt, D.L. (2017)**, "Toolbox for Analysis of Flexural Isostasy (TAFI)".
    * **Key Feature**: We developed the **`flexure_Callback.m`** module to enable **batch processing** of gridded data, significantly improving efficiency compared to single-profile analysis.
    * **来源**: 代码修改自 **Jha et al. (2017)** 的 TAFI 工具箱。
    * **核心改进**: 我们开发了 **`flexure_Callback.m`** 模块，实现了网格化数据的**批量输入与输出**，显著提升了数据处理效率。

* **Usage / 用法**:
    * **Execution**: Run the `flexure_Callback.m` script.
    * **运行**: 运行 `flexure_Callback.m` 脚本。
    * **Input**: `input.xlsx`
        * Format: Requires only the Flexural Rigidity ($D$, corresponding to $T_e$) and Load Magnitude. This specific format supports the batch processing logic.
        * 格式：仅需输入挠曲刚度 $D$（对应 $T_e$）和加载量。该格式专为配合批量处理逻辑而设计。

### 4. Goodness-of-Fit Calculation (拟合度计算)
* **Description / 原理**:
    Evaluates the model accuracy by comparing the simulated deflection with observed control points. The metric used is **`1 - RMSE`** (Root Mean Square Error).
    通过对比模拟弯曲量与观测数据（控制点）来评估模型精度。采用 **`1 - RMSE`** 作为拟合优度的评价标准。

* **Usage / 用法**:
    This module requires three input files:
    本模块需要三个输入文件：

    1.  **`Corrected_Control_Points.xlsx`**:
        * Derived from Step 2 (Control Point Calculation).
        * 源自第二步计算得到的控制点数据。

    2.  **`Model_Calculation_Data.xlsx`**:
        * **Source**: This data is compiled from the results of **Step 3 (2D Flexural Simulation)**.
        * **来源**: 该输入数据整理自**第3步（二维挠曲模拟）**的输出结果。
        * **Structure**: Organized by Sheets (different $T_e$).
        * **Col A**: Rigidity $D$ (Row 2) and X-axis coordinates (integers).
        * **Col B+**: Load value (Row 2) and Flexural Deflection (Y-axis values).
        * **结构**: 分 Sheet 存储不同 $T_e$ 信息。A列为刚度 $D$ 及 X 轴整数点位；B列及之后为负载量及对应的空间挠曲量（Y轴）。

    3.  **`Uplift_Flexure_Params.xlsx`**:
        * Contains summary parameters: $T_e$, Load ($N$), Max Deflection ($W_{max}$), and Orogen Height ($H$).
        * 包含参数汇总：$T_e$、负载量 $N$、二者联合解析的原点向下最大挠曲量 $W_{max}$ 及造山带隆升高度 $H$。

### 5. Scatter Diagram Visualization (结果可视化)
* **Description / 原理**:
    Visualizes the optimal Goodness-of-Fit (GOF) results.
    直观展示最优的拟合优度（GOF）结果。

* **Usage / 用法**:
    * **Input**: Organized by Sheets based on $T_e$.
    * **Format**: In each sheet, input parameters in the following order: $T_e$, Shortening Rate, Load, Max Deflection ($W_{max}$), Paleo-height of Orogen ($H$), and GOF.
    * 格式：按 $T_e$ 分为不同 Sheet。在每个 Sheet 中分别输入：$T_e$、缩短率、加载量、最大挠曲量、造山带古高度以及 GOF。
