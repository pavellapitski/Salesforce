@isTest
private class ContractPostLaunchCSRepNotifyCtrlTest
{
    private static testMethod void testDisplayLaunchedContracts()
    {
        Account acc = TestHelper.createAccount();
        User clientServicesRep = TestHelper.createClientServiceUser();
    
        //Correct
        Project__c contract1 = TestHelper.createContractNoInsert(acc.Id, 'testContract1', NULL); 
        contract1.Start_Date__c = System.Today().addDays(ContractRepository.postLaunchNotificationDelay);
        contract1.End_Date__c = contract1.Start_Date__c.addDays(30);
        contract1.ClientServicesRep__c = clientServicesRep.Id;
        
        //Wrong date
        Project__c contract2 = TestHelper.createContractNoInsert(acc.Id, 'testContract2', NULL);
        contract2.Start_Date__c = contract1.Start_Date__c.addDays(1);
        contract2.End_Date__c = contract2.Start_Date__c.addDays(30);
        contract2.ClientServicesRep__c = clientServicesRep.Id;
        
        //No client service rep
        Project__c contract3 = TestHelper.createContractNoInsert(acc.Id, 'testContract3', NULL);
        contract3.Start_Date__c = contract1.Start_Date__c;
        contract3.End_Date__c = contract2.Start_Date__c.addDays(30);

        //Correct
        Project__c contract4 = TestHelper.createContractNoInsert(acc.Id, 'testContract4', NULL);
        contract4.Start_Date__c = contract1.Start_Date__c;
        contract4.End_Date__c = contract4.Start_Date__c.addDays(60);
        contract4.ClientServicesRep__c = clientServicesRep.Id;
        
        insert new List<Project__c> {contract1, contract2, contract3, contract4}; 
        
        test.startTest(); 
        
            ContractPostLaunchCSRepNotifyCtrl controller = new ContractPostLaunchCSRepNotifyCtrl();
            controller.clientService = clientServicesRep.Id;
            
            List<Project__c> contracts = controller.getLaunchedContracts(); 
        
        test.stopTest();
        
        System.assertEquals(2, contracts.size());
        System.assertEquals(contract1.Id, contracts[0].Id);
        System.assertEquals(contract4.Id, contracts[1].Id);
    }
}