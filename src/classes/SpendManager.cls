/**
 * Created by Pavel Lapitski on 2019-10-10.
 */

public with sharing class SpendManager {

    public static final String ERROR_NAME_NOT_FOUND = 'The following projects were not found: ';
    public static final String ERROR_DIFFERENT_CURRENCY = 'The following project have different currency: ';
    public static final String ERROR_DIFFERENT_ACCOUNT = 'The following projects have different account: ';
    public static final String ERROR_NO_SPENDS_RECEIVED = 'No data received for: ';
    public static final String SUCCESS_SPENDS_RECEIVED = 'Spends imported successfully for: ';

    // for a single contract call
    public static Map<String, Utility.SpendAssignResult> assignAllSpends(Project__c contract) {
        Map<String, Utility.SpendAssignResult> result = new Map<String, Utility.SpendAssignResult>();
        if (contract != null && (!contract.Payments__r.isEmpty() || contract.Payments__r != null)) {
            Map<String,Id> projectNamesToContractIds = new Map<String,Id>();
            for (Payment__c project :contract.Payments__r) {
                projectNamesToContractIds.put(project.StrikeId__c, contract.Id);
            }
            System.debug('### SINGLE projectNamesToContractIds: ' + projectNamesToContractIds);
            Map<String, StrikeDataAPI.SpendCalloutResult> spendsResponseByProjectNames = StrikeDataAPI.getSpendsByProjectNames(projectNamesToContractIds);
            System.debug('### SINGLE spendsResponseByProjectNames: ' + spendsResponseByProjectNames);
            Map<String, Set<String>> existingUniqueIdsByProjectNames = MMSpendingsRepository.getUniqueIdsByProjectNames(spendsResponseByProjectNames.keySet(), null);
            System.debug('### SINGLE existingUniqueIdsByProjectNames: ' + existingUniqueIdsByProjectNames);

            List<MM_Spendings__c> allSpendsToInsert = new List<MM_Spendings__c>();
            for (String projectName :spendsResponseByProjectNames.keySet()) {
                StrikeDataAPI.SpendCalloutResult spendResponse = spendsResponseByProjectNames.get(projectName);
                Utility.SpendAssignResult assignResult = new Utility.SpendAssignResult();

                List<MM_Spendings__c> spendsToInsert = new List<MM_Spendings__c>();
                if (spendResponse.isValid) {
                    if (!spendResponse.spends.isEmpty()) {
                        StrikeDataAPI.PackageType packageType = StrikeDataAPI.getPackageTypeByProjectName(projectName);
                        System.debug('### SINGLE packageType: ' + packageType);
                        System.debug('### SINGLE spendResponse.spends: ' + spendResponse.spends);
                        SpendMappingResult mappingResult = mapSpends(spendResponse.spends, spendsToInsert, existingUniqueIdsByProjectNames.get(projectName), contract, packageType);
                        System.debug('### SINGLE mappingResult: ' + mappingResult);
                        if (mappingResult.getHasErrors()) {
                            assignResult.setFailure(mappingResult.getErrors());
                        } else {
                            allSpendsToInsert.addAll(spendsToInsert);
                            assignResult = null;
                        }
                    } else {
                        assignResult.setFailure(ERROR_NO_SPENDS_RECEIVED);
                    }
                } else {
                    assignResult.setFailure(spendResponse.message);
                }
                result.put(projectName, assignResult);
            }

            List<Database.SaveResult> insertResults = Database.insert(allSpendsToInsert, false);
            Map<String, List<String>> projectNameToErrorsOnInsert = new Map<String, List<String>>();
            for (Integer i = 0; i < insertResults.size(); i++) {
                // assuming that order is the same in both Lists
                Database.SaveResult insertResult = insertResults[i];
                String projectName = allSpendsToInsert[i].StrikeId__c;
                if (!insertResult.isSuccess()) {
                    projectNameToErrorsOnInsert.put(projectName, new List<String>());
                    for (Database.Error err :insertResult.getErrors()) {
                        String errorMessage = err.getMessage();
                        Integer occurrence;
                        if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                            occurrence = errorMessage.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,') + 34;
                            errorMessage = errorMessage.mid(occurrence, errorMessage.length());
                            occurrence = errorMessage.lastIndexOf(':');
                            errorMessage = errorMessage.mid(0, occurrence);
                        }
                        if (errorMessage.contains('FIELD_FILTER_VALIDATION_EXCEPTION')){
                            occurrence = errorMessage.indexOf('FIELD_FILTER_VALIDATION_EXCEPTION,') + 34;
                            errorMessage = errorMessage.mid(occurrence, errorMessage.length());
                            occurrence = errorMessage.lastIndexOf(':');
                            errorMessage = errorMessage.mid(0, occurrence);
                            errorMessage = errorMessage.split('\n')[0];
                        }
                        projectNameToErrorsOnInsert.get(projectName).add(errorMessage);
                    }
                }
            }
            for (String projectName :result.keySet()) {
                if (result.get(projectName) == null) {
                    Utility.SpendAssignResult assignResult = new Utility.SpendAssignResult();
                    if (projectNameToErrorsOnInsert.containsKey(projectName)) {
                        String errorString = String.join(projectNameToErrorsOnInsert.get(projectName), ';\n');
                        assignResult.setFailure(errorString);
                    } else {
                        assignResult.setSuccess();
                    }
                    result.put(projectName, assignResult);
                } else {
                    // leave the first error as main error
                }
                System.debug('### SINGLE RESULT: ' + projectName + ' >>> ' + result.get(projectName));
            }
        }
        return result;
    }

    // for a schedule job call
    public static Map<String, Utility.SpendAssignResult> assignSpends(String packageTypeName) {
        StrikeDataAPI.PackageType packageType = StrikeDataAPI.getPackageTypeByPackageName(packageTypeName);
        Map<String, Utility.SpendAssignResult> result = new Map<String, Utility.SpendAssignResult>();
        Integer lastNDays = 7;
        StrikeDataAPI.SpendCalloutResult spendResponse = StrikeDataAPI.getSpendsLastNDays(lastNDays, packageType);
        Utility.SpendAssignResult assignResult = new Utility.SpendAssignResult();

        List<MM_Spendings__c> allSpendsToInsert = new List<MM_Spendings__c>();
        if (spendResponse.isValid) {
            if (!spendResponse.spends.isEmpty()) {
                Set<String> projectNamesFromResponse = findProjectNames(spendResponse);
                Map<String, Set<String>> existingUniqueIdsByProjectNames = MMSpendingsRepository.getUniqueIdsByProjectNames(projectNamesFromResponse, packageType);

                List<MM_Spendings__c> spendsToInsert = new List<MM_Spendings__c>();
                SpendMappingResult mappingResult = mapSpends(spendResponse.spends, spendsToInsert, existingUniqueIdsByProjectNames, packageType);
                System.debug('### JOB mappingResult: ' + mappingResult);

                if (mappingResult.getHasErrors()) {
                    SpendRetrieveNotification.addErrors(mappingResult.errorsMap);
                    assignResult.setFailure(mappingResult.getErrors());
                } else {
                    allSpendsToInsert.addAll(spendsToInsert);
                    assignResult = null;
                }
            } else {
                assignResult.setFailure(ERROR_NO_SPENDS_RECEIVED);
            }
        } else {
            assignResult.setFailure(spendResponse.message);
        }

        insertSpends(allSpendsToInsert, assignResult);
        result.put('', assignResult);
        return result;
    }


    private static void insertSpends(List<MM_Spendings__c> spendsToInsert, Utility.SpendAssignResult assignResult) {
        List<Database.SaveResult> insertResults = Database.insert(spendsToInsert, false);
        // could be null if there were no errors before
        if (assignResult == null) {
            assignResult = new Utility.SpendAssignResult();

            Set<String> errors = new Set<String>();
            for (Integer i = 0; i < insertResults.size(); i++) {
                Database.SaveResult insertResult = insertResults[i];
                if (!insertResult.isSuccess()) {
                    for (Database.Error err :insertResult.getErrors()) {
                        errors.add(err.getMessage());
                    }
                }
            }

            if (errors.isEmpty()) {
                assignResult.setSuccess();
            } else {
                assignResult.setFailure(String.join(new List<String>(errors), ';\n'));
            }
        }
    }

    // Mapping for a single contract call
    public static SpendMappingResult mapSpends(List<StrikeDataAPI.SpendInfo> spendInfos, List<MM_Spendings__c> spendToInsert, Set<String> uniqueIds, Project__c contract, StrikeDataAPI.PackageType packageType) {
        List<String> existingProjectNames = getExistingProjectNames(contract.Payments__r);

        Map<String, StrikeDataAPI.SpendInfo> accountsNotMatched = new Map<String, StrikeDataAPI.SpendInfo>();
        Map<String, StrikeDataAPI.SpendInfo> incorrectCurrency = new Map<String, StrikeDataAPI.SpendInfo>();

        for (StrikeDataAPI.SpendInfo spendInfo :spendInfos) {
            if (existingProjectNames.contains(spendInfo.projectId)) {
                String accountId, currencyCode = contract.CurrencyIsoCode, contractId = contract.Id;
                if (packageType == StrikeDataAPI.PackageType.ADWORDS) {
                    accountId = Utility.findAdWordsAccountName(contract);
                } else if (packageType == StrikeDataAPI.PackageType.FACEBOOK) {
                    accountId = Utility.findFBAccountName(contract);
                } else if (packageType == StrikeDataAPI.PackageType.DV360) {
                    accountId = Utility.findDBMAccountName(contract);
                }

                if (String.isBlank(accountId) || !accountId.equals(spendInfo.accountId)) { // check if AccountId is NOT DIFFERENT
                    accountsNotMatched.put(spendInfo.projectId, spendInfo);
                } else if (!currencyCode.equalsIgnoreCase(spendInfo.spendCurrency)) { // check if Currency ISO Code is NOT DIFFERENT
                    incorrectCurrency.put(spendInfo.projectId, spendInfo);
                } else { // fine!
                    Integer amountDelivered = 0;
                    if (String.isNotBlank(spendInfo.delivered)) {
                        Integer delivered = Integer.valueOf(spendInfo.delivered);
                        if (delivered > 0) {
                            amountDelivered = delivered;
                        }
                    }
                    String uniqueID = String.format(MMSpendingsRepository.UNIQUE_ID_PATTERN, new List<String>{
                            spendInfo.projectId,
                            String.valueOf(contractId).left(15),
                            String.valueOf(Date.valueOf(Datetime.newInstance(Long.valueOf(spendInfo.spendDate)))),
                            String.valueOf(amountDelivered),
                            String.valueOf(spendInfo.spendAmount)
                    });

                    Boolean doRecordExist = (uniqueIds == null) ? false : uniqueIds.remove(uniqueID);
                    System.debug('### exist?: ' + doRecordExist + ' ** uniqueID: ' + uniqueID);
                    if (!doRecordExist) {
                        spendToInsert.add(new MM_Spendings__c(
                                StrikeId__c = spendInfo.projectId,
                                Media_Spend__c = Decimal.valueOf(spendInfo.spendAmount),
                                Delivered__c = amountDelivered,
                                Date__c = Date.valueOf(Datetime.newInstance(Long.valueOf(spendInfo.spendDate))),
                                Contract__c = contractId,
                                Type__c = packageType.name(),
                                CurrencyIsoCode = spendInfo.spendCurrency,
                                Is_Sync__c = true
                        ));
                    }
                }
            }
        }

        SpendMappingResult mappingResult = new SpendMappingResult();
        if (!incorrectCurrency.isEmpty()) {
            for (StrikeDataAPI.SpendInfo incorrectCurrencyProject :incorrectCurrency.values()) {
                mappingResult.errorsMap.put(incorrectCurrencyProject.projectId, ERROR_DIFFERENT_CURRENCY);
            }
        }
        if (!accountsNotMatched.isEmpty()) {
            for (StrikeDataAPI.SpendInfo notMatchedAccountProject :accountsNotMatched.values()) {
                mappingResult.errorsMap.put(notMatchedAccountProject.projectId, ERROR_DIFFERENT_ACCOUNT);
            }
        }
        return mappingResult;
    }

    // Mapping for a scheduled job call
    private static SpendMappingResult mapSpends(List<StrikeDataAPI.SpendInfo> spendInfos, List<MM_Spendings__c> spendToInsert, Map<String, Set<String>> existingUniqueIdsByProjectNames, StrikeDataAPI.PackageType packageType) {
        List<Payment__c> projects = [
            SELECT Project__r.CurrencyIsoCode, Project__c, StrikeId__c, OpportunityPlatform__r.Platform__r.Name,  OpportunityPlatform__r.PlatformAccount__c,
                    OpportunityPlatform__r.Platform__c
            FROM Payment__c
            WHERE StrikeId__c IN :existingUniqueIdsByProjectNames.keySet()
        ];
        Map<String, ProjectInfo> projectNameToProject = new Map<String, ProjectInfo>();
        for (Payment__c project :projects) {
            System.debug('### JOB projects: ' + project.StrikeId__c + ' => ' + project.OpportunityPlatform__r.PlatformAccount__c);
            projectNameToProject.put(project.StrikeId__c, new ProjectInfo(project));
        }

        Map<String, StrikeDataAPI.SpendInfo> notFound = new Map<String, StrikeDataAPI.SpendInfo>();
        Map<String, StrikeDataAPI.SpendInfo> accountsNotMatched = new Map<String, StrikeDataAPI.SpendInfo>();
        Map<String, StrikeDataAPI.SpendInfo> incorrectCurrency = new Map<String, StrikeDataAPI.SpendInfo>();

        for (StrikeDataAPI.SpendInfo spendInfo :spendInfos) {
            String projectName = spendInfo.projectId;
            Set<String> existingUniqueIds  = existingUniqueIdsByProjectNames.containsKey(projectName) ? existingUniqueIdsByProjectNames.get(projectName) : null;
            System.debug('### JOB projectName: ' + projectName + '  existingUniqueIds == NULL?: ' + (existingUniqueIds == null));
            if (existingUniqueIds == null) {
                // no project name found in among ones
                notFound.put(projectName, spendInfo);
            } else {
                // spend might exists, let's check
                if (projectNameToProject.containsKey(projectName)) {
                    Integer amountDelivered = 0;
                    if (String.isNotBlank(spendInfo.delivered)) {
                        Integer delivered = Integer.valueOf(spendInfo.delivered);
                        if (delivered > 0) {
                            amountDelivered = delivered;
                        }
                    }
                    String  currencyCode = projectNameToProject.get(projectName).currencyIsoCode,
                            contractId = projectNameToProject.get(projectName).contractId,
                            accountId = projectNameToProject.get(projectName).accountId;

                    //System.debug('### JOB contractId: ' + contractId + '    accountId: ' + accountId + '  currencyCode: ' + currencyCode + '   ');
                    //System.debug('### JOB spendInfo: ' + spendInfo);

                    if (String.isBlank(accountId) || !accountId.equals(spendInfo.accountId)) { // check if AccountId is NOT DIFFERENT
                        accountsNotMatched.put(spendInfo.projectId, spendInfo);
                    } else if (!currencyCode.equalsIgnoreCase(spendInfo.spendCurrency)) { // check if Currency ISO Code is NOT DIFFERENT
                        incorrectCurrency.put(spendInfo.projectId, spendInfo);
                    } else {
                        String uniqueID = String.format(MMSpendingsRepository.UNIQUE_ID_PATTERN, new List<String>{
                            projectName,
                            contractId,
                            String.valueOf(Date.valueOf(Datetime.newInstance(Long.valueOf(spendInfo.spendDate)))),
                            String.valueOf(amountDelivered),
                            String.valueOf(spendInfo.spendAmount)
                        });

                        Boolean doRecordExist = existingUniqueIds.remove(uniqueID);
                        //System.debug('### existingUniqueIds: ' + existingUniqueIds);
                        //System.debug('### doRecordExist: ' + doRecordExist + '   uiD: ' + uniqueID);
                        if (!doRecordExist) {
                            spendToInsert.add(new MM_Spendings__c(
                                StrikeId__c = projectName,
                                Media_Spend__c = Decimal.valueOf(spendInfo.spendAmount),
                                Delivered__c = amountDelivered,
                                Date__c = Date.valueOf(Datetime.newInstance(Long.valueOf(spendInfo.spendDate))),
                                Contract__c = contractId,
                                Type__c = packageType.name(),
                                CurrencyIsoCode = spendInfo.spendCurrency,
                                Is_Sync__c = true
                            ));
                        }
                    }
                } else {
                    notFound.put(projectName, spendInfo);
                }
            }
        }

        SpendMappingResult mappingResult = new SpendMappingResult();
        if (!notFound.isEmpty()) {
            for (StrikeDataAPI.SpendInfo notFoundProject :notFound.values()) {
                mappingResult.errorsMap.put(notFoundProject.projectId, ERROR_NAME_NOT_FOUND);
            }
        }
        if (!incorrectCurrency.isEmpty()) {
            for (StrikeDataAPI.SpendInfo incorrectCurrencyProject :incorrectCurrency.values()) {
                mappingResult.errorsMap.put(incorrectCurrencyProject.projectId, ERROR_DIFFERENT_CURRENCY);
            }
        }
        if (!accountsNotMatched.isEmpty()) {
            for (StrikeDataAPI.SpendInfo notMatchedAccountProject :accountsNotMatched.values()) {
                mappingResult.errorsMap.put(notMatchedAccountProject.projectId, ERROR_DIFFERENT_ACCOUNT);
            }
        }
        return mappingResult;
    }

    private static Set<String> findProjectNames(StrikeDataAPI.SpendCalloutResult spendResponse) {
        Set<String> projectNames = new Set<String>();
        for (StrikeDataAPI.SpendInfo spendInfo :spendResponse.spends) {
            projectNames.add(spendInfo.projectId);
        }
        return projectNames;
    }

    private static List<String> getExistingProjectNames(List<Payment__c> projects) {
        List<String> projectNames = new List<String>();
        for (Payment__c project :projects) {
            projectNames.add(project.StrikeId__c);
        }
        return projectNames;
    }

    public class SpendManagerException extends Exception {}

    private class ProjectInfo {
        public String contractId { get; set; }
        public String currencyIsoCode { get; set; }
        public String accountId { get; set; }

        public ProjectInfo(Payment__c project) {
            this.contractId = String.valueOf(project.Project__c).left(15);
            this.currencyIsoCode = project.Project__r.CurrencyIsoCode;
            this.accountId = project.OpportunityPlatform__r.PlatformAccount__c;
        }
    }

    public class SpendMappingResult {
        public Map<String, String> errorsMap { get; set; }

        public Boolean getHasErrors() {
            return !errorsMap.isEmpty();
        }

        public String getErrors() {
            String errors = '';
            for (String errorMsg :errorsMap.values()) {
                errors += '\n' + errorMsg;
            }
            return errors;
        }

        public SpendMappingResult() {
            errorsMap = new Map<String, String>();
        }
    }
}