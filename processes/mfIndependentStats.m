function MF_StatsSummary = mfIndependentStats(regionDataM, regionDataF, integrationM, ...
    integrationF, XtimeMF, regionsToCompare, mfDir)

    MF_StatsSummary = table();

    for r = 1:length(regionsToCompare)
        region = regionsToCompare{r};

        if ~isfield(regionDataM,region) || ~isfield(regionDataF,region)
            fprintf('MF : région "%s" absente dans M ou F, on saute.\n',region);
            continue
        end

        labelsM = regionDataM.(region).labels;
        labelsF = regionDataF.(region).labels;
        communLabels = intersect(labelsM,labelsF,'stable');

        for k = 1:length(communLabels)
            paramName = communLabels{k};
            idxParamM = find(strcmp(labelsM,paramName),1);
            idxParamF = find(strcmp(labelsF,paramName),1);

            sheetIdxM = regionDataM.(region).indPlot(idxParamM);
            sheetIdxF = regionDataF.(region).indPlot(idxParamF);

            valM = integrationM(sheetIdxM,:);
            valF = integrationF(sheetIdxF,:);
            valM = valM(~isnan(valM));
            valF = valF(~isnan(valF));

            if numel(valM) < 3 || numel(valF) < 3
                fprintf('\n[M vs F | %s] %s : pas assez de films valides.\n',region,paramName);
                continue
            end

            [~,p_ttest2,~,stats2] = ttest2(valM,valF,'Vartype','unequal');
            p_ranksum = ranksum(valM,valF);

            MF_StatsSummary = [MF_StatsSummary; table(string(region), string(paramName), ...
                numel(valM), numel(valF), mean(valM,'omitnan'), mean(valF,'omitnan'), ...
                stats2.tstat, p_ttest2, p_ranksum, ...
                'VariableNames', {'Region','Parametre','N_M','N_F', ...
                'MoyenneM','MoyenneF','tStat','p_ttest2_indep','p_ranksum'})]; %#ok<AGROW>

            fprintf('\n[M vs F | %s] %s (N_M=%d, N_F=%d) : ttest2 p=%.4g | ranksum p=%.4g\n', ...
                region,paramName,numel(valM),numel(valF),p_ttest2,p_ranksum);

            try
                yM = regionDataM.(region).Xmoy_plot(:,idxParamM);
                sM = regionDataM.(region).std_plot(:,idxParamM);
                yF = regionDataF.(region).Xmoy_plot(:,idxParamF);
                sF = regionDataF.(region).std_plot(:,idxParamF);

                fig = figure('Name',['MF - ' paramName ' - ' region], 'Visible','off');
                hold on
                errorbar(XtimeMF, yM, sM, '-o','LineWidth',1.5,'CapSize',5,'DisplayName','Mâles')
                errorbar(XtimeMF, yF, sF, '-s','LineWidth',1.5,'CapSize',5,'DisplayName','Femelles')
                grid on; xlabel('Time'); ylabel(paramName,'Interpreter','none')
                title(sprintf('%s - %s (M vs F, indépendant)\np_{ttest2}=%.3g  p_{ranksum}=%.3g', ...
                    paramName,region,p_ttest2,p_ranksum),'Interpreter','none')
                legend('Location','best')

                safeParam = regexprep(paramName,'[\\/:*?"<>|]','_');
                saveas(fig, fullfile(mfDir, ['MF_' safeParam '_' region '.png']))
                close(fig)
            catch ME
                fprintf(2,'   !! Erreur figure MF %s (%s) : %s\n',paramName,region,ME.message);
            end
        end
    end
end