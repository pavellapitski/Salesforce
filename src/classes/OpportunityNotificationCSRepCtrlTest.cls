@isTest
private class OpportunityNotificationCSRepCtrlTest
{
    private static testMethod void testDisplayClosingOpportunities()
    {
        Account acc = TestHelper.createAccount();
        User clientServicesRep = TestHelper.createClientServiceUser();
    
        //Correct
        Opportunity opp1 = TestHelper.createOpportunity(clientServicesRep, acc); 
        opp1.CloseDate = System.Today().addDays(30);
        opp1.ClientServicesRep__c = clientServicesRep.Id;
        opp1.Name = 'opp1';
        
        //Wrong date
        Opportunity opp2 = TestHelper.createOpportunity(clientServicesRep, acc);
        opp2.CloseDate = opp1.CloseDate.addDays(1);
        opp2.ClientServicesRep__c = clientServicesRep.Id;
        opp2.Name = 'opp2';
        
        //No client service rep
        Opportunity opp3 = TestHelper.createOpportunity(clientServicesRep, acc);
        opp3.CloseDate = opp1.CloseDate;
        opp3.Name = 'opp3';
    
        //Correct
        Opportunity opp4 = TestHelper.createOpportunity(clientServicesRep, acc);
        opp4.CloseDate = opp1.CloseDate;
        opp4.ClientServicesRep__c = clientServicesRep.Id;
        opp4.Name = 'opp4';
        
        insert new List<Opportunity> {opp1, opp2, opp3, opp4}; 
        
        test.startTest(); 
        
            OpportunityNotificationCSRepCtrl controller = new OpportunityNotificationCSRepCtrl();
            controller.clientService = clientServicesRep.Id;
            controller.notificationAdvance = 30;
            
            List<Opportunity> opportunities = controller.getClosingOpportunities(); 
        
        test.stopTest();
        
        System.assertEquals(2, opportunities.size());
        System.assertEquals(opp1.Id, opportunities[0].Id);
        System.assertEquals(opp4.Id, opportunities[1].Id);
    }
}