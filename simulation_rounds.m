function [SN, round_params, sim_params] = simulation_rounds(rounds, SN, dims, ener, k, ms_ids, n_clusters, mob_params, sn_model, past_data_considered, sn_select_method, pn_select_method)
%SIMULATION_ROUNDS Simulation Function for the Wireless Sensor Network
%   This function executes the complete simulation of n rounds in a
%   wireless netowrk and also collating data needed for analytics and
%   visualization of the network.
%
%   INPUT PARAMETERS
%   rounds - the total number of rounds in the simualtion.
%   SN - all sensors nodes (including routing routes)
%   p - the percentage of cluster heads desired
%   k - the number of bits transfered per packet
%   dims - container of the dimensions of the WSN plot extremes and the
%           base station point. outputs: x_min, x_min, y_min, x_max, y_max, 
%           bs_x, bs_y.
%   ener - container of the energy values needed in simulation for the
%           transceiver, amplification, aggregation. Outputs: init, tran,
%           rec, amp, agg.
%   rn_ids - ids of all sensor nodes used for routing
%   multiple_sim - boolean checking if executing multiple simulations.
%                   Default: false.
%   sim_number - the current simulation number. [Not necessary if
%                   'multiple_sim' is false]
%
%   OUTPUT PARAMETERS
%   %   SN - all sensors nodes (including routing routes)
%   round_params - container of the parameters used to measure the
%                   performance of the simulation in a round. The params
%                   are: 'dead nodes', 'operating nodes', 'total energy', 
%                   'packets', 'stability period', 'lifetime', 
%                   'stability period round', 'lifetime round'.

%% Initializations

round_params = containers.Map( {'dead nodes', 'operating nodes', 'total energy', 'packets', 'stability period', 'lifetime', 'stability period round', 'lifetime round', 'contact time', 'interconnect time'}, {0, length(SN.n), 0, 0, 0, 0, 0, 0, 0, 0} );
sim_params = containers.Map( {'dead nodes', 'operating nodes', 'total energy', 'packets', 'contact time', 'interconnect time'}, {zeros(1,rounds), zeros(1,rounds), zeros(1,rounds), zeros(1,rounds), zeros(1,rounds), zeros(1,rounds)} );

stability_period_check = true;
lifetime_check = true;

if n_clusters < length(ms_ids)
   error('Number of clusters should be more than number of mobile sinks'); 
end


%% Simulation Loop

% Group the WSN into clusters based on priority nodes
if strcmp(pn_select_method, "cluster_head")
    [SN, rn_ids] = routing_node_selection(SN, dims, n_clusters);
else
    SN = cluster_grouping_others(SN, n_clusters, dims);
end


tic %Initialize timing

% Interconnected timer initializer
int_conn_start = toc;
int_conn_start_check = false;

% Round Display Initialization
fprintf('\n\nRounds for \nMobile Sink Positioning Method: %s \nPriority Node Selection Method: %s \n', sn_select_method, pn_select_method);

for round=1:rounds
    
    % Display the current round
    if mod(round, 100) == 0
        fprintf('%d \n', round); 
    else
        fprintf('.'); 
    end
    
    % Reset Sensor Node Roles (to Normal and Sink)
    if ~strcmp(pn_select_method, "cluster_head")
        [SN] = resetWSN(SN);
    end
    
    % Priority Node or Cluster Head Selection
    if strcmp(pn_select_method, "prediction")
        [SN, pn_ids] = priority_nodes_selection_prediction(SN, ms_ids, sn_model, past_data_considered);
    elseif strcmp(pn_select_method, "no_of_visit")
        [SN, pn_ids] = priority_nodes_selection_visits(SN);
    elseif strcmp(pn_select_method, "cluster_head")
        [SN, CL] = cluster_head_election(SN, round);
        SN = cluster_grouping_CH(SN, CL);
    end
    
    % Perform packet transfer
    if strcmp(pn_select_method, "cluster_head")
        [SN, round_params, int_conn_start, int_conn_start_check] = energy_dissipation_CH(SN, round, rn_ids, ms_ids, dims, ener, k, round_params, int_conn_start, int_conn_start_check);
    else
        [SN, round_params, int_conn_start, int_conn_start_check] = energy_dissipation_others(SN, round, ms_ids, pn_ids, dims, ener, k, round_params, int_conn_start, int_conn_start_check);
    end
    
    % Update the simulation parameters
    [SN, round_params, stability_period_check, lifetime_check] = round_params_update(SN, round_params, dims, ms_ids, round, rounds, stability_period_check, lifetime_check, mob_params, sn_select_method, pn_select_method);
    [sim_params] = sim_params_update(round, round_params, sim_params);
end

end

