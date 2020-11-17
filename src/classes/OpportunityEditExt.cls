public class OpportunityEditExt {
    public static final String ERROR_DIFFERENT_PLATFORM_ACCOUNT = 'Error! All Opportunity Platforms with the same provider should have the same platform account assigned.';

    public Account newAccount {get; set;}
    public Brand__c brand {get; set;}
    public Opportunity opp {get; set;}
    public Boolean createAccount {get; set;}
    public Boolean createBrand {get; set;}
    public Boolean hideBrand {get; set;}
    public List<Contact_Opportunity__c> contactRoles {get; set;}
    public List<VideoUrl__c> videoURLs {get; set;}
    public List<Spend_Threshold__c> spendThresholds {get; set;}
    public Integer contactRoleRow {get; set;}
    public Integer videoUrlRow {get; set;}
    public Integer spendThresholdRow {get; set;}
    public Boolean newOpportunity {get; set;}
    public String platformString {get; set;}

    private ApexPages.StandardController stdController;
    private String initialStage;
    private String oldBillingCondition;
    private String billingConditionName;
    @TestVisible private Map<Id, PlatformWrapper> platformsMap;

    public Boolean showCustomCampaignName {get; set;}

    public OpportunityEditExt(ApexPages.StandardController stdController) {
        showCustomCampaignName = false;
        this.opp = (Opportunity) stdController.getRecord();
        this.stdController = stdController;
        newAccount = new Account();

        if (String.isNotBlank(opp.Id)) {
            opp = OpportunityRepository.getOpportunityById(opp.Id);
        }

        if (String.isBlank(opp.OwnerId)) {
            opp.OwnerId = UserInfo.getUserId();
            opp.CloseDate = System.today().addMonths(3);
            opp.Payment_Type__c = 'Net 30';
        }

        createBrand = false;
        hideBrand = (opp.RecordTypeId == OpportunityRepository.RT_ID_BRAND_DIRECT);
        createAccount = false;

        if (String.isBlank(opp.Brand__c)) {
            brand = new Brand__c();
            if (hideBrand == true) {
                // find a brand related to Brand Direct account
                String brandAccountName = '';
                if (String.isNotBlank(opp.AccountId)) {
                    Account acc = [SELECT Custom_Xero_Naming__c, DefaultPaymentType__c, Name FROM Account WHERE Id = :opp.AccountId];
                    brandAccountName = acc.Name;
                }
                findAppropriateBrand(brandAccountName, false);
            }
        }

        initialStage = opp.StageName;
        videoURLs = new List<VideoUrl__c>();
        contactRoles = new List<Contact_Opportunity__c>(opp.Contact_Opportunities__r);
        spendThresholds = new List<Spend_Threshold__c>{new Spend_Threshold__c(Spend_From__c = 0, Fee__c = 15)};

        platformsMap = new Map<Id, PlatformWrapper>();
        platformString = '';

        for (Platform__c platform : PlatformRepository.getAvailablePlatformsForOpportunity(opp.Id)) {
            platformsMap.put(platform.Id, new PlatformWrapper(platform));
        }

        if (String.isNotBlank(opp.Id)) {
            platformString = Platform.initPlatformsInfo(platformsMap, opp.OpportunityPlatforms__r, opp.OpportunityAdPlacements__r, platformString);
            videoURLs = VideoUrlRepository.getVideosForOpportunity(opp.Id);
            spendThresholds = SpendThresholdRepository.getSpendThresholdsForOpportunity(opp.Id);
            if (spendThresholds.isEmpty()) {
                spendThresholds.add(new Spend_Threshold__c(Spend_From__c = 0, Fee__c = 15));
            }
            newOpportunity = false;
        } else {
            newOpportunity = true;
        }


        String isClonedString = ApexPages.currentPage().getParameters().get('isCloned');
        if (isClonedString != null && Boolean.valueOf(ApexPages.currentPage().getParameters().get('isCloned'))) {
            opp = opp.clone();
            opp.Name = opp.Name + ' (COPY)';
            opp.IO__c = null;
            opp.Id = null;
            opp.StageName = 'Qualification';
            newOpportunity = true;

            // no Creatives should'b be cloned
            videoURLs.clear();

            for (PlatformWrapper platform :platformsMap.values()) {
                OpportunityPlatform__c oppPlatform = platform.oppPlatform;
                oppPlatform.Contract__c = null;

                for (AdPlacementWrapper oppAdPlacement : platform.adPlacementsMap.values()) {
                    OpportunityAdPlacement__c adPlacement = oppAdPlacement.oppAdPlacement;
                    adPlacement.Contract__c = null;
                }
            }
        }
    }

    public void addNewContactRole() {
        contactRoles.add(new Contact_Opportunity__c());
    }

    public void deleteContactRole() {
        Boolean success = true;
        Contact_Opportunity__c recordToDelete = contactRoles[contactRoleRow];

        if (String.isNotBlank(recordToDelete.Id)) {
            try {
                delete recordToDelete;
            } catch (DmlException ex) {
                success = false;
                ApexPages.addMessage(new ApexPages.Message(Apexpages.Severity.ERROR, ex.getDmlMessage(0)));
            }
        }
        if (success) {
            contactRoles.remove(contactRoleRow);
        }
    }

    public void addNewVideoUrl() {
        videoURLs.add(new VideoUrl__c());
    }

    public void deleteVideoUrl() {
        Boolean success = true;
        VideoUrl__c urlToDelete = videoURLs[videoUrlRow];

        if (String.isNotBlank(urlToDelete.Id)) {
            try {
                delete urlToDelete;
            } catch (DmlException ex) {
                success = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
            }
        }
        if (success) {
            videoURLs.remove(videoUrlRow);
        }
    }

    public void addNewSpendThreshold() {
        Spend_Threshold__c newST = new Spend_Threshold__c();
        if (!spendThresholds.isEmpty() && spendThresholds[spendThresholds.size()-1].Spend_To__c!=null) {
            newST.Spend_From__c = spendThresholds[spendThresholds.size()-1].Spend_To__c + 1;
        }
        spendThresholds.add(newST);
    }

    public void deleteSpendThreshold() {
        Boolean success = true;
        Spend_Threshold__c spendThresholdToDelete = spendThresholds[spendThresholdRow];
        if (String.isNotBlank(spendThresholdToDelete.Id)) {
            try {
                delete spendThresholdToDelete;
            } catch (DmlException ex) {
                success = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
            }
        }
        if (success) {
            spendThresholds.remove(spendThresholdRow);
        }
    }

    public void saveAccount() {
        Boolean success = true;
        try {
            insert newAccount;
        } catch (DmlException ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
            success = false;
        }
        if (success) {
            opp.AccountId = newAccount.Id;
            createAccount = false;
            findAppropriateBrand(newAccount.Name, true);
        }
    }

    private void findAppropriateBrand(String accName, Boolean showMessage) {
        if (opp.RecordTypeId == OpportunityRepository.RT_ID_BRAND_DIRECT) {
            List<Brand__c> brands = [SELECT Id, Name FROM Brand__c WHERE Name = :accName];
            if (!brands.isEmpty()) {
                opp.Brand__c = brands[0].Id;
            } else {
                opp.Brand__c = null;
                if (showMessage) {
                    ApexPages.addMessage(new ApexPages.Message(Apexpages.Severity.WARNING, 'No Brand related to selected Account was found. Please click Create New by Brand and select appropriate Company Verticals'));
                }
            }
            hideBrand = String.isNotBlank(opp.Brand__c);
        }
    }

    public Boolean areSpendsCorrect() {
        if (!spendThresholds.isEmpty()) {
            Decimal previousTo = null;
            for (Spend_Threshold__c spendThreshold :spendThresholds) {
                if (spendThreshold.Spend_From__c <= previousTo) {
                    spendThreshold.Spend_From__c.addError('From must be at least 1 bigger than previous To value');
                    return false;
                } else if (previousTo != null && spendThreshold.Spend_From__c != previousTo + 1) {
                    spendThreshold.Spend_From__c.addError('Ranges don\'t overlap across the rows');
                    return false;
                }
                previousTo = spendThreshold.Spend_To__c;
            }
        }
        return true;
    }

    public PageReference saveOpportunity() {
        if (areSpendsCorrect() == false) {
            return null;
        }

        if (Test.isRunningTest() == false && (contactRoles.size() == 0 || contactRoles == null)
                && opp.StageName != 'Qualification'
                && [SELECT Id FROM Contact_Opportunity__c WHERE Opportunity__c=:opp.Id].size()==0) {
            ApexPages.addMessage(new ApexPages.Message(Apexpages.Severity.ERROR, Label.Opportunity_Contact_Mandatory));
            return null;
        }

        PageReference retVal = null;
        Savepoint sp = Database.setSavepoint();
        Boolean createAndClose = false;

        try {
            if (createBrand) {
                insert brand;
                opp.Brand__c = brand.Id;
            }
            if (String.isBlank(opp.Id) && String.isNotBlank(opp.StageName) && opp.StageName == OpportunityRepository.STAGE_CLOSED_WON) {
                opp.StageName = 'Pre-Meeting';
                createAndClose = true;
            }
            upsert opp;

            if (!videoURLs.isEmpty()) {
                for (VideoUrl__c videoUrl : videoURLs) {
                    videoUrl.Opportunity__c = (Id) opp.Id;
                    if (newOpportunity) {
                        videoUrl.Id = null;
                    }
                }
                upsert videoURLs;
            }

            if (!spendThresholds.isEmpty()) {
                for (Spend_Threshold__c spendThreshold : spendThresholds) {
                    spendThreshold.Opportunity__c = (Id) opp.Id;
                    if (newOpportunity) {
                        spendThreshold.Id = null;
                    }
                }
                upsert spendThresholds;
            }

            if (!contactRoles.isEmpty()) {
                List<Contact_Opportunity__c> newRoles = new List<Contact_Opportunity__c>();
                for (Contact_Opportunity__c contactRole: contactRoles) {
                    newRoles.add(new Contact_Opportunity__c(
                            Opportunity__c = (Id) opp.Id,
                            Contact__c = contactRole.Contact__c,
                            Role__c = contactRole.Role__c
                    ));
                }
                Database.upsert(newRoles,false);
            }

            if (newOpportunity)  {
                for(PlatformWrapper pw: platformsMap.values()) {
                    pw.oppPlatform.Id = null;
                    for (AdPlacementWrapper oppAdPlacement : pw.adPlacementsMap.values()) {
                        oppAdPlacement.oppAdPlacement.Id = null;
                    }
                }
            }
            setPlatformInfo();

            if (createAndClose) {
                opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
                update opp;
            }
            retVal = new PageReference('/' + opp.Id);

            if (opp.StageName == OpportunityRepository.STAGE_CLOSED_WON && opp.StageName != initialStage && opp.RecordTypeId!=Label.Opportunity_Record_Type_SaaS) {
                List<Project__c> contract = [SELECT Id FROM Project__c WHERE Opportunity__c = :opp.Id];
                if (!contract.isEmpty()) {
                    retVal = new PageReference('/' + contract[0].Id);
                }
            }
        } catch (DmlException ex) {
            brand = brand = (brand != null) ? brand.clone(false) : new Brand__c();
            if (newOpportunity) {
                opp = opp.clone(false);
            }
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0) +' '+ex.getStackTraceString()));
            if (newOpportunity)  {
                for(PlatformWrapper pw: platformsMap.values()) {
                    pw.oppPlatform.Id=null;
                    for (AdPlacementWrapper oppAdPlacement : pw.adPlacementsMap.values()) {
                        oppAdPlacement.oppAdPlacement.Id=null;
                    }
                }
            }
        }
        return retVal;
    }

    public void brandUpdated() {
        createBrand = String.isBlank(opp.Brand__c);
    }

    public void accountUpdated() {
        createAccount = String.isBlank(opp.AccountId);
        if (String.isNotBlank(opp.AccountId)) {
            Account acc = [SELECT Custom_Xero_Naming__c, DefaultPaymentType__c, Name FROM Account WHERE Id = :opp.AccountId];
            showCustomCampaignName = acc.Custom_Xero_Naming__c;
            if (String.isNotBlank(acc.DefaultPaymentType__c)) {
                opp.Payment_Type__c = acc.DefaultPaymentType__c;
            }
            findAppropriateBrand(acc.Name, true);
        }
    }

    public void createBrand() {
        createBrand = true;
        brand = new Brand__c();
        opp.Brand__c = null;
        hideBrand = true;

        if (String.isNotBlank(opp.AccountId)) {
            Account acc = [SELECT Natural_Name__c, Name FROM Account WHERE Id = :opp.AccountId];
            brand.Name = (String.isNotBlank(acc.Natural_Name__c)) ? acc.Natural_Name__c : acc.Name;
        }
    }

    public void createAccount() {
        createAccount = true;
        newAccount = new Account();
        opp.AccountId = null;
    }

    public void cancelCreateBrand() {
        createBrand = false;
        hideBrand = String.isNotBlank(opp.Brand__c) && (opp.RecordTypeId == OpportunityRepository.RT_ID_BRAND_DIRECT);
    }

    public void cancelCreateAccount() {
        createAccount = false;
    }

    public Boolean getCanEditPaymentType() {
        if (opp.BillingCondition__c != null && opp.BillingCondition__c != oldBillingCondition) {
            billingConditionName = [SELECT Name FROM BillingCondition__c WHERE Id = :opp.BillingCondition__c].Name;
            oldBillingCondition = opp.BillingCondition__c;
        }
        return  billingConditionName == null || billingConditionName != Contract.BILLING_CONDITION_EXTECH;
    }

    public Boolean getIsAfterProposal() {
        if (String.isNotBlank(opp.StageName)) {
            return (opp.StageName.equals('Proposal/Price Quote') || opp.StageName.equals(OpportunityRepository.STAGE_CLOSED_WON));
        }
        return false;
    }

    public List<PlatformWrapper> getPlatforms() {
        return platformsMap.values();
    }

    public void inputUpdated() {
        if (!getCanEditPaymentType()) {
            opp.Payment_Type__c = 'Net 45';
        }
    }

    public void platformUpdated() {}

    public void savePlatforms() {
        Boolean success = true;
        Savepoint sp = Database.setSavepoint();

        try {
            if (newOpportunity)  {
                for(PlatformWrapper pw: platformsMap.values()) {
                    pw.oppPlatform.Id = null;
                    for (AdPlacementWrapper oppAdPlacement : pw.adPlacementsMap.values()) {
                        oppAdPlacement.oppAdPlacement.Id = null;
                    }
                }
            }
            // TODO: in method setPlatformInfo()=>Platform.savePlatformInfo() there is an UPSERT List<OpportunityPlatform__c>
            setPlatformInfo();
            // TODO: in method updateRelatedOppPlatforms() there is an UPDATE List<OpportunityPlatform__c>
            success = updateRelatedOppPlatforms();
            if (!success) Database.rollback(sp);
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            Database.rollback(sp);
            success = false;
        }
        if (success) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Platforms updated successfully.'));
            initOpp();
        }
    }

    public void setPlatformInfo() {
        for (PlatformWrapper pw: platformsMap.values()) {
            if (pw.oppPlatform.KPI__c == null) {
                pw.oppPlatform.KPI__c = opp.KPI__c;
            }
            if (pw.oppPlatform.Gender__c == null) {
                pw.oppPlatform.Gender__c = opp.Gender__c;
                if (pw.oppPlatform.Gender__c == null) {
                    pw.oppPlatform.Gender__c = '';
                }
                if (pw.oppPlatform.Platform_Selected__c == 'Facebook' ||
                        pw.oppPlatform.Platform_Selected__c == 'Instagram' ||
                        pw.oppPlatform.Platform_Selected__c == 'LinkedIn' ||
                        pw.oppPlatform.Platform_Selected__c == 'Snapchat' ||
                        pw.oppPlatform.Platform_Selected__c == 'Twitter'
                ) {
                    pw.oppPlatform.Gender__c = pw.oppPlatform.Gender__c.removeEnd(';Unknown');
                    pw.oppPlatform.Gender__c = pw.oppPlatform.Gender__c.removeEnd('Unknown;');
                    pw.oppPlatform.Gender__c = pw.oppPlatform.Gender__c.removeEnd('Unknown');
                }
            }
        }
        if (newOpportunity) {
            for(PlatformWrapper pw: platformsMap.values()) {
                pw.oppPlatform.Id = null;
                pw.oppPlatform.Opportunity__c = opp.Id;
                for (AdPlacementWrapper oppAdPlacement : pw.adPlacementsMap.values()) {
                    oppAdPlacement.oppAdPlacement.Id = null;
                }
            }
        }
        Platform.savePlatformInfo(opp.Id, null, platformsMap);
    }

    public Boolean updateRelatedOppPlatforms() {
        Boolean isSuccess = false;
        List<OpportunityPlatform__c> oppPlatforms = OpportunityPlatformRepository.getByOpportunityId(opp.Id);

        Map<String, String> providerToPlatformAcc = new Map <String, String>();
        for (OpportunityPlatform__c oppPlatform :oppPlatforms) {
            if (String.isNotBlank(oppPlatform.PlatformAccount__c)) {
                providerToPlatformAcc.put(oppPlatform.Provider__c, oppPlatform.PlatformAccount__c);
            }
        }
        List<OpportunityPlatform__c> oppPlatformsToUpdate = new List<OpportunityPlatform__c>();
        for (OpportunityPlatform__c oppPlatform :oppPlatforms) {
            if (String.isBlank(oppPlatform.PlatformAccount__c) && providerToPlatformAcc.get(oppPlatform.Provider__c) != null) {
                oppPlatform.PlatformAccount__c = providerToPlatformAcc.get(oppPlatform.Provider__c);
                oppPlatformsToUpdate.add(oppPlatform);
            } else if (String.isNotBlank(oppPlatform.PlatformAccount__c) && oppPlatform.PlatformAccount__c != providerToPlatformAcc.get(oppPlatform.Provider__c)) {
                oppPlatform.PlatformAccount__c.addError(ERROR_DIFFERENT_PLATFORM_ACCOUNT);
                return isSuccess;
            }
        }

        try {
            update oppPlatformsToUpdate;
            isSuccess = true;
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return isSuccess;
    }

    private void initOpp() {
        showCustomCampaignName = false;
        this.opp = (Opportunity) stdController.getRecord();
        this.stdController = stdController;
        newAccount = new Account();

        if (String.isNotBlank(opp.Id)) {
            opp = OpportunityRepository.getOpportunityById(opp.Id);
        }

        if (String.isBlank(opp.OwnerId)) {
            opp.OwnerId = UserInfo.getUserId();
            opp.CloseDate = System.today().addMonths(3);
            opp.Payment_Type__c = 'Net 30';
        }

        createBrand = false;
        hideBrand = (this.opp.RecordTypeId == OpportunityRepository.RT_ID_BRAND_DIRECT);
        createAccount = false;
        brand = new Brand__c();
        initialStage = opp.StageName;
        videoURLs = new List<VideoUrl__c>();
        contactRoles = new List<Contact_Opportunity__c>();
        spendThresholds = new List<Spend_Threshold__c>();

        platformString = '';

        platformsMap = new Map<Id, PlatformWrapper>();
        for (Platform__c platform : PlatformRepository.getAvailablePlatformsForOpportunity(opp.Id)) {
            platformsMap.put(platform.Id, new PlatformWrapper(platform));
        }

        if (String.isNotBlank(opp.Id)) {
            platformString = Platform.initPlatformsInfo(platformsMap, opp.OpportunityPlatforms__r, opp.OpportunityAdPlacements__r, platformString);
            videoURLs = VideoUrlRepository.getVideosForOpportunity(opp.Id);
            newOpportunity = false;
        } else {
            newOpportunity = true;
        }
    }

    public PageReference cloneOpportunity() {
        PageReference editPage = new PageReference('/apex/OpportunityEdit?id=' + opp.Id);
        editPage.getParameters().put('isCloned', 'true');
        editPage.setRedirect(true);
        return editPage;
    }

    @RemoteAction
    public static void updateOwner(Id oppId, Id newOwnerId) {
        // let Javascript handle exceptions
        Opportunity opp = [SELECT OwnerId FROM Opportunity WHERE Id = :oppId];
        opp.OwnerId = newOwnerId;
        update opp;
    }

    @RemoteAction
    public static List<User> searchSalesUsers(String searchString) {
        searchString = '%' + String.escapeSingleQuotes(searchString) + '%';
        return [
            SELECT Id, Name, FirstName, LastName
            FROM User
            WHERE (FirstName LIKE :searchString OR LastName LIKE :searchString)
            AND IsActive = TRUE
            AND ProfileId IN (SELECT Id FROM Profile WHERE Name IN ('Sales User', 'Sales Manager'))
        ];
    }
}