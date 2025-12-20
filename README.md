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

### 1. Decompaction Correction (去压实矫正)
* **Description:** Restores the original thickness of sedimentary layers by removing the compaction effect based on lithological parameters.
* **说明**：基于岩性参数去除压实效应，恢复沉积层的原始厚度。

### 2. Control Point Calculation (控制点位置计算)
* **Description:** Simulates basin geometries under different lithospheric flexural rigidities.
    * **Method:** We utilize **drilling/well locations** as spatial control points.
    * **Data:** Each control point contains coordinate information and the decompacted stratigraphic thickness derived from the previous step.
* **说明**：推算不同岩石圈挠曲刚度下的盆地形态。
   采用**钻井位置**作为空间上的控制点。
   每个控制点包含空间坐标以及经过去压实矫正后的地层厚度信息。

### 3. 2D Flexural Simulation (二维挠曲模拟)
* **Description:** Performs numerical simulation of lithospheric deflection under vertical loading based on the elastic plate theory.
* **说明**：基于弹性板理论，对垂直负载下的岩石圈弯曲进行数值模拟。

### 4. Goodness-of-Fit Calculation (拟合度计算)
* **Description:** Evaluates the accuracy of the model by comparing the simulated deflection with observed data.
    * **Metric:** The goodness of fit is calculated using **`1 - RMSE`** (Root Mean Square Error).
* **说明**：通过对比模拟弯曲量与观测数据来评估模型精度。
   采用 **`1 - RMSE`**（1减去均方根误差）作为拟合优度的评价标准。
