@isTest 
private class NotificatorSingleton_Test {

    static testMethod void getNotificator_WhenNoObject() {
         NotificatorSetting__c notificator = NotificatorSingleton.getNotificator();
        
         System.assertNotEquals(null, notificator);
    }
    static testMethod void getNotificator_WhenObjectExist() {
        NotificatorSetting__c notificator = NotificatorTestUtils.prepareTestNotificator();
       
        System.assertEquals(notificator.Id, NotificatorSingleton.getNotificator().Id);        
    }
    
    static testMethod void getStorages_WhenNoObject() {
        List<StorageOCR> storages = NotificatorSingleton.getStorages();
        
        System.assertEquals(2, storages.size());
    }
    
    static testMethod void getStorages_WhenObjectExist() {
        NotificatorSetting__c notificator = NotificatorTestUtils.prepareTestNotificator();
        
        List<StorageOCR> storages = NotificatorSingleton.getStorages();
        
       System.assertEquals(2, storages.size());
    }    
}