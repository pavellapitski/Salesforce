@isTest
public class CalcAverageMonthlyExchangeRatesTest {
    
    @testSetup
    public static void setupTestData ()
    {
        
        CurrencyHistory__c ch1 = new CurrencyHistory__c ();
        ch1.Date__c = Date.newInstance(2018, 05, 01);
        ch1.AUD__c = 0.6;
        ch1.EUR__c = 2.8;
        ch1.CAD__c  = 0;
        ch1.GBP__c  = 0;
        ch1.NZD__c  = 0;
        ch1.PLN__c  = 0;
        ch1.SGD__c  = 0;
        ch1.IDR__c  = 0;
        ch1.MXN__c  = 0;
        ch1.MYR__c  = 0;
        ch1.PHP__c  = 0;
        ch1.HKD__c  = 0;
        ch1.JPY__c  = 0;
        ch1.KRW__c  = 0;
        ch1.INR__c  = 0;
        ch1.THB__c  = 0;
        ch1.RUB__c  = 0;
        
        CurrencyHistory__c ch2 = new CurrencyHistory__c ();
        ch2.Date__c = Date.newInstance(2018, 05, 31);
        ch2.AUD__c = 0.4;
        ch2.EUR__c = 2.2;
        ch2.CAD__c  = 0;
        ch2.GBP__c  = 0;
        ch2.NZD__c  = 0;
        ch2.PLN__c  = 0;
        ch2.SGD__c  = 0;
        ch2.IDR__c  = 0;
        ch2.MXN__c  = 0;
        ch2.MYR__c  = 0;
        ch2.PHP__c  = 0;
        ch2.HKD__c  = 0;
        ch2.JPY__c  = 0;
        ch2.KRW__c  = 0;
        ch2.INR__c  = 0;
        ch2.THB__c  = 0;
        ch2.RUB__c  = 0;
        
        insert new CurrencyHistory__c [] {ch1, ch2};    
    }
    
    @isTest
    public static void testAverages ()
    {
        Test.startTest();
        Database.executeBatch(new CalcAverageMonthlyExchangeRates(Date.newInstance(2018, 05, 31)));
        Test.stopTest();
        
        List <Average_Monthly_Currency_History__c> avgList = [SELECT AUD__c, EUR__c FROM Average_Monthly_Currency_History__c];
        
        
        System.assertEquals (0.5, avgList [0].AUD__c);
        System.assertEquals (2.5, avgList [0].EUR__c);
    }
    
    @isTest
    public static void testMonthlyDistributionUpdate ()
    {
        
        Monthly_Distribution__c md1 = new Monthly_Distribution__c ();
        md1.CurrencyIsoCode = 'EUR';
        md1.Client_Spend__c = 100;
        md1.Start_Date__c=Date.newInstance(2018,05,01);
        md1.End_Date__c=Date.newInstance(2018,05,31);
        
        
        Account acc = new Account (Name = 'TestAccX', BillingCountry = 'Czech Republic');
        insert acc;
        
        Project__c contract = TestHelper.createContractNoInsert (acc.Id, 'Test Contract', '');
        insert contract; 
        
        
        md1.Project__c = [SELECT ID FROM Payment__c LIMIT 1] [0].Id;
        insert md1;
        
        Test.startTest();
        Database.executeBatch(new CalcAverageMonthlyExchangeRates(Date.newInstance(2018,05,31)));
        Test.stopTest();
        
        List <Monthly_Distribution__c> mdList = [SELECT ID, Average_Monthly_Currency_History__c
                                                 FROM Monthly_Distribution__c WHERE ID = :md1.Id];
        
        System.assertNotEquals (null, mdList [0].Average_Monthly_Currency_History__c);
    }    
    
   @isTest
    public static void testMonthlyDistributionPopulateEmpty()
    {
        
        Monthly_Distribution__c md1 = new Monthly_Distribution__c ();
        md1.CurrencyIsoCode = 'EUR';
        md1.Client_Spend__c = 100;
        md1.Start_Date__c=Date.newInstance(2017,05,01);
        md1.End_Date__c=Date.newInstance(2017,05,31);
        
        
        Account acc = new Account (Name = 'TestAccX', BillingCountry = 'Czech Republic');
        insert acc;
        
        Project__c contract = TestHelper.createContractNoInsert (acc.Id, 'Test Contract', '');
        insert contract; 
        
        
        md1.Project__c = [SELECT ID FROM Payment__c LIMIT 1] [0].Id;
        insert md1;
        
        Test.startTest();
        Database.executeBatch(new CalcAverageMonthlyExchangeRates(Date.newInstance(2018,05,31)));
        Test.stopTest();
        
        List <Monthly_Distribution__c> mdList = [SELECT ID, Average_Monthly_Currency_History__c
                                                 FROM Monthly_Distribution__c WHERE ID = :md1.Id];
        
        System.assertNotEquals (null, mdList [0].Average_Monthly_Currency_History__c);
    }    
           
          
}