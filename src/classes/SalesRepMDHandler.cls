public with sharing class SalesRepMDHandler implements ITrigger {

    public SalesRepMDHandler() {}

    public void bulkBefore() {}

    public void bulkAfter() {}

    public void beforeInsert(List<SObject> so) {
        Set<Id> contractSalesRepIDs = new Set<Id>();
        for (Sales_Rep_MD__c srmd : (List<Sales_Rep_MD__c>) so) {
            contractSalesRepIDs.add(srmd.Sales_Rep__c);
        }

        Map<Id, Contract_Sales_Rep__c> reps = new Map<Id, Contract_Sales_Rep__c>([
                SELECT Id, Commission_Profile__c, Commission_Profile__r.CurrencyISOCode
                FROM Contract_Sales_Rep__c
                WHERE Id IN :contractSalesRepIDs
        ]);

        for (Sales_Rep_MD__c srmd : (List<Sales_Rep_MD__c>) so) {
            if (String.isBlank(srmd.Sales_Rep__c)) continue;

            Contract_Sales_Rep__c contractSalesRep = reps.get(srmd.Sales_Rep__c);
            srmd.Commission_Profile__c = contractSalesRep.Commission_Profile__c;
            srmd.CurrencyIsoCode = contractSalesRep.Commission_Profile__r.CurrencyISOCode;
        }
    }

    public void beforeUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {}

    public void beforeDelete(List<SObject> so) {}

    public void afterInsert(List<SObject> so) {}

    public void afterUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {}

    public void afterDelete(List<SObject> so) {}

    public void andFinally() {}
}