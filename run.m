close all;
clc;
clear;

%% Simulation Details
disp("Welcome to Wireless Sensor Simulation");
disp("............................................................");
disp("............................................................");
pause(3)
 
% Initialization Inputs
max_dimension = 100; % Maximum Dimension of the WSN Plot

initial_energy = 500e-3; % Initial node energy
transceiver_energy = 50e-9; % Energy Required for transmission and receiving of packet
ener_amp = 100e-12; % Amplification Energy
ener_agg = 100e-12; % Aggregation Energy

% Simulation Parameters
n = 100; % Number of nodes

sn = 3; % Number of mobile sink
sn_positioning = ["random", "even_nonconfined", "even_confined"]; % Mobile Sink Positioning Method to be compared
% Possible values: random, even_nonconfined, even_confined
pn_select_method = ["cluster_head", "no_of_visit", "prediction"]; % cluster_head only applies to random.
% Possible values: cluster_head, no_of_visit, prediction

if ismember("prediction", pn_select_method)
    generate_new_model = false; % boolean to decide the generation of new predictive model for the mobile sinks
    train_data = 1; % Number of training rounds where data is to be gathered
    past_data_considered = 10; % Number of past data ussed in prediction
else
    past_data_considered = NaN;
end

rounds = 120; % Number of rounds per simulation
k = 80000; % Bits transmitted per packet

% Clustering Paramters
n_clusters = 7;

% Mobility Parameters
min_dist = 0; % Minimum mobility for sensor nodes (in m)
max_dist = 2; % Maximum mobility for sensor nodes (in m)
sn_min_dist = 1; % Minimum mobility for sink nodes (in m)
sn_max_dist = 4; %Maximum mobility for sink nodes (in m)
min_visit_dist = 10; % Minimum distance to affirm visitation by sink nodes (in m)
mob_params = containers.Map({'min_dist', 'max_dist', 'sn_min_dist', 'sn_max_dist', 'min_visit_dist'}, {min_dist, max_dist, sn_min_dist, sn_max_dist, min_visit_dist});

%% Parameters Initialization
[dims, ener] = param_init(max_dimension, initial_energy, transceiver_energy, ener_agg, ener_amp);

%% Prediction Algorithm Modelling

if ismember("prediction", pn_select_method)
    if generate_new_model
        % Gather Mobile Sink Data (Based on Simulation Input)
        data = data_gathering(n, sn, sn_method, dims, ener, n_clusters, rounds, mob_params, train_data);

        % Data Munging
        sn_model = model_training(data, train_data, sn);
    else
        sn_model = load_previous_model();
    end
else
    sn_model = NaN;
end

%% Initialization of the WSN
[initial_SN_LEACH, ms_ids_LEACH] = createWSN(n, 1, sn_positioning, dims, ener('init'), rounds);
[initial_SN, ms_ids] = createWSN(n, sn, sn_positioning, dims, ener('init'), rounds);

%% Comparison Model

SN_compare = containers.Map();
sim_params_compare = containers.Map();

for sn_method = sn_positioning
    for pn_method = pn_select_method
        
        % Smiluation of the WSN
        if strcmp(pn_method, "cluster_head") && ~strcmp(sn_method, "random")
            continue
        elseif strcmp(pn_method, "cluster_head") && strcmp(sn_method, "random")
            [SN, round_params, sim_params] = simulation_rounds(rounds, initial_SN_LEACH, dims, ener, k, ms_ids_LEACH, n_clusters, mob_params, sn_model, past_data_considered, sn_method, pn_method);
        else
            [SN, round_params, sim_params] = simulation_rounds(rounds, initial_SN, dims, ener, k, ms_ids, n_clusters, mob_params, sn_model, past_data_considered, sn_method, pn_method);
        end
        
        
        name = char(sn_method + ' ' + pn_method);
        SN_compare(name) = SN;
        sim_params_compare(name) = sim_params;

        % Lifetime and Stability Periods.

        fprintf('\nSimulation Summary\n')
        fprintf('Stability Period: %d secs\n', round(round_params('stability period'), 2))
        fprintf('Stability Period Round: %d\n', round_params('stability period round'))
        fprintf('Lifetime: %d secs\n', round(round_params('lifetime'), 2))
        fprintf('Lifetime Round: %d\n', round_params('lifetime round'))
        
        pause(2.5)
        
    end
end

%% Data Visualisations
figure_num = 0;

%% Individual Plots
figure_num = plot_data_individuals(figure_num, rounds, sim_params_compare, sn_positioning, pn_select_method);

%% Comparison Plots
figure_num = plot_data_compare(figure_num, rounds, sim_params_compare, sn_positioning, pn_select_method);

%% Mobility Visualization Plot
figure_num = plot_simulation(figure_num, SN_compare, rounds, dims, sn_positioning, pn_select_method);