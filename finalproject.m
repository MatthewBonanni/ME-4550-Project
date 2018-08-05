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

% Fatigue failure conditions

Se_prime = Sut * .5;
ka_a = 2.7;
ka_b = -.265;
ka = (ka_a)*((Sut/1000)^(ka_b));
kb = .9;   %guess for fist iteration
kc = 1;     %1 for combined loading

Se = (ka * kb * kc * Se_prime);

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

%% Deflection - Integral Method

% Fatigue

I = (pi / 64) * Soder_d ^ 4;

s = 0.01; % step size

x_OA = 0:s:20;
x_AB = 20+s:s:36;
x_BC = 36+s:s:46;

x = [x_OA x_AB x_BC];

Fy_OA = O_y + zeros(size(x_OA));
Fy_AB = O_y + A_y + zeros(size(x_AB));
Fy_BC = O_y + A_y + B_y + zeros(size(x_BC));

F_y = [Fy_OA Fy_AB Fy_BC];

Fz_OA = O_z + zeros(size(x_OA));
Fz_AB = O_z - A_z + zeros(size(x_AB));
Fz_BC = O_z - A_z + B_z + zeros(size(x_BC));

F_z = [Fz_OA Fz_AB Fz_BC];

M_y = cumtrapz(x, F_z);
M_z = cumtrapz(x, F_y);

int1M_y = cumtrapz(x, M_y);
int1M_z = cumtrapz(x, M_z);

int2M_y = cumtrapz(x, int1M_y);
int2M_z = cumtrapz(x, int1M_z);

c1_y = - int2M_y(x == 36) / (36 * E * I);
c1_z = - int2M_z(x == 36) / (36 * E * I);

delta_y = (int2M_y / (E * I)) + c1_y * x;
delta_z = (int2M_z / (E * I)) + c1_z * x;

slope_y = (int1M_y / (E * I)) + c1_y;
slope_z = (int1M_z / (E * I)) + c1_z;

F = sqrt(F_y.^2 + F_z.^2);
M = sqrt(M_y.^2 + M_z.^2);
delta = sqrt(delta_y.^2 + delta_z.^2);
slope = sqrt(slope_y.^2 + slope_z.^2);

deflection = max(delta);

%% Critical speed

Nc = (30 / pi) * sqrt(32.2 * 12 / deflection);

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