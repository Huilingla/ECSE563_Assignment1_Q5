function [IT, VNF] = genfault(YN, YF, IintN, IintF, idN, idF)
% GENFAULT Perform generalized fault calculations for interconnected networks.
%
%   [IT, VNF] = GENFAULT(YN, YF, IINTN, IINTF, IDN, IDF) calculates
%   tie-line currents and voltages when two networks are interconnected.
%
%   Inputs:
%     YN    - NxN admittance matrix of healthy network
%     YF    - MxM admittance matrix of fault network  
%     IintN - Nx1 current injection vector of healthy network
%     IintF - Mx1 current injection vector of fault network
%     idN   - Vector of node indices in healthy network for connection
%     idF   - Vector of node indices in fault network for connection
%
%   Outputs:
%     IT    - Vector of tie-line currents between networks
%     VNF   - Vector of node voltages in healthy network after connection
%
%   Method:
%     1. Combine both networks into a larger system
%     2. Add tie-lines between specified connection points
%     3. Solve the combined system using linsolve

    fprintf('=== GENERALIZED FAULT CALCULATION ===\n\n');
    
    % Validate inputs
    N = size(YN, 1);
    M = size(YF, 1);
    
    if length(IintN) ~= N
        error('IintN must have same dimension as YN');
    end
    if length(IintF) ~= M
        error('IintF must have same dimension as YF');
    end
    if length(idN) ~= length(idF)
        error('idN and idF must have same length');
    end
    if max(idN) > N || min(idN) < 1
        error('idN contains invalid node indices');
    end
    if max(idF) > M || min(idF) < 1
        error('idF contains invalid node indices');
    end
    
    fprintf('Healthy network: %d nodes\n', N);
    fprintf('Fault network: %d nodes\n', M);
    fprintf('Connection points: ');
    for i = 1:length(idN)
        fprintf('N%d-F%d ', idN(i), idF(i));
    end
    fprintf('\n\n');
    
    % Step 1: Create combined admittance matrix
    fprintf('Step 1: Creating combined system\n');
    fprintf('--------------------------------\n');
    
    % Initialize combined admittance matrix
    Y_combined = blkdiag(YN, YF);
    
    % Add tie-lines between networks (infinite admittance = direct connection)
    for i = 1:length(idN)
        nodeN = idN(i);
        nodeF = idF(i) + N;  % Offset for fault network nodes
        
        % Add large admittance to simulate direct connection
        Y_combined(nodeN, nodeN) = Y_combined(nodeN, nodeN) + 1e6;
        Y_combined(nodeF, nodeF) = Y_combined(nodeF, nodeF) + 1e6;
        Y_combined(nodeN, nodeF) = Y_combined(nodeN, nodeF) - 1e6;
        Y_combined(nodeF, nodeN) = Y_combined(nodeF, nodeN) - 1e6;
        
        fprintf('  Added tie-line: Healthy node %d <-> Fault node %d\n', nodeN, idF(i));
    end
    
    % Step 2: Create combined current injection vector
    I_combined = [IintN; IintF];
    
    fprintf('Combined system size: %dx%d\n\n', size(Y_combined,1), size(Y_combined,2));
    
    % Step 3: Solve combined system
    fprintf('Step 2: Solving combined system\n');
    fprintf('-------------------------------\n');
    
    V_combined = linsolve(Y_combined, I_combined);
    
    % Extract voltages for healthy network
    VNF = V_combined(1:N);
    
    % Step 4: Calculate tie-line currents
    fprintf('Step 3: Calculating tie-line currents\n');
    fprintf('-------------------------------------\n');
    
    IT = zeros(length(idN), 1);
    for i = 1:length(idN)
        nodeN = idN(i);
        nodeF = idF(i) + N;
        
        % Current flow from healthy to fault network
        IT(i) = 1e6 * (V_combined(nodeN) - V_combined(nodeF));
        
        fprintf('  Tie-line %d (N%d-F%d): %.4f + j%.4f p.u. (|I| = %.4f p.u.)\n', ...
                i, idN(i), idF(i), real(IT(i)), imag(IT(i)), abs(IT(i)));
    end
    
   % Step 5: Display healthy network voltages - CORRECTED VERSION
fprintf('\nStep 4: Healthy Network Voltages with Fault Network Connected\n');
fprintf('-------------------------------------------------------------\n');

VN_original = linsolve(YN, IintN);

fprintf('Node   Pre-fault |V|∠θ°   Post-fault |V|∠θ°   Mag Change   Phase Change (°)\n');
fprintf('----   -----------------   ------------------   ----------   ---------------\n');
for i = 1:N
    pre_mag = abs(VN_original(i));
    post_mag = abs(VNF(i));
    mag_change = post_mag - pre_mag;
    
    pre_angle = angle(VN_original(i)) * 180/pi;
    post_angle = angle(VNF(i)) * 180/pi;
    phase_change = post_angle - pre_angle;
    
    fprintf('%3d     %6.4f∠%6.2f°    %6.4f∠%6.2f°    %9.4f      %9.2f\n', ...
            i, pre_mag, pre_angle, post_mag, post_angle, mag_change, phase_change);
end

% Display voltage in polar form (final state only)
fprintf('\nHealthy Network Voltages - Final State (Polar Form):\n');
fprintf('Node     Magnitude (p.u.)   Phase Angle (°)\n');
fprintf('----     ----------------   --------------\n');
for i = 1:N
    fprintf('%3d         %8.4f           %8.2f\n', ...
            i, abs(VNF(i)), angle(VNF(i))*180/pi);
end
