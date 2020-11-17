@isTest
public class SCH_BATCH_AccountStageSetter_Test {

    testmethod static void setMeetingStage() {
        Account acc = TestHelper.createAccount('TestAcc');
        Event ev = new Event(WhatId=acc.Id, ActivityDateTime=DateTime.now().addDays(5), DurationInMinutes=1);
        insert ev;
        
        Test.startTest();
        Database.executeBatch(new SCH_BATCH_AccountStageSetter(), 200);
        Test.stopTest();
        
        acc = [SELECT account_stage__c from account];
        system.assertEquals('Meeting', acc.account_stage__c);
    }
    
    testmethod static void setOpenStage() {
        Account acc = TestHelper.createAccount('TestAcc');
   
        
        Test.startTest();
        Database.executeBatch(new SCH_BATCH_AccountStageSetter(), 200);
        Test.stopTest();
        
        acc = [SELECT account_stage__c from account];
        system.assertEquals('Open', acc.account_stage__c);
    }    
}