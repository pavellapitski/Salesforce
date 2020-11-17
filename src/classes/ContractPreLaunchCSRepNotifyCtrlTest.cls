@IsTest
private class ContractPreLaunchCSRepNotifyCtrlTest  {

    @IsTest private static void testDisplayLaunchingContracts() {
        Account acc = TestHelper.createAccount();
        User clientServicesRep = TestHelper.createClientServiceUser();

        insert TestHelper.brandRecord;
    
        //Correct
        Project__c contract1 = TestHelper.createContractNoInsert(acc.Id, 'testContract1', null);
        contract1.Start_Date__c = System.today().addDays(ContractRepository.preLaunchNotificationAdvance);
        contract1.End_Date__c = contract1.Start_Date__c.addDays(30);
        contract1.ClientServicesRep__c = clientServicesRep.Id;
        contract1.Brand__c = TestHelper.brandRecord.Id;
        
        //Wrong date
        Project__c contract2 = TestHelper.createContractNoInsert(acc.Id, 'testContract2', null);
        contract2.Start_Date__c = contract1.Start_Date__c.addDays(1);
        contract2.End_Date__c = contract2.Start_Date__c.addDays(30);
        contract2.ClientServicesRep__c = clientServicesRep.Id;
        contract2.Brand__c = TestHelper.brandRecord.Id;
        
        //No client service rep
        Project__c contract3 = TestHelper.createContractNoInsert(acc.Id, 'testContract3', null);
        contract3.Start_Date__c = contract1.Start_Date__c;
        contract3.End_Date__c = contract2.Start_Date__c.addDays(30);
        contract3.Brand__c = TestHelper.brandRecord.Id;

        //Correct
        Project__c contract4 = TestHelper.createContractNoInsert(acc.Id, 'testContract4', null);
        contract4.Start_Date__c = contract1.Start_Date__c;
        contract4.End_Date__c = contract4.Start_Date__c.addDays(60);
        contract4.ClientServicesRep__c = clientServicesRep.Id;
        contract4.Brand__c = TestHelper.brandRecord.Id;
        
        insert new List<Project__c> {contract1, contract2, contract3, contract4}; 
        
        Test.startTest();
        ContractPreLaunchCSRepNotifyCtrl controller = new ContractPreLaunchCSRepNotifyCtrl();
        controller.clientService = clientServicesRep.Id;
        List<Project__c> contracts = controller.getPreLaunchContracts();
        Test.stopTest();
        
        System.assertEquals(2, contracts.size());
        System.assertEquals(contract1.Id, contracts[0].Id);
        System.assertEquals(contract4.Id, contracts[1].Id);
    }
}