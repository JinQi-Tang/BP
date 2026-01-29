function generate_bp_data_with_save(m, n, k)
    % GENERATE_BP_DATA_WITH_SAVE 生成基追踪数据并自动保存
    % 文件夹命名格式示例：Project_Data_20260128/120530_m300_n1000_k30
    arguments
        m (1,1) double = 200   
        n (1,1) double = 1000  
        k (1,1) double = 30    
    end

    % --- 1. 数据生成逻辑 ---
    A = randn(m, n);
    for i = 1:n
        A(:,i) = A(:,i) / norm(A(:,i));
    end
    x_true = zeros(n, 1);
    idx = randperm(n, k);
    x_true(idx) = randn(k, 1);
    b = A * x_true;

    % --- 2. 文件夹管理 (使用修正后的 datetime 逻辑) ---
    currentTime = datetime('now'); 
    
    mainFolderName = '../data';
    if ~exist(mainFolderName, 'dir')
        mkdir(mainFolderName);
    end
    
    % 2.2 创建含参数的子文件夹 (例如 120530_m300_n1000_k30)
    timeStr = string(currentTime, 'HHmmss');
    subFolderName = sprintf('%s_m%d_n%d_k%d', char(timeStr), m, n, k);
    savePath = fullfile(mainFolderName, subFolderName);
    mkdir(savePath);

    % --- 3. 自动保存数据 (.mat) ---
    save(fullfile(savePath, 'data_setup.mat'), 'A', 'b', 'x_true', 'm', 'n', 'k');

    % --- 4. 自动保存预览图 ---
    % 4.1 绘制原始稀疏信号 (纯竖线，无点)
    fig1 = figure('Visible', 'off'); 
    stem(x_true, 'Marker', 'none', 'LineWidth', 1.2, 'Color', 'b');
    title(sprintf('Original Sparse Signal (n=%d, k=%d)', n, k));
    xlabel('Index'); ylabel('Amplitude');
    grid on;
    exportgraphics(fig1, fullfile(savePath, 'original_signal.png'), 'Resolution', 300);
    close(fig1);

    % 4.2 绘制观测值 b
    fig2 = figure('Visible', 'off');
    plot(b, 'LineWidth', 1.2, 'Color', [0.85, 0.33, 0.10]); 
    title(sprintf('Measurement Vector b (m=%d)', m));
    xlabel('Measurement Index'); ylabel('Value');
    grid on;
    exportgraphics(fig2, fullfile(savePath, 'measurements.png'), 'Resolution', 300);
    close(fig2);

    % --- 5. 报告输出 ---
    fprintf('--- 自动保存报告 ---\n');
    fprintf('完成时间: %s\n', string(currentTime, 'yyyy-MM-dd HH:mm:ss'));
    fprintf('保存路径: %s\n', savePath);
    fprintf('参数状态: m=%d, n=%d, k=%d\n', m, n, k);
    fprintf('包含文件: data_setup.mat, original_signal.png, measurements.png\n');
    fprintf('--------------------\n');
end
yaml_content = fileread('../config.yaml');
py_data = py.yaml.safe_load(yaml_content);
generate_bp_data_with_save(py_data.get('m', 200), py_data.get('n', 1000), py_data.get('k', 30))
