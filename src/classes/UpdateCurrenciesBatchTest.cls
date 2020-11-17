@isTest
public class UpdateCurrenciesBatchTest {

    @isTest
    static void test () 
    {
        TestHelper.createAppSettings();
        CurrencyType [] ct = [SELECT id, ISOCode, ConversionRate FROM CurrencyType];
        CurrencyHistory__c currencyHistoryRecord = new CurrencyHistory__c (AUD__c = 1.307102, CAD__c = 1.30466, EUR__c = 0.891904, 
                                                                           GBP__c = 0.76423, IDR__c = 13085, INR__c = 66.596001, 
                                                                           MXN__c = 19.627297, MYR__c = 19.627297, NZD__c = 1.366983, PHP__c = 47.810001, 
                                                                           PLN__c = 3.816702, SGD__c = 1.355799, HKD__c = 3.08,
                                                                           JPY__c = 2.0, KRW__c = 2.0, THB__c = 2.0,
                                                                           Date__c = Date.valueOf('2016-09-22'));
        
        insert CurrencyHistoryRecord;
        
        Test.startTest();
			Test.setMock(HTTPCalloutMock.class, new HTTPCurrencyCalloutMock ());
        	UpdateCurrenciesBatch batchObject = new UpdateCurrenciesBatch();
            DataBase.executeBatch(batchObject);
        Test.stopTest();        
    }    
}