function [matrice_coef_var, matrice_std, matrice_variance, matrice_data, ...
          matrice_moyenne, Xtime, integration, integration_name, rawDataBySheet] = ...
          computeSheetStats(allSheets, allFiles, tStart, tEnd, outputExcel, figuresDir)

    matrice_coef_var = [];
    matrice_std      = [];
    matrice_variance = [];
    matrice_data     = [];
    matrice_moyenne  = [];
    nRowsRef         = [];
    Xtime            = [];

    % Init integration à partir de la première feuille
    T = readtable(allFiles{1},'Sheet',allSheets{1});
    X = T{:,1};
    Y = T{:,2:end};
    mask = X >= tStart & X <= tEnd;
    Y = Y(mask,:);
    integration = nan(length(allSheets),size(Y,2));
    integration_name = strings(0,1);
    rawDataBySheet = cell(length(allSheets),1);

    for s = 1:length(allSheets)

        sheet = allSheets{s};
        file  = allFiles{s};

        fprintf('\nTraitement : %s\n',sheet)

        T = readtable(file,'Sheet',sheet);
        X = T{:,1};
        Y = T{:,2:end};

        mask = X >= tStart & X <= tEnd;
        X = X(mask);
        Y = Y(mask,:);
        rawDataBySheet{s} = Y;

        if isempty(X)
            warning('Aucune donnée dans [%g,%g] pour "%s". Feuille ignorée.', tStart, tEnd, sheet);
            continue
        end

        if isempty(Xtime)
            Xtime = X;
        end

        Vector_data = Y(:);

        moyenne   = mean(Y,2,'omitnan');
        ecartType = std(Y,0,2,'omitnan');
        coefVar   = ecartType ./ moyenne;
        variance  = var(Y,0,2,'omitnan');

        Resultats = table(X, moyenne, ecartType, coefVar, ...
            'VariableNames', {'X','Average','Std','CoefVar'});

        sheetOut = sheet;
        if contains(file,"HistogramExtrusions","IgnoreCase",true)
            sheetOut = [sheet '_Extrusions'];
        elseif contains(file,"HistogramDivisions","IgnoreCase",true)
            sheetOut = [sheet '_Divisions'];
        end

        writetable(Resultats, outputExcel, 'Sheet', sheetOut, 'WriteMode','overwritesheet');

        % Figure par feuille + intégration
        figure('Name',sheetOut, 'Visible','off')
        hold on
        n = size(Y,2);
        colors = turbo(n);

        for k = 1:size(Y,2)
            plot(X, Y(:,k), 'Color', colors(k,:), 'LineWidth', 1.5);
            ok = isfinite(Y(:,k));
            if sum(ok) > 1
                integration(s,k) = trapz(X(ok),Y(ok,k));
            end
        end

        integration_name(end+1) = string(sheetOut); %#ok<AGROW>

        plot(X,moyenne,'k','LineWidth',3)
        xlabel(T.Properties.VariableNames{1})
        ylabel('Value')
        title(sheetOut,'Interpreter','none')
        grid on
        legend([T.Properties.VariableNames(2:end),{'Mean'}], 'Location','bestoutside','Interpreter','none')

        safeName = regexprep(sheetOut,'[\\/:*?"<>|]','_');
        saveas(gcf, fullfile(figuresDir,[safeName '.png']))
        close(gcf)

        if isempty(nRowsRef)
            nRowsRef = numel(coefVar);
        elseif numel(coefVar) ~= nRowsRef
            error(['La feuille "' sheet '" a ' num2str(numel(coefVar)) ...
                ' lignes, incohérent avec les précédentes (' num2str(nRowsRef) ').']);
        end

        matrice_coef_var = [matrice_coef_var coefVar]; %#ok<AGROW>
        matrice_data     = [matrice_data Vector_data];  %#ok<AGROW>
        matrice_moyenne  = [matrice_moyenne moyenne];   %#ok<AGROW>
        matrice_std      = [matrice_std ecartType];     %#ok<AGROW>
        matrice_variance = [matrice_variance variance]; %#ok<AGROW>
    end
end