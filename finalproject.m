% Design and analysis script for ME 4550 final design project
%
% Matthew Bonanni, Nicolas Iacovelli, Adrian Kombe, Ryan Loehr, Becca Sung

%% Parameters and Characteristics

% Gear diameters
d_A = 24;
d_C = 10;

% Load parameters
P_Angle = 20;
P_A = 600;

% Length parameters
OA = 20;
AB = 16;
BC = 10;

% Material characteristics
n_desired = 3;
Sy = 71000;
Sut = 85000;
E = 29000000;

%% Force balance

% Breaking P_A into components
A_y = P_A * cosd(P_Angle);
A_z = P_A * sind(P_Angle);

% The torque generated by P_A
T = A_y * (d_A/2);

% Calculate P_C from torque balance
C_z = T / (d_C / 2);
P_C = C_z / cosd(P_Angle);
C_y = P_C * sind(P_Angle);

% Z Moment balance around B
O_y = -(A_y * AB + C_y * BC) / (OA + AB);
B_y = -O_y - A_y + C_y;

% Y Moment balance around B
O_z = (A_z * AB + C_z * BC) / (OA + AB);
B_z = - O_z + A_z - C_z;

% Moments at A
M_Ay = O_z * OA;
M_Az = -O_y * OA;
M_A_tot = sqrt((M_Ay^2) + (M_Az)^2);

% Moments at B
M_By = -C_z * BC;
M_Bz = -C_y * BC;
M_B_tot = sqrt((M_By^2)+(M_Bz^2));

%% Stresses

M_a = max(M_A_tot, M_B_tot);

% Critical point determined to be at B, where M_tot is largest

syms d % symbolic shaft diameter

sigma_a = (32* M_a / (pi*d^3));
sigma_m = 0;
M_m = 0;
tao_a = 0;
T_a = 0;
tao_m = (16* M_a / (pi*d^3));
T_m = T;

Kf = 1;
Kfs = 1;

sigma_a_prime = ((Kf*sigma_a)^2+3*(Kfs*tao_a)^2)^.5;
sigma_m_prime = ((Kf*sigma_m)^2+3*(Kfs*tao_m)^2)^.5;

%% Diameter calculation based on static approach
% Using Distortion Energy (DE) Method

syms d_s % symbolic shaft diameter

sigma = (32 * M_a / (pi*d_s^3));
tao = (16 * M_a / (pi*d_s^3));

sigma_prime = (sigma^2 + 3*tao^2)^.5;
n_y = Sy / sigma_prime;
solutions = double(solve(n_y - n_desired));

d_s = solutions((solutions > 0) & imag(solutions) == 0);

%% Diameter calculation based on fatigue approach

% Fatigue failure conditions
Se_prime = Sut * .5;
ka_a = 2.7;
ka_b = -.265;
ka = (ka_a)*((Sut/1000)^(ka_b));
kb = .9; % guess for fist iteration
kc = 1; % 1 for combined loading

Se = (ka * kb * kc * Se_prime);

% Using DE-Goodman Method

tolerance = 1;
MGM_dnext = 6; % Initial diameter assumption

while tolerance >= .001
    MGM_d = double(solve(((16 * n_desired / (pi * d^3)) * ((Se^-1) * sqrt(4* (Kf * M_a)^2 + ...
        3 * (Kfs * T_a)^2) + (Sut^-1) * sqrt(4 * (Kf * M_m)^2 + 3 * (Kfs * T_m)^2))) - 1));
    
    MGM_d = MGM_d((MGM_d > 0) & imag(MGM_d) == 0); % Select real, positive solution
    tolerance = abs(((MGM_d - MGM_dnext) / MGM_d));
    MGM_dnext = MGM_d;
    kb = (.879 * MGM_d^-.107);
    Se = (ka * kb * kc * Se_prime);
end

% Using DE-Gerber Method

tolerance = 1;
Ger_dnext = 6; % Initial diameter assumption

while tolerance >= .001
    Ger_d = double(solve((n_desired * sigma_a_prime / Se) +...
        (n_desired * sigma_m_prime / Sy)^2 - 1));
    
    Ger_d = Ger_d((Ger_d > 0) & imag(Ger_d) == 0); % Select real, positive solution
    tolerance = abs(((Ger_d - Ger_dnext) / Ger_d));
    Ger_dnext = Ger_d;
    kb = (.879 * Ger_d^-.107);
    Se = (ka * kb * kc * Se_prime);
end

% Using DE-ASME Elliptic Method

tolerance = 1;
ASME_dnext = 6; % Initial diameter assumption

while tolerance >= .001
    ASME_d = double(solve((n_desired * sigma_a_prime / Se)^2 +...
        (n_desired * sigma_m_prime / Sy)^2 - 1));
    
    ASME_d = ASME_d((ASME_d > 0) & imag(ASME_d) == 0); % Select real, positive solution
    tolerance = abs(((ASME_d - ASME_dnext) / ASME_d));
    ASME_dnext = ASME_d;
    kb = (.879 * ASME_d^-.107);
    Se = (ka * kb * kc * Se_prime);
end

% Using DE-Soderberg Method

tolerance = 1;
Soder_dnext = 6; % Initial diameter assumption

while tolerance >= .001
    Soder_d = double(solve(((16 * n_desired / (pi * d^3)) * ((Se^-1) * sqrt(4 * (Kf * M_a)^2 + ...
        3 * (Kfs * T_a)^2) + (Sy^-1) * sqrt(4 * (Kf * M_m)^2 + 3 * (Kfs * T_m)^2))) - 1));
    
    Soder_d = Soder_d((Soder_d > 0) & imag(Soder_d) == 0); % Select real, positive solution
    tolerance = abs(((Soder_d - Soder_dnext) / Soder_d));
    Soder_dnext = Soder_d;
    kb = (.879 * Soder_d^-.107);
    Se = (ka * kb * kc * Se_prime);
end

% Soder_d = 2.632 in, therefore select standard 2 5/8" shaft

d_actual = 2.625;

%% Deflection - Integral Method

I = (pi / 64) * d_actual ^ 4;

s = 0.01; % step size

% Determine segment domains
x_OA = 0:s:20;
x_AB = 20+s:s:36;
x_BC = 36+s:s:46;

% Combined domain
x = [x_OA x_AB x_BC];

% Calculate piecewise forces
Fy_OA = O_y + zeros(size(x_OA));
Fy_AB = O_y + A_y + zeros(size(x_AB));
Fy_BC = O_y + A_y + B_y + zeros(size(x_BC));

Fz_OA = O_z + zeros(size(x_OA));
Fz_AB = O_z - A_z + zeros(size(x_AB));
Fz_BC = O_z - A_z + B_z + zeros(size(x_BC));

% Forces across the length of the shaft
F_y = [Fy_OA Fy_AB Fy_BC];
F_z = [Fz_OA Fz_AB Fz_BC];

% Integrate to determine moments across the shaft
M_y = cumtrapz(x, F_z);
M_z = cumtrapz(x, F_y);

% First integral of moment
int1M_y = cumtrapz(x, M_y);
int1M_z = cumtrapz(x, M_z);

% Second integral of moment
int2M_y = cumtrapz(x, int1M_y);
int2M_z = cumtrapz(x, int1M_z);

% Calculate constants of integration based on
% delta(0) = 0, delta(36) = 0
c1_y = - int2M_y(x == 36) / (36 * E * I);
c1_z = - int2M_z(x == 36) / (36 * E * I);

% Calculate deflection curves
delta_y = (int2M_y / (E * I)) + c1_y * x;
delta_z = (int2M_z / (E * I)) + c1_z * x;

% Calculate slope curves
slope_y = (int1M_y / (E * I)) + c1_y;
slope_z = (int1M_z / (E * I)) + c1_z;

% Calculate magnitudes of all curves
F = sqrt(F_y.^2 + F_z.^2);
M = sqrt(M_y.^2 + M_z.^2);
delta = sqrt(delta_y.^2 + delta_z.^2);
slope = sqrt(slope_y.^2 + slope_z.^2);

% Determine maximum deflection
delta_max = max(delta);
slope_O = slope(x == 0);
slope_B = slope(x == 36);

%{
%% Graphs

figure;

subplot(2, 2, 1);
hold on
plot(x, F_y, 'LineWidth', 2);
plot(x, F_z, 'LineWidth', 2);
plot(x, F, 'LineWidth', 2);
fplot(@(x) 0, [0 46], 'k--');
title("Shear")
xlabel("Shaft Position (in)");
ylabel("Shear (lbf)");
legend({"y-direction", "z-direction", "total"}, 'Location', 'best');

subplot(2, 2, 2);
hold on
plot(x, M_y, 'LineWidth', 2);
plot(x, M_z, 'LineWidth', 2);
plot(x, M, 'LineWidth', 2);
fplot(@(x) 0, [0 46], 'k--');
title("Moment")
xlabel("Shaft Position (in)");
ylabel("Moment (lbf-in)");
legend({"y-direction", "z-direction", "total"}, 'Location', 'best');

subplot(2, 2, 3);
hold on
plot(x, delta_y, 'LineWidth', 2);
plot(x, delta_z, 'LineWidth', 2);
plot(x, delta, 'LineWidth', 2);
fplot(@(x) 0, [0 46], 'k--');
title("Deflection")
xlabel("Shaft Position (in)");
ylabel("Deflection (in)");
legend({"y-direction", "z-direction", "total"}, 'Location', 'best');

subplot(2, 2, 4);
hold on
plot(x, slope_y, 'LineWidth', 2);
plot(x, slope_z, 'LineWidth', 2);
plot(x, slope, 'LineWidth', 2);
fplot(@(x) 0, [0 46], 'k--');
title("Slope")
xlabel("Shaft Position (in)");
ylabel("Slope (rad)")
legend({"y-direction", "z-direction", "total"}, 'Location', 'best');
%}

%% Critical speed

Nc = (30 / pi) * sqrt(32.2 * 12 / delta_max);

%% Keys

% Select standard key based on 2.625" shaft diameter
w1 = 5/8;
h1 = 5/8;

% Force at the key
F_key = T / (Soder_d / 2);

% Acceptable stresses at key
sigma_key = Sy / n_desired;
tao_key = (.577 * Sy) / n_desired;

% Length based on stresses
l_a_normal = F_key / (0.5 * h1 * sigma_key);
l_a_shear = F_key / (tao_key * w1);

% Stress concentration - use end-mill keyseat
Kf_key = 2.14;
Kfs_key = 3.0;

%% New shaft based on concentrations at key A

tolerance = 1;
d_keya_next = 6; % Initial diameter assumption

while tolerance >= .001
    d_keya = double(solve(((16 * n_desired / (pi * d^3)) * ((Se^-1) * sqrt(4 * (Kf_key * M_A_tot)^2 + ...
        3 * (Kfs_key * T_a)^2) + (Sy^-1) * sqrt(4 * (Kf_key * M_m)^2 + 3 * (Kfs_key * T_m)^2))) - 1));
    
    d_keya = d_keya((d_keya > 0) & imag(d_keya) == 0); % Select real, positive solution
    tolerance = abs(((d_keya - d_keya_next) / d_keya));
    d_keya_next = d_keya;
    kb = (.879 * d_keya^-.107);
    Se = (ka * kb * kc * Se_prime);
end

% Check for yielding

sigma_a_prime = Kf_key * 32 * M_A_tot / (pi * d_keya^3);
sigma_m_prime = sqrt(3) * Kfs_key * 16 * T_m / (pi * d_keya^3);

sigma_max = sigma_a_prime + sigma_m_prime;

n_keya = Sy / sigma_max;

% Re-check key design and pick new key w and h if necessary
% Select standard key based on 3.32" shaft diameter

w1 = 7/8;
h1 = 7/8;

% Force at the key
F_key = T / (d_keya / 2);

% Acceptable stresses at key
sigma_key = Sy / n_desired;
tao_key = (.577 * Sy) / n_desired;

% Length based on stresses
l_a_normal = F_key / (0.5 * h1 * sigma_key);
l_a_shear = F_key / (tao_key * w1);

%% New shaft based on concentrations at key C

M_C_tot = M(x == 46);

tolerance = 1;
d_keyc_next = 6; % Initial diameter assumption

while tolerance >= .001
    d_keyc = double(solve(((16 * n_desired / (pi * d^3)) * ((Se^-1) * sqrt(4 * (Kf_key * M_C_tot)^2 + ...
        3 * (Kfs_key * T_a)^2) + (Sy^-1) * sqrt(4 * (Kf_key * M_m)^2 + 3 * (Kfs_key * T_m)^2))) - 1));
    
    d_keyc = d_keyc((d_keyc > 0) & imag(d_keyc) == 0); % Select real, positive solution
    tolerance = abs(((d_keyc - d_keyc_next) / d_keyc));
    d_keyc_next = d_keyc;
    kb = (.879 * d_keyc^-.107);
    Se = (ka * kb * kc * Se_prime);
end

% Check for yielding

sigma_a_prime = Kf_key * 32 * M_C_tot / (pi * d_keyc^3);
sigma_m_prime = sqrt(3) * Kfs_key * 16 * T_m / (pi * d_keyc^3);

sigma_max = sigma_a_prime + sigma_m_prime;

n_keyc = Sy / sigma_max;

% Re-check key design and pick new key w and h if necessary
% Select standard key based on 3.32" shaft diameter

w1 = 7/8;
h1 = 7/8;

% Force at the key
F_key = T / (d_keya / 2);

% Acceptable stresses at key
sigma_key = Sy / n_desired;
tao_key = (.577 * Sy) / n_desired;

% Length based on stresses
l_c_normal = F_key / (0.5 * h1 * sigma_key);
l_c_shear = F_key / (tao_key * w1);

%% Bearings Selection

hp = 20;
rpm = (5252 * hp)*12 / T;
L = (rpm * 60 * 2 * 200 * 10) / 10^6; % rpm * h/day * day/yr * 10 years

lbf_to_N = 4.44822;

% Convert loads from lbf to N
O_y_N = O_y * lbf_to_N;
O_z_N = O_z * lbf_to_N;

B_y_N = B_y * lbf_to_N;
B_z_N = B_z * lbf_to_N;

Fr_O = sqrt(O_y_N^2 + O_z_N^2);
Fa_O = 0;

Fr_B = sqrt(B_y_N^2 + B_z_N^2);
Fa_B = 0;

% Purely radial loading, therefore
X = 1;
Y = 0;

a = 10/3; % Select roller bearings, because no axial load

V = 1; % Inner ring rotating

Fe_O = X * V * Fr_O + Y * Fa_O;
Fe_B = X * V * Fr_B + Y * Fa_B;

C_O = Fe_O * L ^ (1/a);
C_B = Fe_B * L ^ (1/a);

%% Bolt Calculations

% Bolt Parameters
d = .75; % Diameter of bolts
Wb = 1.125;  % Width of the bolt
Wt = .134; % Thickness of the washer
Lb = 4; % Length of the bolt
bh = 2.125; % Height of bearing housing
SP = .5; % Steel plate thickness
ECI = 14.5 * 10^6; % Given by book

PS = 120000; % Proof strength for the bolts of Grade 8 Steel
Se = 23200; % Endurance Strength of the bolts 
Sut = 150000;  % Ultimate strength of the bolts

HL = (Wt + bh + SP) / 2; % Dividing our Frustra into two
Dia_F1 = cosd(30)* HL + 1.125; % Dia of First Frustrum
Dia_F2 = (Dia_F1 / HL) * .8795; 

K1 = .5744 * pi * ECI * d / ((log(((1.155 * HL) + Wb - d) * (Wb + d)) / ...
    ((1.155 * HL + Wb + d) * (Wb - d))));
K2 = .5744 * pi * ECI * d / ((log((((1.155 * (Wt + bh - HL)) + Dia_F2 - d) ...
    * (Dia_F2 + d)) / ((1.155 * ((Wt + bh - HL) + Dia_F2 + d)) * (Dia_F2 - d)))));
K3 = .5744 * pi * E * d / ((log(((1.155 * (2 * HL - Wt + bh - HL)) + Wb - d) ...
    * (Wb + d)) / ((1.155 * ((2 * HL - Wt + bh - HL) + Wb + d) * (Wb - d)))));
Km = (((1 / K1) + (1 / K2) + (1 / K3))^-1);

Ad = pi * .75^2  / 4; % Bolt Area
At = 0.334; % Transverse area from Table 8-1
l_squeeze = Lb - SP - bh;  % Length squeezed in between bolts
Kb = E * At * Ad / ((At * 2.25) + (Ad * 1.75)); % Stiffness of bolt 

%Km = .5774 * pi * E * d / (2 * ln(5 * (.5774 * l_squeeze + .5 * d) / (.5774 * l_squeeze + 2.5 * d)))

c = Kb / (Kb + Km); 

% Force on the bolt
O_y_abs = abs(O_y);

Pb_O = O_y_abs * c / 4;
Pm_O = (1 - c) * O_y_abs / 4;

Fi = .75 * At * PS; % Suggested pre-load for bolt assuming semi-permanent status 
Np = PS * At / ((c * O_y_abs) + Fi); % Static factor of safety 
Sigma_amp = (c * O_y_abs) / (2 * At); % Amplitudal stress
Sigma_mid = Sigma_amp + (Fi / At); % Midline stress
Nf = Se * (Sut - (Fi / At)) / (Sigma_amp * (Sut + Se)); % Fatigue safety using Goodman method

% Load Factor Calculations
Nl= (PS * At - Fi) / (c * O_y_abs);

% Separation Factor
No = Fi / ((1 - c) * O_y_abs);

% Max Transverse Shear at Bolts
TS_O = (.25 * 4 * O_z) / (3*pi * .75^2 / 4);
TS_B = (.25 * 4 * B_z) / (3*pi * .75^2 / 4);

%% Gear Calculations

St = 22000; %psi for Steel, flame hardened type A Grade 1
Yn = .95;
Kt = 1;
Kr = 1; % for 99% reliability
sigma_gears = ((St * Yn/ (Kt * Kr)) /n_desired);
Qv = 7;

%Gear 3:
Kv3 = 1.4;
Wt3 = A_y;
Pd3 = 1;
teethnum3 = 24;
Y3 = .337;

%Face width for gear 3:
Face3 = Kv3 * Wt3 * Pd3 / (sigma_gears * Y3);

%Gear 4:
Kv4 = 1.2;
Wt4 = C_z;
Pd4 = 2;
teethnum4 = 20;
Y4 = .322;

%Face width for gear 4:
Face4 = Kv4 * Wt4 * Pd4 / (sigma_gears * Y4);