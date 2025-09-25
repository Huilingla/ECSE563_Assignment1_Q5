function Y = admittance(nfrom, nto, r, x, b)
% ADMITTANCE Calculate the admittance matrix for an AC power network using KCL.
%
%   Y = ADMITTANCE(NFROM, NTO, R, X, B) computes the nodal admittance matrix
%
%   Inputs:
%     nfrom - Mx1 vector of branch starting nodes
%     nto   - Mx1 vector of branch ending nodes  
%     r     - Mx1 vector of branch resistances (p.u.)
%     x     - Mx1 vector of branch reactances (p.u.)
%     b     - Mx1 vector of branch shunt susceptances (p.u.)
%
%   Output:
%     Y     - NxN nodal admittance matrix (p.u.)

    % Determine network size
    all_nodes = unique([nfrom; nto]);
    N = max(all_nodes);  % Total number of nodes
    M = length(nfrom);   % Total number of branches
    
    % Validate input dimensions
    if length(nto) ~= M || length(r) ~= M || length(x) ~= M || length(b) ~= M
        error('All input vectors must have the same length');
    end
    
    % Initialize admittance matrix
    Y = zeros(N, N);
    
    % Build admittance matrix
    for m = 1:M
        i = nfrom(m);
        j = nto(m);
        
        % Calculate series admittance for this branch
        z_series = r(m) + 1i*x(m);
        y_series = 1/z_series;
        
        % Shunt admittance (half at each end) from line charging
        y_shunt = 1i * b(m) / 2;
        
        % Update diagonal elements (sum of admittances connected to node)
        Y(i, i) = Y(i, i) + y_series + y_shunt;
        Y(j, j) = Y(j, j) + y_series + y_shunt;
        
        % Update off-diagonal elements (-admittance between nodes)
        Y(i, j) = Y(i, j) - y_series;
        Y(j, i) = Y(j, i) - y_series;
    end
end
