function figure_num = plot_data_compare(figure_num, rounds, sim_params_compare, sn_positioning, pn_select_method)
%PLOT_DATA_COMPARE Summary of this function goes here
%   Detailed explanation goes here

figure_num = figure_num + 1;
figure(figure_num)

% Getting Legend Names
k = 0;
legend_names = {};
for sn_method = sn_positioning
    for pn_method = pn_select_method

        if strcmp(pn_method, "cluster_head") && ~strcmp(sn_method, "random")
            continue
        elseif strcmp(pn_method, "cluster_head") && strcmp(sn_method, "random")
            k = k + 1;
            legend_names(k) = {'LEACH Algorithm: Static Sinks'};
        else
            k = k + 1;
            legend_names(k) = { capitalize(strjoin(split(sn_method, '_'))) + ': ' + capitalize(strjoin(split(pn_method, '_'))) };
        end
        
    end
end
        
        

i = 0;
colors = containers.Map( {1, 2, 3, 4, 5, 6, 7}, {'-r', '-g', '-b', '-k', '-m', '-y', '-c'} );
for param = ["dead nodes", "operating nodes", "total energy", "packets", "contact time", "interconnect time"]
    i = i + 1;
    subplot(2, 3, i)
    
    color_num = 0;
    for sn_method = sn_positioning
        for pn_method = pn_select_method

            if strcmp(pn_method, "cluster_head") && ~strcmp(sn_method, "random")
                continue
            end

            name = char(sn_method + ' ' + pn_method);
            sim_params = sim_params_compare(char(name));
            
            color_num = color_num + 1;
            plot(1:rounds,sim_params(param),colors(color_num),'Linewidth',2);
            hold on
        end
    end
    
    xlim([0 rounds]);
    axis tight
    title( [capitalize(param), 'Per Round'] );
    xlabel 'Rounds';

    ylabel ( capitalize(param) );
    legend(legend_names, 'Location', 'best');
    
    hold off;
    
end

