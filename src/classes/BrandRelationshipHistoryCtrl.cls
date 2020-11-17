public with sharing class BrandRelationshipHistoryCtrl {
    public Account acc { get;set; }
    public List<Brand_Account__c> brandAccounts { get {
        if (brandAccounts == null) brandAccounts = new List<Brand_Account__c>();
        return brandAccounts;
    } set; }
    public String retUrl { get; private set;}
    private ApexPages.StandardController stdController;

    @testVisible private static Id brandDirectRTId = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Brand_Direct'].Id;

    public BrandRelationshipHistoryCtrl (ApexPages.StandardController stdController) {
        this.acc = [SELECT Natural_Name__c, Name, Id, RecordTypeId FROM Account WHERE Id = :stdController.getId()];
        this.stdController = stdController;

        retUrl = stdController.view().getUrl();

        if (this.acc.RecordTypeId == brandDirectRTId) {
            List<Brand_Account__c> relatedBrandAccounts = [SELECT Brand__c, Accounts__c FROM Brand_Account__c WHERE Brand__r.Name = :this.acc.Natural_Name__c];
            // could be more than one record
            Set<Id> brandIds = new Set<Id>();
            for (Brand_Account__c ba :relatedBrandAccounts) {
                brandIds.add(ba.Brand__c);
            }

            brandAccounts = [
                SELECT OpenOpportunities__c, NoOfContracts__c, ContractsClientSpend__c, ClientSince__c, LastContractEndDate__c, Name, Accounts__r.Name, Accounts__r.Natural_Name__c, Accounts__c
                FROM Brand_Account__c
                WHERE Brand__c IN :brandIds
            ];
        }

    }
}