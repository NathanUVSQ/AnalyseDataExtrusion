function plotSingleMovieComparison(regionData, rawDataBySheet, pairesAComparer, Xtime, ...
    tStart, tEnd, movieID, comparisonDir, regionColors)

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

            sheetIdxA = regionData.(regA).indPlot(idxA);
            sheetIdxB = regionData.(regB).indPlot(idxB);

            YA = rawDataBySheet{sheetIdxA};
            YB = rawDataBySheet{sheetIdxB};

            if movieID > size(YA,2) || movieID > size(YB,2)
                fprintf('Film %d indisponible pour "%s" (%s vs %s)\n', movieID, paramName, regA, regB);
                continue
            end

            fig = figure('Name',[paramName ' - ' regA ' vs ' regB ' - Film ' num2str(movieID)], 'Visible','off');
            hold on
            plot(Xtime, YA(:,movieID), '-o','LineWidth',1.5,'Color',regionColors(regA),'DisplayName',regA);
            plot(Xtime, YB(:,movieID), '-s','LineWidth',1.5,'Color',regionColors(regB),'DisplayName',regB);
            hold off
            grid on; xlabel('Time'); ylabel(paramName,'Interpreter','none')
            xlim([tStart tEnd])
            title([paramName ' : ' regA ' vs ' regB ' - Film ' num2str(movieID)],'Interpreter','none')
            legend('Location','best')

            safeParam = regexprep(paramName,'[\\/:*?"<>|]','_');
            saveas(fig, fullfile(comparisonDir, [safeParam ' - ' regA ' vs ' regB ' - Film' num2str(movieID) '.png']))
            close(fig)
        end
    end
end