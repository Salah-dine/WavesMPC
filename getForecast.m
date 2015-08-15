function [ robot ] = getForecast( dt, robot, spectra, count, input )

motorInputX = input(1); robot.uX = motorInputX;
motorInputZ = input(2); robot.uZ = motorInputZ;

rho = spectra.rho;

fA = robot.fA;                      %Forward Thruster Angle
aA = robot.aA;                      %Aft Thruster Angle
vA = robot.vA;                      %Vertical Thruster Angle
Tmax = robot.Tmax;                  %Max Thrust
mDry = robot.mDry;                  %robot dry mass
mAdx = robot.mAdx;                  %robot added mass in x
mAdz = robot.mAdz;                  %robot added mass in z
Ax = robot.width * robot.height;    %incident area in x
Az = robot.length * robot.width;    %incident area in z

vx = robot.particles.vx(count); ax = robot.particles.ax(count);
vz = robot.particles.vz(count); az = robot.particles.az(count);

[ Cd ] = getCd( vx, vz, Ax, Az );


Bx = [ cos(fA) cos(fA) -cos(aA) -cos(aA) ];
ux = [ motorInputX motorInputX -motorInputX -motorInputX ]';

Bz = [ -cos(vA) -cos(vA) ]; 
uz = [ -motorInputZ -motorInputZ ]';

x2dot = @(tx,x1dot) ...
    ((mAdx*ax + rho*Ax*Cd/2 * abs(x1dot-vx) * (x1dot-vx)) / -(mDry+mAdx) ...
    + (Tmax/mDry) * Bx * ux)/3;

z2dot = @(tz,z1dot) ...
    ((mAdz*az + rho*Az*Cd/2 * abs(z1dot-vz) * (z1dot-vz)) / -(mDry+mAdz) ...
    + (Tmax/mDry) * Bz * uz)/3;

[ tx, yx ] = ode45( x2dot, [0 dt], robot.vx );
[ tz, yz ] = ode45( z2dot, [0 dt], robot.vz );


robot.ax = x2dot( tx(end), yx(end) );
robot.az = z2dot( tz(end), yz(end) );
robot.vx = yx(end); 
robot.vz = yz(end);
robot.px = odeDisplacement( robot.px, yx, tx );
robot.pz = odeDisplacement( robot.pz, yz, tz );

Y = [ robot.px, robot.pz, robot.vx, robot.vz, robot.ax, robot.az ]; 
[ robot.robotPlots ] = updatePlotHistory( Y, robot.robotPlots, count, 1 );

pErrorX = robot.errors.pErrorX;
pErrorZ = robot.errors.pErrorZ;
[ robot ] = updateErrors( robot, count, pErrorX, pErrorZ );

tempPx = robot.particlePlots.px(count) + robot.particles.vx(count) * dt;
tempPz = robot.particlePlots.pz(count) + robot.particles.vz(count) * dt;
tempVx = robot.particles.vx(count+1);
tempVz = robot.particles.vz(count+1);
tempAx = robot.particles.ax(count+1);
tempAz = robot.particles.az(count+1);

U = [tempPx, tempPz, tempVx, tempVz, tempAx, tempAz];
[ robot.particlePlots ] = updatePlotHistory( U, robot.particlePlots, count, 1 );

return

end