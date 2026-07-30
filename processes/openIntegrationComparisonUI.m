function openIntegrationComparisonUI(integration, integration_name)

    sheetList = cellstr(integration_name);

    fig = uifigure('Name','Comparaison t-test - Intégration','Position',[100 100 520 420]);

    uilabel(fig,'Position',[20 380 200 22],'Text','Feuille A :','FontWeight','bold');
    listA = uilistbox(fig,'Position',[20 160 230 210],'Items',sheetList);

    uilabel(fig,'Position',[270 380 200 22],'Text','Feuille B :','FontWeight','bold');
    listB = uilistbox(fig,'Position',[270 160 230 210],'Items',sheetList);

    btn = uibutton(fig,'push','Text','Comparer','Position',[20 110 150 32]);
    resultArea = uitextarea(fig,'Position',[20 20 480 80],'Editable','off');

    btn.ButtonPushedFcn = @(btn,event) compareCallback(listA,listB,resultArea,integration,integration_name);

    fprintf('\nFenêtre de comparaison ouverte.\n')
end

function compareCallback(listA,listB,resultArea,integration,integration_name)

    nameA = listA.Value;
    nameB = listB.Value;

    idxA = find(strcmp(cellstr(integration_name),nameA),1);
    idxB = find(strcmp(cellstr(integration_name),nameB),1);

    if isempty(idxA) || isempty(idxB)
        resultArea.Value = {'Erreur : feuille introuvable.'};
        return
    end
    if idxA == idxB
        resultArea.Value = {'Veuillez sélectionner deux feuilles différentes.'};
        return
    end

    dataA = integration(idxA,:);
    dataB = integration(idxB,:);
    valid = ~isnan(dataA) & ~isnan(dataB);
    dataA = dataA(valid); dataB = dataB(valid);

    if numel(dataA) < 3
        resultArea.Value = {'Pas assez de films valides en commun.'};
        return
    end

    [h,p] = ttest(dataA,dataB);

    resultArea.Value = { ...
        sprintf('Comparaison (appariée) : %s vs %s', nameA, nameB), ...
        sprintf('N = %d films', numel(dataA)), ...
        sprintf('h = %d', h), sprintf('p = %.4g', p)};

    fprintf('\nTest apparié %s vs %s : N=%d, h=%d, p=%.4g\n', nameA, nameB, numel(dataA), h, p);
end