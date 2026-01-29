function x = lasso_BCD(x0, A, b, mu, opts)
    % LASSO_BCD 使用坐标下降法求解 Lasso 问题
    
    % 获取参数，提供默认值防止报错
    if isfield(opts, 'itr_inn'), max_iter = opts.itr_inn; else, max_iter = 1000; end
    
    [m, n] = size(A);
    x = x0; 
    
    % 1. 预计算 Lipschitz 常数 (列的平方范数)
    L = sum(A.^2, 1)'; 
    
    % 2. 修正：正确初始化残差 (考虑 x0 可能不为0的情况)
    r = b - A * x; 
    
    for iter = 1:max_iter
        
        % --- 坐标下降循环 ---
        for j = 1:n
            % 记录更新前的 x_j 值
            x_j_prev = x(j);
            
            % 计算相关性 rho (利用当前残差)
            % 公式推导: 
            % Grad_j = -A_j' * (b - Ax) = -A_j' * r
            % 我们需要最小化的二次部分关于 x_j 的极值点在: x_j + (A_j' * r) / L_j
            % 这里 r 包含的是旧的 x_j，所以要先加回旧的贡献: A_j' * r + L_j * x_j
            rho = A(:, j)' * r + L(j) * x(j);
            
            % 软阈值更新
            if L(j) > 0
                x(j) = soft_threshold(rho, mu) / L(j);
            else
                x(j) = 0; % 防止除以0（如果某列全为0）
            end
            
            % 3. 修正：计算 Delta 并更新残差
            % 必须使用 "本次更新前的值" (x_j_prev)，而不是 "本轮迭代初的值"
            delta = x(j) - x_j_prev;
            
            % 仅当有变化时才更新残差，节省计算
            if abs(delta) > 0
                r = r - A(:, j) * delta;
            end
        end
    end
end

function z = soft_threshold(rho, lambda)
    % 优化写法的软阈值算子 (Sign * Max)
    z = sign(rho) * max(abs(rho) - lambda, 0);
end