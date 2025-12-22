clc
clear
close all
Data = readmatrix("input.xlsx");
data_matrix = [];
data_matrix1 = [];
global rhomantle rhoinfill xmin xmax apload Plate g gamma D alpha Te l E pr spacing x w loadtype loadpos xcross xb wmax ExpW
header = {'D', 'Load Magnitude', 'ZeroCross', 'Wmax', 'ZeroCross (appdata)', ...
          'Wmax (appdata)', 'flex_exp', 'alpha', 'xb', 'Wb'};

for i = 1:length(Data)

% Reading inputs.
%Plate = get(handles.plategeometrymenu, 'Value'); %取2
Plate =2;
% loadtype = get(handles.loadshapemenu, 'Value');  %取4即可
loadtype = 1;
    D = Data(i,1);
    apload = Data(i,2); % Load magnitude (N)
rhoinfill = 2200;%Infill Density (kg/m3)
rhocrust = 2800;%Crust Density (kg/m3)
rhomantle = 3300;%Mantle Density (kg/m3)
cflrdepth = 3700;%1st Interface Depth (m)
crustalT = 45000;%2nd interface Depth (m)

%Te = str2double(get(handles.Te,'String'))*1000;%0.0509618
Te = 0.0509618*1000;
%loadpos = str2double(get(handles.loadpos,'String'))*1000;%取0
loadpos = 0;
%l = str2double(get(handles.lambda,'String'))*1000;
l = 1000;
xmin = 0; %converting input to meters 取0
xmax = 1200000; %converting input to meters
if xmin>xmax
    errordlg('Xmax should be greater than Xmin');
end

gamma = rhomantle-rhoinfill;



% ***********Initialising geodynamic modeling *****************
% The default values for acceleration due to gravity, young's modulus and 
% poisson's ration and earth's radius are stored in an external matlab 
% file called DefConstant, which can be edited, if needed from the TAFI 
% interface by selecting Change Defaults.

g = 9.8;
E = 7*1e10;
pr = 0.25;
eta = 1e18;
R = 6370000;

%Calculate flexural parameter, alpha. The flexparam function reads in the
%loadtype and computes the flexural parameter accordingly.
[alpha] = flexparam(D,gamma, g, E, Te, R, loadtype,Plate);
        spacing = 1*1000;


%     setTAFIenv(handles, Plate, loadtype);
%     % Set titles
%     title = 'Gravity and flexure model of Lithosphere for a Discontinous Plate';
%     set(handles.Title,'String',title);
% If the plate geometry selected is semi-infinite, then the loading options
% are 2-D Impulse load and 2-D distributed loads. Following function computes flexural deflection
% for semi-infinite plate with two loading options.
%     setTAFIenv(handles, Plate, loadtype);
%     % Set titles
%     title = 'Gravity and flexure model of Lithosphere for a Discontinous Plate';
%     set(handles.Title,'String',title);
    % Read plot spacing

    % Determine X vector. See x_vector help for decision tree.
    if loadtype == 1
        [x] = x_vector(alpha,l,xmin, spacing, xmax, Plate, loadtype,0);
    elseif loadtype == 2
        % Read the 2-D distributed load
        [apload,loadingfnpos] = ReadLoad2D(spacing,handles);
        % Adding a check here to ensure program still runs even if the user
        % hit cancel button while importing load
        if length(apload) == 1 && apload == 0
            loadfilemin = 0;
            loadfilemax = 0;
        else
            loadfilemin = loadingfnpos(1);
            loadfilemax = loadingfnpos(length(apload));
        end
        [x] = x_vector(alpha,l,xmin, spacing, xmax, Plate, loadtype,loadfilemin,loadfilemax);
    end


    % Calculate green's function of semi-infinite plate depending on chosen
    % load geometry.
    [wgreen] = Halfspace2D_flex(alpha,D,x);
    
% All wgreen's have been calculated in meters.

% ******** CONVOLUTION PART ************
% **************************************
 
% Convolve/Scale the Green's function with load

if (Plate == 1 && (loadtype == 1 || loadtype == 2 || loadtype == 3)) || (Plate ==2 && (loadtype == 1))
    % Correct for sign conventions and variable name. Axisymmetric is
    % upside down in green's function, and periodic is calculated not as
    % green's function. 
    if Plate == 1 && loadtype == 2
        wgreen = -1*wgreen;
    elseif Plate == 1 && loadtype == 3
        wgreen = w;
    end
    % Read the length of flexural deflection vector
    nw = length(wgreen);
    
    % Scale the load. No scaling needed for periodic loading as it is
    % already taken into account while calculating the flexural deflection
    % vector.
    if Plate == 1 && loadtype == 3
        plotx = x2;
    elseif (Plate == 1 && (loadtype == 1 || loadtype ==2)) || (Plate == 2 && loadtype == 1)
        w2 = apload*wgreen;
        w(nw+1:2*nw-1)=w2(2:nw);
        w(1:nw)=fliplr(w2(1:nw));
        plotx(nw+1:2*nw-1) = x(2:nw);
        plotx(1:nw) = fliplr(-x);
    end

elseif (Plate == 1 && (loadtype == 4 || loadtype == 5))||(Plate == 2 && loadtype == 2)
    
    [w,plotx]=  loadconv2D(wgreen, apload,loadtype,spacing,x);
    
elseif (Plate ==1 && loadtype == 6)
    [flexuregrid] = loadconv3D(wgreen, loadscale, loadgrid, nx,ny,dx,dy);
end

% W (flexure) is in meters
        
%% Plot flexural response


[flexcolor]= calcindex(w,plotx, xmin,spacing,xmax);
setappdata(0,'flexcolor',flexcolor);
[calcW,calcX] = TAFIPlot2D(w,plotx,loadpos,flexcolor,1);
%TAFIPlot2D(w,plotx,loadpos,flexcolor,1);

%% Find output parameters
% calcX = getappdata(0,'calcX');
% calcW = getappdata(0,'calcW');


[xcross, xb,wmax,ExpW,wb] = outputparam(calcX, calcW, l,D, g,gamma,alpha,apload, Plate, loadtype, loadpos);

%% Declare flexural parameter variable and covert to string for displaying
global FParam
FParam = num2str(alpha/1000);
% Assemble data.组装数据
    col_data = [{'D', 'Load Magnitu de'}; 
                {D, apload}; 
                num2cell([calcX; calcW*(-1)])'];

    % Concatenating data.拼接数据
    data_matrix = [data_matrix, col_data]; 

    row_data = {D, apload, ...
                (xcross+loadpos)/1000, wmax, xcross/1000, ...
                wmax, ExpW, FParam, xb, abs(-1*wb/1000)};

    data_matrix1 = [data_matrix1; row_data]; 


end
% % Output.将数据写入 Excel，Sheet1 页
xlswrite('output_flexure.xlsx', data_matrix, 'Sheet1');
xlswrite('output_flexure.xlsx', [header; data_matrix1], 'Sheet2');
fprintf('计算完成！');

