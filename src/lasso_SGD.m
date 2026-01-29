function x = lasso_SGD(x0, A, b, mu, opts)
    %%%
    % 从输入的结构体 |opts| 中读取参数或采取默认参数。
    %
    % * |opts.itr| ：外层迭代的最大迭代步数
    % * |opts.gamma| ：线搜索参数
    if ~isfield(opts, 'gamma'); opts.gamma = 0.9; end
    %gamma = opts.gamma;
    %%%
    % 迭代准备。
    x = x0;
    L = opts.L;
    %Cval = 0;
    alpha = 1 / L;
    %%%
    % 次梯度下降迭代
    for k = 1:opts.itr_inn
        % 计算次梯度
        sg = sub_grad(A, x, b, mu);
        
        % 步长选择（可以使用递减步长）
        
        % 线搜索：Armijo准则
        f_old = 0.5*norm(A*x - b, 2)^2 + mu*norm(x, 1);
        x_new = x - alpha * sg;
        f_new = 0.5*norm(A*x_new - b, 2)^2 + mu*norm(x_new, 1);
        %Cval = (f_old + gamma * Cval) / (1 + gamma);
        % 如果不满足下降条件，减小步长
        nls = 0;
        while f_new > f_old - 0.5*alpha*norm(sg, 2)^2 && nls < 5
            alpha = 0.9 * alpha;
            x_new = x - alpha * sg;
            f_new = 0.5*norm(A*x_new - b, 2)^2 + mu*norm(x_new, 1);
            nls = nls + 1;
        end
        
        x = x_new;
        alpha = min(max(alpha, 1 / L), 1e12);

    end
    
end

function sg = sub_grad(A, x, b, mu)
    sg = A' * (A*x - b) + mu * sign(x);
end