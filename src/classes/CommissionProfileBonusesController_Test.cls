@isTest
public class CommissionProfileBonusesController_Test {

    testmethod static void getBonuses() {
    	Commission_Profile__c profile1 = TestHelper.createSalesCommissionProfile();
		CurrencyHistory__c ch1 = new CurrencyHistory__c (Date__c = Date.newInstance(2018, 01, 1),
            AUD__c = 0.6, EUR__c = 2.8, CAD__c  = 0, GBP__c  = 0, NZD__c  = 0, PLN__c  = 0, SGD__c  = 0,
            IDR__c  = 0, MXN__c  = 0, MYR__c=0, PHP__c  = 0, HKD__c  = 0, JPY__c  = 0, KRW__c  = 0, INR__c  = 0,
            THB__c  = 0, RUB__c  = 0);
        insert ch1;     
           
        Test.startTest();
        database.executeBatch(new SCH_BATCH_SalesRepBonusCalc(Date.newInstance(2018,01,01)));
        Test.stopTest();

        Sales_Rep_Quarterly_Bonus__c bonus = [SELECT Id FROM Sales_Rep_Quarterly_Bonus__c LIMIT 1];
        bonus.Gross_Profit__c=1;
        update bonus;
        CommissionProfileBonusesController ctrl = new CommissionProfileBonusesController(new ApexPages.StandardController(profile1));


        List<Sales_Rep_Quarterly_Bonus__c> bonuses = ctrl.getBonuses();
		system.assertEquals(1, bonuses.size());        
        
    }
}