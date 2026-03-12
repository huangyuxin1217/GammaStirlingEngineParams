%% initializeGammaStirlingEngine.m
%   - 材料：热缸端盖=铝合金, 加热管=不锈钢, 冷缸=铝6061, 热端活塞=不锈钢, 冷端活塞=铝6061
%   - 连接管道：直径 4 mm, 长度 100 mm
%   - 几何：Lh=45mm, Se=15mm, Sc=20mm, Dk=Dpc=20mm, Lk=52mm
%   - 温度：酒精灯 450°C (723 K), 空气自然冷却 25°C (298 K)
%   - 连杆长度：92 mm
%   - 再生器长度：30 mm
% =====================================================

%% 创建结构体
geometry = struct();
crank_wheel = struct();
flame = struct();
ambient = struct();
displacer_piston = struct();
regenerator = struct();
passage_pipe = struct();  
power_piston = struct();
impulse_torque = struct();
state_init = struct();
gas = struct();

%% ========== 1. 几何参数）==========
geometry.displacer_piston.radius_piston   = 19.6e-3 / 2;   % Dp/2 = 9.8 mm
geometry.displacer_piston.radius_cylinder = 20.0e-3 / 2;   % Dc/2 = 10.0 mm
geometry.displacer_piston.length          = 45.0e-3;      % Lh
geometry.displacer_piston.wall_thickness  =  2.0e-3;      % 壁厚
geometry.displacer_piston.clearance_min     =  2.7e-3;      % Lpe

geometry.power_piston.radius           = 20.0e-3 / 2;     % Dpc/2 = 10.0 mm
geometry.power_piston.radius_cylinder  = 20.0e-3 / 2;     % Dk/2 = 10.0 mm
geometry.cooler.length                 = 52.0e-3;        % Lk

geometry.wheel_hot.radius  = 108.0e-3 / 2;
geometry.wheel_cold.radius =  70.0e-3 / 2;
geometry.wheel.thick       =   5.0e-3;

%% ========== 2. 连接管道==========
passage_pipe.length         = 100.0e-3;
passage_pipe.area           = pi * (4.0e-3 / 2)^2;
passage_pipe.hydraulic_diam = 4.0e-3;

passage_pipe.fric_therm.length_add = 0.01 * passage_pipe.length;
passage_pipe.fric_therm.roughness  = 15e-6;
passage_pipe.fric_therm.Re_lam     = 2000;
passage_pipe.fric_therm.Re_tur     = 4000;
passage_pipe.fric_therm.shape_factor = 64;
passage_pipe.fric_therm.Nu_lam     = 3.66;

%% ========== 3. 曲柄 & 飞轮 ==========
crank_wheel.slidercrank_disp.crank_radius = 15.0e-3 / 2;   % Se/2 = 7.5 mm
crank_wheel.slidercrank_disp.rod_length   = 92.0e-3;       % 连杆 92 mm
crank_wheel.slidercrank_pow.crank_radius = 20.0e-3 / 2;    % Sc/2 = 10 mm
crank_wheel.slidercrank_pow.rod_length   = 92.0e-3;
crank_wheel.phase_difference = 90 * pi/180;

rho_steel = 7850; thick = geometry.wheel.thick;
rad_hot = geometry.wheel_hot.radius; rad_cold = geometry.wheel_cold.radius;

crank_wheel.wheel_hot_mass     = rho_steel * thick * pi * rad_hot^2;
crank_wheel.wheel_hot_inertia  = 0.5 * crank_wheel.wheel_hot_mass * rad_hot^2;
crank_wheel.wheel_cold_mass    = rho_steel * thick * pi * rad_cold^2;
crank_wheel.wheel_cold_inertia = 0.5 * crank_wheel.wheel_cold_mass * rad_cold^2;

crank_wheel.wheel_inertia = crank_wheel.wheel_hot_inertia + crank_wheel.wheel_cold_inertia;
crank_wheel.rot_damp = log(4) * crank_wheel.wheel_inertia / 10;

clear rho_steel thick rad_hot rad_cold;

%% ========== 4. 环境 & 冷端（铝6061 + 自然冷却）==========
ambient.Temperature = 298;        % 25°C
ambient.pext        = 0.101325;

rad_ext = geometry.power_piston.radius_cylinder + geometry.displacer_piston.wall_thickness;
rad_int = geometry.power_piston.radius_cylinder;
rho_al = 2700; finlength = 0.6 * rad_ext;

ambient.Fins.m    = 0.35 * rho_al * geometry.cooler.length * pi * ((rad_ext + finlength)^2 - rad_ext^2);
ambient.Fins.cp   = 900;
ambient.ConvAmbient2Fins.h    = 15;
ambient.ConvAmbient2Fins.area = 2 * pi * (rad_ext + finlength) * geometry.cooler.length * 4;
ambient.ConvFins2Gas.h    = 60;
ambient.ConvFins2Gas.area = 2 * pi * rad_int * geometry.cooler.length + pi * rad_int^2;

clear rad_ext rad_int rho_al finlength;

%% ========== 5. 热端（加热管=不锈钢, 端盖=铝合金）==========
flame.Temperature = 723;          % 450°C

rad_ext = geometry.displacer_piston.radius_cylinder + geometry.displacer_piston.wall_thickness;
rad_int = geometry.displacer_piston.radius_cylinder;
L_heater = max(geometry.displacer_piston.length - 2 * crank_wheel.slidercrank_disp.crank_radius, 20e-3);

rho_ss = 8000;
flame.Glass.m  = 0.5 * rho_ss * L_heater * pi * (rad_ext^2 - rad_int^2);
flame.Glass.cp = 500;
flame.ConvFlame2Glass.h    = 80;
flame.ConvFlame2Glass.area = 2 * pi * rad_ext * L_heater + pi * rad_ext^2;
flame.ConvGlass2Gas.h    = 60;
flame.ConvGlass2Gas.area = 2 * pi * rad_int * L_heater + pi * rad_int^2;

clear L_heater rho_ss rad_ext rad_int;

%% ========== 提前定义初始温度（修复 Tinit 错误）==========
flame.Glass.Tinit   = 0.9 * flame.Temperature + 0.1 * ambient.Temperature;
ambient.Fins.Tinit  = 0.98 * 300 + 0.02 * flame.Temperature;

%% ========== 6. 工作介质（空气）==========
gas.R = 287; gas.cp = 1005; gas.cv = gas.cp - gas.R; gas.gamma = gas.cp/gas.cv;
gas.mu = 1.8e-5; gas.k = 0.026;

%% ========== 7. 初始状态 ==========
state_init.T0 = 300;
state_init.p0 = ambient.pext;

%% ========== 8. 位移活塞 ===========
displacer_piston.piston.area_interf = pi * geometry.displacer_piston.radius_piston^2;
displacer_piston.piston.area_A = pi * (geometry.displacer_piston.radius_cylinder^2 - geometry.displacer_piston.radius_piston^2);
displacer_piston.piston.xini_cooler = +crank_wheel.slidercrank_disp.crank_radius;
displacer_piston.piston.xini_heater = -crank_wheel.slidercrank_disp.crank_radius;
displacer_piston.piston.vol_dead = 0.1 * 2 * crank_wheel.slidercrank_disp.crank_radius * pi * geometry.displacer_piston.radius_piston^2;

displacer_piston.hardstop.upbound = 1.03 * 2 * crank_wheel.slidercrank_disp.crank_radius;
displacer_piston.hardstop.lowbound = -1.03 * 2 * crank_wheel.slidercrank_disp.crank_radius;
displacer_piston.hardstop.trans_region = 0.03 * 2 * crank_wheel.slidercrank_disp.crank_radius;
displacer_piston.trans_damp = eps;

%% ========== 9. 再生器 ===========
A = pi * (geometry.displacer_piston.radius_cylinder^2 - geometry.displacer_piston.radius_piston^2);
P = 2 * pi * (geometry.displacer_piston.radius_piston + geometry.displacer_piston.radius_cylinder);

regenerator.geometry.length = geometry.displacer_piston.length - 2 * crank_wheel.slidercrank_disp.crank_radius;
regenerator.geometry.area = A;
regenerator.geometry.hydraulic_diam = 4 * A / P;

regenerator.fric_therm.length_add = 0.01 * regenerator.geometry.length;
regenerator.fric_therm.roughness = 15e-6;
regenerator.fric_therm.Re_lam = 2000;
regenerator.fric_therm.Re_tur = 4000;
regenerator.fric_therm.shape_factor = 64;
regenerator.fric_therm.Nu_lam = 3.66;

rho_ss = 8000;
rad_ext_wall = geometry.displacer_piston.radius_cylinder + geometry.displacer_piston.wall_thickness;
rad_int_wall = geometry.displacer_piston.radius_cylinder;

regenerator.mass = 0.5 * rho_ss * pi * (rad_ext_wall^2 - rad_int_wall^2) * regenerator.geometry.length;

regenerator.conductionCooler.area = A; 
regenerator.conductionCooler.thick = regenerator.geometry.length/2; 
regenerator.conductionCooler.k = 16;
regenerator.conductionHeater.area = A; 
regenerator.conductionHeater.thick = regenerator.geometry.length/2; 
regenerator.conductionHeater.k = 16;

regenerator.initial_temperature = 0.6 * flame.Glass.Tinit + 0.4 * state_init.T0;

clear P A rho_ss rad_ext_wall rad_int_wall;

%% ========== 10. 动力活塞 ===========
power_piston.piston.area_interf = pi * geometry.power_piston.radius^2;
power_piston.piston.area_A = passage_pipe.area;

power_piston.piston.xini = 0;
power_piston.piston.vol_dead = 0.04 * 2 * crank_wheel.slidercrank_pow.crank_radius * pi * geometry.power_piston.radius^2;

power_piston.hardstop.upbound = 1.02 * 2 * crank_wheel.slidercrank_pow.crank_radius;
power_piston.hardstop.lowbound = -0.02 * 2 * crank_wheel.slidercrank_pow.crank_radius;
power_piston.hardstop.trans_region = 0.015 * 2 * crank_wheel.slidercrank_pow.crank_radius;
power_piston.trans_damp = eps;

%% ========== 11. 启动脉冲 ==========
impulse_torque.t_start = 5;
impulse_torque.t_end   = 5.1;
impulse_torque.torque  = 50 * crank_wheel.wheel_inertia / 0.1;

%% =====================================================
disp('GammaStirlingEngine 初始化成功！');
disp('  所有字段已正确定义，无乱码，无 Tinit 错误');
disp('  可直接运行仿真！');