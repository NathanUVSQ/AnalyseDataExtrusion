function plotCVComparisons(regionData, pairesAComparer, Xtime, comparisonDir, regionColors)

    for p = 1:length(pairesAComparer)
        regA = pairesAComparer{p}{1};
        regB = pairesAComparer{p}{2};

        if ~isfield(regionData,regA) || ~isfield(regionData,regB)
            fprintf('Comparaison CV %s vs %s impossible (données manquantes)\n',regA,regB);
            continue
        end

        labelsA = regionData.(regA).labels;
        labelsB = regionData.(regB).labels;
        communLabels = intersect(labelsA,labelsB,'stable');

        for k = 1:length(communLabels)
            paramName = communLabels{k};
            idxA = find(strcmp(labelsA,paramName),1);
            idxB = find(strcmp(labelsB,paramName),1);

            cvA = regionData.(regA).Xcoef_plot(:,idxA);
            cvB = regionData.(regB).Xcoef_plot(:,idxB);

            fig = figure('Name',['CV ' paramName ' - ' regA ' vs ' regB], 'Visible','off');
            hold on
            plot(Xtime, cvA, '-o','LineWidth',1.5,'Color',regionColors(regA),'DisplayName',regA);
            plot(Xtime, cvB, '-s','LineWidth',1.5,'Color',regionColors(regB),'DisplayName',regB);
            hold off
            grid on; xlabel('Time'); ylabel(['CV - ' paramName],'Interpreter','none')
            title(['CoefVar ' paramName ' : ' regA ' vs ' regB],'Interpreter','none')
            legend('Location','best')

            safeParam = regexprep(paramName,'[\\/:*?"<>|]','_');
            saveas(fig, fullfile(comparisonDir, ['CV ' safeParam ' - ' regA ' vs ' regB '.png']))
            close(fig)
        end
    end
end