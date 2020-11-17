public class BrandAccountHandler implements ITrigger {

    public BrandAccountHandler() {}
    
    public void bulkBefore() {}

    public void bulkAfter() {}

    public void beforeInsert(List<SObject> so) {
        checkDuplicates((List<Brand_Account__c>)so);
    }

    public void beforeUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {
        checkDuplicates(((Map<Id, Brand_Account__c>)so).values());
    }
    
    public void beforeDelete(List<SObject> so) {}

    public void afterInsert(List<SObject> so) {
        List <Brand_Account__c> brandAccs = [SELECT Id, Brand_Account__c, Name FROM Brand_Account__c WHERE Name = 'tmpBrand / tmpAccount'];
        for (Brand_Account__c brandAcc :brandAccs) {
            if (brandAcc.Brand_Account__c != null && brandAcc.Brand_Account__c.length() > 80) {
                brandAcc.Name = brandAcc.Brand_Account__c.substring(0,79);
            } else {
                brandAcc.Name = brandAcc.Brand_Account__c;
            }
        }
        update brandAccs;
    }
    
    public void afterUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {}
        
    public void afterDelete(List<SObject> so) {}

    public void andFinally() {}
    
    private void checkDuplicates(List<Brand_Account__c> brandAccounts) {
        for (Brand_Account__c brandAcc :brandAccounts) {
        	brandAcc.UniqueKey__c = (String) brandAcc.Accounts__c + (String) brandAcc.Brand__c;
        }
    }    
}