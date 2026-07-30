close all
clear

%% CONFIG
MF_decision = false;
moyenne_decision = true;
regression_decision = false;
variance_decision = false;
cumulative_decision = false;

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

    fprintf('\n--- Itération %d : %s ---\n', i, file)

    [allSheets, allFiles, sheetNamesExtr, sheetNamesDiv] = ...
        getSheetList(excelFile, excelExtrusions, excelDivisions); %

    [matrice_coef_var, matrice_std, matrice_variance, matrice_data, ...
     matrice_moyenne, Xtime, integration, integration_name, rawDataBySheet] = ...
        computeSheetStats(allSheets, allFiles, tStart, tEnd, outputExcel, figuresDir); %Calcul matrices

    close all

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
end

%% COMPARAISON M vs F
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
openIntegrationComparisonUI(integration, integration_name);

fprintf('\nTerminé.\n')