%% Plot P-V diagram of Stirling engine thermodynamical cycle
% This script extracts last cycle's pressure and volume of a
% simulation of GammaStirlingEngine example and plots the corresponding P-V
% cycle, computing power and efficiency.

% Copyright 2019 The MathWorks, Inc.

%% Simulate

if ~strcmp(bdroot, 'GammaStirlingEngine')
    open_system('GammaStirlingEngine')
end

if ~exist('out', 'var')
 out = sim('GammaStirlingEngine');
end 


%% Extract pressure and volume data.

pressurePowerPiston = out.simlog_GammaStirlingEngine.Power_piston.Expansion_Piston.p_I.series.values('Pa'); 
volPowerPiston = out.simlog_GammaStirlingEngine.Power_piston.Expansion_Piston.volume.series.values('m^3');  


%% Get 1 cycle

samplesPerCycle = 1;
volChange = [0 0];
endVolume = volPowerPiston(end);
if endVolume < volPowerPiston(end-1)
    while endVolume < volPowerPiston(end-samplesPerCycle)
        endVolume = volPowerPiston(end-samplesPerCycle);
        samplesPerCycle = samplesPerCycle + 1;
    end
    volChange(1) = samplesPerCycle;
    while endVolume > volPowerPiston(end-samplesPerCycle)
        endVolume = volPowerPiston(end-samplesPerCycle);
        samplesPerCycle = samplesPerCycle + 1;
    end
    volChange(2) =  samplesPerCycle;
    while endVolume < volPowerPiston(end-samplesPerCycle)
        endVolume = volPowerPiston(end-samplesPerCycle);
        samplesPerCycle = samplesPerCycle + 1;
    end
else
    while endVolume > volPowerPiston(end-samplesPerCycle)
        endVolume = volPowerPiston(end-samplesPerCycle);
        samplesPerCycle = samplesPerCycle + 1;
    end
    volChange(1) =  samplesPerCycle;
    while  endVolume < volPowerPiston(end-samplesPerCycle)
        endVolume = volPowerPiston(end-samplesPerCycle);
        samplesPerCycle = samplesPerCycle + 1;
    end
    volChange(2) =  samplesPerCycle;
    while endVolume > volPowerPiston(end-samplesPerCycle)
        endVolume = volPowerPiston(end-samplesPerCycle);
        samplesPerCycle = samplesPerCycle + 1;
    end
end

% Complete cycle
volCycle = volPowerPiston(end-samplesPerCycle:end);
pressureCycle = pressurePowerPiston(end-samplesPerCycle:end);

% Upper and lower parts of cycle
volhalfCycle1 = volCycle([end:end-volChange(1)+1 1:end-volChange(2)-1]);
pressurehalfCycle1 = pressureCycle([end:end-volChange(1)+1 1:end-volChange(2)-1]);
volhalfCycle2 = volCycle(end-volChange(2):end-volChange(1));
pressurehalfCycle2 = pressureCycle(end-volChange(2):end-volChange(1));


%% Compute power and efficiency and plot PV cycle

volHalf = 0.5*(max(volCycle)+min(volCycle));
idxHalfVolume1 = find(volhalfCycle1 > volHalf, 1, 'first');
idxHalfVolume2 = find(volhalfCycle2 > volHalf, 1, 'first');

if ~exist('pvPlotFig', 'var') || ~isgraphics(pvPlotFig, 'figure')
    pvPlotFig = figure('Name','GammaStirlingEngine');
end
figure(pvPlotFig);
clf(pvPlotFig);

if pressurehalfCycle1(idxHalfVolume1)>pressurehalfCycle2(idxHalfVolume2) %If first part is the upper one
    work = trapz(volhalfCycle1, pressurehalfCycle1) - trapz(flip(volhalfCycle2), flip(pressurehalfCycle2));
    totalEnergy =  trapz(volhalfCycle1, pressurehalfCycle1);
    plot(volhalfCycle1,pressurehalfCycle1,'b');
    area(volhalfCycle1,pressurehalfCycle1, 'FaceColor', 'b');
    hold on
    plot(volhalfCycle2,pressurehalfCycle2,'c');
    area(volhalfCycle2,pressurehalfCycle2, 'FaceColor', 'c');
else
    work = trapz(volhalfCycle2, pressurehalfCycle2) - trapz(flip(volhalfCycle1), flip(pressurehalfCycle1));
    totalEnergy = trapz(volhalfCycle2, pressurehalfCycle2);
    plot(volhalfCycle2,pressurehalfCycle2,'b');
    area(volhalfCycle2,pressurehalfCycle2, 'FaceColor', 'b');
    hold on
    plot(volhalfCycle1,pressurehalfCycle1,'c');
    area(volhalfCycle1,pressurehalfCycle1, 'FaceColor', 'c');
end

Efficiency = work/totalEnergy;

text( 0.3*(max(volhalfCycle1)+min(volhalfCycle1)), 0.9*(min(pressurehalfCycle1)), ...
    ['Work per cycle: ',num2str(work), 'J']);
text( 0.3*(max(volhalfCycle1)+min(volhalfCycle1)), 0.7*(min(pressurehalfCycle1)), ...
    ['Heat absorbed per cycle: ',num2str(totalEnergy), 'J']);
text( 0.3*(max(volhalfCycle1)+min(volhalfCycle1)), 0.5*(min(pressurehalfCycle1)), ...
    ['Thermodynamic efficiency: ',num2str(Efficiency*100,'%.2f'), '%']);

title('P-V diagram');
ylabel('Pressure [Pa]');
xlabel('Volume [m^3]');
grid on;

disp(['Work per cycle: ',num2str(work), 'J']);
disp(['Heat absorption per cycle: ', num2str(totalEnergy), 'J']);
disp(['Thermodynamic efficiency: ',num2str(Efficiency*100,'%.2f'), '%']);

om = out.simlog_GammaStirlingEngine.Slider_Crank_and_Flywheel.Flywheel_Inertia.w.series.values('rad/s');
om_avg = 1./(out.tout(end) - out.tout(end-samplesPerCycle)).*...
            trapz(out.tout(end-samplesPerCycle:end), om(end-samplesPerCycle:end));
disp(['Mechanical power: ', num2str(work*om_avg/(2*pi)), 'W']);
disp(['Thermal power absorbed: ', num2str(totalEnergy*om_avg/(2*pi)), 'W']);
disp('-----------------------');

clear totalEnergy Efficiency work volCycle pressureCycle idxHalfVolume1 idxHalfVolume2;
clear volhalfCycle1 pressurehalfCycle1 volhalfCycle2 pressurehalfCycle2;
clear endVolume samplesPerCycle volChange  volHalf;
clear pressurePowerPiston volPowerPiston om om_avg;
