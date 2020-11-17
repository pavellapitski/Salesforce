@IsTest
private class ContractNotificationTest {

    @IsTest private static void testPrepareSalesRepNotifications() {
        TestHelper.createAppSettings();
        Account acc = TestHelper.createAccount();
        insert TestHelper.brandRecord;

        Project__c contract1 = TestHelper.createContractNoInsert(acc.Id, 'testContract', null);
        contract1.Start_Date__c = System.today().addDays(ContractRepository.preLaunchNotificationAdvance);
        contract1.End_Date__c = contract1.Start_Date__c.addDays(30);
        contract1.Brand__c = TestHelper.brandRecord.Id;

        Project__c contract2 = TestHelper.createContractNoInsert(acc.Id, 'testContract', null);
        contract2.Start_Date__c = System.today().addDays(ContractRepository.preLaunchNotificationAdvance);
        contract2.End_Date__c = contract2.Start_Date__c.addDays(30);
        contract2.Brand__c = TestHelper.brandRecord.Id;

        Project__c contract3 = TestHelper.createContractNoInsert(acc.Id, 'testContract', null);
        contract3.Start_Date__c = contract1.Start_Date__c.addDays(10);
        contract3.End_Date__c = contract3.Start_Date__c.addDays(30);
        contract3.Brand__c = TestHelper.brandRecord.Id;

        insert new List<Project__c> {contract1, contract2, contract3};

        Contract_Sales_Rep__c salesRep1 = TestHelper.createContractSalesRepNoInsert(contract1.Id);
        Contract_Sales_Rep__c salesRep2 = TestHelper.createContractSalesRepNoInsert(contract2.Id);
        Contract_Sales_Rep__c salesRep3 = TestHelper.createContractSalesRepNoInsert(contract3.Id);
        insert new List<Contract_Sales_Rep__c> {salesRep1, salesRep2, salesRep3};

        Test.startTest();

        System.assertNotEquals(salesRep1.Commission_Profile__c, salesRep2.Commission_Profile__c);
        System.assertNotEquals(salesRep2.Commission_Profile__c, salesRep3.Commission_Profile__c);

        List<Messaging.SingleEmailMessage> salesrepNotifications = ContractNotification.getSalesRepNotifications(new List<Contact>());

        Test.stopTest();

        Set<String> whatIds = new Set<String>();

        for (Messaging.SingleEmailMessage message : salesrepNotifications) {
            whatIds.add(message.getWhatId());
        }

        System.assertEquals(2, salesrepNotifications.size());
        System.assert(whatIds.contains(salesRep1.Commission_Profile__c));
        System.assert(whatIds.contains(salesRep2.Commission_Profile__c));
        System.assert(!whatIds.contains(salesRep3.Commission_Profile__c));
    }

    @IsTest private static void testPrepareCSRepNotifications() {
        TestHelper.createAppSettings();
        Account acc = TestHelper.createAccount();
        insert TestHelper.brandRecord;

        User clientServicesRep1 = TestHelper.createClientServiceUserNoInsert();
        clientServicesRep1.UserName += '1';
        User clientServicesRep2 = TestHelper.createClientServiceUserNoInsert();
        clientServicesRep2.UserName += '2';
        User clientServicesRep3 = TestHelper.createClientServiceUserNoInsert();
        clientServicesRep3.UserName += '3';
        insert new List<User> {clientServicesRep1, clientServicesRep2, clientServicesRep3};

        Project__c contract1 = TestHelper.createContractNoInsert(acc.Id, 'testContract', null);
        contract1.Start_Date__c = System.today().addDays(ContractRepository.preLaunchNotificationAdvance);
        contract1.End_Date__c = contract1.Start_Date__c.addDays(30);
        contract1.ClientServicesRep__c = clientServicesRep1.Id;
        contract1.Brand__c = TestHelper.brandRecord.Id;

        Project__c contract2 = TestHelper.createContractNoInsert(acc.Id, 'testContract', null);
        contract2.Start_Date__c = System.today().addDays(ContractRepository.preLaunchNotificationAdvance);
        contract2.End_Date__c = contract2.Start_Date__c.addDays(30);
        contract2.ClientServicesRep__c = clientServicesRep2.Id;
        contract2.Brand__c = TestHelper.brandRecord.Id;

        Project__c contract3 = TestHelper.createContractNoInsert(acc.Id, 'testContract', null);
        contract3.Start_Date__c = contract1.Start_Date__c.addDays(10);
        contract3.End_Date__c = contract3.Start_Date__c.addDays(30);
        contract3.ClientServicesRep__c = clientServicesRep3.Id;
        contract3.Brand__c = TestHelper.brandRecord.Id;

        insert new List<Project__c> {contract1, contract2, contract3};

        Test.startTest();

        System.assertNotEquals(contract1.ClientServicesRep__c, contract2.ClientServicesRep__c);
        System.assertNotEquals(contract2.ClientServicesRep__c, contract3.ClientServicesRep__c);

        List<Messaging.SingleEmailMessage> clientServiceNotifications = ContractNotification.getClientServiceNotifications(new List<Contact>());

        Test.stopTest();

        Set<String> whatIds = new Set<String>();

        for (Messaging.SingleEmailMessage message : clientServiceNotifications) {
            whatIds.add(message.getWhatId());
        }

        System.assertEquals(2, clientServiceNotifications.size());
        System.assert(whatIds.contains(clientServicesRep1.Id));
        System.assert(whatIds.contains(clientServicesRep2.Id));
        System.assert(!whatIds.contains(clientServicesRep3.Id));
    }

    @IsTest private static void testSendSalesRepNotifications() {
        TestHelper.createAppSettings();
        insert TestHelper.brandRecord;
        Account acc = TestHelper.createAccount();
    
        Project__c contract1 = TestHelper.createContractNoInsert(acc.Id, 'testContract', null);
        contract1.Start_Date__c = System.today().addDays(ContractRepository.preLaunchNotificationAdvance);
        contract1.End_Date__c = contract1.Start_Date__c.addDays(30);
        contract1.Brand__c = TestHelper.brandRecord.Id;
        
        Project__c contract2 = TestHelper.createContractNoInsert(acc.Id, 'testContract', null);
        contract2.Start_Date__c = System.today().addDays(ContractRepository.preLaunchNotificationAdvance);
        contract2.End_Date__c = contract2.Start_Date__c.addDays(30);
        contract2.Brand__c = TestHelper.brandRecord.Id;

        insert new List<Project__c> {contract1, contract2};
        
        Contract_Sales_Rep__c salesRep1 = TestHelper.createContractSalesRepNoInsert(contract1.Id);
        Contract_Sales_Rep__c salesRep2 = TestHelper.createContractSalesRepNoInsert(contract1.Id);
        Contract_Sales_Rep__c salesRep3 = TestHelper.createContractSalesRepNoInsert(contract1.Id);
        Contract_Sales_Rep__c salesRep4 = TestHelper.createContractSalesRepNoInsert(contract1.Id);
        Contract_Sales_Rep__c salesRep5 = TestHelper.createContractSalesRepNoInsert(contract1.Id);
        Contract_Sales_Rep__c salesRep6 = TestHelper.createContractSalesRepNoInsert(contract1.Id);
        Contract_Sales_Rep__c salesRep7 = TestHelper.createContractSalesRepNoInsert(contract2.Id);
        Contract_Sales_Rep__c salesRep8 = TestHelper.createContractSalesRepNoInsert(contract2.Id);
        Contract_Sales_Rep__c salesRep9 = TestHelper.createContractSalesRepNoInsert(contract2.Id);
        Contract_Sales_Rep__c salesRep10 = TestHelper.createContractSalesRepNoInsert(contract2.Id);
        Contract_Sales_Rep__c salesRep11 = TestHelper.createContractSalesRepNoInsert(contract2.Id);
        Contract_Sales_Rep__c salesRep12 = TestHelper.createContractSalesRepNoInsert(contract2.Id);

        insert new List<Contract_Sales_Rep__c> {salesRep1, salesRep2, salesRep3, salesRep4, salesRep5, salesRep6, salesRep7, salesRep8, salesRep9, salesRep10, salesRep11, salesRep12};
        
        Test.startTest();
        List<NotificationUtil.NotificationResult> notificationResults = ContractNotification.sendSalesRepNotifications();
        System.assertEquals(2, Limits.getEmailInvocations());
        Test.stopTest();
        
        System.assertEquals(12, notificationResults.size());
        for (NotificationUtil.NotificationResult result : notificationResults) {
            System.assert(result.isSuccess);
        }
    }

    @IsTest private static void testSendCSRepNotifications() {
        TestHelper.createAppSettings();

        insert TestHelper.brandRecord;
        Account acc = TestHelper.createAccount();
        
        User clientServicesRep1 = TestHelper.createClientServiceUserNoInsert();
        clientServicesRep1.UserName += '1';
        User clientServicesRep2 = TestHelper.createClientServiceUserNoInsert();
        clientServicesRep2.UserName += '2';
        User clientServicesRep3 = TestHelper.createClientServiceUserNoInsert();
        clientServicesRep3.UserName += '3';
        insert new List<User> {clientServicesRep1, clientServicesRep2, clientServicesRep3};
    
        Project__c contract1 = TestHelper.createContractNoInsert(acc.Id, 'testContract', null);
        contract1.Start_Date__c = System.today().addDays(ContractRepository.preLaunchNotificationAdvance);
        contract1.End_Date__c = contract1.Start_Date__c.addDays(30);
        contract1.ClientServicesRep__c = clientServicesRep1.Id;
        contract1.Brand__c = TestHelper.brandRecord.Id;
        
        Project__c contract2 = TestHelper.createContractNoInsert(acc.Id, 'testContract', null);
        contract2.Start_Date__c = System.today().addDays(ContractRepository.preLaunchNotificationAdvance);
        contract2.End_Date__c = contract2.Start_Date__c.addDays(30);
        contract2.ClientServicesRep__c = clientServicesRep2.Id;
        contract2.Brand__c = TestHelper.brandRecord.Id;
        
        Project__c contract3 = TestHelper.createContractNoInsert(acc.Id, 'testContract', null);
        contract3.Start_Date__c = System.today().addDays(ContractRepository.preLaunchNotificationAdvance).addDays(1);
        contract3.End_Date__c = contract3.Start_Date__c.addDays(30);
        contract3.ClientServicesRep__c = clientServicesRep3.Id;
        contract3.Brand__c = TestHelper.brandRecord.Id;

        insert new List<Project__c> {contract1, contract2, contract3};

        Test.startTest();
        List<NotificationUtil.NotificationResult> notificationResults = ContractNotification.sendCSRepNotifications();
        Test.stopTest();
        
        System.assertEquals(2, notificationResults.size());
        
        for (NotificationUtil.NotificationResult result : notificationResults) {
            System.assert(result.isSuccess);
        }
    }
}