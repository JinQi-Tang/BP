clear;
clc;
% 假设 Logger.m 和 visualize.m 在 utils 文件夹中
addpath('../utils'); 

method = "cvx_gurobi";

% --- 定义求解器函数 (局部函数) ---
function x = solver(A, b)
    n = size(A, 2);
    cvx_begin
        cvx_solver gurobi
        variable x_var(n)
        minimize( norm(x_var, 1) ) 
        subject to
            A * x_var == b
    cvx_end
    x = x_var;
end

% --- 主程序流程 ---

% 1. 初始化日志 (会在 ../logs 下生成文件夹)
log = Logger('bp_' + method, '../');

log.info(repelem('=', 50));
log.info("开始加载数据集...");

% 2. 加载数据
data_path = "../data/m200_n1000_k30_210545/data_setup.mat";
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
    f = visualize(x_true, x, method);
    log.saveFigure(f, 'comparison.png');
    
catch ME
    log.error(sprintf("求解过程中发生错误: %s", ME.message));
end