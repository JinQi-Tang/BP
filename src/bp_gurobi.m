function x = bp_gurobi(A, b)
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