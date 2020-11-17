public with sharing class ContractCtrl {

    public Brand__c brand {get; set;}
    public Project__c contract { get;set; }
    public Integer videoUrlRow {get; set;}
    public List<VideoUrl__c> videoURLs {get; set;}
    public Boolean createBrand {get; set;}
    public Boolean savedSuccessfully { get;set; }
    public Boolean saveAndNew { get;set; }
    public Boolean showPaymentClientSpendDifferenceMsg { get;set; }
    public Boolean showProjectClientSpendDifferenceMsg { get;set; }
    public Boolean isAllHistoryDisplayed { get;set; }
    public String platformString {get; set;}
    public List<ContractHistoryWrapper> historyOfRecord {get; set;}

    @TestVisible  private Map<Id, PlatformWrapper> platformsMap;
    private Decimal initialClientSpend;
    private ApexPages.StandardController stdController;

    public ContractCtrl(ApexPages.StandardController stdController) {
        this.stdController = stdController;
        this.contract = (Project__c) stdController.getRecord();
        brand = new Brand__c();
        createBrand = false;
        platformsMap = new Map<Id, PlatformWrapper>();
        platformString = '';
        videoURLs = new List<VideoUrl__c>();

        checkClientSpendDifference();
        refreshContract();
        readPlatformsInfo();
    }

    private void checkClientSpendDifference() {
        if (this.contract == null || (this.contract != null && String.isBlank(this.contract.Id))) return;

        Project__c contractWithPayments = ContractRepository.getContractWithPayments(this.contract.Id);
        Decimal paymentsClientSpend = 0;
        Set<Id> paymentIds = new Set<Id>();
        for (Sub_Project__c payment :contractWithPayments.Sub_Projects__r) {
            paymentsClientSpend += payment.Client_Spend__c;
            paymentIds.add(payment.Id);
        }
        showPaymentClientSpendDifferenceMsg = (paymentsClientSpend != contractWithPayments.Client_Spend__c);

        showProjectClientSpendDifferenceMsg = false;
        for (Sub_Project__c payment :SubProjectRepository.getPaymentsByIDsWithProjects(paymentIds)) {
            Decimal projectsClientSpend = 0;
            for (Payment__c project : payment.Projects__r) {
                projectsClientSpend += project.Client_Spend__c;
            }
            showProjectClientSpendDifferenceMsg |= (projectsClientSpend != payment.Client_Spend__c);
        }
    }

    public void addNewVideoUrl() {
        videoURLs.add(new VideoUrl__c());
    }

    public void deleteVideoUrl() {
        Boolean isSuccess = true;
        VideoUrl__c urlToDelete = videoURLs[videoUrlRow];
        if (String.isNotBlank(urlToDelete.Id)) {
            try {
                delete urlToDelete;
            } catch (DmlException ex) {
                isSuccess = false;
                ApexPages.addMessage(new ApexPages.Message(Apexpages.Severity.ERROR, ex.getDmlMessage(0)));
            }
        }
        if (isSuccess) {
            videoURLs.remove(videoUrlRow);
        }
    }

    public List<PlatformWrapper> getPlatforms() {
        return platformsMap.values();
    }

    public void initPlatformsInfo() {
        platformString = Platform.initPlatformsInfo(platformsMap, contract.ContractPlatforms__r, contract.ContractAdPlacements__r, platformString);
    }

    public PageReference getAllSpends() {
        PageReference contractPage = new PageReference('/' + contract.Id);
        Project__c contractRecord = ContractRepository.getContractsByIdsForSpends(new Set<Id>{contract.Id})[0];
        try {
            Map<String, Utility.SpendAssignResult> assignResults = SpendManager.assignAllSpends(contractRecord);
            System.debug('### TEST assignResults: ' + assignResults);
            Map<String, List<String>> errorsMap = new Map<String, List<String>>();
            List<String> successProjectNames = new List<String>();
            for (String projectName :assignResults.keySet()) {
                Utility.SpendAssignResult assignResult = assignResults.get(projectName);
                if (!assignResult.isValid) {
                    // project with error
                    if (!errorsMap.containsKey(assignResult.message)) {
                        errorsMap.put(assignResult.message, new List<String>());
                    }
                    errorsMap.get(assignResult.message).add(projectName);
                } else {
                    // project without error
                    successProjectNames.add(projectName);
                }
            }
            if (!successProjectNames.isEmpty()) {
                String successMessage = SpendManager.SUCCESS_SPENDS_RECEIVED + String.join(successProjectNames, ', ') + '. Please <b>Refresh</b> the page.';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, successMessage));
            }
            System.debug('### errorsMap: ' + errorsMap);
            if (!errorsMap.isEmpty()) {
                List<String> errorsList = new List<String>();
                for (String errorMainMessage :errorsMap.keySet()) {
                    String errorOnProjectsMessage = String.join(errorsMap.get(errorMainMessage) , ',');
                    if (errorMainMessage.endsWith(': ')) {
                        errorsList.add(errorMainMessage + errorOnProjectsMessage);
                    } else if (errorMainMessage.endsWith('.') || errorMainMessage.endsWith('. ')) {
                        errorsList.add(errorMainMessage + ' The following projects are affected: ' + errorOnProjectsMessage);
                    } else {
                        errorsList.add(errorMainMessage + '. The following projects are affected: ' + errorOnProjectsMessage);
                    }
                }
                System.debug('### errorsList: ' + errorsList);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, String.join(errorsList, '\n')));
                return null;
            }
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }
        return contractPage;
    }

    public void brandUpdated() {
        createBrand = String.isBlank(contract.Brand__c) ? true : false;
    }

    public void cancelCreateBrand() {
        createBrand = false;
    }

    public void createBrand() {
        createBrand = true;
        brand = new Brand__c();
        contract.Brand__c = null;
    }

    public void onEditReady() {
        if (String.isNotBlank(contract.Id)) {
            reselectContract();
            getRecordHistory(this.contract.Histories);

            if (contract.Histories.size() <= 5) {
                isAllHistoryDisplayed = true;
            } else {
                isAllHistoryDisplayed = false;
            }
            initialClientSpend = this.contract.Client_Spend__c;
        }
        saveAndNew = false;
    }

    public PageReference syncWithDataWarehouse() {
        PageReference refreshPage = null;
        try {
            StrikeDataAPI.notifyAboutChanges(this.contract.Id);
            refreshPage = new PageReference('/' + this.contract.Id);
        } catch (System.CalloutException ex) {
            if (ex.getMessage().containsIgnoreCase('Read timed out')) {
                refreshPage = new PageReference('/' + this.contract.Id);
            } else {
                System.debug('### syncWithDataWarehouse ex1: ' + ex.getStackTraceString());
                ApexPages.Message msg = new apexPages.Message(ApexPages.Severity.ERROR, ex.getMessage());
                ApexPages.addMessage(msg);
            }
        } catch (Exception ex) {
            System.debug('### syncWithDataWarehouse ex2: ' + ex.getStackTraceString());
            ApexPages.Message msg = new apexPages.Message(ApexPages.Severity.ERROR, ex.getMessage());
            ApexPages.addMessage(msg);
        }
        return refreshPage;
    }

    public PageReference save() {
        Savepoint sp = Database.setSavepoint();
        savedSuccessfully = false;
        try {
            if (createBrand) {
                insert brand;
                this.contract.Brand__c = brand.Id;
            }
            contract.LastModifiedBy__c = UserInfo.getUserId();
            contract.PerformMMSync__c = true;
            upsert contract;

            if (!videoURLs.isEmpty()) {
                for (VideoUrl__c videoUrl : videoURLs) {
                    videoUrl.Contract__c = (Id)this.contract.Id;
                }
                upsert videoURLs;
            }
            savedSuccessfully = true;
        } catch (DmlException e) {
            brand = (brand != null) ? brand.clone(false) : new Brand__c();
            if (String.isBlank(contract.Id)) {
                contract = contract.clone(false);
            }
            Database.rollback(sp);
            ApexPages.Message msg = new apexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0));
            ApexPages.addMessage(msg);
            return null;
        }
        if (saveAndNew) {
            ApexPages.currentPage().setRedirect(true);
            return new PageReference('/' + stdController.getRecord().getSObjectType().getDescribe().getKeyPrefix() + '/e');
        }
        return new PageReference('/' + this.contract.Id);
    }

    public Project__c reselectContract() {
        contract = ContractRepository.getContractById(this.contract.Id);

        reps = [
            SELECT Id, Commission_Profile__c, Commission_Profile__r.GP_Bonus__c, Commission_Type__c, Notes__c, Percentage_of_GP_Allocation__c, Commission__c, Expected_commission__c
            FROM Contract_Sales_Rep__c
            WHERE Contract__c = :contract.Id
        ];

        List<String> platformNames = new List<String>();
        for (OpportunityPlatform__c oppPlatform :contract.ContractPlatforms__r) {
            platformNames.add(oppPlatform.Platform__r.Name);
        }
        platformString = String.join(platformNames, ', ');

        return contract;
    }

    public void refreshContract() {
        if (String.isNotBlank(contract.Id)) {
            reselectContract();
        }
    }

    public void savePlatforms() {
        Boolean success = true;
        Savepoint sp = Database.setSavepoint();
        try {
            contract.PerformMMSync__c = true;
            contract.LastModifiedBy__c = UserInfo.getUserId();
            update contract;

            Platform.savePlatformInfo(contract.Opportunity__c, contract.Id, platformsMap);
            success = validatePlatformAccountsForRelatedOppPlatforms();
            if (!success) Database.rollback(sp);
        } catch(Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            Database.rollback(sp);
            success = false;
        }

        if (success) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Platforms updated successfully.'));
            readPlatformsInfo();

            checkClientSpendDifference();
        }
    }

    @TestVisible
    private void getRecordHistory(List<Project__History> history) {
        Integer counter = 0;
        historyOfRecord = new List<ContractHistoryWrapper>();
        ContractHistoryWrapper tmp;

        for (Project__History ph : history) {
            if (ph.OldValue instanceof Id && ph.NewValue instanceof Id) {
                continue;
            }
            tmp = new ContractHistoryWrapper(ph);
            if (!tmp.ignoreRecord) {
                if (counter >= 1 && historyOfRecord[counter-1].history.CreatedDate == ph.CreatedDate
                    && historyOfRecord[counter-1].history.Field == ph.Field) {
                    continue;
                }
                historyOfRecord.add(tmp);
                counter++;
            }
            if (counter >= 5) {
                break;
            }
        }
    }

   public class ContractHistoryWrapper {
        public Project__History history { get;set; }
        public Boolean recordCreated { get;set; }
        public Boolean ignoreRecord { get;set; }
        public Decimal oldValue { get;set; }
        public Decimal newValue { get;set; }
        public Date oldDate { get;set; }
        public Date newDate { get;set; }
        public String action { get;set; }

        public ContractHistoryWrapper(Project__History history) {
            this.history = history;
            ignoreRecord = false;

            Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Project__c.fields.getMap();
            String fieldName, fieldLabel, oldParam, newParam;
            Schema.DisplayType fieldType;
            if (history.Field == 'Owner') {
                fieldName = 'OwnerId';
            } else {
                fieldName = history.Field;
            }

            if (fieldName.equalsIgnoreCase('created')) {
                recordCreated = true;
                action = 'Created';
            } else if (fieldMap.containsKey(fieldName) && fieldMap.get(fieldName).getDescribe().getType() == Schema.DisplayType.TEXTAREA) {
                recordCreated = false;
                action = 'Changed <strong>' + fieldMap.get(fieldName).getDescribe().getLabel() + '</strong>.';
            } else if (fieldMap.containsKey(fieldName)) {
                recordCreated = false;

                fieldType = fieldMap.get(fieldName).getDescribe().getType();
                if (fieldName == 'OwnerId') {
                    fieldLabel = 'Owner';
                } else {
                    fieldLabel = fieldMap.get(fieldName).getDescribe().getLabel();
                }

                if (fieldType == Schema.DisplayType.CURRENCY) {
                    Decimal tmp;
                    tmp      = history.OldValue != null ? Decimal.valueOf(Double.valueOf(history.OldValue)) : null;
                    oldValue = tmp == null ? null : tmp.setScale(2);
                    tmp      = history.NewValue != null ? Decimal.valueOf(Double.valueOf(history.NewValue)) : null;
                    newValue = tmp == null ? null : tmp.setScale(2);

                    oldParam = history.Parent.CurrencyIsoCode + ' {2, number, #,##0.00}';
                    newParam = history.Parent.CurrencyIsoCode + ' {3, number, #,##0.00}';
                } else if (fieldType == Schema.DisplayType.DOUBLE) {
                    oldParam = '{0,number,#,##0.00}';
                    newParam = '{1,number,#,##0.00}';
                } else if (fieldType == Schema.DisplayType.PERCENT) {
                    oldParam = '{0,number,#,##0.00}%';
                    newParam = '{1,number,#,##0.00}%';
                } else if (fieldType == Schema.DisplayType.STRING) {
                    oldParam = '{0}';
                    newParam = '{1}';
                } else if (fieldType == Schema.DisplayType.REFERENCE) {
                    oldParam = '{0}';
                    newParam = '{1}';
                } else if (fieldType == Schema.DisplayType.DATE) {
                    oldParam = history.OldValue != null ? Date.valueOf(history.OldValue).format() : null;
                    newParam = history.NewValue != null ? Date.valueOf(history.NewValue).format() : null;
                } else if (fieldType == Schema.DisplayType.PICKLIST) {
                    oldParam = String.valueOf(history.OldValue);
                    newParam = String.valueOf(history.NewValue);
                } else {
                    ignoreRecord = true;
                }

                if (history.OldValue != null && history.NewValue != null) {
                    action = 'Changed <strong>' + fieldLabel
                        + '</strong> from ' + oldParam + ' to <strong>' + newParam + '</strong>.';
                } else if (history.OldValue != null) {
                    action = 'Deleted ' + oldParam + ' in <strong>' + fieldLabel + '</strong>.';
                } else {
                    action = 'Changed <strong>' + fieldLabel + '</strong>'
                        + ' to <strong>' + newParam + '</strong>.';
                }
            }
        }
   }

    public Boolean validatePlatformAccountsForRelatedOppPlatforms() {
        List<OpportunityPlatform__c> oppPlatforms = [
            SELECT Id, Account_Entity__c, Opportunity__c, Provider__c, PlatformAccount__c
            FROM OpportunityPlatform__c
            WHERE Opportunity__c = :contract.Opportunity__c
        ];

        Map<String, String> providerToPlatformAcc = new Map<String, String>();
        for (OpportunityPlatform__c oppPlatform : oppPlatforms) {
            if (String.isNotBlank(oppPlatform.PlatformAccount__c)) {
                providerToPlatformAcc.put(oppPlatform.Provider__c, oppPlatform.PlatformAccount__c);
            }
        }

        Boolean isSuccess = true;
        for (OpportunityPlatform__c oppPlatform :oppPlatforms) {
            if (String.isNotBlank(oppPlatform.PlatformAccount__c) && oppPlatform.PlatformAccount__c != providerToPlatformAcc.get(oppPlatform.Provider__c)) {
                oppPlatform.PlatformAccount__c.addError(OpportunityEditExt.ERROR_DIFFERENT_PLATFORM_ACCOUNT);
                return false;
            }
        }
        return isSuccess;
    }

    public void readPlatformsInfo() {
        for (Platform__c platform : PlatformRepository.getAvailablePlatformsForContract(contract.Id)) {
            platformsMap.put(platform.Id, new PlatformWrapper(platform));
        }

        if (!String.isBlank(contract.Id)) {
            videoURLs = VideoUrlRepository.getVideosForContract(contract.Id);
            initPlatformsInfo();
        }
    }

    public List<Contract_Sales_Rep__c> reps {get; set;}

    public PageReference saveSalesReps() {
        Decimal sumOfGPs = 0;
        for(Contract_Sales_Rep__c rep: reps) {
            if (rep.Percentage_of_GP_Allocation__c!=null) sumOfGPs += rep.Percentage_of_GP_Allocation__c;
        }

        if (sumOfGPs==100) {
            try {
                update reps;
            } catch(Exception ex) {
                ApexPages.addMessage(new ApexPages.Message(Apexpages.Severity.ERROR,  ex.getMessage()));
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(Apexpages.Severity.ERROR, 'GP allocation must sum to 100%'));
        }
        return null;
    }

}