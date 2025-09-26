% RUN_GENFAULT_VALIDATION Validate generalized fault calculations
clear all; close all; clc;

fprintf('=== GENERALIZED FAULT CALCULATION VALIDATION ===\n\n');

%% Part (a): Line 8 outage in IEEE 9-bus system
fprintf('PART (A): LINE 8 OUTAGE (8-9) IN IEEE 9-BUS SYSTEM\n');
fprintf('==================================================\n\n');

% Load IEEE 9-bus system
ieee9_A1;

% Create healthy network (full system)
YN = admittance(nfrom, nto, r, x, b);
IintN = Iint;

% Create fault network (system with line 8-9 removed)
fprintf('Creating fault network by removing line 8-9...\n');

% Find and remove line 8-9
line_to_remove = find((nfrom == 8 & nto == 9) | (nfrom == 9 & nto == 8));
if isempty(line_to_remove)
    error('Line 8-9 not found in the network');
end

nfrom_f = nfrom;
nto_f = nto;
r_f = r;
x_f = x;
b_f = b;

nfrom_f(line_to_remove) = [];
nto_f(line_to_remove) = [];
r_f(line_to_remove) = [];
x_f(line_to_remove) = [];
b_f(line_to_remove) = [];

YF = admittance(nfrom_f, nto_f, r_f, x_f, b_f);
IintF = Iint;  % Same current injections

% Connect at all nodes (simulate line outage)
idN = 1:9;
idF = 1:9;

[IT_a, VNF_a] = genfault(YN, YF, IintN, IintF, idN, idF);

% Display results for line outage
fprintf('\nLINE OUTAGE ANALYSIS RESULTS:\n');
fprintf('=============================\n');

VN_original = linsolve(YN, IintN);
fprintf('Node   Pre-fault |V|   Post-outage |V|   Change\n');
fprintf('----   -------------   --------------   ------\n');
for i = 1:9
    fprintf('%2d       %8.4f        %8.4f       %7.4f\n', ...
            i, abs(VN_original(i)), abs(VNF_a(i)), abs(VNF_a(i)) - abs(VN_original(i)));
end

%% Part (b): Two IEEE 9-bus systems connected at node 1 and node 5
fprintf('\n\nPART (B): TWO IEEE 9-BUS SYSTEMS CONNECTED AT N1-N5\n');
fprintf('==================================================\n\n');

% Two identical IEEE 9-bus systems
YN_b = YN;
YF_b = YN;  % Same system
IintN_b = Iint;
IintF_b = Iint;

% Connect at node 1 (healthy) to node 5 (fault)
idN_b = 1;
idF_b = 5;

[IT_b, VNF_b] = genfault(YN_b, YF_b, IintN_b, IintF_b, idN_b, idF_b);

fprintf('\nTwo-system connection results:\n');
fprintf('Tie-line current: %.4f ∠ %.2f° p.u.\n', abs(IT_b(1)), angle(IT_b(1))*180/pi);

%% Part (c): Multiple connections between two systems
fprintf('\n\nPART (C): MULTIPLE CONNECTIONS N3-N7 AND N5-N4\n');
fprintf('==============================================\n\n');

idN_c = [3, 5];
idF_c = [7, 4];

[IT_c, VNF_c] = genfault(YN, YN, Iint, Iint, idN_c, idF_c);

fprintf('\nMultiple connection results:\n');
for i = 1:length(IT_c)
    fprintf('Tie-line %d (N%d-F%d): %.4f ∠ %.2f° p.u.\n', ...
            i, idN_c(i), idF_c(i), abs(IT_c(i)), angle(IT_c(i))*180/pi);
end

%% Part (d): IEEE 24-bus system interconnected with itself
fprintf('\n\nPART (D): IEEE 24-BUS SYSTEM SELF-INTERCONNECTION\n');
fprintf('================================================\n\n');

% Load IEEE 24-bus system
ieee24_A1;

YN_d = admittance(nfrom, nto, r, x, b);
IintN_d = Iint;

% Create second identical system
YF_d = YN_d;
IintF_d = Iint;

% Connection points: 7-3, 13-15, 23-17
idN_d = [7, 13, 23];
idF_d = [3, 15, 17];

fprintf('Interconnection points:\n');
fprintf('  System 1 node %d <-> System 2 node %d\n', idN_d(1), idF_d(1));
fprintf('  System 1 node %d <-> System 2 node %d\n', idN_d(2), idF_d(2));
fprintf('  System 1 node %d <-> System 2 node %d\n', idN_d(3), idF_d(3));

[IT_d, VNF_d] = genfault(YN_d, YF_d, IintN_d, IintF_d, idN_d, idF_d);

% Display results for 24-bus system
fprintf('\nIEEE 24-BUS SYSTEM INTERCONNECTION RESULTS:\n');
fprintf('==========================================\n');

VN_original_d = linsolve(YN_d, IintN_d);

fprintf('\nTie-line currents:\n');
for i = 1:length(IT_d)
    fprintf('  Connection %d-%d: %.4f ∠ %.2f° p.u.\n', ...
            idN_d(i), idF_d(i), abs(IT_d(i)), angle(IT_d(i))*180/pi);
end

fprintf('\nVoltage magnitudes in first system:\n');
fprintf('Node   Original |V|   Interconnected |V|   Change\n');
fprintf('----   ------------   ------------------   ------\n');

for i = 1:min(24, length(VNF_d))  % Display first 24 nodes
    fprintf('%2d       %8.4f        %8.4f       %7.4f\n', ...
            i, abs(VN_original_d(i)), abs(VNF_d(i)), abs(VNF_d(i)) - abs(VN_original_d(i)));
end

% Summary of largest changes
voltage_changes_d = abs(VNF_d) - abs(VN_original_d);
[max_change, max_node] = max(abs(voltage_changes_d));
fprintf('\nSummary:\n');
fprintf('Maximum voltage change: %.4f p.u. at node %d\n', max_change, max_node);
fprintf('Total tie-line power flow: %.4f p.u.\n', sum(abs(IT_d)));

fprintf('\n=== GENERALIZED FAULT ANALYSIS COMPLETE ===\n');

% Save results
save('genfault_results.mat', 'IT_a', 'VNF_a', 'IT_b', 'VNF_b', 'IT_c', 'VNF_c', 'IT_d', 'VNF_d');

%-----------------------------------------------------
%% Validation Tests
fprintf('\n\n=== VALIDATION TESTS ===\n');
fprintf('=======================\n');

% Test Part (b) results
fprintf('\nPART (B) VALIDATION:\n');
fprintf('-------------------\n');
fprintf('Tie-line current: %.4f + j%.4f p.u. (|I| = %.4f p.u.)\n', real(IT_b), imag(IT_b), abs(IT_b));

% Check power balance
S_injected_b = VNF_b .* conj(IintN_b);
total_power_b = sum(S_injected_b);
fprintf('Total power balance: %.6f + j%.6f VA\n', real(total_power_b), imag(total_power_b));

% Check voltage magnitude range
fprintf('Voltage magnitude range: %.4f to %.4f p.u.\n', min(abs(VNF_b)), max(abs(VNF_b)));

% Check load bus voltages (typical IEEE 9-bus load buses: 5, 6, 8)
load_buses_b = [5, 6, 8];
fprintf('Load bus voltages:\n');
for i = 1:length(load_buses_b)
    node = load_buses_b(i);
    fprintf('  Node %d: %.4f p.u. (angle: %.2f°)\n', node, abs(VNF_b(node)), angle(VNF_b(node))*180/pi);
end

% Test Part (c) results
fprintf('\nPART (C) VALIDATION:\n');
fprintf('-------------------\n');

% Check tie-line current balance
fprintf('Tie-line currents:\n');
for i = 1:length(IT_c)
    fprintf('  Tie-line %d: %.4f + j%.4f p.u. (|I| = %.4f p.u.)\n', ...
            i, real(IT_c(i)), imag(IT_c(i)), abs(IT_c(i)));
end

fprintf('Sum of tie-line currents: %.6f + j%.6f (should be near zero)\n', ...
        real(sum(IT_c)), imag(sum(IT_c)));

% Check power balance
S_injected_c = VNF_c .* conj(IintN);
total_power_c = sum(S_injected_c);
fprintf('Total power balance: %.6f + j%.6f VA\n', real(total_power_c), imag(total_power_c));

% Check voltage magnitude range
fprintf('Voltage magnitude range: %.4f to %.4f p.u.\n', min(abs(VNF_c)), max(abs(VNF_c)));

% Check specific buses mentioned in connection
connection_buses_c = [3, 4, 5, 7];
fprintf('Connection bus voltages:\n');
for i = 1:length(connection_buses_c)
    node = connection_buses_c(i);
    fprintf('  Node %d: %.4f p.u. (angle: %.2f°)\n', node, abs(VNF_c(node)), angle(VNF_c(node))*180/pi);
end

% Physical consistency checks
fprintf('\nPHYSICAL CONSISTENCY CHECKS:\n');
fprintf('---------------------------\n');

% 1. Check if voltages are within reasonable range (0.9-1.1 p.u. typical)
reasonable_voltage = all(abs(VNF_b) > 0.8 & abs(VNF_b) < 1.2);
fprintf('Voltages in reasonable range (0.8-1.2 p.u.): %s\n', string(reasonable_voltage));

% 2. Check if angles are within typical range (-30° to +30°)
angles_b = angle(VNF_b) * 180/pi;
reasonable_angles = all(angles_b > -50 & angles_b < 50);
fprintf('Angles in reasonable range (-50° to +50°): %s\n', string(reasonable_angles));

% 3. Check if there's a clear reference angle (one angle near 0°)
[~, ref_node] = min(abs(angles_b));
fprintf('Reference angle node: %d (angle = %.2f°)\n', ref_node, angles_b(ref_node));

% Compare with your friend's results
fprintf('\nCOMPARISON WITH FRIEND''S RESULTS:\n');
fprintf('--------------------------------\n');

% For part (b)
fprintf('Part (b) - Tie-line current magnitude:\n');
fprintf('  Your result: %.4f p.u.\n', abs(IT_b));
fprintf('  Friend''s result: 0.0563 p.u.\n');
fprintf('  Difference: %.4f p.u.\n', abs(abs(IT_b) - 0.0563));

% For part (c) - check if currents are balanced
fprintf('\nPart (c) - Tie-line current balance:\n');
fprintf('  Your sum: %.6f + j%.6f p.u.\n', real(sum(IT_c)), imag(sum(IT_c)));
fprintf('  Friend''s sum: %.6f + j%.6f p.u.\n', 0.2727-0.2835, -0.0209+0.0202);

% Save validation results
save('validation_results.mat', 'VNF_b', 'IT_b', 'VNF_c', 'IT_c');

fprintf('\n=== VALIDATION COMPLETE ===\n');
