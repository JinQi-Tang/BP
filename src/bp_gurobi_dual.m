function x = bp_gurobi_dual(A, b)
    % SOLVE_BP_GUROBI_DUAL 使用 Gurobi 求解基追踪问题的对偶形式
    %   原问题: min ||x||_1  s.t.  Ax = b
    %   对偶问题: max b'y   s.t.  ||A'y||_inf <= 1
    %
    %   转换给 Gurobi (Minimization):
    %   min -b'y
    %   s.t.   A'y <= 1
    %         -A'y <= 1
    %
    % 输入:
    %   A: m x n 测量矩阵
    %   b: m x 1 观测向量
    % 输出:
    %   x: 通过对偶变量（影子价格）恢复的稀疏信号
    
    [m, n] = size(A);

    % --- 1. 构建 Gurobi 模型 ---
    
    % 变量 y 是 m 维向量 (对应原问题的等式约束，故无符号限制)
    % 目标函数: min -b'y
    model.obj = -b;
    
    % 变量界限: y 取值范围 (-inf, +inf)
    model.lb = -inf(m, 1);
    model.ub =  inf(m, 1);
    
    % 约束矩阵: 
    % Gurobi 不像 MOSEK 那样支持双边区间约束，
    % 我们必须把 -1 <= A'y <= 1 拆成两个部分：
    % 1)  A' * y <= 1
    % 2) -A' * y <= 1
    model.A = [sparse(A'); sparse(-A')];
    
    % 约束右端项: 都是 1
    model.rhs = ones(2*n, 1);
    
    % 约束符号: 都是小于等于
    model.sense = '<';
    
    % --- 2. 求解 ---
    
    params.OutputFlag = 0; % 静默模式
    params.Method = 2;     % 2 = Barrier (内点法) 通常对这类问题最快
    params.Crossover = 0;  % 关闭交叉验证可加速，但得到的对偶解可能非基解（不影响恢复x）
    
    try
        result = gurobi(model, params);
    catch me
        error('Gurobi 调用失败: %s', me.message);
    end
    
    % --- 3. 恢复原信号 x ---
    
    if isfield(result, 'x')
        % 注意：这里的 result.x 是对偶问题变量 y 的解
        % 我们需要的是原问题变量 x，它对应于 Gurobi 约束的"影子价格" (Shadow Prices / Duals)
        % Gurobi 将其存储在 result.pi 中
        
        if ~isfield(result, 'pi')
            error('Gurobi 未返回影子价格 (pi)，无法恢复 x。请检查求解方法是否支持对偶提取。');
        end
        
        pi_vec = result.pi; % 长度为 2n
        
        % pi_vec 的前 n 个元素对应约束  A'y <= 1
        % pi_vec 的后 n 个元素对应约束 -A'y <= 1
        
        pi_pos = pi_vec(1:n);
        pi_neg = pi_vec(n+1:end);
        
        % --- 数学推导结论 ---
        % 根据 KKT 条件平稳性: -b + [A, -A] * pi = 0
        % => b = A * pi_pos - A * pi_neg
        % => b = A * (pi_pos - pi_neg)
        % 因此 x = pi_pos - pi_neg
        
        x = -pi_pos + pi_neg;
        
    else
        error('Gurobi 求解未成功，状态: %s', result.status);
    end

end