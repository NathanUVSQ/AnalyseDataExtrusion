function [allSheets, allFiles, sheetNamesExtr, sheetNamesDiv] = getSheetList(excelFile, excelExtrusions, excelDivisions)
    sheetNames     = sheetnames(excelFile);
    sheetNamesExtr = sheetnames(excelExtrusions);
    sheetNamesDiv  = sheetnames(excelDivisions);

    allSheets = [sheetNames ; sheetNamesExtr ; sheetNamesDiv];
    allFiles  = [ ...
        repmat({excelFile},length(sheetNames),1) ; ...
        repmat({excelExtrusions},length(sheetNamesExtr),1) ; ...
        repmat({excelDivisions},length(sheetNamesDiv),1)];
end