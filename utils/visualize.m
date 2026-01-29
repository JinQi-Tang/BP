function fig = visualize(x_true, title1, x, title2, mode)
    if strcmp(mode, 'stem')
        % --- 结果对比绘图 ---
        fig = figure('Name', 'Basis Pursuit Result', 'NumberTitle', 'off');
        
        % 使用 subplot(2,1,1) 
        subplot(2,1,1);
        stem(x_true, 'Marker', 'none', 'LineWidth', 1.5, 'Color', [0.5, 0.5, 0.5]); % 灰色背景作为参考
        hold on;
        title(title1, 'Interpreter', 'none');
        grid on;
        %ylabel('Amplitude');
        
        % 使用 subplot(2,1,2)
        subplot(2,1,2);
        stem(x, 'Marker', 'none', 'LineWidth', 1.5, 'Color', 'r'); % 红色表示重建结果
        title(title2, 'Interpreter', 'none');
        grid on;
        %xlabel('Index'); ylabel('Amplitude');
    elseif strcmp(mode, 'plot')
        fig = figure('Name', 'Basis Pursuit Visualization', 'NumberTitle', 'off');
        
        % 使用 subplot(2,1,1) 
        subplot(2,1,1);
        semilogy(x_true, 'Marker', 'none', 'LineWidth', 1.5, 'Color', [0.5, 0.5, 0.5]); % 灰色背景作为参考
        hold on;
        title(title1, 'Interpreter', 'none');
        grid on;
        %ylabel('Amplitude');
        
        % 使用 subplot(2,1,2)
        subplot(2,1,2);
        semilogy(x, 'Marker', 'none', 'LineWidth', 1.5, 'Color', 'r'); % 红色表示重建结果
        title(title2, 'Interpreter', 'none');
        grid on;
        %xlabel('Index'); ylabel('Amplitude');
    end
end