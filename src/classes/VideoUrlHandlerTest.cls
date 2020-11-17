@isTest
private class VideoUrlHandlerTest 
{
    static testMethod void willWillAssignToContractOnInsertWhenOpportunityDefined()
    {
        User usr = TestHelper.createUser();
        Account acc = TestHelper.createAccount();
        
        Opportunity opp = TestHelper.createOpportunity(usr, acc);        
        insert opp;
        
        Project__c contract = TestHelper.createContract(acc.Id, 'testContract', opp.Id);
        
        test.startTest();
        
            VideoUrl__c url = TestHelper.createVideoUrl();
            url.Opportunity__c = opp.Id;
       		url.Platform__c = 'TrueView';
	        url.Format__c = 'Video';
            url.StartDate__c = opp.Flight_Start__c;
            url.EndDate__c = opp.Flight_End__c;
            insert url;         
        
        test.stopTest();
        
        System.assertEquals(contract.Id, [SELECT Contract__c FROM VideoUrl__c WHERE Id = :url.Id].Contract__c);
    }
    
    static testMethod void willWillAssignToOpportunityOnInsertWhenContractDefined()
    {
        User usr = TestHelper.createUser();
        Account acc = TestHelper.createAccount();
        
        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        insert opp;
        
        Project__c contract = TestHelper.createContract(acc.Id, 'testContract', opp.Id);
        
        test.startTest();
        
            VideoUrl__c url = TestHelper.createVideoUrl();
            url.Contract__c = contract.Id;
       		url.Platform__c = 'TrueView';
	        url.Format__c = 'Video';
            url.StartDate__c = opp.Flight_Start__c;
            url.EndDate__c = opp.Flight_End__c;
            insert url;         
        
        test.stopTest();
        
        System.assertEquals(opp.Id, [SELECT Opportunity__c FROM VideoUrl__c WHERE Id = :url.Id].Opportunity__c);
    }
    
    static testMethod void willSetPerformMMSyncOnInsert()
    {
        Account acc = TestHelper.createAccount();
        
        Project__c contractSynced = TestHelper.createContractNoInsert(acc.Id, 'syncedWithMM', NULL);
        contractSynced.Sync_with_MM__c = System.Now();
        Project__c contractNotSynced = TestHelper.createContractNoInsert(acc.Id, 'notSyncedWithMM', NULL);
        insert new List<Project__c> { contractSynced, contractNotSynced };
        
        contractSynced.PerformMMSync__c = false;
        update contractSynced;
        
        test.startTest();
            
            System.assertEquals(false, [SELECT PerformMMSync__c FROM Project__c WHERE Id = :contractSynced.Id].PerformMMSync__c);
            System.assertEquals(false, [SELECT PerformMMSync__c FROM Project__c WHERE Id = :contractNotSynced.Id].PerformMMSync__c);
            
            VideoUrl__c url1 = TestHelper.createVideoUrl();
            url1.Contract__c = contractSynced.Id;
       		url1.Platform__c = 'TrueView';
	        url1.Format__c = 'Video';
        	url1.StartDate__c = contractSynced.Start_Date__c;
            url1.EndDate__c = contractSynced.End_Date__c;
            
            VideoUrl__c url2 = TestHelper.createVideoUrl();
            url2.Contract__c = contractNotSynced.Id;
       		url2.Platform__c = 'TrueView';
	        url2.Format__c = 'Video';
        	url2.StartDate__c = contractNotSynced.Start_Date__c;
            url2.EndDate__c = contractNotSynced.End_Date__c;
            
            insert new List<VideoUrl__c> { url1, url2 };   
        
        test.stopTest();
        
        System.assertEquals(true, [SELECT PerformMMSync__c FROM Project__c WHERE Id = :contractSynced.Id].PerformMMSync__c);
        System.assertEquals(false, [SELECT PerformMMSync__c FROM Project__c WHERE Id = :contractNotSynced.Id].PerformMMSync__c);
    }
    
    static testMethod void willSetPerformMMSyncOnUpdate()
    {
        Account acc = TestHelper.createAccount();
        
        Project__c contractSynced1 = TestHelper.createContractNoInsert(acc.Id, 'syncedWithMM', NULL);
        contractSynced1.Sync_with_MM__c = System.Now();
        
        Project__c contractSynced2 = TestHelper.createContractNoInsert(acc.Id, 'syncedWithMM', NULL);
        contractSynced2.Sync_with_MM__c = System.Now();
        
        Project__c contractNotSynced = TestHelper.createContractNoInsert(acc.Id, 'notSyncedWithMM', NULL);
        
        insert new List<Project__c> { contractSynced1, contractSynced2, contractNotSynced };
        
        test.startTest();

            VideoUrl__c url1 = TestHelper.createVideoUrl();
            url1.Contract__c = contractSynced1.Id;
       		url1.Platform__c = 'TrueView';
	        url1.Format__c = 'Video';
        	url1.StartDate__c = contractSynced1.Start_Date__c;
            url1.EndDate__c = contractSynced1.End_Date__c;
            
            VideoUrl__c url2 = TestHelper.createVideoUrl();
            url2.Contract__c = contractSynced2.Id;
       		url2.Platform__c = 'TrueView';
	        url2.Format__c = 'Video';
        	url2.StartDate__c = contractSynced2.Start_Date__c;
            url2.EndDate__c = contractSynced2.End_Date__c;
            
            VideoUrl__c url3 = TestHelper.createVideoUrl();
            url3.Contract__c = contractNotSynced.Id;
       		url3.Platform__c = 'TrueView';
	        url3.Format__c = 'Video';
        	url3.StartDate__c = contractNotSynced.Start_Date__c;
            url3.EndDate__c = contractNotSynced.End_Date__c;
            
            insert new List<VideoUrl__c> { url1, url2, url3 };  
            
            contractSynced1.PerformMMSync__c = false;
            contractSynced2.PerformMMSync__c = false;
            contractNotSynced.PerformMMSync__c = false;
        
            update new List<Project__c> {contractSynced1, contractSynced2, contractNotSynced};
        
            url1.Url__c += '123';
            url3.Url__c += '456';
            
            update new List<VideoUrl__c> { url1, url2, url3 };
        
        test.stopTest();
        
        System.assertEquals(true, [SELECT PerformMMSync__c FROM Project__c WHERE Id = :contractSynced1.Id].PerformMMSync__c);
        System.assertEquals(false, [SELECT PerformMMSync__c FROM Project__c WHERE Id = :contractSynced2.Id].PerformMMSync__c);
        System.assertEquals(false, [SELECT PerformMMSync__c FROM Project__c WHERE Id = :contractNotSynced.Id].PerformMMSync__c);
    }
    
    static testMethod void willAssignSalesforceID() {
        Account acc          = TestHelper.createAccount();
        Brand__c brand             = TestHelper.createBrand('testBrand');
        Brand_Account__c brandAcc  = TestHelper.createBrandAccount(acc.Id, brand.Id);
        
        Project__c contract1 = TestHelper.createContractNoInsert(acc.Id, 'syncedWithMM', NULL);
        
        insert new List<Project__c> { contract1 };
            
            VideoUrl__c url1 = TestHelper.createVideoUrl();
            url1.Contract__c = contract1.Id;
       		url1.Platform__c = 'TrueView';
	        url1.Format__c = 'Video';
        	url1.StartDate__c = System.today();
            url1.EndDate__c = System.today()+1;
        	url1.Salesforce_ID__c = '906F00000008zgyIAA';
        Test.startTest();
        insert url1;
        Test.stopTest();
        
        url1 = [SELECT Salesforce_ID__c FROM VideoUrl__c WHERE Id = :url1.Id];
        
        //System.assert(!string.isBlank(url1.Salesforce_ID__c));
        //System.assertEquals(url1.Id, url1.Salesforce_ID__c);
    }
}