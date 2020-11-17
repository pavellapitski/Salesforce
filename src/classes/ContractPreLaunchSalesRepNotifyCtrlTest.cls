@isTest
private class ContractPreLaunchSalesRepNotifyCtrlTest
{
    private static testMethod void testDisplayLaunchingContracts()
    {
        Account acc = TestHelper.createAccount();
    
        Project__c contract1 = TestHelper.createContractNoInsert(acc.Id, 'testContract1', NULL);
        contract1.Start_Date__c = System.Today().addDays(ContractRepository.prelaunchNotificationAdvance);
        contract1.End_Date__c = contract1.Start_Date__c.addDays(30);
        
        Project__c contract2 = TestHelper.createContractNoInsert(acc.Id, 'testContract2', NULL);
        contract2.Start_Date__c = contract1.Start_Date__c.addDays(1);
        contract2.End_Date__c = contract2.Start_Date__c.addDays(30);
        
        Project__c contract3 = TestHelper.createContractNoInsert(acc.Id, 'testContract3', NULL);
        contract3.Start_Date__c = contract1.Start_Date__c;
        contract3.End_Date__c = contract3.Start_Date__c.addDays(60);
        
        insert new List<Project__c> {contract1, contract2, contract3};
        
        Contract_Sales_Rep__c salesRep1 = TestHelper.createContractSalesRepNoInsert(contract1.Id);
        Contract_Sales_Rep__c salesRep2 = TestHelper.createContractSalesRepNoInsert(contract2.Id, salesRep1.Commission_Profile__c);
        Contract_Sales_Rep__c salesRep3 = TestHelper.createContractSalesRepNoInsert(contract3.Id, salesRep1.Commission_Profile__c);
        insert new List<Contract_Sales_Rep__c> {salesRep1, salesRep2, salesRep3};
        
        test.startTest();
        
            System.assertEquals(salesRep1.Commission_Profile__c, salesRep2.Commission_Profile__c);
        
            ContractPreLaunchSalesRepNotifyCtrl controller = new ContractPreLaunchSalesRepNotifyCtrl();
            controller.salesRep = salesRep1.Commission_Profile__c;
            
            List<Project__c> contracts = controller.getPreLaunchContracts(); 
        
        test.stopTest();
        
        System.assertEquals(2, contracts.size());
        System.assertEquals(contract1.Id, contracts[0].Id);
        System.assertEquals(contract3.Id, contracts[1].Id);
    }
}