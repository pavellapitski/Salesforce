public with sharing class OpportunityHandler implements ITrigger {

    @TestVisible private Set<Opportunity> opportunityClosedWon = new Set<Opportunity>();
    @TestVisible private static Set<String> insertedUniqueContractIds = new Set<String>();

    public OpportunityHandler() {}

    public void bulkBefore() {}

    public void bulkAfter() {}

    public void beforeInsert(List<SObject> so) {
        List<Opportunity> opportunities = (List<Opportunity>) so;

        Map<String, Opportunity> opportunityForBrandAccount = new Map<String, Opportunity>();
        for (Opportunity opp :opportunities) {
            // if opportunity has Stage Name equals to Closed Won, then add to list
            if (opp.StageName == OpportunityRepository.STAGE_CLOSED_WON) {
                opp.CloseDate = System.today();
            }
            if (String.isNotBlank(opp.Brand__c) && String.isNotBlank(opp.AccountId)) {
                String brandId = ((String)opp.Brand__c).left(15);
                String accountId = ((String)opp.AccountId).left(15);
                opportunityForBrandAccount.put(brandId + '-' + accountId, opp);
            }
        }

        if (!opportunityForBrandAccount.isEmpty()) {
            updateBrandAccount(opportunityForBrandAccount);
        }

        for (Opportunity opp :opportunities) {
            if (String.isBlank(opp.ClientServicesRep__c) && String.isNotBlank(opp.DefaultClientServicesRep__c)) {
                opp.ClientServicesRep__c = opp.DefaultClientServicesRep__c;
            }

            if (String.isNotBlank(opp.DefaultClientServicesRepEmail__c)) {
                opp.CSEmailFromBrandAccount__c = opp.DefaultClientServicesRepEmail__c;
            }

            if (String.isNotBlank(opp.DefaultPaymentType__c) && String.isBlank(opp.Payment_Type__c)) {
                opp.Payment_Type__c = opp.DefaultPaymentType__c;
            }

            if (opp.Percent_Margin__c == null) {
                setDefaultMargin(opp);
            }

            opp.Payment_Type__c = opp.AccPaymentType__c;
        }
    }

    public void beforeUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {
        Opportunity oldOpp;
        Opportunity newOpp;

        Map<String, Opportunity> opportunityForBrandAccount = new Map<String, Opportunity>();
        for (Id id : so.keySet()) {
            newOpp = (Opportunity) so.get(id);
            oldOpp = (Opportunity) oldSo.get(id);

            // if opportunity Stage Name is changed to Closed Won, then add to list
            if (newOpp.StageName == OpportunityRepository.STAGE_CLOSED_WON && oldOpp.StageName != OpportunityRepository.STAGE_CLOSED_WON) {
                newOpp.CloseDate = System.today();
            }

            if (String.isNotBlank(newOpp.BillingConditionName__c) && newOpp.BillingConditionName__c == Contract.BILLING_CONDITION_EXTECH) {
                newOpp.Payment_Type__c = 'Net 45';
            }

            Boolean isBrandChanged = (newOpp.Brand__c != oldOpp.Brand__c);
            Boolean isAccountChanged = (newOpp.AccountId != oldOpp.AccountId);
            if ((isBrandChanged || isAccountChanged) && String.isNotBlank(newOpp.Brand__c) && String.isNotBlank(newOpp.AccountId)) {
                String brandId = ((String)newOpp.Brand__c).left(15);
                String accountId = ((String)newOpp.AccountId).left(15);
                opportunityForBrandAccount.put(brandId + '-' + accountId, newOpp);
            }

            if (newOpp.Percent_Margin__c == null || newOpp.Account_Type__c != oldOpp.Account_Type__c || newOpp.BillingCondition__c != oldOpp.BillingCondition__c) {
                setDefaultMargin(newOpp);
            }
        }

        if (!opportunityForBrandAccount.isEmpty()) {
            updateBrandAccount(opportunityForBrandAccount);
        }

        for (Opportunity opp : (List<Opportunity>)so.values()) {
            if (String.isBlank(opp.ClientServicesRep__c) && String.isNotBlank(opp.DefaultClientServicesRep__c)) {
                opp.ClientServicesRep__c = opp.DefaultClientServicesRep__c;
            }
            if (String.isNotBlank(opp.DefaultClientServicesRepEmail__c)) {
                opp.CSEmailFromBrandAccount__c = opp.DefaultClientServicesRepEmail__c;
            }
        }
    }

    public void beforeDelete(List<SObject> so) {}

    public void afterInsert(List<SObject> so) {
        List<Opportunity> opportunities = (List<Opportunity>) so;
        for (Opportunity opp :opportunities) {
            if (opp.StageName == OpportunityRepository.STAGE_CLOSED_WON && opp.RecordTypeId != Label.Opportunity_Record_Type_SaaS) {
                opportunityClosedWon.add(opp);
            }
        }
        ContactOpportunityHandler.replicateOpportunityStatus(new Map<Id,Opportunity>(opportunities));
    }

    public void afterUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {
        Opportunity oldOpp, newOpp;
        for (Id oppId :so.keySet()) {
            newOpp = (Opportunity) so.get(oppId);
            oldOpp = (Opportunity) oldSo.get(oppId);
            // if opportunity Stage Name is changed to Closed Won, then add to list
            if (newOpp.StageName == OpportunityRepository.STAGE_CLOSED_WON && oldOpp.StageName != OpportunityRepository.STAGE_CLOSED_WON && newOpp.RecordTypeId != Label.Opportunity_Record_Type_SaaS) {
                opportunityClosedWon.add(newOpp);
            }
        }
        ContactOpportunityHandler.replicateOpportunityStatus((Map<Id,Opportunity>) so);
    }

    public void afterDelete(List<SObject> so) {}

    public void andFinally() {
        createContractForOpportunities();
    }

    public void updateBrandAccount(Map<String, Opportunity> opportunityForBrandAccount) {
        Set<String> accountIds = new Set<String>();
        Set<String> brandIds = new Set<String>();
        for (Opportunity opp :opportunityForBrandAccount.values()) {
            accountIds.add(opp.AccountId);
            brandIds.add(opp.Brand__c);
        }

        // get all Brands related to new Opportunity records
        Map<String,String> brandIdToName = new Map<String,String>();
        for (Brand__c brand :[SELECT Id, Name FROM Brand__c WHERE Id IN :brandIds]) {
            brandIdToName.put(brand.Id, brand.Name);
        }
        // get all Accounts with BrandAccounts related to new Opportunity records
        Map<String, String> accIdToName = new Map<String, String>();
        Map<String, Brand_Account__c> brandIdAccountIdKeys_existing = new Map<String, Brand_Account__c>();
        for (Account acc :[SELECT Id, Name, (SELECT Brand__c, Id FROM Brand_Accounts__r) FROM Account WHERE Id IN :accountIds]) {
            accIdToName.put(acc.Id, acc.Name);

            for (Brand_Account__c ba :acc.Brand_Accounts__r) {
                brandIdAccountIdKeys_existing.put(((String)ba.Brand__c).left(15) + '-' + ((String)acc.Id).left(15), ba);
            }
        }

        // Check if BrandAccount exists or create a new one
        Map<String, Brand_Account__c> newBrandAccounts = new Map<String,Brand_Account__c>();
        for (String key :opportunityForBrandAccount.keySet()) {
            if (brandIdAccountIdKeys_existing.containsKey(key)) {
                // if BrandAccount exists on related Account, then assign it to Opportunity.BrandAccount__c
                opportunityForBrandAccount.get(key).BrandAccount__c = brandIdAccountIdKeys_existing.get(key).Id;
            } else {
                //create a new BrandAccount record based on Account and Brand
                String accId = opportunityForBrandAccount.get(key).AccountId;
                String brandId = opportunityForBrandAccount.get(key).Brand__c;
                String accName = accIdToName.get(accId);
                String brandName = brandIdToName.get(brandId);
                newBrandAccounts.put(key, new Brand_Account__c(Accounts__c = accId, Brand__c = brandId, Name = brandName + ' / ' + accName));
            }
        }
        insert newBrandAccounts.values();

        for (String key :opportunityForBrandAccount.keySet()) {
            if (!newBrandAccounts.containsKey(key)) {
                continue;
            }
            // update Opportunity.BrandAccount based on newly created BrandAccounts
            opportunityForBrandAccount.get(key).BrandAccount__c = newBrandAccounts.get(key).Id;
        }
    }

    private String createUniqueContractId(Project__c contract) {
        return ''+contract.BrandAccount__c + contract.Opportunity__c + contract.BillingCondition__c + contract.Client_Spend__c + contract.Margin__c + contract.Strike_ID__c + contract.Account_Type__c;
    }

    private void createContractForOpportunities() {
        List<Project__c> contractsToInsert = new List<Project__c>();
        for (Opportunity opp :opportunityClosedWon) {
            Project__c contract = Utility.copyOpportunityDataToContract(opp);
            String uniqueId = createUniqueContractId(contract);
            if (!insertedUniqueContractIds.contains(uniqueId)) {
                insertedUniqueContractIds.add(uniqueId);
                contractsToInsert.add(contract);
            }
        }
        insert contractsToInsert;
    }

    private static void setDefaultMargin(Opportunity opp) {
        if (opp.BillingConditionName__c == 'Normal') {
            opp.Percent_Margin__c = (opp.Account_Type__c == 'Client') ? 25 : 26;
        } else {
            opp.Percent_Margin__c = opp.DefaultMargin__c;
        }
    }
}