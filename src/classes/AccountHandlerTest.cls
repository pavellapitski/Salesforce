@IsTest
private class AccountHandlerTest {
	
	@IsTest static void noXeroIdToAssign() {
		Account parentAccount = TestHelper.createAccount('ParentAccount', true);
		Account childAccount = TestHelper.createAccount('ChildAccount', false);
		childAccount.ParentId = parentAccount.Id;

		Test.startTest();
		insert childAccount;
		Test.stopTest();
		System.assertEquals(null, [SELECT Id, Xero_Id__c FROM Account WHERE Id = :childAccount.Id LIMIT 1].Xero_Id__c);
	}
	
	@IsTest static void parentAccountWithXeroId() {
		String initialXeroId = 'Some_Xero_Id', changedXeroId = 'New_Xero_Id';

		Account parentAccount = TestHelper.createAccount('ParentAccount', false);
		parentAccount.Xero_Id__c = initialXeroId;
		insert parentAccount;

		Account acc1 = TestHelper.createAccount('ChildAccount1', false);
		acc1.ParentId = parentAccount.Id;
		
		Account acc2 = TestHelper.createAccount('ChildAccount2', false);
		acc2.ParentId = parentAccount.Id;
		acc2.Xero_Id__c = 'Other_Xero_Id';
		
		Account acc3 = TestHelper.createAccount('ChildAccount3', false);
		acc3.ParentId = parentAccount.Id;

		Test.startTest();
		insert new List<Account>{acc1, acc2, acc3};

		parentAccount.Xero_Id__c = changedXeroId;
		update parentAccount;
		Test.stopTest();

		List<Account> insertedAccounts = [SELECT Id, Name, ParentId, Xero_Id__c FROM Account WHERE ParentId = :parentAccount.Id];
		for (Account acc :insertedAccounts) {
			if (acc.Name == acc1.Name || acc.Name == acc3.Name) {
				System.assertEquals(initialXeroId, acc.Xero_Id__c);
			} else if (acc.Name == acc2.Name) {
				System.assertEquals(acc2.Xero_Id__c, acc.Xero_Id__c);
			}
		}
	}
	
	@IsTest static void willSetXeroContactBasedOnXeroId() {
    	 XeroSettings__c xs = TestHelper.createXeroEntity();
    
         Account acc1 = TestHelper.createAccount('ChildAccount1', false);
         Account acc2 = TestHelper.createAccount('ChildAccount2', false);
         Account acc3 = TestHelper.createAccount('ChildAccount3', false);
         insert new List<Account>{acc1, acc2, acc3};
         
         XeroEntity__c xeroContact1 = TestHelper.createXeroObject(xs);
         xeroContact1.XeroId__c = '127ac1df-9d07-4e27-a0b1-7d439f756845';
         XeroEntity__c xeroContact2 = TestHelper.createXeroObject(xs);
         xeroContact2.XeroId__c = '3284aa6b-a492-4b75-a84b-3821327498e0';
         insert new List<XeroEntity__c> {xeroContact1, xeroContact2};
         
         Test.startTest();
            acc1.Xero_Id__c = xeroContact1.XeroId__c;
            acc2.Xero_Id__c = xeroContact1.XeroId__c;
            acc3.Xero_Id__c = xeroContact2.XeroId__c;
            update new List<Account> {acc1, acc2, acc3};
         Test.stopTest();
         System.assertEquals(xeroContact1.Id, [SELECT XeroObject__c FROM Account WHERE Id = :acc1.Id].XeroObject__c);
         System.assertEquals(xeroContact1.Id, [SELECT XeroObject__c FROM Account WHERE Id = :acc2.Id].XeroObject__c);
         System.assertEquals(xeroContact2.Id, [SELECT XeroObject__c FROM Account WHERE Id = :acc3.Id].XeroObject__c);
    }

	@IsTest static void setRelatedContractsToSyncAfterUpdate() {
		Project__c contract = TestHelper.createContract('Test Contract', null, null, true); //NoInsert(acc.Id, 'TestCon', null);
        System.assertEquals(false, [SELECT PerformMMSync__c FROM Project__c WHERE Id = :contract.Id].PerformMMSync__c);
        
        Test.startTest();
        TestHelper.accountRecord.Name = 'Changed';
        update TestHelper.accountRecord;
        Test.stopTest();
        System.assertEquals(true, [SELECT PerformMMSync__c FROM Project__c WHERE Id = :contract.Id].PerformMMSync__c);
    }
}