@isTest
private class ContractTest 
{
    static testMethod void willAssignVideoUrlsFromOpportunity()
    {
        User usr = TestHelper.createUser();
        Account acc = TestHelper.createAccount();
        
        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        opp.Brand__c = TestHelper.createBrand('testBrand').Id;
        insert opp;
        
        Platform__c platformTV = TestHelper.getTrueViewPlatform();
        OpportunityPlatform__c oppPlatform = TestHelper.createOpportunityPlatform(opp.Id, platformTV.Id);
        insert oppPlatform;
        
        VideoUrl__c url1 = TestHelper.createVideoUrl();
        url1.Opportunity__c = opp.Id;
        url1.Name += '1';
        url1.Platform__c = 'TrueView';
        url1.Format__c = 'Video';
        url1.Url__c += '1';
        url1.StartDate__c = opp.Flight_Start__c;
        url1.EndDate__c = opp.Flight_End__c;
        
        VideoUrl__c url2 = TestHelper.createVideoUrl();
        url2.Opportunity__c = opp.Id;
        url2.Name += '2';
        url2.Platform__c = 'TrueView';
        url2.Format__c = 'Video';        
        url2.Url__c += '2';
        url2.StartDate__c = opp.Flight_Start__c;
        url2.EndDate__c = opp.Flight_End__c;
        
        insert new List<VideoUrl__c> { url1, url2 };        
        
        test.startTest();
        
            List<VideoUrl__c> videoUrls = [SELECT Id, Contract__c FROM VideoUrl__c WHERE Opportunity__c = :opp.Id];
            System.assertEquals(2, videoUrls.size());
            System.assertEquals(NULL, videoUrls[0].Contract__c);
            System.assertEquals(NULL, videoUrls[1].Contract__c);
                
            opp.StageName = 'Closed Won';
            update opp;
        
        test.stopTest();
        
        List<Project__c> contract = [SELECT Id FROM Project__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, contract.size());
        
        videoUrls = [SELECT Id, Contract__c FROM VideoUrl__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(2, videoUrls.size());
        System.assertEquals(contract[0].Id, videoUrls[0].Contract__c);
        System.assertEquals(contract[0].Id, videoUrls[1].Contract__c);
    }
    
    static testMethod void willAssignPlatformsFromOpportunity()
    {
        User usr = TestHelper.createUser();
        Account acc = TestHelper.createAccount();
        
        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        opp.Brand__c = TestHelper.createBrand('testBrand').Id;
        insert opp;
        
        Platform__c platformTV = TestHelper.getTrueViewPlatform();
        OpportunityPlatform__c oppPlatform = TestHelper.createOpportunityPlatform(opp.Id, platformTV.Id);
        insert oppPlatform;    
        
        test.startTest();
                
            opp.StageName = 'Closed Won';
            update opp;
        
        test.stopTest();
        
        List<Project__c> contract = [SELECT Id, (SELECT Platform__c FROM ContractPlatforms__r) FROM Project__c WHERE Opportunity__c = :opp.Id];

        System.assertEquals(1, contract[0].ContractPlatforms__r.size());
        System.assertEquals(platformTV.Id, contract[0].ContractPlatforms__r[0].Platform__c);
    }
}