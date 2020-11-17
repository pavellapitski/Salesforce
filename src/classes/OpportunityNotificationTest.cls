@isTest
private class OpportunityNotificationTest
{
    private static testMethod void testPrepareSalesRepNotifications() 
    {
        TestHelper.createAppSettings();
        Account acc = TestHelper.createAccount();
        
        User salesRepUser1 = TestHelper.createUser('salesrep1@salesforce.com' + math.random());
        User salesRepUser2 = TestHelper.createUser('salesrep2@salesforce.com' + math.random());
        User salesRepUser3 = TestHelper.createUser('salesrep3@salesforce.com' + math.random());
    
        Opportunity opp1 = TestHelper.createOpportunity(salesRepUser1, acc); 
        opp1.CloseDate = System.Today().addDays(30);

        Opportunity opp2 = TestHelper.createOpportunity(salesRepUser2, acc); 
        opp2.CloseDate = System.Today().addDays(30);

        Opportunity opp3 = TestHelper.createOpportunity(salesRepUser3, acc); 
        opp3.CloseDate = opp1.CloseDate.addDays(10);

        insert new List<Opportunity> {opp1, opp2, opp3};
        
        test.startTest();
        
            List<Messaging.SingleEmailMessage> salesrepNotifications = OpportunityNotification.getSalesRepNotifications(new List<Contact>(), 'OpportunitySalesRepReminder30Days', 30); 
            
        test.stopTest();
        
        Set<String> whatIds = new Set<String>();
        
        for (Messaging.SingleEmailMessage message : salesrepNotifications)
        {
            whatIds.add(message.getWhatId());
        }

        System.assertEquals(2, salesrepNotifications.size());
        System.assert(whatIds.contains(salesRepUser1.Id));
        System.assert(whatIds.contains(salesRepUser2.Id));
        System.assert(!whatIds.contains(salesRepUser3.Id));
    }
   
    private static testMethod void testPrepareCSRepNotifications() 
    {
        TestHelper.createAppSettings();
        Account acc = TestHelper.createAccount();
        
        User salesRepUser = TestHelper.createUser('salesrep@salesforce.com' + math.random());
        
        User clientServicesRep1 = TestHelper.createClientServiceUserNoInsert();
        clientServicesRep1.UserName += '1';
        User clientServicesRep2 = TestHelper.createClientServiceUserNoInsert();
        clientServicesRep2.UserName += '2';
        User clientServicesRep3 = TestHelper.createClientServiceUserNoInsert();
        clientServicesRep3.UserName += '3';
        insert new List<User> {clientServicesRep1, clientServicesRep2, clientServicesRep3};
    
        Opportunity opp1 = TestHelper.createOpportunity(salesRepUser, acc); 
        opp1.CloseDate = System.Today().addDays(30);
        opp1.ClientServicesRep__c = clientServicesRep1.Id;
        
        Opportunity opp2 = TestHelper.createOpportunity(salesRepUser, acc); 
        opp2.CloseDate = System.Today().addDays(30);
        opp2.ClientServicesRep__c = clientServicesRep2.Id;
        
        Opportunity opp3 = TestHelper.createOpportunity(salesRepUser, acc); 
        opp3.CloseDate = opp1.CloseDate.addDays(10);
        opp3.ClientServicesRep__c = clientServicesRep3.Id;
        
        insert new List<Opportunity> {opp1, opp2, opp3};
        
        test.startTest();
        
            System.assertNotEquals(opp1.ClientServicesRep__c, opp2.ClientServicesRep__c);
            System.assertNotEquals(opp2.ClientServicesRep__c, opp3.ClientServicesRep__c);
        
            List<Messaging.SingleEmailMessage> clientServiceNotifications = OpportunityNotification.getClientServiceNotifications(new List<Contact>(), 'OpportunityClientServiceReminder30Days', 30); 
            
        test.stopTest();
        
        Set<String> whatIds = new Set<String>();
        
        for (Messaging.SingleEmailMessage message : clientServiceNotifications)
        {
            whatIds.add(message.getWhatId());
        }

        System.assertEquals(2, clientServiceNotifications.size());
        System.assert(whatIds.contains(clientServicesRep1.Id));
        System.assert(whatIds.contains(clientServicesRep2.Id));
        System.assert(!whatIds.contains(clientServicesRep3.Id));
    }
    
    private static testMethod void testSendSalesRepNotifications()
    {
        TestHelper.createAppSettings();
        Account acc = TestHelper.createAccount();
        User salesRepUser1 = TestHelper.createUser('salesrep1p@salesforce.com' + math.random());
        User salesRepUser2 = TestHelper.createUser('salesrep2@salesforce.com' + math.random());
    
        Opportunity opp1 = TestHelper.createOpportunity(salesRepUser1, acc); 
        opp1.CloseDate = System.Today().addDays(30);

        Opportunity opp2 = TestHelper.createOpportunity(salesRepUser2, acc); 
        opp2.CloseDate = System.Today().addDays(30);

        insert new List<Opportunity> {opp1, opp2};
 
        test.startTest();
            List<NotificationUtil.NotificationResult> notificationResults = OpportunityNotification.sendSalesRepNotifications('OpportunitySalesRepReminder30Days', 30);  
        test.stopTest();
        
        System.assertEquals(2, notificationResults.size());
        for (NotificationUtil.NotificationResult result : notificationResults)
        {
            system.assert(result.isSuccess);
        }
    }
     
    private static testMethod void testSendCSRepNotifications()
    {
        TestHelper.createAppSettings();
        Account acc = TestHelper.createAccount();
        User salesRepUser = TestHelper.createUser('salesrep@salesforce.com' + math.random());
        
        User clientServicesRep1 = TestHelper.createClientServiceUserNoInsert();
        clientServicesRep1.UserName += '1';
        User clientServicesRep2 = TestHelper.createClientServiceUserNoInsert();
        clientServicesRep2.UserName += '2';
        User clientServicesRep3 = TestHelper.createClientServiceUserNoInsert();
        clientServicesRep3.UserName += '3';
        insert new List<User> {clientServicesRep1, clientServicesRep2, clientServicesRep3};
    
        Opportunity opp1 = TestHelper.createOpportunity(salesRepUser, acc); 
        opp1.CloseDate = System.Today().addDays(30);
        opp1.ClientServicesRep__c = clientServicesRep1.Id;
        
        Opportunity opp2 = TestHelper.createOpportunity(salesRepUser, acc); 
        opp2.CloseDate = System.Today().addDays(30);
        opp2.ClientServicesRep__c = clientServicesRep2.Id;
        
        Opportunity opp3 = TestHelper.createOpportunity(salesRepUser, acc); 
        opp3.CloseDate = System.Today().addDays(30).addDays(1);
        opp3.ClientServicesRep__c = clientServicesRep3.Id;

        insert new List<Opportunity> {opp1, opp2, opp3};
        
        test.startTest();
            List<NotificationUtil.NotificationResult> notificationResults = OpportunityNotification.sendCSRepNotifications('OpportunityClientServiceReminder30Days', 30); 
        test.stopTest();
        
        System.assertEquals(2, notificationResults.size());
        
        for (NotificationUtil.NotificationResult result : notificationResults)
        {
            system.assert(result.isSuccess);
        }
    }
}