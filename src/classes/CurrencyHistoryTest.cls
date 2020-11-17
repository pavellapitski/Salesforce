@isTest
private class CurrencyHistoryTest {

    static testMethod void willCreateCurrencyHistoryRecord(){
        
        TestHelper.createAppSettings();
        Date dt = System.today();
        
        System.assert([SELECT Id FROM CurrencyHistory__c].isEmpty());
   	    
        test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new CurrencyLayerMockUpResponse());
    	CurrencyHistory.updateCurrencyRates(dt);
        
        test.stopTest();
        
        System.assertEquals(1, [SELECT Id FROM CurrencyHistory__c WHERE Date__c = :dt].size());
    }
}