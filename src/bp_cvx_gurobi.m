function x = bp_cvx_gurobi(A, b)
    n = size(A, 2);
    cvx_begin
        cvx_solver gurobi
        variable x_var(n)
        minimize( norm(x_var, 1) ) 
        subject to
            A * x_var == b
    cvx_end
    x = x_var;
end