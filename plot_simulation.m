function figure_num = plot_simulation(figure_num, SN_compare, rounds, dims, sn_positioning, pn_select_method);
%PLOT_SIMULATION Summary of this function goes here
%   Detailed explanation goes here

% Sub Plot Defining
if length(SN_compare) <= 4
    sp_row = 2;
    sp_col = 2;
elseif length(SN_compare) <= 6
    sp_row = 2;
    sp_col = 3;
else
    sp_row = ceil(length(SN_compare)/3);
    sp_col = 3;
end


figure_num = figure_num + 1;
figure(figure_num);
hold on;

plot_i = 0;
node_plots = {};
clear round_val_texts;

for sn_method = sn_positioning
    for pn_method = pn_select_method

        if strcmp(pn_method, "cluster_head") && ~strcmp(sn_method, "random")
            continue
        end
        
        name = char(sn_method + ' ' + pn_method);
        title_name = { capitalize(strjoin(split(sn_method, '_'))), capitalize(strjoin(split(pn_method, '_'))) };
        SN = SN_compare(char(name));
        
        if strcmp(pn_method, "cluster_head") && strcmp(sn_method, "random")
            title_name = {'LEACH Algorithm', 'Single Static Sinks'};
        end
        
        plot_i = plot_i + 1;
        subplot(sp_row, sp_col, plot_i)
        
        xlabel('X (meters)');
        ylabel('Y (meters)');
        title(title_name);

        plot( dims('x_min'),dims('y_min'),dims('x_max'),dims('y_max') );

        for i = 1:length(SN.n)
            node_plot(i) = scatter(SN.n(i).Xs(1), SN.n(i).Ys(1), SN.n(i).size );
            node_plot(i).MarkerFaceColor = SN.n(i).COLs(1);
            node_plot(i).MarkerFaceAlpha = SN.n(i).ALPHAs(1);
            node_plot(i).MarkerEdgeAlpha = 0;
        end

        round_val_text = text(dims('x_min'), dims('y_max'), cat(2,'Round = 0'));
        
        node_plots(plot_i) = {node_plot};
        round_val_texts(plot_i) = round_val_text;
        
        hold on;
        
    end
end


for round = 1:rounds
    
    plot_i = 0;
    for sn_method = sn_positioning
        for pn_method = pn_select_method

            if strcmp(pn_method, "cluster_head") && ~strcmp(sn_method, "random")
                continue
            end
            
            name = char(sn_method + ' ' + pn_method);
            SN = SN_compare(char(name));
            
            plot_i = plot_i + 1;
            subplot(sp_row, sp_col, plot_i)
            
            node_plot = node_plots{plot_i};
            round_val_text = round_val_texts(plot_i);
            hold on;
    
            set(round_val_text, 'String', cat(2,'Round = ', num2str(round)));
            hold on;
            
            for i = 1:length(SN.n)
                set(node_plot(i), {'XData', 'YData', 'MarkerFaceColor', 'MarkerFaceAlpha' }, {SN.n(i).Xs(round), SN.n(i).Ys(round), SN.n(i).COLs(round), SN.n(i).ALPHAs(round)});
                hold on;
            end
            drawnow;
            hold on;
        end
    end
end

hold off;

end

