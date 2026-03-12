%% Determine sensitivity of Stirling engine efficiency to crank radius
% This script simulates the GammaStirlingEngine model with two power piston
% crank radius values to compare the performance of both options.
% The default radius of 19.8 mm  is simulated first (unless it was
% previously simulated) and then a smaller radius of 12 mm is simulated.
% Efficiency, power and speed are calculated to compare and choose the
% right design.

% Copyright 2019 The MathWorks, Inc.


%% Crank radius values

if ~strcmp(bdroot, 'GammaStirlingEngine')
    open_system('GammaStirlingEngine')
end

crank_rad = [crank_wheel.slidercrank_pow.crank_radius,  12e-3];


%% Simulate

if ~exist('out', 'var')
 out = sim('GammaStirlingEngine');
end 
if ~exist('out2', 'var')
    crank_wheel.slidercrank_pow.crank_radius = crank_rad(2);
    assignin('base', 'crank_wheel', crank_wheel);
    out2 = sim('GammaStirlingEngine');
end


%% Plot P-V cycles

if ~exist('pvPlotFig2', 'var') || ~isgraphics(pvPlotFig2, 'figure')
    pvPlotFig2 = figure('Name','GammaStirlingEngine');
end
figure(pvPlotFig2);
clf(pvPlotFig2);

for ii = 1:2
    
    if ii == 1
        out_temp = out;
    elseif ii == 2
        out_temp = out2;
    end
    
    % Extract pressure and volume data.
    pressurePowerPiston = out_temp.simlog_GammaStirlingEngine.Power_piston.Expansion_Piston.p_I.series.values('Pa'); 
    volPowerPiston = out_temp.simlog_GammaStirlingEngine.Power_piston.Expansion_Piston.volume.series.values('m^3');  

    % Get 1 cycle

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

    % Entire cycle
    volCycle = volPowerPiston(end-samplesPerCycle:end);
    pressureCycle = pressurePowerPiston(end-samplesPerCycle:end);

    % Upper and lower part cycle
    volhalfCycle1 = volCycle([end:end-volChange(1)+1 1:end-volChange(2)-1]);
    pressurehalfCycle1 = pressureCycle([end:end-volChange(1)+1 1:end-volChange(2)-1]);
    volhalfCycle2 = volCycle(end-volChange(2):end-volChange(1));
    pressurehalfCycle2 = pressureCycle(end-volChange(2):end-volChange(1));

    % Compute power and efficiency 
    volHalf = 0.5*(max(volCycle)+min(volCycle));
    idxHalfVolume1 = find(volhalfCycle1 > volHalf, 1, 'first');
    idxHalfVolume2 = find(volhalfCycle2 > volHalf, 1, 'first');
    
    hold on;
    if ii == 1
        if pressurehalfCycle1(idxHalfVolume1)>pressurehalfCycle2(idxHalfVolume2) %If first part is the upper one
            work = trapz(volhalfCycle1, pressurehalfCycle1) - trapz(flip(volhalfCycle2), flip(pressurehalfCycle2));
            totalEnergy =  trapz(volhalfCycle1, pressurehalfCycle1);
            plot(volhalfCycle1,pressurehalfCycle1,'b');
            hold on
            p1 = plot(volhalfCycle2,pressurehalfCycle2,'b');
        else
            work = trapz(volhalfCycle2, pressurehalfCycle2) - trapz(flip(volhalfCycle1), flip(pressurehalfCycle1));
            totalEnergy = trapz(volhalfCycle2, pressurehalfCycle2);
            plot(volhalfCycle2,pressurehalfCycle2,'b');
            hold on
            p1 = plot(volhalfCycle1,pressurehalfCycle1,'b');
        end
        
    elseif ii == 2
        if pressurehalfCycle1(idxHalfVolume1)>pressurehalfCycle2(idxHalfVolume2) %If first part is the upper one
            work = trapz(volhalfCycle1, pressurehalfCycle1) - trapz(flip(volhalfCycle2), flip(pressurehalfCycle2));
            totalEnergy =  trapz(volhalfCycle1, pressurehalfCycle1);
            plot(volhalfCycle1,pressurehalfCycle1,'r');
            hold on
            p2 = plot(volhalfCycle2,pressurehalfCycle2,'r');
        else
            work = trapz(volhalfCycle2, pressurehalfCycle2) - trapz(flip(volhalfCycle1), flip(pressurehalfCycle1));
            totalEnergy = trapz(volhalfCycle2, pressurehalfCycle2);
            plot(volhalfCycle2,pressurehalfCycle2,'r');
            hold on
            p2 = plot(volhalfCycle1,pressurehalfCycle1,'r');
        end
    end
    hold off;
    Efficiency = work/totalEnergy;
    
    if ii == 1
        disp('1st crank radius');
    elseif ii == 2
        disp('2nd crank radius');
    end
    
    disp(['Work per cycle: ',num2str(work), 'J']);
    disp(['Heat absorption per cycle: ', num2str(totalEnergy), 'J']);
    disp(['Thermodynamic efficiency: ',num2str(Efficiency*100,'%.2f'), '%']);

    om = out_temp.simlog_GammaStirlingEngine.Slider_Crank_and_Flywheel.Flywheel_Inertia.w.series.values('rad/s');
    om_avg = 1./(out_temp.tout(end) - out_temp.tout(end-samplesPerCycle)).*...
                trapz(out_temp.tout(end-samplesPerCycle:end), om(end-samplesPerCycle:end));
    disp(['Shaft speed: ', num2str(om_avg*60/(2*pi)), 'rpm']);
    disp(['Mechanical power: ', num2str(work*om_avg/(2*pi)), 'W']);
    disp(['Thermal power absorbed: ', num2str(totalEnergy*om_avg/(2*pi)), 'W']);
    disp('-----------------------');

end

title('P-V diagram');
ylabel('Pressure [Pa]');
xlabel('Volume [m^3]');
legend([p1, p2], '1st crank radius','2nd crank radius');
grid on;

clear crank_rad Efficiency endVolume idxHalfVolume1 idxHalfVolume2 ii om om_avg out_temp p1 p2;
clear pressureCycle pressurehalfCycle1 pressurehalfCycle2 pressurePowerPiston samplesPerCycle;
clear totalEnergy volChange volCycle volHalf volhalfCycle1 volhalfCycle2 volPowerPiston work;
