@isTest
private class OpportunityAdPlacementHandlerTest
{
    static testMethod void willAssignToContractOnInsertWhenOpportunityDefined()
    {
        User usr = TestHelper.createUser();
        Account acc = TestHelper.createAccount();
        
        Opportunity opp = TestHelper.createOpportunity(usr, acc);        
        insert opp;
        
        Project__c contract = TestHelper.createContract(acc.Id, 'testContract', opp.Id);
        
        test.startTest();
        
            Platform__c platform = TestHelper.getTrueViewPlatform();
            
            OpportunityPlatform__c oppPlatform = TestHelper.createOpportunityPlatform(opp.Id, platform.Id);
            insert oppPlatform; 
            
            AdPlacement__c adPlacement = TestHelper.createAdPlacement(platform.Id, 'InStream');
            insert adPlacement;
        
            OpportunityAdPlacement__c oppAdPlacement = TestHelper.createOpportunityAdPlacement(opp.Id, adPlacement.Id);
            oppAdPlacement.OpportunityPlatform__c = oppPlatform.Id;
            insert oppAdPlacement;         
        
        test.stopTest();
        
        System.assertEquals(contract.Id, [SELECT Contract__c FROM OpportunityAdPlacement__c WHERE Id = :oppAdPlacement.Id].Contract__c);
    }
    
    static testMethod void willAssignToOpportunityOnInsertWhenContractDefined()
    {
        User usr = TestHelper.createUser();
        Account acc = TestHelper.createAccount();
        
        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        insert opp;
        
        Project__c contract = TestHelper.createContract(acc.Id, 'testContract', opp.Id);
        
        test.startTest();
        
            Platform__c platform = TestHelper.getTrueViewPlatform();

            OpportunityPlatform__c oppPlatform = TestHelper.createOpportunityPlatform(opp.Id, platform.Id);
            insert oppPlatform; 
        
            AdPlacement__c adPlacement = TestHelper.createAdPlacement(platform.Id, 'InStream');
            insert adPlacement;
        
            OpportunityAdPlacement__c oppAdPlacement = TestHelper.createOpportunityAdPlacement(NULL, adPlacement.Id);
            oppAdPlacement.Contract__c = contract.Id;
            oppAdPlacement.OpportunityPlatform__c = oppPlatform.Id;
            insert oppAdPlacement;         
        
        test.stopTest();
        
        System.assertEquals(opp.Id, [SELECT Opportunity__c FROM OpportunityAdPlacement__c WHERE Id = :oppAdPlacement.Id].Opportunity__c);
    }
}