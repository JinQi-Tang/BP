function x = bp_mosek(A, b)
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
    A_aug = sparse([A, -A]);   % 增广矩阵 (MOSEK 要求稀疏格式)
    
    % 2. 配置 MOSEK 的 prob 结构体
    clear prob;
    prob.c = c;
    prob.a = A_aug;
    
    % 等式约束 Ax = b (即 b <= Ax <= b)
    prob.blc = b; 
    prob.buc = b;
    
    % 变量非负约束 z >= 0 (即 0 <= z <= +inf)
    prob.blx = zeros(2*n, 1);
    prob.bux = []; % 空代表正无穷
    
    % 3. 调用 mosekopt
    % 'minimize': 最小化
    % 'echo(0)': 关闭 MOSEK 自身的控制台输出 (避免刷屏，让 Logger 记录)
    [r, res] = mosekopt('minimize echo(0)', prob);
    
    % 4. 结果重构
    if strcmp(res.sol.itr.prosta, 'PRIMAL_AND_DUAL_FEASIBLE') || ...
       strcmp(res.sol.itr.prosta, 'PRIMAL_FEASIBLE')
        
        z_sol = res.sol.itr.xx; % 获取解向量 z = [u; v]
        
        % 还原 x = u - v
        u = z_sol(1:n);
        v = z_sol(n+1:end);
        x = u - v;
    else
        error('Mosek 求解失败，状态: %s', res.sol.itr.prosta);
    end
end
