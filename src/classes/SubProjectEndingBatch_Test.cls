@isTest
private class SubProjectEndingBatch_Test {

    testmethod static void synchronizeContractEnd() {
        TestHelper.setupEnv();
        Sub_Project__c sp = [SELECT Id, Project__c FROM Sub_Project__c LIMIT 1];
        sp.Contract_Ended__c=false;
        update sp;
        
        Test.startTest();
        Database.executeBatch(new SubProjectEndingBatch(), 200);
        Test.stopTest();
        
        system.assertEquals(0, [SELECT count() FROM Sub_Project__c WHERE Contract_Ended__c=false
                               AND Id=:sp.Id]);
        
    }
}