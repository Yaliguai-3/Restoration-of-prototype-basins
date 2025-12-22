# 2D Flexural Model Constrained by Stratigraphy and Orogeny
# 受地层与造山约束的二维挠曲模型

## Introduction (项目介绍)

**English:**
This project involves a 2D lithospheric flexural model constrained by stratigraphy and orogenic loads. It is implemented in **MATLAB** and is designed to quantitatively reveal the prototype structure of the basin and its formation mechanism.

**中文:**
这是一个基于 **MATLAB** 实现的、受地层和造山运动约束的二维岩石圈挠曲模型。项目旨在通过定量模拟手段，揭示盆地的原始结构及其形成机制。

---

## Workflow & Features (流程与功能)

The modeling process consists of four main modules:
本模型主要包含以下四个核心步骤：

### 1. Decompaction(去压实矫正)
* **Description:** Restores the original thickness of sedimentary layers by removing the compaction effect based on lithological parameters.
* **说明**：基于岩性参数去除压实效应，恢复沉积层的原始厚度。
* **用法**：使用input_data.xlsx输入数据，示例用了4口井，三套地层，和地层对应的现今厚度孔隙度和密度参数。结果会通过“output_result.xlsx”输出，并且会将每一层的去压实量展示出来。

### 2. Control Point Calculation (控制点位置计算)
* **Description:** Simulates basin geometries under different lithospheric flexural rigidities.
    * **Method:** We utilize **drilling/well locations** as spatial control points.
    * **Data:** Each control point contains coordinate information and the decompacted stratigraphic thickness derived from the previous step.
* **说明**：推算不同岩石圈挠曲刚度下的盆地形态。
   采用**钻井位置**作为空间上的控制点。
   每个控制点包含空间坐标以及经过去压实矫正后的地层厚度信息。
  * **用法**：使用input_Control_Points.xlsx输入数据，示例展示了4口作为控制点的井以及沉积中心的空间位置，并且将它们代入现今Te下的空间位置，按示例的格式代码会自动计算Te从50-65且去缩短量从0-10%的值。
    结果通过“Output_Calculated_Points.xlsx”输出，输出的结果并未通过整数形式输出。

### 3. 2D Flexural Simulation (二维挠曲模拟)
* **Description:** Performs numerical simulation of lithospheric deflection under vertical loading based on the elastic plate theory.
* **说明**：基于弹性板理论，对垂直负载下的岩石圈弯曲进行数值模拟。
* **用法**：使用input.xlsx输入数据，只用输入D（即对应的Te）和加载量，通过这样的形式实现对网格化数据的批量处理。
* **代码改自**：Jha, S., Harry, D.L., and Schutt, D.L., 2017, Toolbox for Analysis of Flexural Isostasy (TAFI)—A MATLAB toolbox for modeling flexural deformation of the lithosphere: Geosphere, v. 13, no. 5, p. 1555–1565, doi:10.1130/GES01421.1.

### 4. Goodness-of-Fit Calculation (拟合度计算)
* **Description:** Evaluates the accuracy of the model by comparing the simulated deflection with observed data.
    * **Metric:** The goodness of fit is calculated using **`1 - RMSE`** (Root Mean Square Error).
* **说明**：通过对比模拟弯曲量与观测数据来评估模型精度。
   采用 **`1 - RMSE`**（1减去均方根误差）作为拟合优度的评价标准。
* **用法**：包含三个输入表格。第一个是控制点位置表格：Corrected_Control_Points.xlsx，其是从2. Control Point Calculation得来的；第二个表格是：Model_Calculation_Data.xlsx，它通过不同Sheet包含不同的Te信息，每一个单独的Sheet中第A列都是D其下一行对应其数值，再往下是对应的X轴点位，以整数形式展示，B列之后则是负载量，同样第二行是其数值，再往下是空间挠曲量（Y轴数值）；第三个表是：Uplift_Flexure_Params.xlsx，它展示的是Te、负载量N以及二者联合解析出来的原点向下挠曲量Wmax和H造山带的隆升高度。

### 5. Scatter diagram (结果可视化)
* **描述:**将最优GOF结果直观展示出来
* * **用法**：按照Te分为不同Sheet，参照示例，在每一个Sheet中分别输入Te、缩短率、加载量、最大挠曲量、造山带古高度以及GOF
