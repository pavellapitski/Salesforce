@isTest
public class SCH_BATCH_MediaSpendSummarizer_Test {

    testmethod static void summarizeMMSpends() {
        MM_Spendings__c mediaSpending1;
        MM_Spendings__c mediaSpending2;
        Set<String> strikeIds;
        Map<Id, MM_Spendings__c> mediaSpendings;
        Map<Id, Project_Media_Spend__c> contractSpendingForMediaManagerSpending;   
        strikeIds = new Set<String>();
        mediaSpendings = new Map<Id, MM_Spendings__c>();
        contractSpendingForMediaManagerSpending= new Map<Id, Project_Media_Spend__c>(); 
        
        TestHelper.setupEnv();
		Project__c contract = TestHelper.contract; 
                
        mediaSpending1 = TestHelper.createMediaSpendings(TestHelper.contract.Id, TestHelper.contract.End_Date__c);          
        mediaSpending2 = TestHelper.createMediaSpendings(TestHelper.contract.Id, TestHelper.contract.End_Date__c.addDays(-1));  
              
        insert new List<MM_Spendings__c> {mediaSpending1, mediaSpending2};


        List<MM_Spendings__c> originalMMSpends =  [select ID FROM MM_Spendings__c];
        system.assertEquals(2,originalMMSpends.size());
        
        Test.startTest();
        Database.executeBatch(new SCH_BATCH_MediaSpendSummarizer());
        Test.stopTest();
        
        List<MM_Spendings__c> summarizedMMSpends =  [select ID FROM MM_Spendings__c];
        system.assertEquals(1,summarizedMMSpends.size());
             
    }
    
    testmethod static void summarizePMS() {
        MM_Spendings__c mediaSpending1;
        MM_Spendings__c mediaSpending2;
        Set<String> strikeIds;
        Map<Id, MM_Spendings__c> mediaSpendings;
        Map<Id, Project_Media_Spend__c> contractSpendingForMediaManagerSpending;   
        strikeIds = new Set<String>();
        mediaSpendings = new Map<Id, MM_Spendings__c>();
        contractSpendingForMediaManagerSpending= new Map<Id, Project_Media_Spend__c>(); 
        
        TestHelper.setupEnv();
		Project__c contract = TestHelper.contract; 
                
        mediaSpending1 = TestHelper.createMediaSpendings(TestHelper.contract.Id, TestHelper.contract.End_Date__c);          
        mediaSpending2 = TestHelper.createMediaSpendings(TestHelper.contract.Id, TestHelper.contract.End_Date__c.addDays(-1));  
              
        insert new List<MM_Spendings__c> {mediaSpending1, mediaSpending2};
            
        List<Project_Media_Spend__c> originalPMS =  [SELECT Delivered__c, Amount__c, Project__r.ProjectID__c, Date__c, MMSpending__c 
                                                          FROM Project_Media_Spend__c];
        system.assertEquals(2,originalPMS.size());
        
        Test.startTest();
        Database.executeBatch(new SCH_BATCH_MediaSpendSummarizer());
        Test.stopTest();
        
        List<Project_Media_Spend__c> summarizedPMS =  [SELECT Delivered__c, Amount__c, Project__r.ProjectID__c, Date__c, MMSpending__c 
                                                          FROM Project_Media_Spend__c];
        system.assertEquals(1,summarizedPMS.size());
           
    }    
    
    testmethod static void setLookupsOnSummarizedRecords() {
        MM_Spendings__c mediaSpending1;
        MM_Spendings__c mediaSpending2;
        Set<String> strikeIds;
        Map<Id, MM_Spendings__c> mediaSpendings;
        Map<Id, Project_Media_Spend__c> contractSpendingForMediaManagerSpending;   
        strikeIds = new Set<String>();
        mediaSpendings = new Map<Id, MM_Spendings__c>();
        contractSpendingForMediaManagerSpending= new Map<Id, Project_Media_Spend__c>(); 
        
        TestHelper.setupEnv();
		Project__c contract = TestHelper.contract; 
                
        mediaSpending1 = TestHelper.createMediaSpendings(TestHelper.contract.Id, TestHelper.contract.End_Date__c);          
        mediaSpending2 = TestHelper.createMediaSpendings(TestHelper.contract.Id, TestHelper.contract.End_Date__c.addDays(-1));  
              
        insert new List<MM_Spendings__c> {mediaSpending1, mediaSpending2};
            
        Test.startTest();
        Database.executeBatch(new SCH_BATCH_MediaSpendSummarizer());
        Test.stopTest();
        
        List<MM_Spendings__c> summarizedMMSpends =  [select ID FROM MM_Spendings__c];
        List<Project_Media_Spend__c> summarizedPMS =  [SELECT Delivered__c, Amount__c, Project__r.ProjectID__c, Date__c, MMSpending__c 
                                                          FROM Project_Media_Spend__c];
        
        system.assertEquals(summarizedMMSpends[0].Id, summarizedPMS[0].MMSpending__c);        
    }        
}