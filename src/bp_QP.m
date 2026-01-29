function [x, out] = bp_QP(x0, A, b, opts)

    if ~isfield(opts, 'itr'); opts.itr = 30; end
    if ~isfield(opts, 'itr_inn'); opts.itr_inn = 200; end
    if ~isfield(opts, 'sigma'); opts.sigma = 1; end
    sigma = opts.sigma;
    %%%
    % 迭代准备。
    k = 1;
    out = struct();

    x = x0;
    out.itr_inn = 0;
    out.feavec = norm(A*x0 - b);
    out.relative_error = norm(x0 - opts.x_true) / norm(opts.x_true);

    if opts.video
        itervec = zeros(length(x0),opts.itr);
    end

    L = eigs(A'*A,1);
    opts.L = L;

    while k < opts.itr  
        x = lasso_SGD(x, A, b, 1 / sigma, opts);
        k = k + 1;
        if opts.video
            itervec(:,k) = x;
        end
        out.feavec = [out.feavec; norm(A*x - b)];
        out.relative_error = [out.relative_error; norm(x - opts.x_true) / norm(opts.x_true)];
        if out.relative_error(k) > 0.9 * out.relative_error(k - 1)
            sigma = min(sigma * 3, 1e12);
        end
        if opts.video
            itervec(:,k) = x;
        end
        out.itr_inn = out.itr_inn + opts.itr_inn;
    end

    out.itr = k;
    if opts.video
        out.itervec = itervec;
    end
end


