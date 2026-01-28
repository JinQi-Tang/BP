clear;
clc;
% 假设 Logger.m 和 visualize.m 在 utils 文件夹中
addpath('../utils'); 

method = "gurobi"; % 修改方法名为 gurobi

% --- 定义求解器函数 (局部函数) ---
function x = solver(A, b)
    % 获取维度
    [m, n] = size(A);
    
    % ---------------------------------------------------------
    % 数学转化: Basis Pursuit -> Linear Programming
    % 原问题: min ||x||_1  s.t. Ax = b
    % 令 x = u - v, 其中 u>=0, v>=0
    % 目标函数: min sum(u) + sum(v)
    % 约束条件: [A, -A] * [u; v] = b
    % ---------------------------------------------------------
    
    % 1. 构造 LP 参数
    % 变量 z = [u; v], 长度 2n
    c = ones(2*n, 1);          % 目标函数系数 (全1向量)
    A_aug = sparse([A, -A]);   % 增广矩阵 (Gurobi 推荐使用稀疏格式)
    
    % 2. 配置 Gurobi 的 model 结构体
    clear model;
    model.obj = c;             % 目标系数
    model.A = A_aug;           % 约束矩阵
    model.rhs = b;             % 等式右边向量 (RHS)
    model.sense = '=';         % 等式约束 (Gurobi 中 '=' 代表相等)
    
    % 变量非负约束 z >= 0 (Gurobi 默认 lb=0，但显式指定更安全)
    model.lb = zeros(2*n, 1);
    % model.ub 默认为 +Inf，无需设置
    
    % 3. 配置 Gurobi 参数
    clear params;
    params.OutputFlag = 0;     % 0: 关闭控制台输出 (避免刷屏)
    params.Method = 1;         % (可选) 1=Dual Simplex, 2=Barrier. 通常默认即可
    
    % 4. 调用 gurobi
    result = gurobi(model, params);
    
    % 5. 结果重构
    if strcmp(result.status, 'OPTIMAL')
        z_sol = result.x; % 获取解向量 z = [u; v]
        
        % 还原 x = u - v
        u = z_sol(1:n);
        v = z_sol(n+1:end);
        x = u - v;
    else
        % 如果状态不是 OPTIMAL，抛出错误
        error('Gurobi 求解失败，状态: %s', result.status);
    end
end

% --- 主程序流程 (保持完全一致) ---

% 1. 初始化日志 (会在 ../logs 下生成文件夹)
log = Logger('bp_' + method, '../');

log.info(repelem('=', 50));
log.info("开始加载数据集...");

% 2. 加载数据
yaml_content = fileread('../config.yaml');
py_data = py.yaml.safe_load(yaml_content);
data_path = fullfile("../", char(py_data.get('data_path')));

if exist(data_path, 'file')
    load(data_path);
    log.info(sprintf("数据集加载完成: %s", data_path));
else
    log.error("找不到数据文件，请检查路径");
    return;
end

log.info(repelem('=', 50));
log.info(sprintf("开始调用 %s (原生接口) 进行求解...", method));

% 3. 计时并求解
tic;
try
    x = solver(A, b);
    time = toc;
    log.info("求解完成");
    
    % 4. 记录结果
    res = struct();
    res.relative_error = norm(x_true - x) / norm(x_true);
    res.time = time;
    res.method = method;
    
    % 保存 JSON (Logger 会自动生成 results.json)
    log.saveJSON(res, 'results.json');
    
    log.info(sprintf("L2相对误差: %g", res.relative_error));
    log.info(sprintf("耗时: %f s", time));
    
    % 5. 可视化
    % 传入 'Interpreter', 'none' 防止标题中的下划线被当做下标
    f = visualize(x_true, x, method); 
    log.saveFigure(f, 'comparison.png');
    
catch ME
    log.error(sprintf("求解过程中发生错误: %s", ME.message));
end