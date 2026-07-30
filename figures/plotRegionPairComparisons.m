function plotRegionPairComparisons(regionData, pairesAComparer, Xtime, tStart, tEnd, comparisonDir, regionColors)

    for p = 1:length(pairesAComparer)
        regA = pairesAComparer{p}{1};
        regB = pairesAComparer{p}{2};

        if ~isfield(regionData,regA) || ~isfield(regionData,regB)
            fprintf('Comparaison %s vs %s impossible (données manquantes)\n',regA,regB);
            continue
        end

        labelsA = regionData.(regA).labels;
        labelsB = regionData.(regB).labels;
        communLabels = intersect(labelsA,labelsB,'stable');

        for k = 1:length(communLabels)
            paramName = communLabels{k};
            idxA = find(strcmp(labelsA,paramName),1);
            idxB = find(strcmp(labelsB,paramName),1);

            yA = regionData.(regA).Xmoy_plot(:,idxA);
            sA = regionData.(regA).std_plot(:,idxA);
            yB = regionData.(regB).Xmoy_plot(:,idxB);
            sB = regionData.(regB).std_plot(:,idxB);

            fig = figure('Name',[paramName ' - ' regA ' vs ' regB], 'Visible','off');
            hold on
            errorbar(Xtime, yA, sA, '-o','LineWidth',1.5,'CapSize',5,'Color',regionColors(regA),'DisplayName',regA);
            errorbar(Xtime, yB, sB, '-s','LineWidth',1.5,'CapSize',5,'Color',regionColors(regB),'DisplayName',regB);
            hold off
            grid on; xlabel('Time'); ylabel(paramName,'Interpreter','none')
            xlim([tStart tEnd])
            title([paramName ' : ' regA ' vs ' regB],'Interpreter','none')
            legend('Location','best')

            safeParam = regexprep(paramName,'[\\/:*?"<>|]','_');
            saveas(fig, fullfile(comparisonDir, [safeParam ' - ' regA ' vs ' regB '.png']))
            close(fig)
        end
    end
end