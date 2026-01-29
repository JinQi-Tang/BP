function x = bp_ADMM(x0, A, b, opts)
    % 基追踪 (Basis Pursuit) 的 ADMM 算法 (Cholesky 分解优化版)
    % 优化目标: min ||x||_1  s.t. Ax = b
    
    % --- 参数设置 ---
    max_iter = opts.itr;
    tol = opts.tol0;
    rho = 1.0;
    
    [m, n] = size(A);
    
    % --- 预计算 (Pre-computation) ---
    % 针对 Ax = b 的投影算子需要求解 (AA')y = rhs
    % 我们预先对 AA' 进行 Cholesky 分解: M = L * L'
    M = A * A';
    
    % 为了数值稳定性，如果矩阵接近奇异，可以添加微小的对角扰动 (jitter)
    % M = M + 1e-10 * eye(m); 
    
    L = chol(M, 'lower'); % 计算下三角矩阵 L
    
    % --- 变量初始化 ---
    x = x0;
    z = zeros(n, 1);
    u = zeros(n, 1);
    
    % 缓存 At (避免循环内转置)
    At = A';
    
    for k = 1:max_iter
        x_old = x;
        
        % --- 1. x-update: 快速投影 ---
        % 原始公式: x = v - A' * (AA')^-1 * (Av - b)
        % 其中 v = z - u
        
        v = z - u;
        residual = A * v - b;
        
        % 使用预计算的 Cholesky 因子求解 (AA') * gamma = residual
        % 等价于求解 L * L' * gamma = residual
        % MATLAB 的 mldivide (\) 对三角矩阵极其高效
        gamma = L' \ (L \ residual);
        
        x = v - At * gamma;
        
        % --- 2. z-update: 软阈值 (Soft-thresholding) ---
        % 求解 min ||z||_1 + (rho/2)||x - z + u||_2^2
        kappa = 1/rho;
        vec = x + u;
        % 向量化计算软阈值
        z = sign(vec) .* max(abs(vec) - kappa, 0);
        
        % --- 3. u-update: 对偶变量更新 ---
        u = u + (x - z);
        
        % --- 收敛检测 ---
        dual_res = norm(rho * (z - x_old));
        prim_res = norm(x - z);
        
        if (prim_res < tol && dual_res < tol)
            fprintf('ADMM converged at iter: %d\n', k);
            break;
        end
    end
    
    % 返回结果
    x = z;
end