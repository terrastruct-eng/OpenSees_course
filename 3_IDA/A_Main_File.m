%% IDA for a 3DoF
% By Luis Fernando Gutiérrez Urzúa
% The aim of this script is to help executing and processing the results from the Opensees analysis

%% Clean workspace ========================================================

clear;
clc;
close all;                     
        
%% Input starts ===========================================================

% Damping for NLTHA and IDA
xi1 = 3/100;
xi2 = 3/100;

% Accelerogram source and selection and GM sequences creation
load .\Groundmotions\LA_30.mat % Import GM data
accelerograms_vector = (1:2:9); % Write a vector to select which GM in the imported file will be run

% Groundmotions intensity scaling =========================================
GMscaling = (0.1:0.1:1.0)*9.81; %Vector of GM scaling

%% Modal analysis =========================================================

% Input
fid = fopen('Input_modal.tcl','w'); % Create a new file, with the name given by the concatenation of strings and with the permission to write (w)
    fprintf(fid,'% s\n','wipe'); % It's a good practice to wipe OpenSees before starting a new analysis 
    fprintf(fid,'% s\n','source Example_Model_1.tcl'); % Add the structure model to the new file
    fprintf(fid,'% s\n','source Analysis_Modal.tcl'); % Add the modal analysis to the new file
fclose(fid);

% Analysis  
dos(strcat('OpenSees Input_modal.tcl')); % Execute the DOS command and open OpenSees to run the input modal file

% Change files extension and move to folder to keep main folder tidy
files = dir('*.out'); % Make a list of files with .out extension in the folder
for i=1:length(files)
    filename = files(i).name; % Get the names of one file at each cycle
    [pathstr,name,ext]=fileparts(filename); % Separate name from path and extension
    newname = strcat(name,'.txt'); % Write the name plus the .txt extension
    copyfile(filename,newname) % Copy contents from .out to .txt files
end
movefile *.txt ResultsModal f; % Put result files in a folder to avoid crowded folder
delete('*.out','*.txt','Input*.tcl');  % Delete any files not needed anymore

% Read periods and save to variables
temp = readtable('.\ResultsModal\ModalAnalysis_Node_EigenVectors_EigenVal.txt'); % Read in table format
T1=temp.(3)(1); % Get the periods using the table format indexing
T2=temp.(3)(2);

% Eigen vectors
for i=1:2 
    temp = readmatrix(strcat('.\ResultsModal\ModalAnalysis_Node_EigenVectors_EigenVec',num2str(i),'.txt'),'delimiter',' '); % Read .txt file 
%     temp =
%     dlmread(strcat('.\ResultsModal\ModalAnalysis_Node_EigenVectors_EigenVec',num2str(i),'.txt')); % This one can also read files
    eval(['Mode',num2str(i),'= temp;']); % Assign to variable (which name changes at each iteration)
end

Modeshape1 = Mode1/Mode1(1,3); % Normalise mode shapes
Modeshape2 = Mode2/Mode2(1,3);    

%% Incremental Dynamic Analysis ===========================================

% Rayleigh damping
omega1 = 2*pi/T1;
omega2 = 2*pi/T2;
aR = 2*(omega1*omega2*(omega2*xi1-omega1*xi2))/(omega2^2-omega1^2); % Alpha factor for Rayleigh damping (also known as a0 in Chopra's book)
bR = 2*(omega2*xi2-omega1*xi1)/(omega2^2-omega1^2); % Beta factor for Rayleigh damping (also known as a1 in Chopra's book)

% Ground motion Scaling
% Normalisation of the ground motion based on the first period of the
% structure (as the selected intensity measure (IM) is the Sa at T1)
for k = 1:size(acc,2)
    accIM = acc(1:numstep(k),k); % Assign one GM         
    Sa(k) = Z_Spectral(T1,xi1,accIM,dt(k));  %  Use pre-defined function to calculate Sa at T1 through the Newmark Algorithm
    acc(:,k) = (acc(:,k))/Sa(k); % Normalise GM, so Sa at T1 is equal to 1 (later to be scaled with GMscaling vector)
end

delete('*uccessfulNLTHA') % Erase registry files for successful and unsuccesful cases, to avoid double appending

tic % Starts a stopwatch timer to measure performance of PC

% Create a list of combinations to be run for the parfor function
clear run_vector1 run_vector2 run_matrix
run_vector1 = accelerograms_vector(1)*ones(1,length(GMscaling));
run_vector2 = 1:length(GMscaling);
for kact = 2:length(accelerograms_vector) %Appending the run_vector variables
    run_vector1 = [run_vector1 accelerograms_vector(kact)*ones(1,length(GMscaling))];  %Vector with GMs ids
    run_vector2 = [run_vector2 1:length(GMscaling)]; %Vector with scaling ids
end
run_matrix = [run_vector1;run_vector2]; % This matrix has all the combinations of k and j to run

parfor TH = 1:length(run_matrix) % 'parfor' uses all the cores in your processor simultaneously, however, you need the Matlab parallel toolbox. You can also use 'for', although it will be slower
    
    k = run_matrix(1,TH); % This is the GM id
    j = run_matrix(2,TH); % This is the scaling id
    
    fid = fopen( strcat('acc_',num2str(k),'.txt') ,'w' ); % Create a GM .txt file
        fprintf( fid,'%3.4f\n',acc(:,k) ); % 3 decimals before the comma, 4 decimals after the comma
    fclose(fid);

    fid = fopen( strcat('Input_time_history_',num2str(k),'_',num2str(j),'.tcl') ,'w' );
        fprintf(fid,'% s\n','wipe'); % It's a good practice to wipe before starting
        fprintf(fid,'set lambda %3.2f\n',GMscaling(j)); % 'lambda' is the scaling factor used, corresponding to scaling tag 'j'
        fprintf(fid,'set k %2.0f\n',k); % Export id values to .tcl for file naming
        fprintf(fid,'set j %2.0f\n',j);               
        fprintf(fid,'set numstep %5.0f\n',numstep(k)); % Export the number of steps in the GM
        fprintf(fid,'set dt %5.4f\n',dt(k)); % Export the dt value for the GM steps
        fprintf(fid,'set aR %5.4f\n',aR); % Export the previously defined Rayleigh damping parameters
        fprintf(fid,'set bR %5.8f\n',bR); 
        fprintf(fid,'% s\n','source Example_Model_1.tcl'); % Add the structure model to the new file
        fprintf(fid,'% s\n','source Analysis_Gravity.tcl'); % Add the gravity analysis to the new file
        fprintf(fid,'% s\n','source Analysis_Time_History.tcl'); % Add the time-history analysis to the new file
    fclose(fid);           

    % Run the Analysis 1
    dos(strcat ('opensees Input_time_history_',num2str(k),'_',num2str(j),'.tcl')); % Run the analysis
   
end

% Change files extension and move to folder to keep main folder tidy
files = dir('*.out'); % Make a list of files with .out extension in the folder
for i=1:length(files)
    filename = files(i).name; % Get the names of one file at each cycle
    [pathstr,name,ext]=fileparts(filename); % Separate name from path and extension
    newname = strcat(name,'.txt'); % Write the name plus the .txt extension
    copyfile(filename,newname) % Copy contents from .out to .txt files
end
movefile *.txt ResultsTimeHistory f; % Put result files in a folder to avoid crowded folder
delete('*.out','*.txt','Input*.tcl');  % Delete any files not needed anymore
 
toc % Stops the stopwatch timer

%% Extracting results from the IDA

IDR_MAX = zeros(length(GMscaling),length(accelerograms_vector),2); % Prealocating memory to improve performance
for k = accelerograms_vector % For all GMs
    for j = 1:length(GMscaling) % For all scaling factors
        temp = readmatrix(strcat('.\ResultsTimeHistory\TimeHistory_Storey_Displacement.',num2str(k),'.',num2str(j),'.txt'),'delimiter',' '); % Read .txt file 
        IDR_MAX(j,k,1) = max(abs(temp(:,2)))/3.5; % Displacement at bottom storey, divided by inter-storey height
        IDR_MAX(j,k,2) = max(abs(temp(:,3)-temp(:,2)))/3.5; % Displacement at top storey, minus displacement at bottom storey, divided by inter-storey height
    end
end
IDR_MAX = IDR_MAX(:,accelerograms_vector,:);

figure
hold on
for k = 1:length(accelerograms_vector) % For all GMs
    scatter(GMscaling/9.81,IDR_MAX(:,k,1),'k','p','filled') % Plot each GM first storey
    scatter(GMscaling/9.81,IDR_MAX(:,k,2),'r','c','filled') % Plot each GM second storey
end
grid on
xlabel('IM = S_a(T_1) [ g ]')
xlim([0 max(GMscaling)/9.81])
ylabel('IDR_M_A_X [ - ]')
hold off


    
    
    
    
    
    
    
    