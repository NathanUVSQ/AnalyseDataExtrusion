function PairedStatsSummary = pairedStatsTest(regionData, pairesAComparer, integration, ...
    rawDataBySheet, Xtime, tStart, tEnd, statsDir)

    PairedStatsSummary = table();

    for p = 1:length(pairesAComparer)
        regA = pairesAComparer{p}{1};
        regB = pairesAComparer{p}{2};

        if ~isfield(regionData,regA) || ~isfield(regionData,regB)
            fprintf('Stats appariées %s vs %s impossibles (données manquantes)\n',regA,regB);
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

            valA = integration(sheetIdxA,:);
            valB = integration(sheetIdxB,:);
            valid = ~isnan(valA) & ~isnan(valB);
            valA = valA(valid); valB = valB(valid);

            if numel(valA) >= 3
                [~,p_ttest,~,stats] = ttest(valA,valB);
                p_wilcoxon = signrank(valA,valB);
                diffMean = mean(valA - valB);
                diffStd  = std(valA - valB);

                PairedStatsSummary = [PairedStatsSummary; table(string(regA),string(regB),string(paramName), ...
                    numel(valA), diffMean, diffStd, stats.tstat, p_ttest, p_wilcoxon, ...
                    'VariableNames', {'RegionA','RegionB','Parametre','N', ...
                    'DiffMoyenne','DiffStd','tStat','p_ttest_appariee','p_wilcoxon'})]; %#ok<AGROW>

                fprintf('\n[%s vs %s] %s (n=%d films) : t-test apparié p=%.4g | Wilcoxon p=%.4g\n', ...
                    regA,regB,paramName,numel(valA),p_ttest,p_wilcoxon);
            else
                fprintf('\n[%s vs %s] %s : pas assez de films valides.\n',regA,regB,paramName);
            end

            YA = rawDataBySheet{sheetIdxA};
            YB = rawDataBySheet{sheetIdxB};
            nT = size(YA,1);
            pTime = nan(nT,1);

            for t = 1:nT
                a = YA(t,:); b = YB(t,:);
                okT = ~isnan(a) & ~isnan(b);
                if sum(okT) >= 3
                    [~,pTime(t)] = ttest(a(okT),b(okT));
                end
            end

            validP = ~isnan(pTime);
            pFDR = nan(size(pTime));
            if any(validP)
                pFDR(validP) = bh_correction(pTime(validP));
            end

            try
                fig = figure('Name',['Paired stats - ' paramName ' - ' regA ' vs ' regB], 'Visible','off');
                hold on
                errorbar(Xtime, regionData.(regA).Xmoy_plot(:,idxA), regionData.(regA).std_plot(:,idxA), ...
                    '-o','LineWidth',1.5,'DisplayName',regA)
                errorbar(Xtime, regionData.(regB).Xmoy_plot(:,idxB), regionData.(regB).std_plot(:,idxB), ...
                    '-s','LineWidth',1.5,'DisplayName',regB)

                yl = ylim;
                sigTimes = Xtime(pFDR < 0.05);
                if ~isempty(sigTimes)
                    plot(sigTimes, repmat(yl(2)*0.95,size(sigTimes)), 'k*','DisplayName','p_{FDR}<0.05')
                end

                grid on; xlabel('Time'); ylabel(paramName,'Interpreter','none')
                xlim([tStart tEnd])
                title(['Test apparié par instant - ' paramName ' : ' regA ' vs ' regB],'Interpreter','none')
                legend('Location','best')

                safeParam = regexprep(paramName,'[\\/:*?"<>|]','_');
                saveas(fig, fullfile(statsDir, ['Paired_' safeParam '_' regA 'vs' regB '.png']))
                close(fig)
            catch ME
                fprintf(2,'   !! Erreur figure %s (%s vs %s) : %s\n',paramName,regA,regB,ME.message);
            end
        end
    end
end