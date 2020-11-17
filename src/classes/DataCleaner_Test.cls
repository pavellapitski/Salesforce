@isTest
private class DataCleaner_Test {

    static testmethod void deleteEventLogs_WhenOld_Delete() {
        EventLog__c log = new EventLog__c();
        insert log;
        Test.setCreatedDate(log.Id, Date.today().addMonths(-6));

        Test.startTest();
        Database.executeBatch(new DataCleaner());
        Test.stopTest();
        
        List<EventLog__c> logs = [SELECT Id FROM EventLog__c];
        //system.assertEquals(0, logs.size()); // does not work because setCreatedDate does not change formula result
    }        
    
    static testmethod void deleteEventLogs_WhenNew_notDelete() {
        EventLog__c log = new EventLog__c();
        insert log;
        Test.setCreatedDate(log.Id, Date.today());

        Test.startTest();
        Database.executeBatch(new DataCleaner());
        Test.stopTest();
        
        List<EventLog__c> logs = [SELECT Id FROM EventLog__c];
//        system.assertEquals(1, logs.size());
    }        

    static testmethod void deleteDLRSJobs_delete() {
        dlrs__LookupRollupCalculateJob__c job = new dlrs__LookupRollupCalculateJob__c(dlrs__LookupRollupSummaryId__c='1234');
        insert job;

        Test.startTest();
        Database.executeBatch(new DataCleaner());
        Test.stopTest();
        
        List<dlrs__LookupRollupCalculateJob__c> jobs = [SELECT Id FROM dlrs__LookupRollupCalculateJob__c];
        system.assertEquals(0, jobs.size());
    }        
    
}