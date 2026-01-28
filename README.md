# BP

本项目使用 matlab 语言，为求解经典的基追踪问题：

$$
 \begin{aligned} 
 \min_{x \in \mathbb{R}^n} \quad  & \|  x  \|_1  \\
  \text{s.t.} \quad & Ax = b \\
   \end{aligned} 
$$

提供了多种求解方式：
- **CVX + Gurobi**：`bp_cvx_gurobi.m`
- **CVX + Mosek**：`bp_cvx_mosek.m`
- **原生 Gurobi 接口**：`bp_gurobi.m`
- **原生 Mosek 接口**：`bp_mosek.m`

并包含：
- **数据自动生成与可视化**：`utils/data.m`
- **统一日志记录与结果保存**：`utils/Logger.m`
- **重建结果可视化**：`utils/visualize.m`

## 快速开始

### 步骤 1：配置参数
修改 `config.yaml` 文件中的 $m,n,k$ 值：
- `m`：矩阵 $A$ 的行数
- `n`：矩阵 $A$ 的列数
- `k`：真值向量 $x_{true}$ 的非零分量个数

### 步骤 2：生成数据
运行 `utils/data.m` 文件生成测试数据

### 步骤 3：更新数据路径
在 `data` 目录下找到新生成的数据文件 `data/m*_n*_k*_*******/data_setup.mat`，将其路径复制到 `config.yaml` 文件中的 `data_path` 字段

### 步骤 4：求解BP问题
在 `src` 目录下找到你喜欢的算法并运行

### 步骤5：查看实验日志
在 `logs` 目录下找到你进行实验的日期对应的子目录，并找到印有时间戳的日志文件

## 目录结构

- **`src/`**
  - `bp_cvx_gurobi.m`：使用 CVX 调用 Gurobi 求解 BP
  - `bp_cvx_mosek.m`：使用 CVX 调用 Mosek 求解 BP
  - `bp_gurobi.m`：使用 Gurobi 原生接口，将 BP 转化为线性规划求解
  - `bp_mosek.m`：使用 Mosek 原生接口，将 BP 转化为线性规划求解
- **`utils/`**
  - `data.m`：生成随机稀疏向量、测量矩阵和观测向量，并自动保存到 `data/`
  - `Logger.m`：简单日志系统，负责实验日志、结果 JSON、图片等的保存
  - `visualize.m`：比较真实信号 `x_true` 与重建结果 `x` 的图形
- **`data/`**
  - 存放自动生成的 `.mat` 数据以及预览图片（例如 `original_signal.png`、`measurements.png`）
- **`logs/`**
  - 每次运行会在其中创建带时间戳的文件夹，保存日志、求解器输出、结果 JSON、图像等
- **`config.yaml`**
  - 实验配置文件，主要包括：`m`、`n`、`k` 和 `data_path`

## 依赖环境

- **MATLAB**
  - 建议 R2021a 及以上版本（其他版本通常也可）
  - 需要支持 `datetime`、`jsonencode` 等函数
- **CVX（可选，用于 `bp_cvx_*`）**
  - 已正确安装并设置好路径（`cvx_setup`）
- **Gurobi（用于 Gurobi 相关脚本）**
  - 已安装 Gurobi 与对应 MATLAB 接口并激活 license
- **Mosek（用于 Mosek 相关脚本）**
  - 已安装 Mosek 与 MATLAB 接口并激活 license
- **Python + PyYAML（用于读取 `config.yaml`）**
  - MATLAB 中可通过 `py.*` 调用 Python