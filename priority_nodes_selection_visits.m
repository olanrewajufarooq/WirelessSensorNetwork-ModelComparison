function [SN,  pn_ids] = priority_nodes_selection_visits(SN)
%PRIORITY_NODES_SELECTION Summary of this function goes here
%   Detailed explanation goes here


pn_ids = zeros( 1, length(unique([SN.n.cluster])) );
clusters = unique([SN.n.cluster]);

for cluster = clusters(~isnan(clusters))
    
    node_ids = []; % Node ID
    visits = []; % A nodes shortest distance to a predicted path
        
    for i=1:length(SN.n)
        if strcmp(SN.n(i).role, 'N') && strcmp(SN.n(i).cond, 'A') && (SN.n(i).cluster == cluster) && (~isnan(cluster))
            node_ids(end+1) = SN.n(i).id;
            visits(end+1) = SN.n(i).sn_visits; % Minimum DMS for each mobile nodes
        end 
    end
    
    [n_visits, J]=max(visits(:)); % finds the maximum visits of node by MS
    
    if n_visits > 0
        % To detect is J returns sn empty array
        j_shape = size(J);

        if j_shape(1) > 0
            pn_id = node_ids(J);
            SN.n(pn_id).role = 'P';
            SN.n(pn_id).col = "b"; % node color when plotting
            pn_ids(cluster) = pn_id;

            for i=1:length(SN.n)
                if strcmp(SN.n(i).role, 'N') && (SN.n(i).cluster == cluster)
                    SN.n(i).dnp = sqrt( (SN.n(i).x - SN.n(pn_id).x)^2 + (SN.n(i).y - SN.n(pn_id).y)^2 );
                    SN.n(i).pn_id = pn_id;
                end
            end

            SN.n(pn_id).dnp = 0;
            SN.n(pn_id).pn_id = pn_id;
        end
    end
    
end


end

