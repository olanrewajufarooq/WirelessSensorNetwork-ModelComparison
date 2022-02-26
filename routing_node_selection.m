function [SN, rn_ids] = routing_node_selection(SN, dims, n_routing_nodes)
%ROUTING_NODE_SELECTION Summary of this function goes here
%   Detailed explanation goes here

rn_ids = zeros(1, n_routing_nodes);
rn_dist_x = 0.25 * ( dims("x_max") - dims("x_min") );
rn_dist_y = 0.25 * ( dims("y_max") - dims("y_min") );


for i=1:n_routing_nodes
    theta = i * 2*pi / n_routing_nodes;
    route_x = dims("x_min") + 0.5*( dims("x_max") - dims("x_min") ) + rn_dist_x * cos(theta);
    route_y = dims("y_min") + 0.5*( dims("y_max") - dims("y_min") ) + rn_dist_y * sin(theta);

    % Computation of distance of each sensor node to the routing node
    % mark point
    dsr = zeros(1, length(SN.n));
    for j = 1:length(SN.n)
        if strcmp(SN.n(j).role, 'N')             
            dist = sqrt( (route_x - SN.n(j).x)^2 + (route_y - SN.n(j).y)^2 );
            dsr(j) = dist;
        else
            dsr(j) = dims('x_max');
        end
    end

    % Determination of the ID of the sensor node closest to the
    % location of the desired routing node
    [~, route_id] = min( dsr(:) );

    SN.n(route_id).role = 'R';
    SN.n(route_id).col = "b"; % node color when plotting
    rn_ids(i) = route_id;
    
end

end

