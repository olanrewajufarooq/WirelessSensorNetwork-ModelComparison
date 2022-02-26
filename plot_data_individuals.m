function figure_num = plot_data_individuals(figure_num, rounds, sim_params_compare, sn_positioning, pn_select_method)
%PLOT_DATA_INDIVIDUALS Summary of this function goes here
%   Detailed explanation goes here

for sn_method = sn_positioning
    
    for pn_method = pn_select_method
        
        if strcmp(pn_method, "cluster_head") && ~strcmp(sn_method, "random")
            continue
        end
        
        name = char(sn_method + ' ' + pn_method);
        legend_name = capitalize(strjoin(split(sn_method, '_'))) + ': ' + capitalize(strjoin(split(pn_method, '_')));
        sim_params = sim_params_compare(char(name));
        
        if strcmp(pn_method, "cluster_head") && strcmp(sn_method, "random")
            legend_name = {'LEACH Algorithm: Single Static Sinks'};
        end
        
        figure_num = figure_num + 1;
        figure(figure_num)

        i = 0;
        for param = ["dead nodes", "operating nodes", "total energy", "packets", "contact time", "interconnect time"]
            i = i + 1;
            subplot(2, 3, i)

            plot(1:rounds,sim_params(param),'-r','Linewidth',2);
            hold on

            xlim([0 rounds]);
            axis tight
            title( [capitalize(param), 'Per Round'] );
            xlabel 'Rounds';

            ylabel ( capitalize(param) );
            legend(legend_name);
        end
        hold off
    end
end

end

