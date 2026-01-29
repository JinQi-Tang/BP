clear;
clc;
% 假设 Logger.m 和 visualize.m 在 utils 文件夹中
addpath('../utils'); 

% --- 主程序流程 ---

yaml_content = fileread('../config.yaml');
py_data = py.yaml.safe_load(yaml_content);
method = string(py_data.get('method'));

% 1. 初始化日志 (会在 ../logs 下生成文件夹)
log = Logger('bp_' + method, '../');

log.info(repelem('=', 50));
log.info("开始加载数据集...");

% 2. 加载数据
data_path = fullfile("../", char(py_data.get('data_path')));

if exist(data_path, 'file')
    load(data_path);
    log.info(sprintf("数据集加载完成: %s", data_path));
else
    log.error("找不到数据文件，请检查路径");
    return;
end

log.info(repelem('=', 50));
log.info(sprintf("开始调用 %s 进行求解...", method));

use_pkg = false;
opts = struct('itr', double(py_data.get('itr', 25)), 'itr_inn', double(py_data.get('itr_inn', 150)), 'sigma', 1, 'tol0', 1e-12, 'gamma', 1, 'verbose', 0, 'x_true', x_true, 'video', py_data.get('video', true), 'L', 1);
% 3. 计时并求解
tic;
if strcmp(method, "ALM")
    [x, out] = bp_ALM(zeros(n, 1), A, b, opts);
elseif strcmp(method, "QP")
    [x, out] = bp_QP(zeros(n, 1), A, b, opts);
elseif strcmp(method, "cvx_mosek")
    x = bp_cvx_mosek(A, b);
    use_pkg = true;
elseif strcmp(method, "cvx_gurobi")
    x = bp_cvx_gurobi(A, b);
    use_pkg = true;
elseif strcmp(method, "gurobi")
    x = bp_gurobi(A, b);
    use_pkg = true;
elseif strcmp(method, "mosek")
    x = bp_mosek(A, b);
    use_pkg = true;
elseif strcmp(method, "ADMM")
    x = bp_ADMM(zeros(n, 1), A, b, opts);
    use_pkg = true;
elseif strcmp(method, "QP_BCD")
    [x, out] = bp_QP_BCD(zeros(n, 1), A, b, opts);
elseif strcmp(method, "mosek_dual")
    x = bp_mosek_dual(A, b);
    use_pkg = true;
elseif strcmp(method, "gurobi_dual")
    x = bp_gurobi_dual(A, b);
    use_pkg = true;
end
time = toc;
log.info("求解完成");


% 4. 记录结果
res = struct();
res.relative_error = norm(x_true - x) / norm(x_true);
res.time = time;
res.method = method;
if ~use_pkg
    res.itr = out.itr;
    res.itr_inn = out.itr_inn;
end

if strcmp(method, "ADMM")
    res.itr = double(py_data.get('itr', 25));
end

% 保存 JSON (Logger 会自动生成 results.json)
log.saveJSON(res, 'results.json');

log.info(sprintf("L2相对误差: %g", res.relative_error));
log.info(sprintf("耗时: %f s", time));
if ~use_pkg
    log.info(sprintf("内层迭代轮次: %d", out.itr_inn));
    log.info(sprintf("外层迭代轮次: %d", out.itr));
end

% 5. 可视化
f = visualize(x_true, 'Original Sparse Signal (x_true)', x, 'Reconstructed Signal (x) using ' + method, 'stem');
log.saveFigure(f, 'comparison.png');

if ~use_pkg
    f2 = visualize(out.feavec, 'Feasibility Error', out.relative_error, 'Relative Error', 'plot');
    log.saveFigure(f2, 'iteration.png');

    if opts.video
        figure;
        v = VideoWriter(fullfile(log.SessionPath, 'reconstruction_progress.avi'));
        v.FrameRate = 10;
        open(v);
        for i = 1:size(out.itervec, 2)
            stem(out.itervec(:,i), 'Marker', 'none', 'LineWidth', 1.5, 'Color', 'r'); % 红色表示重建结果
            title('Reconstructed Signal (x) using ' + method, 'Interpreter', 'none');
            grid on;
            frame = getframe(gcf);
            writeVideo(v, frame);
        end
        close(v);
        log.info(sprintf("视频已保存: %s", 'reconstruction_progress.avi'));
    end
end
