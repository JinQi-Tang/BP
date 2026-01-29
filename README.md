# BP

本项目使用 matlab 语言，为求解经典的 **基追踪 (Basis Pursuit)** 问题：

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
- **Gurobi 求解对偶问题**: `bp_gurobi_dual.m`
- **Mosek 求解对偶问题**: `bp_mosek_dual.m`
- **二次罚函数 + 次梯度下降**: `bp_QP.m`
- **二次罚函数 + 分块坐标下降**： `bp_QP_BCD.m`
- **增广拉格朗日函数 + 近似点梯度下降**：`bp_ALM.m`
- **交替方向乘子法**：`bp_ADMM.m`

并包含：
- **数据自动生成与可视化**：`utils/data.m`
- **统一日志记录与结果保存**：`utils/Logger.m`
- **重建结果可视化**：`utils/visualize.m`

## 快速开始

直接运行 `src/main.m`. 使用配置

```yaml
m: 200
n: 1000
k: 30
data_path: "data/m200_n1000_k30/data_setup.mat"
method: "cvx_mosek"
```

## 自定义开始

### 步骤 1：配置参数
修改 `config.yaml` 文件中的 $m,n,k$ 值：
- `m`：矩阵 $A$ 的行数
- `n`：矩阵 $A$ 的列数
- `k`：真值向量 $x_{true}$ 的非零分量个数

### 步骤 2：生成数据
运行 `utils/data.m` 文件生成测试数据

### 步骤 3：更新数据路径
在 `data` 目录下找到新生成的数据文件 `data/*******_m*_n*_k*/data_setup.mat`，将其路径复制到 `config.yaml` 文件中的 `data_path` 字段

### 步骤 4：求解BP问题
在 `src` 目录下找到你喜欢的算法，将其名称写入配置文件的 `method` 字段，并运行 `src/main.m`

### 步骤5：查看实验日志
在 `logs` 目录下找到你进行实验的日期对应的子目录，并找到印有时间戳的日志文件

## 目录结构

- **`src/`**
  - `bp_cvx_gurobi.m`：使用 CVX 调用 Gurobi 求解 BP
  - `bp_cvx_mosek.m`：使用 CVX 调用 Mosek 求解 BP
  - `bp_gurobi.m`：使用 Gurobi 原生接口，将 BP 转化为线性规划求解
  - `bp_mosek.m`：使用 Mosek 原生接口，将 BP 转化为线性规划求解
  - `bp_gurobi_dual.m`：使用 Gurobi 原生接口，对 BP 的对偶问题进行线性规划求解
  - `bp_mosek_dual.m`：使用 Mosek 原生接口，对 BP 的对偶问题进行线性规划求解
  - `bp_QR.m`：使用二次罚函数法，对应的 LASSO 子问题用次梯度法求解
  - `bp_QR_BCD.m`：使用二次罚函数法，对应的 LASSO 子问题用分块坐标下降法求解
  - `bp_ALM.m`：使用增广拉格朗日函数法，对应的子问题用近似点梯度下降求解
  - `bp_ADMM.m`：对原问题使用交替方向乘子法求解
- **`utils/`**
  - `data.m`：生成随机稀疏向量、测量矩阵和观测向量，并自动保存到 `data/`
  - `Logger.m`：简单日志系统，负责实验日志、结果 JSON、图片等的保存
  - `visualize.m`：比较真实信号 `x_true` 与重建结果 `x` 的图形
- **`data/`**
  - 存放自动生成的 `.mat` 数据以及预览图片（例如 `original_signal.png`、`measurements.png`）
- **`logs/`**
  - 每次运行会在其中创建带时间戳的文件夹，保存日志、求解器输出、结果 JSON、图像等
- **`config.yaml`**
  - 实验配置文件
  
  ```yaml
  m: 200 # 矩阵 A 的行数
  n: 1000 # 矩阵 A 的列数
  k: 30 # 真解 x_true 的非零值个数
  data_path: "data/m200_n1000_k30/data_setup.mat" # 数据路径
  method: "cvx_mosek" 
  # 可选 cvx_mosek/mosek/mosek_dual, cvx_gurobi/gurobi/gurobi_dual, QR, QR_BCD, ALM, ADMM
  itr: 50 # 外层最大迭代次数，不支持 Mosek, Gurobi
  itr_inn: 250 # 内层子问题最大迭代次数，不支持 Mosek, Gurobi, ADMM
  video: true # 是否生成解的迭代过程动态图，不支持 Mosek, Gurobi, ADMM
  ```

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

## 实验结果
| 方法 | 相对误差 | 时间 |
| :--- | :---: | :---: |
| cvx_mosek | 5e-12 | 0.31s |
| cvx_gurobi | 8e-9 | 0.30s |
| mosek | 3.5e-12 | 0.17s |
| mosek_dual | 5.8e-12 | 0.11s |
| gurobi | 5.4e-15 | 0.14s |
| gurobi_dual | 2.4e-11 | 0.16s |
| QP | 1.7e-12 | 1.00s |
| QP_BCD | 1.0e-12 | 0.99s |
| ALM | 5.5e-16 | 0.48s |
| ADMM | 1.4e-13 | 0.04s |

### 从夯到拉排名

#### 夯：ADMM，gurobi，mosek_dual

#### 顶尖：ALM

#### 人上人：mosek, gurobi_dual, cvx_mosek, cvx_gurobi

#### NPC：QP_BCD

#### 拉完了：QP