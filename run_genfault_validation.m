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

% Save validation results
save('validation_results.mat', 'VNF_b', 'IT_b', 'VNF_c', 'IT_c');

fprintf('\n=== VALIDATION COMPLETE ===\n');
