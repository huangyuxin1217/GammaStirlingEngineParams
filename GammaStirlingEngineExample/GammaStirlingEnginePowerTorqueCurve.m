%% Plot power and torque curves for Stirling engine example
% This script simulates a gamma Stirling engine ramping up in speed, to
% compute the associated power and torque curves in function of shaft
% speed.
% The impulse torque source is disabled (commented out) and a ramp angular
% velocity source is enabled (uncommented) to provide a range of angular
% speeds lower and higher than the operating point.

% Copyright 2019 The MathWorks, Inc.

%% Simulate

if ~strcmp(bdroot, 'GammaStirlingEngine')
    open_system('GammaStirlingEngine')
end

omSourcePath = 'GammaStirlingEngine/Slider-Crank and Flywheel/omegaSource';
torSourcePath = 'GammaStirlingEngine/Slider-Crank and Flywheel/torqueSource';
if ~exist('out_rpmRamp', 'var')
set_param(omSourcePath, 'commented', 'off');
set_param(torSourcePath, 'commented', 'on');
out_rpmRamp = sim('GammaStirlingEngine');
end
set_param(omSourcePath, 'commented', 'on');
set_param(torSourcePath, 'commented', 'off');


%% Extract variables

tor = out_rpmRamp.simlog_GammaStirlingEngine.Slider_Crank_and_Flywheel.SliderCrank.t.series.values('N*m');
om = out_rpmRamp.simlog_GammaStirlingEngine.Slider_Crank_and_Flywheel.Flywheel_Inertia.w.series.values('rad/s');
theta = out_rpmRamp.simlog_GammaStirlingEngine.Slider_Crank_and_Flywheel.SliderCrank.theta.series.values('rad');
tout = out_rpmRamp.tout;


%% Compute indexes of each cycle

numCycles = floor((theta(end)-theta(1))/(2*pi));
period_idx = nan(numCycles, 1);
for n = 1:numCycles
period_idx(n) = find(theta - theta(1) > 2*pi*n, 1, 'first');
end


%% Compute average torque in each cycle and shaft speed in each cycle

tor_cycle = nan(numCycles, 1);

tor_cycle(1) = 1./(tout(period_idx(1))).*...
    trapz(tout(1:period_idx(1)), tor(1:period_idx(1)));
for i = 2:numCycles
tor_cycle(i) = 1./(tout(period_idx(i)) - tout(period_idx(i-1))).*...
    trapz(tout(period_idx(i-1):period_idx(i)), tor(period_idx(i-1):period_idx(i)));
end
om_cycle = om(period_idx);

%% Plot power and torque curves

%Remove 1st cycle
om_cycle(1) = [];
tor_cycle(1) = [];

if ~exist('torPowFig', 'var') || ~isgraphics(torPowFig, 'figure')
    torPowFig = figure('Name','GammaStirlingEngine');
end
figure(torPowFig);
clf(torPowFig);

yyaxis left;
plot(om_cycle*60/(2*pi), -tor_cycle);
title('Power and Torque curves');
xlabel('Shaft speed [RPM]');
ylabel('Torque [N*m]');

yyaxis right;
plot(om_cycle*60/(2*pi), -om_cycle.*tor_cycle);
ylabel('Power [W]');
grid on;


%% Clean up
clear i n numCycles om om_cycle omSourcePath period_idx theta tor tor_cycle;
clear torSourcePath tout;

