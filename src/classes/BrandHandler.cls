public class BrandHandler implements ITrigger {
    public BrandHandler() {}
    
    public void bulkBefore() {}

    public void bulkAfter() {}

    public void beforeInsert(List<SObject> so) {}

    public void beforeUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {}
    
    public void beforeDelete(List<SObject> so) {}

    public void afterInsert(List<SObject> so) {}
    
    public void afterUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {
        Map<Id, Brand__c> oldMap = (Map<Id, Brand__c>)oldSo;
        Set<Id> updatedBrandIds = new Set<Id>();
        for (Brand__c brand :((Map<Id, Brand__c>)so).values()) {
            if (brand.Verticals__c != oldMap.get(brand.Id).Verticals__c) {
                updatedBrandIds.add(brand.Id);
            }
        }
        
        markForMMSync(updatedBrandIds);
    }
        
    public void afterDelete(List<SObject> so) {}

    public void andFinally() {}
    
    private static void markForMMSync(Set<Id> brandIds) {
        List<Project__c> contractsToSyncWithMM = new List<Project__c>();
        for (Project__c contract :[SELECT Id, PerformMMSync__c FROM Project__c WHERE Sync_with_MM__c != NULL AND PerformMMSync__c = false AND Brand__c IN :brandIds]) {
            contract.PerformMMSync__c = true;
            contractsToSyncWithMM.add(contract);
        }
        update contractsToSyncWithMM;
    }
}