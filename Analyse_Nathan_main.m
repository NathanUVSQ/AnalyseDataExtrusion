function Analyse_Nathan_main(MF_decision, moyenne_decision,regression_decision,variance_decision,cumulative_decision)
    close all
    
    %% CONFIG
    % MF_decision = true; %% COMPARAISON M et F (stat + fig)
    % moyenne_decision = true; %% OBLIGATION
    % regression_decision = true; %% REGRESSION
    % variance_decision = true; %% VARIANCE
    % cumulative_decision = true; %% CUMULATIF
    f = waitbar(0,'Please wait...',HandleVisibility = 'callback'); %Progression
    
    
    tStart = -5;
    tEnd   = 10;
    movieID = 3;
    
    regions = {'Up','Down','Posterior','Midline','All'};
    pairesAComparer = {{'Up','Down'}, {'Posterior','Midline'}};
    regionColors = containers.Map( ...
        {'Up','Down','Posterior','Midline'}, ...
        { [0 0.6 0], [0.9290 0.6940 0.1250], [0.8500 0.0980 0.0980], [0 0.4470 0.7410] }); %Couleurs des régions
    
    
    %------------------------------------------------------------------------%
    %------------------------------------------------------------------------%
    
    %% CHOIX DES FICHIERS
    [file_all, path] = uigetfile('*.xlsx','Choisir un fichier Features_ALL');
    if isequal(file_all,0)
        error('Aucun fichier sélectionné.'); 
    end
    file_all = string(file_all);
    file_M = replace(file_all, "all", "M");
    file_F = replace(file_all, "all", "F");
    file_list = {file_all, file_M, file_F};
    path_list = {};
    
    integration_all_iter = cell(length(file_list),1);
    integration_name_all_iter = cell(length(file_list),1);
    regionData_all_iter = cell(length(file_list),1);
    Xtime_all_iter = cell(length(file_list),1);
    
    %------------------------------------------------------------------------%
    %------------------------------------------------------------------------%
    
    %% BOUCLE PRINCIPALE
    for i = 1:length(file_list) %Pour toute les feuilles
        file = file_list{i};
    
        excelFile = fullfile(path, file);
        fileExtrusions = 'HistogramExtrusions'+ extractAfter(file, 'Histogram_Features');
        fileDivisions  = 'HistogramDivisions'+ extractAfter(file, 'Histogram_Features');
        excelExtrusions = fullfile(path, fileExtrusions);
        excelDivisions  = fullfile(path, fileDivisions);
    
        [~,name,~] = fileparts(file);
        analysisDir = fullfile(path,'analyses',name);
        figuresDir  = fullfile(analysisDir,'figures');
    
        if ~exist(figuresDir,'dir')
            mkdir(figuresDir); 
        end
    
        outputExcel = fullfile(analysisDir,name + "_Analysis.xlsx");
        path_list{i} = analysisDir;
        
        if exist('f','var') && isvalid(f)
            waitbar(.10,f,'Creating file...');
        end
        fprintf('\n--- Itération %d : %s ---\n', i, file)
        if exist('f','var') && isvalid(f)
            waitbar(.20,f,'Data calcul...');
        end
        [allSheets, allFiles, sheetNamesExtr, sheetNamesDiv] = ...
            getSheetList(excelFile, excelExtrusions, excelDivisions); %
    
        [matrice_coef_var, matrice_std, matrice_variance, matrice_data, ...
         matrice_moyenne, Xtime, integration, integration_name, rawDataBySheet] = ...
            computeSheetStats(allSheets, allFiles, tStart, tEnd, outputExcel, figuresDir); %Calcul matrices
        

        
        %close all
        if exist('f','var') && isvalid(f)
            waitbar(.33,f,'Statistic calcul...');
        end

        [regionData, RegressionSummary] = buildRegionData(regions, allSheets, ...
            matrice_coef_var, matrice_std, matrice_variance, matrice_data, matrice_moyenne, ...
            Xtime, tStart, tEnd, figuresDir, moyenne_decision, regression_decision, ...
            variance_decision, cumulative_decision, excelExtrusions, excelDivisions, ...
            sheetNamesExtr, sheetNamesDiv);
    
        comparisonDir = fullfile(figuresDir,'Comparaisons Regions');
        if ~exist(comparisonDir,'dir') 
            mkdir(comparisonDir); 
        end
    
        plotRegionPairComparisons(regionData, pairesAComparer, Xtime, tStart, tEnd, comparisonDir, regionColors); %Statistiques entre région du Notum (up/down post/mid) 
    
        statsDir = fullfile(figuresDir,'Stats Paired');
        if ~exist(statsDir,'dir')
            mkdir(statsDir); 
        end
        if exist('f','var') && isvalid(f)
            waitbar(.67,f,'Regression calcul...');
        end
    
        PairedStatsSummary = pairedStatsTest(regionData, pairesAComparer, integration, ...
            rawDataBySheet, Xtime, tStart, tEnd, statsDir);
        writetable(PairedStatsSummary, fullfile(analysisDir,'PairedStatsSummary.xlsx'));
        writetable(RegressionSummary, fullfile(analysisDir,'LinearRegressionSummary.xlsx'));
    
        plotCVComparisons(regionData, pairesAComparer, Xtime, comparisonDir, regionColors);
    
        comparisonDirFilm = fullfile(figuresDir,'Comparaisons Regions Film');
        if ~exist(comparisonDirFilm,'dir')
            mkdir(comparisonDirFilm); 
        end
        plotSingleMovieComparison(regionData, rawDataBySheet, pairesAComparer, Xtime, ...
            tStart, tEnd, movieID, comparisonDirFilm, regionColors);
    
        %% Stockage pour comparaison M vs F
        integration_all_iter{i} = integration;
        integration_name_all_iter{i} = integration_name;
        regionData_all_iter{i} = regionData;
        Xtime_all_iter{i} = Xtime;
    
    
        if i == 1
            integration_ALL = integration;
            integration_ALL_name = integration_name;
        end
    
    end
    
    %% COMPARAISON M vs F
    if exist('f','var') && isvalid(f)
        waitbar(.80,f,'Comparaison M/F...');
    end
    if MF_decision
        mfDir = fullfile(path,'analyses','MF_Comparison');
        if ~exist(mfDir,'dir') 
            mkdir(mfDir); 
        end
    
        MF_StatsSummary = mfIndependentStats( ...
            regionData_all_iter{2}, regionData_all_iter{3}, ...
            integration_all_iter{2}, integration_all_iter{3}, ...
            Xtime_all_iter{2}, regions, mfDir);
    
        writetable(MF_StatsSummary, fullfile(mfDir,'MF_StatsSummary.xlsx'));
        fprintf('\nComparaison M vs F terminée.\n')
    end
    
    fprintf('\nCréation des figures terminée.\n')
    
    %% WIDGET INTERACTIF (utilise les données de la DERNIÈRE itération, ici F)
    openIntegrationComparisonUI(integration_ALL, integration_ALL_name); %PB prend
    %seulement les valeurs de F !!!
    waitbar(1,f,'Finish !');
    pause(1)
    close(f)
    fprintf('\nTerminé.\n')
end