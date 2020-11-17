@isTest
private class OpportunityNotificationSalesRepCtrlTest
{
    private static testMethod void testDisplayClosingOpportunities()
    {
        Account acc = TestHelper.createAccount();
        User salesRepUser1 = TestHelper.createUser('salesrep1@salesforce.com' + math.random());
        User salesRepUser2 = TestHelper.createUser('salesrep2@salesforce.com' + math.random());
    
        //Correct
        Opportunity opp1 = TestHelper.createOpportunity(salesRepUser1, acc); 
        opp1.Name = 'testOpp1';
        opp1.CloseDate = System.Today().addDays(30);

        //Wrong date
        Opportunity opp2 = TestHelper.createOpportunity(salesRepUser1, acc);
        opp2.Name = 'testOpp2';
        opp2.CloseDate = opp1.CloseDate.addDays(1);
        
        //Different Sales Rep
        Opportunity opp3 = TestHelper.createOpportunity(salesRepUser2, acc);
        opp3.Name = 'testOpp3';
        opp3.CloseDate = opp1.CloseDate;

        //Correct
        Opportunity opp4 = TestHelper.createOpportunity(salesRepUser1, acc);
        opp4.Name = 'testOpp4';
        opp4.CloseDate = opp1.CloseDate;

        insert new List<Opportunity> {opp1, opp2, opp3, opp4}; 
        
        test.startTest(); 
        
            OpportunityNotificationSalesRepCtrl controller = new OpportunityNotificationSalesRepCtrl();
            controller.salesRep = salesRepUser1.Id;
            controller.notificationAdvance = 30;
            
            List<Opportunity> opportunities = controller.getClosingOpportunities(); 
        
        test.stopTest();
        
        System.assertEquals(2, opportunities.size());
        System.assertEquals(opp1.Id, opportunities[0].Id);
        System.assertEquals(opp4.Id, opportunities[1].Id);
    }
}