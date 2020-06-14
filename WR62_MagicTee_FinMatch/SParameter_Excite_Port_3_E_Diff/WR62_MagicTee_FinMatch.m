close all
clear
clc

addpath('~/opt/openEMS/share/openEMS/matlab');
addpath('~/opt/openEMS/share/CSXCAD/matlab');

%% setup the simulation
physical_constants;
unit = 1e-3;

% frequency range of interest
f_start =  12.4e9;
f_stop  =  18e9;

% frequency of interest
f0 = 15.2e9;

% waveguide dimensions
a = 15.8;
b = 7.9;

FDTD = InitFDTD( 'NrTS', 30000, 'EndCriteria', 1e-4, 'OverSampling', 50);
FDTD = SetGaussExcite(FDTD,0.5*(f_start+f_stop),0.5*(f_stop-f_start));
FDTD = SetBoundaryCond(FDTD,{'PML_8' 'PML_8' 'PML_8' 'PML_8' 'PML_8' 'PML_8'});

CSX = InitCSX();

mesh.x = [-24.22 -19.9 -16.625 -16.14 -14.9 -9.9 -7.9 -5.95 -3.95 3.95 5.95 7.9 9.9 14.9 16.14 16.625 19.9 24.22];
mesh.y = [-14.32 -10 -6.725 -5 0 2 5 14.8 17.8 19.8 26.5];
mesh.z = [-10.2 0 2 9.9 11.9 12.9 16.9 21.9 26.22];
mesh.x = SmoothMeshLines(mesh.x, 0.5, 1.3);
mesh.y = SmoothMeshLines(mesh.y, 0.5, 1.3);
mesh.z = SmoothMeshLines(mesh.z, 0.5, 1.3);
CSX = DefineRectGrid(CSX, unit, mesh);

magic_tee_model = 'WR62_MagicTee_FinMatch.stl'

CSX = AddMaterial(CSX, 'magic_tee');
CSX = SetMaterialProperty(CSX, 'magic_tee', 'Kappa', 5.96e7);
CSX = ImportSTL(CSX, 'magic_tee', 10, magic_tee_model, 'Transform', {'Scale',1});

% Input Port
start=[b/-2 a+2 21.9];
stop =[b/2  2   16.9];
[CSX, port{1}] = AddRectWaveGuidePort( CSX, 0, 1, start, stop, 'z', b*unit, a*unit, 'TE01', 1);

% Port 2
start=[a/-2 -10 2];
stop =[a/2  -5  b+2];
[CSX, port{2}] = AddRectWaveGuidePort( CSX, 0, 2, start, stop, 'y', a*unit, b*unit, 'TE10');

% Coupled Port 3
start=[-19.9 a+2 2];
stop =[-14.9  2   b+2];
[CSX, port{3}] = AddRectWaveGuidePort( CSX, 0, 3, start, stop, 'x', a*unit, b*unit, 'TE10');

% Coupled Port 4
start=[19.9 a+2 2];
stop =[14.9  2   b+2];
[CSX, port{4}] = AddRectWaveGuidePort( CSX, 0, 4, start, stop, 'x', a*unit, b*unit, 'TE10');

Sim_Path = 'WR62_MagicTee_FinMatch';
Sim_CSX = 'WR62_MagicTee_FinMatch.xml';

[status, message, messageid] = rmdir( Sim_Path, 's' ); % clear previous directory
[status, message, messageid] = mkdir( Sim_Path ); % create empty simulation folder

copyfile(['../' magic_tee_model], [Sim_Path '/' magic_tee_model])
copyfile(['../' magic_tee_model], '.')

WriteOpenEMS([Sim_Path '/' Sim_CSX],FDTD,CSX);

CSXGeomPlot([Sim_Path '/' Sim_CSX]);

RunOpenEMS(Sim_Path,Sim_CSX,'');

%% postprocessing & do the plots
freq = linspace(f_start,f_stop,201);
port = calcPort(port, Sim_Path, freq);
 
s11 = port{1}.uf.ref./ port{1}.uf.inc;
s21 = port{2}.uf.ref./ port{1}.uf.inc;
s31 = port{3}.uf.ref./ port{1}.uf.inc;
s41 = port{4}.uf.ref./ port{1}.uf.inc;
ZL = port{1}.uf.tot./port{1}.if.tot;
ZL_a = port{1}.ZL; % analytic waveguide impedance
 
figure
plot(freq*1e-6,20*log10(abs(s11)),'k-','Linewidth',2);
xlim([freq(1) freq(end)]*1e-6);
grid on;
hold on;
plot(freq*1e-6,20*log10(abs(s21)),'r--','Linewidth',2);
plot(freq*1e-6,20*log10(abs(s31)),'b--','Linewidth',2);
plot(freq*1e-6,20*log10(abs(s41)),'g--','Linewidth',2);
l = legend('S_{11}','S_{21}','S_{31}','S_{41}','Location','Best');
set(l,'FontSize',12);
ylabel('S-Parameter (dB)','FontSize',12);
xlabel('frequency (MHz) \rightarrow','FontSize',12);

drawnow
pause;