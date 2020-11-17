@isTest
public class SCH_BATCH_SalesRepBonusCalc_Test {

    testmethod static void createAnnualBonus() {
    	Commission_Profile__c profile1 = TestHelper.createSalesCommissionProfile();
        
        Test.startTest();
        database.executeBatch(new SCH_BATCH_SalesRepBonusCalc(Date.newInstance(2018,01,01)));
        Test.stopTest();
        
        system.assertEquals(1, [SELECT count() FROM Sales_Rep_Annual_Bonus__c where year__c=2018]);        
    }
    
    testmethod static void createQuarterBonus() {
    	Commission_Profile__c profile1 = TestHelper.createSalesCommissionProfile();
        database.executeBatch(new SCH_BATCH_SalesRepBonusCalc(Date.newInstance(2018,01,01)));
		CurrencyHistory__c ch1 = new CurrencyHistory__c (Date__c = Date.newInstance(2018, 01, 1),
            AUD__c = 0.6, EUR__c = 2.8, CAD__c  = 0, GBP__c  = 0, NZD__c  = 0, PLN__c  = 0, SGD__c  = 0,
            IDR__c  = 0, MXN__c  = 0, MYR__c=0, PHP__c  = 0, HKD__c  = 0, JPY__c  = 0, KRW__c  = 0, INR__c  = 0,
            THB__c  = 0, RUB__c  = 0);
        insert ch1;        
        
        Test.startTest();
        database.executeBatch(new SCH_BATCH_SalesRepBonusCalc(Date.newInstance(2018,10,01)));
        Test.stopTest();
        
        system.assertEquals(1, [SELECT count() FROM Sales_Rep_Quarterly_Bonus__c where quarter__c=4
                               and start_date__c=:date.newInstance(2018,10,1)
                               and end_Date__c=:date.newInstance(2018,12,31)]);        
    }   
        
}