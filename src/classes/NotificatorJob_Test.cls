@isTest 
private class  NotificatorJob_Test {
    
    static testMethod void StorageLicenseCheck_UpdateAlertStatus() {
       NotificatorSetting__c notificator = NotificatorTestUtils.prepareTestNotificator();
        
       NotificatorStorage__c storageToUpdate = [SELECT Id, Name, Status__c FROM NotificatorStorage__c WHERE Name='File Storage'];
        
       storageToUpdate.InfoPercentageThreshold__c=10;
       update storageToUpdate;

       Test.startTest();
       NotificatorJob.notify();
       Test.stopTest();
        
       storageToUpdate = [SELECT Id, Name, Status__c FROM NotificatorStorage__c WHERE Name='File Storage'];
       system.assertEquals('Info',storageToUpdate.Status__c); 
    }

}