function x = bp_mosek_dual(A, b)
    % SOLVE_BP_MOSEK 使用 MOSEK 求解基追踪问题的对偶形式
    %   min ||x||_1  s.t.  Ax = b
    %   修正版：修复了恢复 x 时的符号错误
    
    [m, n] = size(A);

    % --- 1. 构建 MOSEK prob 结构体 ---
    
    % 目标函数：Maximize b'y  =>  Minimize -b'y
    prob.c = -b;
    
    % 约束矩阵：A'y
    prob.a = sparse(A');
    
    % 约束范围：-1 <= A'y <= 1 (对应 ||A'y||_inf <= 1)
    prob.blc = -ones(n, 1);
    prob.buc =  ones(n, 1);
    
    % 变量 y 的范围：无限制
    prob.blx = -inf(m, 1);
    prob.bux =  inf(m, 1);
    
    % --- 2. 调用 mosekopt 求解 ---
    % 增加 'statuskeys(1)' 可以让 MOSEK 返回更详细的解状态
    [r, res] = mosekopt('minimize echo(0)', prob);
    
    % --- 3. 提取结果 ---
    
    if isfield(res, 'sol')
        % 优先使用内点法解
        if isfield(res.sol, 'itr')
            sol = res.sol.itr;
        elseif isfield(res.sol, 'bas')
            sol = res.sol.bas;
        else
            error('MOSEK 求解完成但未返回有效解结构 (itr/bas)');
        end
        
        % --- 关键修正 ---
        % MOSEK 定义： prob.c = prob.a' * sol.y
        % 即： -b = A * sol.y
        % 所以： b = A * (-sol.y)
        x = -sol.y; 
        
    else
        % 错误处理：输出 MOSEK 返回码以便调试
        error('MOSEK 求解失败，未返回解。返回码 r: %d', r);
    end

end