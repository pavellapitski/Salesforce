@isTest
private class BrandHandlerTest {

    @IsTest static void willSetPerformMMSyncOnUpdate() {
        Account acc = TestHelper.createAccount();
        Date nextMonth = System.today().addMonths(1);
        Brand__c brand1 = TestHelper.createBrand('testBrand1', false);
        Brand__c brand2 = TestHelper.createBrand('testBrand2', false);
        Brand__c brand3 = TestHelper.createBrand('testBrand3', false);
        insert new List<Brand__c> {brand1, brand2, brand3};
        
        Project__c contractSynced1 = TestHelper.createContractNoInsert(acc.Id, 'syncedWithMM', null);
        contractSynced1.Brand__c = brand1.Id;
        contractSynced1.Start_Date__c = Date.newInstance(nextMonth.year(), nextMonth.month(), 1);
        contractSynced1.End_Date__c = contractSynced1.Start_Date__c.addMonths(1).addDays(-1);
        contractSynced1.Sync_with_MM__c = System.now();
        
        Project__c contractSynced2 = TestHelper.createContractNoInsert(acc.Id, 'syncedWithMM', null);
        contractSynced2.Brand__c = brand2.Id;
        contractSynced2.Start_Date__c = contractSynced1.Start_Date__c;
        contractSynced2.End_Date__c = contractSynced1.End_Date__c;
        contractSynced2.Sync_with_MM__c = System.now();
        
        Project__c contractNotSynced = TestHelper.createContractNoInsert(acc.Id, 'notSyncedWithMM', null);
        contractNotSynced.Brand__c = brand3.Id;
        contractNotSynced.Start_Date__c = contractSynced1.Start_Date__c;
        contractNotSynced.End_Date__c = contractSynced1.End_Date__c;
        
        insert new List<Project__c> { contractSynced1, contractSynced2, contractNotSynced };
        
        Test.startTest();
            update [SELECT Id FROM Brand__c];
            
            contractSynced1.PerformMMSync__c = false;
            contractSynced2.PerformMMSync__c = false;
            contractNotSynced.PerformMMSync__c = false;
            update new List<Project__c> {contractSynced1, contractSynced2, contractNotSynced};
            
            brand1.Verticals__c = 'Beauty';
            brand3.Verticals__c = 'Retail';
            System.assertEquals(false, [SELECT PerformMMSync__c FROM Project__c WHERE Id = :contractSynced1.Id].PerformMMSync__c);
            System.assertEquals(false, [SELECT PerformMMSync__c FROM Project__c WHERE Id = :contractSynced2.Id].PerformMMSync__c);
            System.assertEquals(false, [SELECT PerformMMSync__c FROM Project__c WHERE Id = :contractNotSynced.Id].PerformMMSync__c);
            update new List<Brand__c> { brand1, brand2, brand3 };
        Test.stopTest();

        System.assertEquals(true, [SELECT PerformMMSync__c FROM Project__c WHERE Id = :contractSynced1.Id].PerformMMSync__c);
        System.assertEquals(false, [SELECT PerformMMSync__c FROM Project__c WHERE Id = :contractSynced2.Id].PerformMMSync__c);
        System.assertEquals(false, [SELECT PerformMMSync__c FROM Project__c WHERE Id = :contractNotSynced.Id].PerformMMSync__c);
    }
}