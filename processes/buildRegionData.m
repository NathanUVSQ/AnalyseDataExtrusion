function [regionData, RegressionSummary] = buildRegionData(regions, allSheets, ...
    matrice_coef_var, matrice_std, matrice_variance, matrice_data, matrice_moyenne, ...
    Xtime, tStart, tEnd, figuresDir, moyenne_decision, regression_decision, ...
    variance_decision, cumulative_decision, excelExtrusions, excelDivisions, ...
    sheetNamesExtr, sheetNamesDiv)

    regionData = struct();
    RegressionSummary = table();

    for r = 1:length(regions)

        region = regions{r};

        isRegionMatch = false(length(allSheets),1);
        for k = 1:length(allSheets)
            tokens = regexp(allSheets{k}, '[_\-\s]', 'split');
            isRegionMatch(k) = any(strcmpi(tokens, region));
        end

        isOrientation   = contains(allSheets,'meanOri','IgnoreCase',true) & isRegionMatch;
        isEccentricity  = contains(allSheets,'meanEcc','IgnoreCase',true) & isRegionMatch;
        isArea          = contains(allSheets,'meanArea','IgnoreCase',true) & isRegionMatch;
        isCvOrientation = contains(allSheets,'cvOri','IgnoreCase',true) & isRegionMatch;
        isCvEccentricity= contains(allSheets,'cvEcc','IgnoreCase',true) & isRegionMatch;
        isCvArea        = contains(allSheets,'cvArea','IgnoreCase',true) & isRegionMatch;
        isTotal         = contains(allSheets,'meanCells','IgnoreCase',true) & isRegionMatch;

        tmp = find(strcmpi(allSheets, region));
        extr = NaN; div = NaN;
        if ~isempty(tmp), extr = tmp(1); end
        if length(tmp) >= 2, div = tmp(2); end

        ori  = find(isOrientation,1);
        ecc  = find(isEccentricity,1);
        area = find(isArea,1);
        cvOri  = find(isCvOrientation,1);
        cvEcc  = find(isCvEccentricity,1);
        cvArea = find(isCvArea,1);
        totalCells = find(isTotal,1);

        allInd = [extr ori ecc area div totalCells cvOri cvEcc cvArea];
        allLabels = {'Extrusions','Orientation','Eccentricity','Area','Division','Number Cells', ...
                     'cvOrientation','cvEccentricity','cvArea'};

        mask = ~isnan(allInd) & allInd > 0;
        ind = allInd(mask);
        labels = allLabels(mask);

        if isempty(ind)
            fprintf('Aucune donnée trouvée pour la région "%s", on saute.\n',region)
            continue
        end

        Xcoef = matrice_coef_var(:,ind);
        Xdata = matrice_data(:,ind);

        coefMask = ismember(labels, {'Extrusions','Orientation','Eccentricity','Area','Division','Number Cells'});
        Xcoef_plot = Xcoef(:,coefMask);
        labels_plot = labels(coefMask);
        indPlot = ind(coefMask);
        regionData.(region).indPlot = indPlot;

        Xmoy = matrice_moyenne(:,ind);
        Xmoy_plot = Xmoy(:,coefMask);
        std_plot = matrice_std(:,ind);
        std_plot = std_plot(:,coefMask);

        if moyenne_decision
            plotMeansOverTime(Xmoy_plot, std_plot, labels_plot, Xtime, tStart, tEnd, region, figuresDir);
        end

        regionData.(region).Xmoy_plot  = Xmoy_plot;
        regionData.(region).std_plot   = std_plot;
        regionData.(region).labels     = labels_plot;
        regionData.(region).Xcoef_plot = Xcoef_plot;

        if regression_decision
            RegressionSummary = [RegressionSummary; ...
                regressionSDvsMean(labels_plot, Xmoy_plot, std_plot, region, figuresDir)]; %#ok<AGROW>
        end

        plotCVOverTime(Xcoef_plot, labels_plot, Xtime, tStart, tEnd, region, figuresDir);
        plotSpearmanMatrix(Xcoef_plot, labels_plot, ['CoefVar - ' region], ...
            fullfile(figuresDir,['Matrice coef variation ' region '.png']));

        if variance_decision
            Xvar = matrice_variance(:,ind);
            Xvar_plot = Xvar(:,coefMask);
            plotVarianceOverTime(Xvar_plot, labels_plot, Xtime, tStart, tEnd, region, figuresDir);
        end

        if cumulative_decision
            plotCumulativeEvents(labels_plot, ind, allSheets, excelExtrusions, excelDivisions, ...
                tStart, tEnd, region, figuresDir);
        end

        plotSpearmanMatrix(Xdata, labels, ['Spearman Raw Data - ' region], ...
            fullfile(figuresDir,['Matrice Raw Data ' region '.png']));

        %close all
    end
end


%% ---- sous-fonctions locales (même fichier, appelées seulement ici) ----

function plotMeansOverTime(Xmoy_plot, std_plot, labels_plot, Xtime, tStart, tEnd, region, figuresDir)
    nParams = size(Xmoy_plot,2);
    nCols = 3;
    nRows = ceil(nParams/nCols);
    colorsMoy = lines(nParams);

    figFullscreen = figure('Name',['Moyennes over time - ' region], ...
        'Units','normalized','Position',[0.05 0.05 0.9 0.85],'Visible','off');

    for k = 1:nParams
        subplot(nRows, nCols, k)
        errorbar(Xtime, Xmoy_plot(:,k), std_plot(:,k), ...
            'Color',colorsMoy(k,:),'LineWidth',1.5,'CapSize',5);
        xlabel('Time'); ylabel(labels_plot{k}, 'Interpreter','none')
        xlim([tStart tEnd]); grid on
        title(labels_plot{k}, 'Interpreter','none')
    end
    sgtitle(['Moyennes vs Temps - ' region], 'Interpreter','none')
    saveas(figFullscreen, fullfile(figuresDir,['Moyennes vs Temps ' region '.png']))
end

function plotCVOverTime(Xcoef_plot, labels_plot, Xtime, tStart, tEnd, region, figuresDir)
    figure('Name',['CoefVar over time - ' region], 'Visible','off')
    hold on
    colorsCV = lines(size(Xcoef_plot,2));
    for k = 1:size(Xcoef_plot,2)
        plot(Xtime, Xcoef_plot(:,k), 'LineWidth', 1.5, 'Color', colorsCV(k,:));
    end
    hold off
    xlabel('Time'); ylabel('Coefficient of Variation')
    xlim([tStart tEnd]); grid on
    title(['Coefficient de variation vs Temps - ' region],'Interpreter','none')
    legend(labels_plot,'Location','bestoutside','Interpreter','none')
    saveas(gcf, fullfile(figuresDir,['CoefVar et Temps ' region '.png']))
end

function plotVarianceOverTime(Xvar_plot, labels_plot, Xtime, tStart, tEnd, region, figuresDir)
    figure('Name',['Variance over time - ' region],'Visible','off')
    hold on
    colorsVar = lines(size(Xvar_plot,2));
    for k = 1:size(Xvar_plot,2)
        plot(Xtime, Xvar_plot(:,k), 'LineWidth',1.5, 'Color',colorsVar(k,:));
    end
    hold off
    xlabel('Time'); ylabel('Variance')
    title(['Variance vs Temps - ' region])
    xlim([tStart tEnd]); grid on
    legend(labels_plot,'Location','bestoutside','Interpreter','none')
    saveas(gcf, fullfile(figuresDir,['Variance et Temps ' region '.png']))
end

function RegressionSummary = regressionSDvsMean(labels_plot, Xmoy_plot, std_plot, region, figuresDir)
    RegressionSummary = table();
    wantedNames = {'Extrusions','Division','Orientation','Eccentricity','Area'};
    regIdx = []; regNames = {};
    for ii = 1:numel(wantedNames)
        idx = find(strcmp(labels_plot,wantedNames{ii}),1);
        if ~isempty(idx)
            regIdx(end+1) = idx; %#ok<AGROW>
            regNames{end+1} = wantedNames{ii}; %#ok<AGROW>
        end
    end
    colorsReg = lines(length(regIdx));

    for k = 1:length(regIdx)
        idx = regIdx(k);
        Xmean = Xmoy_plot(:,idx);
        Ystd  = std_plot(:,idx);
        valid = ~isnan(Xmean) & ~isnan(Ystd);
        Xmean = Xmean(valid); Ystd = Ystd(valid);
        if numel(Xmean) < 3, continue; end

        p = polyfit(Xmean,Ystd,1);
        Yfit = polyval(p,Xmean);
        SSres = sum((Ystd-Yfit).^2);
        SStot = sum((Ystd-mean(Ystd)).^2);
        R2 = 1-SSres/SStot;
        [Rho,Pval] = corr(Xmean,Ystd,'Type','Pearson');

        RegressionSummary = [RegressionSummary; table(string(region), string(regNames{k}), ...
            p(1), p(2), Rho, R2, Pval, numel(Xmean), ...
            'VariableNames', {'Region','Type','Slope','Intercept','R','R2','Pvalue','N'})]; %#ok<AGROW>

        fig = figure('Visible','off','Name',[regNames{k} ' - ' region]);
        scatter(Xmean,Ystd,70,'filled','MarkerFaceColor',colorsReg(k,:));
        hold on
        [Xsort,ord] = sort(Xmean);
        plot(Xsort,Yfit(ord),'Color',colorsReg(k,:),'LineWidth',2);
        grid on
        xlabel(['Mean ' regNames{k}]); ylabel('Standard deviation')
        title(sprintf('%s - %s\nR = %.2f   p = %.3g   R² = %.2f', regNames{k},region,Rho,Pval,R2),'Interpreter','none')
        saveas(fig, fullfile(figuresDir, sprintf('Regression_SD_Mean_%s_%s.png',regNames{k},region)))
        close(fig)
    end
end

function plotCumulativeEvents(labels_plot, ind, allSheets, excelExtrusions, excelDivisions, tStart, tEnd, region, figuresDir)
    idxExtr = find(strcmp(labels_plot,'Extrusions'));
    idxDiv  = find(strcmp(labels_plot,'Division'));
    if isempty(idxExtr) && isempty(idxDiv), return; end

    figure('Name',['Cumulative events - ' region], 'Visible','off')
    hold on
    lgd = {};

    if ~isempty(idxExtr)
        T = readtable(excelExtrusions,'Sheet',allSheets{ind(idxExtr)});
        [meanCum, stdCum, X] = cumulSeries(T, tStart, tEnd);
        errorbar(X, meanCum, stdCum, '-o','LineWidth',2,'MarkerSize',4)
        lgd{end+1} = 'Extrusions';
    end
    if ~isempty(idxDiv)
        T = readtable(excelDivisions,'Sheet',allSheets{ind(idxDiv)});
        [meanCum, stdCum, X] = cumulSeries(T, tStart, tEnd);
        errorbar(X, meanCum, stdCum, '-s','LineWidth',2,'MarkerSize',4)
        lgd{end+1} = 'Divisions';
    end

    grid on; xlabel('Time'); ylabel('Cumulative number of events')
    title(['Cumulative events - ' region],'Interpreter','none')
    legend(lgd,'Location','best')
    saveas(gcf, fullfile(figuresDir,['Cumulative events ' region '.png']))
end

function [meanCum, stdCum, X] = cumulSeries(T, tStart, tEnd)
    X = T{:,1}; Y = T{:,2:end};
    mask = X>=tStart & X<=tEnd;
    X = X(mask); Y = Y(mask,:);
    Ycum = cumsum(Y,1);
    meanCum = mean(Ycum,2,'omitnan');
    stdCum  = std(Ycum,0,2,'omitnan');
end

function plotSpearmanMatrix(Xmat, labelsIn, titleStr, savePath)
    [R,P] = corr(Xmat,'Type','Spearman','Rows','pairwise');
    figure('Name',titleStr, 'Visible','off')
    imagesc(R); colorbar; clim([-1 1]); axis square
    hold on
    for i = 1:size(R,1)
        for j = 1:size(R,2)
            if P(i,j) < 0.001, sig = '***';
            elseif P(i,j) < 0.01, sig = '**';
            elseif P(i,j) < 0.05, sig = '*';
            else, sig = 'ns'; end
            text(j, i-0.15, sprintf('%.2f',R(i,j)), 'HorizontalAlignment','center','FontWeight','bold','FontSize',11);
            text(j, i+0.20, sig, 'HorizontalAlignment','center','FontSize',8,'Color','r');
        end
    end
    xticks(1:length(labelsIn)); yticks(1:length(labelsIn))
    xticklabels(labelsIn); yticklabels(labelsIn); xtickangle(45)
    title(titleStr,'Interpreter','none')
    saveas(gcf, savePath)
end