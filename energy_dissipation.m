function [SN, round_params, int_conn_start, int_conn_start_check] = energy_dissipation_others(SN, round, rn_ids, ms_ids, energy, k, round_params, int_conn_start, int_conn_start_check)
%SN, round, dims, energy, k, round_params, method
%ENERGY_DISSIPATION Energy dissipation function for the WSN
%   This function evaluates the energy dissipated in the sensor nodes
%   during the transmission netween the nodes to the base station of the
%   network
%
%   INPUT PARAMETERS
%   SN - all sensors nodes (including routing routes)
%   CLheads - number of cluster heads elected.
%   round - the current round in the simulation.
%   dims - container of the dimensions of the WSN plot extremes and the
%           base station point. outputs: x_min, x_min, y_min, x_max, y_max, 
%           bs_x, bs_y.
%   ener - container of the energy values needed in simulation for the
%           transceiver, amplification, aggregation. Outputs: init, tran,
%           rec, amp, agg.
%   rn_ids - ids of all sensor nodes used for routing
%   k - the number of bits transfered per packet
%   round_params - container of the parameters used to measure the
%                   performance of the simulation in a round. The params
%                   are: 'dead nodes', 'operating nodes', 'total energy', 
%                   'packets', 'stability period', 'lifetime', 
%                   'stability period round', 'lifetime round'.
%   method - the approach used in the transfer of data from normal nodes to
%               the base station. The available parameters are: 'force CH'
%               and 'shortest'. Default: 'force CH'. 'force CH' compels the
%               nodes to pass through a channel head. 'shortest' searches
%               for the minimum energy dissipation route.
%
%   OUTPUT PARAMETERS
%   SN - all sensors nodes (including routing routes)
%   round_params - container of the parameters used to measure the
%                   performance of the simulation in a round. The params
%                   are: 'dead nodes', 'operating nodes', 'total energy', 
%                   'packets', 'stability period', 'lifetime', 
%                   'stability period round', 'lifetime round'.

if int_conn_start_check
    int_conn_stop = toc;
    int_conn_time = int_conn_stop - int_conn_start;

    round_params('interconnect time') = round_params('interconnect time') + int_conn_time;
end

% Number of Channel Heads Selected
CL_heads = unique([SN.n.chid]);

start_time = toc;

for i = 1:length(SN.n)

    % Packet Transfer for Nodes in Given Cluster
    if strcmp(SN.n(i).role, 'N') && strcmp(SN.n(i).cond,'A')

        if SN.n(i).E > 0 && SN.n(i).chid ~= 0 % Verification that node is alive and it has a priority node
            
            ETx = energy('tran')*k + energy('amp') * k * SN.n(i).dnc^2;
            SN.n(i).E = SN.n(i).E - ETx;
            SN.n(i).alpha = (4/25)*(2.5^4).^(SN.n(i).E);
            round_params('total energy') = round_params('total energy') + ETx;

            % Dissipation for channel head during reception
            if SN.n(SN.n(i).chid).E > 0 && strcmp(SN.n(SN.n(i).chid).cond, 'A') && strcmp(SN.n(SN.n(i).chid).role, 'C')
                ERx = (energy('rec') + energy('agg'))*k;
                round_params('total energy') = round_params('total energy') + ERx;
                SN.n(SN.n(i).chid).E = SN.n(SN.n(i).chid).E - ERx;
                SN.n(SN.n(i).chid).alpha = (4/25)*(2.5^4).^(SN.n(SN.n(i).chid).E);

                if SN.n(SN.n(i).chid).E<=0  % if priority node energy depletes with reception
                    SN.n(SN.n(i).chid).cond = 'D';
                    SN.n(SN.n(i).chid).rop=round;
                    SN.n(SN.n(i).chid).E=0;
                    SN.n(SN.n(i).chid).alpha = 0;
                    round_params('dead nodes') = round_params('dead nodes') + 1;
                    round_params('operating nodes') = round_params('operating nodes') - 1;
                end
            end
            
        elseif SN.n(i).E > 0 && SN.n(i).chid == 0 % Verification that node is alive but it has no priority node
            
            distances = zeros(1, length(ms_ids));
            for j = 1:length(ms_ids)
                distances(j) = sqrt( (SN.n(ms_ids(j)).x - SN.n(i).x)^2 + (SN.n(ms_ids(j)).y - SN.n(i).y)^2 );
            end
            
            dns = min(distances(:)); % Distance to closest mobile sink
            
            ETx = energy('tran')*k + energy('amp') * k * dns^2;
            SN.n(i).E = SN.n(i).E - ETx;
            SN.n(i).alpha = (4/25)*(2.5^4).^(SN.n(i).E);
            round_params('total energy') = round_params('total energy') + ETx;
            
            % Energy Dissipation in Mobile Sink
            ERx=(energy('rec') + energy('agg'))*k;
            round_params('total energy') = round_params('total energy') + ERx;

        end

        % Check for node depletion
        if SN.n(i).E<=0 % if nodes energy depletes with transmission
            round_params('dead nodes') = round_params('dead nodes') + 1;
            round_params('operating nodes') = round_params('operating nodes') - 1;
            SN.n(i).cond = 'D';
            SN.n(i).pn_id=0;
            SN.n(i).rop=round;
            SN.n(i).E=0;
            SN.n(i).alpha=0;
        end

    end
end

% Transmission from sensor node through shortest route
for i=1:length(SN.n)
    if strcmp(SN.n(i).cond,'A') && strcmp(SN.n(i).role, 'N') && CL_heads > 0
        if SN.n(i).E > 0
            
            % Initializing the distance matrix
            distances = zeros(1, length(rn_ids) + length(ms_ids) + 1);

            % Search for closest routing node
            for j=1:length(rn_ids)

                if strcmp(SN.n(rn_ids(j)).cond,'A')
                    % distance of cluster head to routing node
                    distances(j)=sqrt((SN.n(rn_ids(j)).x-SN.n(i).x)^2 + (SN.n(rn_ids(j)).y-SN.n(i).y)^2);
                else
                    distances(j)=sqrt( (dims('x_max'))^2 + (dims('y_max'))^2 );
                end

            end
            
            % Search for closest mobile sink
            for j=1:length(ms_ids)
                k = length(rn_ids) + j;

                if strcmp(SN.n(ms_ids(j)).cond,'A')
                    % distance of cluster head to routing node
                    distances(k)=sqrt((SN.n(ms_ids(j)).x-SN.n(i).x)^2 + (SN.n(ms_ids(j)).y-SN.n(i).y)^2);
                else
                    distances(k)=sqrt( (dims('x_max'))^2 + (dims('y_max'))^2 );
                end

            end
            
            % Checking for availability of cluster head
            if SN.n(i).cluster ~= 0
                distances(length(rn_ids) + length(ms_ids) + 1) = SN.n(i).dnc;
            else
                distances(k)=sqrt( (dims('x_max'))^2 + (dims('y_max'))^2 );
            end

            [~,I]=min(distances(:)); % finds the minimum distance of node to RN

            % Transmission via cluster head
            if I == length(rn_ids) + length(ms_ids) + 1
                
                ETx = energy('tran')*k + energy('amp') * k * SN.n(i).dnc^2;
                SN.n(i).E = SN.n(i).E - ETx;
                SN.n(i).alpha = (4/25)*(2.5^4).^(SN.n(i).E);
                round_params('total energy') = round_params('total energy') + ETx;

                % Dissipation for channel head during reception
                if SN.n(SN.n(i).chid).E > 0 && strcmp(SN.n(SN.n(i).chid).cond, 'A') && strcmp(SN.n(SN.n(i).chid).role, 'C')
                    ERx = (energy('rec') + energy('agg'))*k;
                    round_params('total energy') = round_params('total energy') + ERx;
                    SN.n(SN.n(i).chid).E = SN.n(SN.n(i).chid).E - ERx;
                    SN.n(SN.n(i).chid).alpha = (4/25)*(2.5^4).^(SN.n(SN.n(i).chid).E);

                    if SN.n(SN.n(i).chid).E<=0  % if priority node energy depletes with reception
                        SN.n(SN.n(i).chid).cond = 'D';
                        SN.n(SN.n(i).chid).rop=round;
                        SN.n(SN.n(i).chid).E=0;
                        SN.n(SN.n(i).chid).alpha = 0;
                        round_params('dead nodes') = round_params('dead nodes') + 1;
                        round_params('operating nodes') = round_params('operating nodes') - 1;
                    end
                end

                
            % Transmission via base station
            elseif I > length(rn_ids)
                
                ms_id = SN.n(I - length(rn_ids)).id;
                dist_to_sink = sqrt((SN.n(ms_id).x-SN.n(i).x)^2 + (SN.n(ms_id).y-SN.n(i).y)^2);
                
                ETx = (energy('tran')+energy('agg'))*k + energy('amp') * k * dist_to_sink^2;
                SN.n(i).E = SN.n(i).E - ETx;
                SN.n(i).alpha = (4/25)*(2.5^4).^(SN.n(i).E);
                round_params('total energy') = round_params('total energy') + ETx;

                % Energy Dissipation in Mobile Sink
                ERx=(energy('rec') + energy('agg'))*k;
                round_params('total energy') = round_params('total energy') + ERx;


            % Transmission via routing
            else           
                dnr = distances(I); % assigns the distance of node to RN
                SN.n(i).route_id = rn_ids(I);

                % Transmission energy to the Routing Node
                ETx = (energy('tran')+energy('agg'))*k + energy('amp') * k * dnr^2;
                SN.n(i).E = SN.n(i).E - ETx;
                SN.n(i).alpha = (4/25)*(2.5^4).^(SN.n(i).E);
                round_params('total energy') = round_params('total energy') + ETx;
                
                % Dissipation for Routing Node during reception
                if SN.n(SN.n(i).route_id).E > 0 && strcmp(SN.n(SN.n(i).route_id).cond, 'A') && strcmp(SN.n(SN.n(i).route_id).role, 'R')
                    ERx = (energy('rec') + energy('agg'))*k;
                    round_params('total energy') = round_params('total energy') + ERx;
                    SN.n(SN.n(i).route_id).E = SN.n(SN.n(i).route_id).E - ERx;
                    SN.n(SN.n(i).route_id).alpha = (4/25)*(2.5^4).^(SN.n(SN.n(i).route_id).E);

                    if SN.n(SN.n(i).route_id).E<=0  % if priority node energy depletes with reception
                        SN.n(SN.n(i).route_id).cond = 'D';
                        SN.n(SN.n(i).route_id).rop=round;
                        SN.n(SN.n(i).route_id).E=0;
                        SN.n(SN.n(i).route_id).alpha = 0;
                        round_params('dead nodes') = round_params('dead nodes') + 1;
                        round_params('operating nodes') = round_params('operating nodes') - 1;
                    end
                end
            end
            
        end
        
        % Check for node depletion
        if SN.n(i).E<=0 % if nodes energy depletes with transmission            
            round_params('dead nodes') = round_params('dead nodes') + 1;
            round_params('operating nodes') = round_params('operating nodes') - 1;
            SN.n(i).cond = 'D';
            SN.n(i).chid=0;
            SN.n(i).rop=round;
            SN.n(i).E=0;
            SN.n(i).alpha=0;            
        end
        
    end        
end

% Packet Transmission from Channel Heads to the Mobile Sink
ch_ids = unique([SN.n.chid]);

for chid = ch_ids
    if (chid ~= 0)
        if strcmp(SN.n(chid).role, 'C') &&  strcmp(SN.n(chid).cond, 'A')

            if SN.n(chid).E > 0

                % Initializing the distance matrix
                distances = zeros(1, length(rn_ids) + length(ms_ids));

                % Search for closest routing node
                for j=1:length(rn_ids)

                    if strcmp(SN.n(rn_ids(j)).cond,'A')
                        % distance of cluster head to routing node
                        distances(j)=sqrt((SN.n(rn_ids(j)).x-SN.n(chid).x)^2 + (SN.n(rn_ids(j)).y-SN.n(chid).y)^2);
                    else
                        distances(j)=sqrt( (dims('x_max'))^2 + (dims('y_max'))^2 );
                    end

                end

                % Search for closest mobile sink
                for j=1:length(ms_ids)
                    k = length(rn_ids) + j;

                    if strcmp(SN.n(ms_ids(j)).cond,'A')
                        % distance of cluster head to mobile sink
                        distances(k)=sqrt((SN.n(ms_ids(j)).x-SN.n(chid).x)^2 + (SN.n(ms_ids(j)).y-SN.n(chid).y)^2);
                    else
                        distances(k)=sqrt( (dims('x_max'))^2 + (dims('y_max'))^2 );
                    end

                end

                [~,I]=min(distances(:)); % finds the minimum distance to the cluster head

                % Direct transmission to mobile sink without routing
                if I > length(rn_ids)

                    ms_id = SN.n(I - length(rn_ids)).id;
                    dist_to_sink = sqrt((SN.n(ms_id).x-SN.n(chid).x)^2 + (SN.n(ms_id).y-SN.n(chid).y)^2);

                    ETx = (energy('tran')+energy('agg'))*k + energy('amp') * k * dist_to_sink^2;
                    SN.n(chid).E = SN.n(chid).E - ETx;
                    SN.n(chid).alpha = (4/25)*(2.5^4).^(SN.n(chid).E);
                    round_params('total energy') = round_params('total energy') + ETx;

                    % Energy Dissipation in Mobile Sink
                    ERx=(energy('rec') + energy('agg'))*k;
                    round_params('total energy') = round_params('total energy') + ERx;

                % Transmission via routing
                else           

                    dcr = distances(I); % assigns the distance of node to RN
                    SN.n(chid).route_id = rn_ids(I);

                    % Transmission energy to the Routing Node
                    ETx = (energy('tran')+energy('agg'))*k + energy('amp') * k * dcr^2;
                    SN.n(chid).E = SN.n(chid).E - ETx;
                    SN.n(chid).alpha = (4/25)*(2.5^4).^(SN.n(chid).E);
                    round_params('total energy') = round_params('total energy') + ETx;

                    % Receiving energy at the Routing Node
                    ERx=( energy('rec') + energy('agg') )*k;
                    round_params('total energy') = round_params('total energy') + ERx;
                    SN.n(SN.n(chid).route_id).E=SN.n(SN.n(chid).route_id).E - ERx;
                    SN.n(SN.n(chid).route_id).alpha = (4/25)*(2.5^4).^(SN.n(SN.n(chid).route_id).E);

                    % Transmission from the routing node to the Mobile Sink
                    if SN.n(SN.n(chid).route_id).E > 0 

                        % Checking for the closest mobile sink
                        distances = zeros(1, length(ms_ids));
                        for j = 1:length(ms_ids)
                            distances(j) = sqrt( (SN.n(ms_ids(j)).x - SN.n(chid).x)^2 + (SN.n(ms_ids(j)).y - SN.n(chid).y)^2 );
                        end

                        dist_to_nearest_sink = min(distances(:)); % Distance to closest mobile sink

                        ETx = (energy('tran')+energy('agg'))*k + energy('amp') * k * dist_to_nearest_sink^2;
                        SN.n(SN.n(chid).route_id).E = SN.n(SN.n(chid).route_id).E - ETx;
                        SN.n(SN.n(chid).route_id).alpha = (4/25)*(2.5^4).^(SN.n(SN.n(chid).route_id).E);
                        round_params('total energy') = round_params('total energy') + ETx;
                        round_params('packets') = round_params('packets') + 1;

                        % Energy Dissipation in Mobile Sink
                        ERx = (energy('rec') + energy('agg')) * k;
                        round_params('total energy') = round_params('total energy') + ERx;
                    end

                    if SN.n(SN.n(chid).route_id).E <= 0  % if routing node energy depletes with transmission
                        SN.n(SN.n(chid).route_id).cond = 'D';
                        SN.n(SN.n(chid).route_id).rop=round;
                        SN.n(SN.n(chid).route_id).E=0;
                        SN.n(SN.n(chid).route_id).alpha = 0;
                        round_params('dead nodes') = round_params('dead nodes') + 1;
                        round_params('operating nodes') = round_params('operating nodes') - 1;
                    end

                end

                if  SN.n(chid).E <= 0 % if cluster heads energy depletes with transmission
                    round_params('dead nodes') = round_params('dead nodes') + 1;
                    round_params('operating nodes') = round_params('operating nodes') - 1;
                    SN.n(chid).cond='D';
                    SN.n(chid).rop=round;
                    SN.n(chid).E=0;
                    SN.n(chid).alpha = 0;
                end

            end
        end
    end
end

stop_time = toc;
contact_time = stop_time - start_time;

round_params('contact time') = round_params('contact time') + contact_time;

int_conn_start = toc;
int_conn_start_check = true;

end

