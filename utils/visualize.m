function fig = visualize(x_true, x, method)
    % --- 结果对比绘图 ---
    fig = figure('Name', 'Basis Pursuit Result Comparison', 'NumberTitle', 'off');
    
    % 使用 subplot(2,1,1) 展示原始信号
    subplot(2,1,1);
    stem(x_true, 'Marker', 'none', 'LineWidth', 1.5, 'Color', [0.5, 0.5, 0.5]); % 灰色背景作为参考
    hold on;
    title('Original Sparse Signal (x_true)', 'Interpreter', 'none');
    grid on;
    ylabel('Amplitude');
    
    % 使用 subplot(2,1,2) 展示重建信号
    subplot(2,1,2);
    stem(x, 'Marker', 'none', 'LineWidth', 1.2, 'Color', 'r'); % 红色表示重建结果
    title('Reconstructed Signal (x) using ' + method, 'Interpreter', 'none');
    grid on;
    xlabel('Index'); ylabel('Amplitude');
end