function [x, out] = bp_ALM(x0, A, b, opts)
    %%%
    % 从输入的结构体 |opts| 中读取参数或采取默认参数。
    %
    % * |opts.itr| ：外层迭代的最大迭代步数
    % * |opts.itr_inn| ：内层迭代的最大迭代步数
    % * |opts.sigma| ：罚因子
    % * |opts.tol0| ：初始的收敛精度
    % * |opts.gamma| ：线搜索参数
    % * |opts.verbose| ：表示输出的详细程度， |>1| 时每一步输出， |=1| 时每一次外层循环输出， |=0| 时不输出
    if ~isfield(opts, 'itr'); opts.itr = 20; end
    if ~isfield(opts, 'itr_inn'); opts.itr_inn = 2500; end
    if ~isfield(opts, 'sigma'); opts.sigma = 1; end
    if ~isfield(opts, 'tol0'); opts.tol0 = 1e-1; end
    if ~isfield(opts, 'gamma'); opts.gamma = 0.9; end
    if ~isfield(opts, 'verbose'); opts.verbose = 0; end
    sigma = opts.sigma;
    gamma = opts.gamma;

    %%%
    % 迭代准备。
    k = 0;
    out = struct();

    %%%
    % 计算并记录初始时刻的约束违反度。
    out.feavec = norm(A*x0 - b);
    x = x0;
    lambda = zeros(size(b));
    out.itr_inn = 0;
    out.relative_error = norm(x0 - opts.x_true) / norm(opts.x_true);

    if opts.video
        itervec = zeros(length(x0),opts.itr);
    end
    L = sigma*eigs(A'*A,1);


    while k < opts.itr  

        Axb = A*x - b;
        c = Axb + lambda/sigma;
        g = sigma*(A'*c);
        tmp = .5*sigma*norm(c,2)^2;
        f = norm(x,1) + tmp;

        nrmG = norm(x - prox(x - g,1),2);
        tol_t = opts.tol0*10^(-k);
        t = 1/L;

        Cval = tmp; Q = 1;
        k1 = 0;

        while k1 < opts.itr_inn 
            %&& nrmG > tol_t
            
            gp = g;
            xp = x;
    
            x = prox(xp - t*gp, t);
            nls = 1;
            
            while 1
                tmp = 0.5 *sigma*norm(A*x - b + lambda/sigma, 2)^2;
                if tmp <= Cval + g'*(x-xp) + .5*sigma/t*norm(x-xp,2)^2 || nls == 5
                    break;
                end

                t = 0.2*t;
                nls = nls + 1;
                x = prox(xp - t * g, t);
            end
            
            f = tmp + norm(x,1);
            nrmG = norm(x - xp,2)/t;
            Axb = A*x - b;
            c = Axb + lambda/sigma;
            g = sigma*(A' * c);

            dx = x - xp;
            dg = g - gp;
            dxg = abs(dx'*dg);
            if dxg > 0
                if mod(k,2) == 0
                    t = norm(dx,2)^2/dxg;
                else
                    t = dxg/norm(dg,2)^2;
                end
            end
            
            t = min(max(t,1/L),1e12);
            Qp = Q; Q = gamma*Qp + 1; Cval = (gamma*Qp*Cval + tmp)/Q;
            k1 = k1 + 1;
            if opts.verbose > 1
                fprintf('itr_inn: %d\tfval: %e\t nrmG: %e\n', k1, f,nrmG);
            end
        end
        
        if opts.verbose
            fprintf('itr_inn: %d\tfval: %e\t nrmG: %e\n', k1, f,nrmG);
        end
        
        lambda = lambda + sigma*Axb;
        k = k + 1;
        out.feavec = [out.feavec; norm(Axb)];
        out.relative_error = [out.relative_error; norm(x - opts.x_true) / norm(opts.x_true)];
        if opts.video
            itervec(:,k) = x;
        end
        out.itr_inn = out.itr_inn + k1;
    end

    out.fval = f;
    out.itr = k;
    if opts.video
        out.itervec = itervec;
    end
end

function y = prox(x,mu)
    y = max(abs(x) - mu, 0);
    y = sign(x) .* y;
end


