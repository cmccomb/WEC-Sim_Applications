close all
clear all

%% Define Files to Use
draftVals = 18:0.05:22;
h5Files = strings(length(draftVals),1);
for i = 1:length(draftVals)
    h5Files(i) = ['/depth_' num2str(draftVals(i), '%.2f'), '.h5'];
end

% h5disp("depth_18.00.h5")

%% Access Information from H5 files
for i = 1:length(draftVals)
    draftMesh(i) = loadDraftFile(draftVals(i), h5Files(i)); 
end

%% Plot CG and CB
cgZ = zeros(length(draftVals),1);
cbZ = zeros(length(draftVals),1);
for i = 1:length(draftVals)
    cgZ(i) = draftMesh(i).cg(1,3); 
    cbZ(i) = draftMesh(i).cb(1,3); 
end

figure()
plot(draftVals, cgZ)
hold on
plot(draftVals, cbZ)
hold off
legend("Center of Gravity", "Center of Buoyancy")
ylabel("Z Position (m)")
xlabel("Draft (m)")
title("CoG and CoB for OC4")

%% Plot Inertia Values
for i = 1:length(draftVals)
    inertiaVals(i,:) = table2array(readtable(['/depth_' num2str(draftVals(i), '%.2f') '_inertiaMatrix.csv']));
end

figure()
plot(draftVals, inertiaVals(:,1))
hold on
plot(draftVals, inertiaVals(:,2))
plot(draftVals, inertiaVals(:,3))
hold off
legend("I_x", "I_y", "I_z")
ylabel("Inertia (kg*m^2)")
xlabel("Draft (m)")
title("Inertial Components for OC4")

%% Plot Added Mass at Infinity
A_inf11 = zeros(length(draftVals),1);
A_inf33 = zeros(length(draftVals),1);
A_inf55 = zeros(length(draftVals),1);
for i = 1:length(draftVals)
    A_inf11(i) = draftMesh(i).A_inf11; 
    A_inf33(i) = draftMesh(i).A_inf33; 
    A_inf55(i) = draftMesh(i).A_inf55/100;
end

figure()
plot(draftVals, A_inf11)
hold on
plot(draftVals, A_inf33)
plot(draftVals, A_inf55)
hold off
ylabel('$A(\infty)$', 'Interpreter','latex')
legend("$A_{1,1} (\infty)$","$A_{3,3} (\infty)$", "$A_{5,5} (\infty)/100$", 'Interpreter','latex')
xlabel("Draft (m)")
title("Added Mass at Infinity for the OC4 Varying Draft")

%% Plot Radiation Damping
w = draftMesh(1).w;
B_11 = zeros(length(draftVals), length(w));
B_33 = zeros(length(draftVals), length(w));
B_55 = zeros(length(draftVals), length(w));
for i = 1:length(draftVals)
    B_11(i,:) = draftMesh(i).B_11;
    B_33(i,:) = draftMesh(i).B_33;
    B_55(i,:) = draftMesh(i).B_55;
end

[X,Y] = meshgrid(w, draftVals);
figure()
surf(X,Y,B_11)
ylabel("Draft (m)")
xlabel("Frequency (rad/s)")
zlabel('$\bar{B}_{1,1} (\omega)$', 'Interpreter','latex')
title("Normalized Radiation Damping in Surge vs Draft")

figure()
surf(X,Y,B_33)
ylabel("Draft (m)")
xlabel("Frequency (rad/s)")
zlabel('$\bar{B}_{3,3} (\omega)$', 'Interpreter','latex')
title("Normalized Radiation Damping in Heave vs Draft")

figure()
surf(X,Y,B_55)
ylabel("Draft (m)")
xlabel("Frequency (rad/s)")
zlabel('$\bar{B}_{5,5} (\omega)$', 'Interpreter','latex')
title("Normalized Radiation Damping in Pitch vs Draft")

%% Plot Added Mass
A_11 = zeros(length(draftVals), length(w));
A_33 = zeros(length(draftVals), length(w));
A_55 = zeros(length(draftVals), length(w));
for i = 1:length(draftVals)
    A_11(i,:) = draftMesh(i).A_11;
    A_33(i,:) = draftMesh(i).A_33;
    A_55(i,:) = draftMesh(i).A_55;
end

figure()
surf(X,Y,A_11)
ylabel("Draft (m)")
xlabel("Frequency (rad/s)")
zlabel('$\bar{A}_{1,1} (\omega)$', 'Interpreter','latex')
title("Normalized Added Mass in Surge vs Draft")

figure()
surf(X,Y,A_33)
ylabel("Draft (m)")
xlabel("Frequency (rad/s)")
zlabel('$\bar{A}_{3,3} (\omega)$', 'Interpreter','latex')
title("Normalized Added Mass in Heave vs Draft")

figure()
surf(X,Y,A_55)
ylabel("Draft (m)")
xlabel("Frequency (rad/s)")
zlabel('$\bar{A}_{5,5} (\omega)$', 'Interpreter','latex')
title("Normalized Added Mass in Pitch vs Draft")

%% Plot Displaced Volume
disp_vol = zeros(length(draftVals),1);
for i = 1:length(draftVals)
    disp_vol(i) = draftMesh(i).disp_vol; 
end


figure()
plot(draftVals, disp_vol)
ylabel("Displaced Volume (m3)")
xlabel("Draft (m)")
title("Displaced Volume for the OC4 Varying Draft")

%% Functions
function mesh = loadDraftFile(draftName, h5file)
    % draft name
    mesh.draft = draftName;
    
    % Get the CoG and CoB
    mesh.cg = h5read(h5file,'/body1/properties/cg');
    mesh.cb = h5read(h5file,'/body1/properties/cb');

    % Get the added mass at inf
    rho = h5read(h5file,'/simulation_parameters/rho');
    A_inf = h5read(h5file,'/body1/hydro_coeffs/added_mass/inf_freq');
    mesh.A_inf11 = A_inf(1,1)*rho; % Added mass for surge in kg
    mesh.A_inf33 = A_inf(3,3)*rho; % Added mass for heave in kg
    mesh.A_inf55 = A_inf(5,5)*rho; % Added mass for pitch in kg 

    % Frequency (rad/s);
    mesh.w = h5read(h5file,'/simulation_parameters/w');

    % Radiation damping (N/(m/s)) (multiply by rho to get in N/(m/s))
    B = h5read(h5file,'/body1/hydro_coeffs/radiation_damping/all');
    mesh.B_11 = B(:,1,1)';
    mesh.B_33 = B(:,3,3)';
    mesh.B_55 = B(:,5,5)';

    % Get the normalized A_w values for pitch
    A = h5read(h5file,'/body1/hydro_coeffs/added_mass/all');
    mesh.A_11 = A(:,1,1)';
    mesh.A_33 = A(:,3,3)';
    mesh.A_55 = A(:,5,5)';

    % Get displaced volume
    mesh.disp_vol = h5read(h5file,'/body1/properties/disp_vol');
end