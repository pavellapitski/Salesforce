@isTest
private class SubProjectNotificationTest {

    private static Opportunity opp1;
    private static Opportunity opp2;
    private static Opportunity opp3;

    private static user clientServicesRep1;
    private static user clientServicesRep2;
    private static user clientServicesRep3;

    private static void closeOpportunities()
    {
        opp1.StageName = 'Closed Won';
        opp2.StageName = 'Closed Won';
        opp3.StageName = 'Closed Won';
        update new List<Opportunity> {opp1, opp2, opp3};
    }

    private static void setupCSReps()
    {
        clientServicesRep1 = TestHelper.createClientServiceUserNoInsert();
        clientServicesRep1.UserName += '1';
        clientServicesRep2 = TestHelper.createClientServiceUserNoInsert();
        clientServicesRep2.UserName += '2';
        clientServicesRep3 = TestHelper.createClientServiceUserNoInsert();
        clientServicesRep3.UserName += '3';
        insert new List<User> {clientServicesRep1, clientServicesRep2, clientServicesRep3};
    }
    
    private static void setupOpportunities()
    {
        Account acc = TestHelper.createAccount();
        Brand__c brand = TestHelper.createBrand('testBrand');
        User usr = TestHelper.createUser();
    
        opp1 = TestHelper.createOpportunity(usr, acc);  
        opp1.Account_Type__c = 'Client';
        opp1.Brand__c = brand.Id;
        opp1.ClientServicesRep__c = clientServicesRep1.Id;
        
        opp2 = TestHelper.createOpportunity(usr, acc);  
        opp2.Account_Type__c = 'Client';
        opp2.Brand__c = brand.Id;
        opp2.ClientServicesRep__c = clientServicesRep2.Id;
        
        opp3 = TestHelper.createOpportunity(usr, acc);  
        opp3.Account_Type__c = 'Client';
        opp3.Brand__c = brand.Id;
        opp3.ClientServicesRep__c = clientServicesRep3.Id;
    }
    
    private static void setupPlatforms()
    {
        Platform__c platformTV = TestHelper.getTrueViewPlatform();
        
        OpportunityPlatform__c opp1Platform = TestHelper.createOpportunityPlatform(opp1.Id, platformTV.Id);
        opp1Platform.CostStructure__c = 'CPV';
        OpportunityPlatform__c opp2Platform = TestHelper.createOpportunityPlatform(opp2.Id, platformTV.Id);
        opp2Platform.CostStructure__c = 'CPV';
        OpportunityPlatform__c opp3Platform = TestHelper.createOpportunityPlatform(opp3.Id, platformTV.Id);
        opp3Platform.CostStructure__c = 'CPV';
        
        insert new List<OpportunityPlatform__c> {opp1Platform, opp2Platform, opp3Platform}; 
    }

    static testMethod void willSendNotificationWhenLastMediaSpendDelivered()
    {
        Date today = System.today();
        
        TestHelper.createAppSettings();
        
        setupCSReps();
        
        setupOpportunities();
        
        insert new List<Opportunity> {opp1, opp2, opp3};
        
        setupPlatforms();
        
        closeOpportunities();
        
        Project__c contract1 = [SELECT Id FROM Project__c WHERE Opportunity__c = :opp1.Id];
        Project__c contract2 = [SELECT Id FROM Project__c WHERE Opportunity__c = :opp2.Id];
        
        Sub_Project__c payment1 = [SELECT Id, End_Date__c FROM Sub_Project__c WHERE Project__c = :contract1.Id LIMIT 1];
        Sub_Project__c payment2 = [SELECT Id, End_Date__c FROM Sub_Project__c WHERE Project__c = :contract2.Id LIMIT 1];
        
        CreditNote__c creditNote = TestHelper.createCreditNoteNoInsert(payment1.Id);
        insert creditNote;
        
        test.startTest();
        
            System.assertEquals(false, [SELECT InvoiceNotificationSent__c FROM Sub_Project__c WHERE Id = :payment1.Id].InvoiceNotificationSent__c);
            
            MM_Spendings__c mmSpending = TestHelper.createMediaSpendings(contract1.Id, payment1.End_Date__c);
            insert mmSpending;
        
            SubProjectNotification.sendPaymentsNotification();
        	SubProjectNotification.sendCreditNotesNotification();
        
        test.stopTest();
        
        System.assertEquals(true, [SELECT InvoiceNotificationSent__c FROM Sub_Project__c WHERE Id = :payment1.Id].InvoiceNotificationSent__c);
        System.assertEquals(false, [SELECT InvoiceNotificationSent__c FROM Sub_Project__c WHERE Id = :payment2.Id].InvoiceNotificationSent__c);
    }
    
    private static testMethod void testPrepareInvoiceNotifications() 
    {
        TestHelper.createAppSettings();

        setupCSReps();
        
        setupOpportunities();
        
        insert new List<Opportunity> {opp1, opp2, opp3};
        
        setupPlatforms();
        
        closeOpportunities();
        
        Project__c contract1 = [SELECT Id, End_Date__c, ClientServicesRep__c FROM Project__c WHERE Opportunity__c = :opp1.Id];
        Project__c contract2 = [SELECT Id, End_Date__c, ClientServicesRep__c FROM Project__c WHERE Opportunity__c = :opp2.Id];
        Project__c contract3 = [SELECT Id, End_Date__c, ClientServicesRep__c FROM Project__c WHERE Opportunity__c = :opp3.Id];
        
        test.startTest();
        
            System.assertNotEquals(contract1.ClientServicesRep__c, contract2.ClientServicesRep__c);
            System.assertNotEquals(contract2.ClientServicesRep__c, contract3.ClientServicesRep__c);
            
            MM_Spendings__c spend1 = TestHelper.createMediaSpendings(contract1.Id, contract1.End_Date__c);
            spend1.Media_Spend__c = 150000;
            MM_Spendings__c spend2 = TestHelper.createMediaSpendings(contract2.Id, contract2.End_Date__c);
            spend2.Media_Spend__c = 150000;
            
            insert new List<MM_Spendings__c> {spend1, spend2};
        
            List<Messaging.SingleEmailMessage> clientServiceNotifications = SubProjectNotification.getPaymentNotifications(new List<Contact>()); 
            
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
    
}