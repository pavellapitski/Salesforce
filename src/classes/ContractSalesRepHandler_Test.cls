@IsTest
public class ContractSalesRepHandler_Test {

    @IsTest public static void getMissingSharedReps() {
        Account account = new Account(Name='TestAcc1', BillingCity = 'Chicago', BillingState = 'Michigan');
        insert account;

        Project__c contract = TestHelper.createContract(account.Id);

        Commission_Profile__c profile1 = TestHelper.createSalesCommissionProfile_Shared();
        Commission_Profile__c profile2 = TestHelper.createSalesCommissionProfile_Shared();
        Commission_Profile__c profile3 = TestHelper.createSalesCommissionProfile_Shared();

        Contract_Sales_Rep__c contractSalesRep = TestHelper.createContractSalesRepNoInsert(contract.Id, profile1.Id);
        contractSalesRep.Commission_Profile__c = profile1.Id;
        insert contractSalesRep;

        List<Contract_Sales_Rep__c> sharedReps = [SELECT Id, Commission_Profile__c, Commission_Profile__r.Salesforce_User__c FROM Contract_Sales_Rep__c WHERE Contract__c = :contract.Id];
        System.assert (sharedReps.size() == 3);
        System.assert (sharedReps[0].Commission_Profile__c == profile1.Id);
        System.assert (sharedReps[1].Commission_Profile__c == profile2.Id || sharedReps[1].Commission_Profile__c == profile3.Id);
        System.assert (sharedReps[2].Commission_Profile__c == profile3.Id || sharedReps[2].Commission_Profile__c == profile2.Id);
    }

	@IsTest public static void recalculationOnAfterDelete() {
        Account account = new Account(Name = 'TestAcc1', BillingCity = 'Chicago', BillingState = 'Michigan');

       	Test.startTest();
        insert account;
        Project__c contract1 = TestHelper.createContract(account.Id);

		Commission_Profile__c profile1 = TestHelper.createSalesCommissionProfile(),
                              profile3 = TestHelper.createSalesCommissionProfile();
        
        Contract_Sales_Rep__c rep1 = TestHelper.createContractSalesRepNoInsert(contract1.Id, profile1.Id),
                              rep3 = TestHelper.createContractSalesRepNoInsert(contract1.Id, profile3.Id);
        
        rep1.Commission_Profile__c = profile1.Id;        
        rep3.Commission_Profile__c = profile3.Id;
        
        rep1.Contract_Client_Spend_YT__c = 400;
        rep1.Contract_Gross_Profit_YT__c = 100;
        
        rep3.Contract_Client_Spend_YT__c = 1000;
        rep3.Contract_Gross_Profit_YT__c = 100;
        
        insert new List<Contract_Sales_Rep__c>{rep1, rep3};
        Test.stopTest();

        rep3 = [SELECT ExpectedCommission__c FROM Contract_Sales_Rep__c WHERE Id = :rep3.Id];
        Decimal comm3 = rep3.ExpectedCommission__c;
        delete rep1;

        rep3 = [SELECT ExpectedCommission__c FROM Contract_Sales_Rep__c WHERE Id = :rep3.Id];
        System.assert (comm3 != rep3.ExpectedCommission__c);
    }
    
    @IsTest public static void afterInsert_recalculate() {
        Account account = new Account(Name = 'TestAcc1', BillingCity = 'Chicago', BillingState = 'Michigan');

        Test.startTest();
        insert account;
        Project__c contract = TestHelper.createContract(account.Id);

		Commission_Profile__c profile1 = TestHelper.createSalesCommissionProfile(),
                profile3 = TestHelper.createSalesCommissionProfile();
        
        Contract_Sales_Rep__c rep1 = TestHelper.createContractSalesRepNoInsert(contract.Id, profile1.Id),
                rep3 = TestHelper.createContractSalesRepNoInsert(contract.Id, profile3.Id);
        
        rep1.Commission_Profile__c = profile1.Id;        
        rep3.Commission_Profile__c = profile3.Id;
        
        rep1.Contract_Client_Spend_YT__c = 400;
        rep1.Contract_Gross_Profit_YT__c = 100;

        rep3.Contract_Client_Spend_YT__c = 1000;
        rep3.Contract_Gross_Profit_YT__c = 100;
        
        insert rep1;
        rep1 = [SELECT ExpectedCommission__c FROM Contract_Sales_Rep__c WHERE Id = :rep1.Id];
        Decimal comm1 = rep1.ExpectedCommission__c;
        insert rep3;
        
        rep1 = [SELECT ExpectedCommission__c FROM Contract_Sales_Rep__c WHERE Id = :rep1.Id];
		Test.stopTest();            
        System.assert (comm1 != rep1.ExpectedCommission__c);
    }
   
	/* 
	@isTest
    public static void afterInsert_doNotRecalculateUnrelatedRep ()
    {
        Account acc1 = new Account (Name='TestAcc1');
        acc1.BillingCity	= 'Chicago';
        acc1.BillingState   = 'Michigan';

        Test.startTest();
        insert acc1;
            
        Project__c contract1 = TestHelper.createContract(acc1.Id),
            		contract2 = TestHelper.createContract(acc1.Id);
        Project__c [] contracts = new Project__c [] {TestHelper.createContractNoInsert (acc1.Id, 'Test Contract', null),
            										 TestHelper.createContractNoInsert (acc1.Id, 'Test Contract', null)};
		insert contracts;                                                         
        
        Commission_Profile__c profile1, profile2 = new Commission_Profile__c();
        
        profile1.Salesforce_User__c = (TestHelper.usr != NULL) ? TestHelper.usr.Id : TestHelper.createUser().Id;
        profile1.CommissionType__c = Label.COMMISSION_TYPE_DEFAULT;
        
        profile2.Salesforce_User__c = (TestHelper.usr != NULL) ? TestHelper.usr.Id : TestHelper.createUser().Id;
        profile2.CommissionType__c = Label.COMMISSION_TYPE_DEFAULT;
        
        insert new Commission_Profile__c [] {profile1,profile2};
            
		Commission_Profile__c profile1 = TestHelper.createSalesCommissionProfile(),
            					profile2 = TestHelper.createSalesCommissionProfile();
            
        Contract_Sales_Rep__c rep1 = TestHelper.createContractSalesRepNoInsert(contract1.Id, profile1.Id),
            					rep2 = TestHelper.createContractSalesRepNoInsert(contract2.Id, profile2.Id);        
        rep1.Commission_Profile__c = profile1.Id;        
        rep2.Commission_Profile__c = profile2.Id;
        
        rep1.Contract_Client_Spend_YT__c = 400;
        rep1.Contract_Gross_Profit_YT__c = 100;
        
        rep2.Contract_Client_Spend_YT__c = 800;
        rep2.Contract_Gross_Profit_YT__c = 100;
        
        insert rep1;
        Contract_Sales_Rep__c [] reps = [SELECT ExpectedCommission__c FROM Contract_Sales_Rep__c 
                                         WHERE Id=:rep1.Id OR Id=:rep2.Id ORDER BY CreatedDate];
        rep1 = reps [0];
        rep2 = reps [1];
        Decimal comm1 = rep1.ExpectedCommission__c;
        Decimal comm2 = rep2.ExpectedCommission__c;

        insert rep2;
        
        rep1 = [SELECT ExpectedCommission__c FROM Contract_Sales_Rep__c 
                                         WHERE Id=:rep1.Id];
		Test.stopTest();            
        System.assert (comm1 == rep1.ExpectedCommission__c);
        System.assert (comm2 == rep2.ExpectedCommission__c);
    }*/
    
     @IsTest public static void recalculationOnAfterUpdate() {
         Account account = new Account(Name = 'TestAcc1', BillingCity = 'Chicago', BillingState = 'Michigan');

        insert account;
        Project__c contract = TestHelper.createContract(account.Id);
                        
		Commission_Profile__c profile1 = TestHelper.createSalesCommissionProfile(),
            					profile3 = TestHelper.createSalesCommissionProfile();
        
        Contract_Sales_Rep__c rep1 = TestHelper.createContractSalesRepNoInsert(contract.Id, profile1.Id),
            					rep3 = TestHelper.createContractSalesRepNoInsert(contract.Id, profile3.Id);
        
        rep1.Commission_Profile__c = profile1.Id;        
        rep3.Commission_Profile__c = profile3.Id;
        
        rep1.Contract_Client_Spend_YT__c = 400;
        rep1.Contract_Gross_Profit_YT__c = 100;

        Test.startTest();
        insert new Contract_Sales_Rep__c [] {rep1, rep3};
        rep1 = [SELECT ExpectedCommission__c FROM Contract_Sales_Rep__c WHERE Id = :rep1.Id];
        rep3 = [SELECT ExpectedCommission__c, Contract_Gross_Profit_YT__c, Contract_Client_Spend_YT__c FROM Contract_Sales_Rep__c WHERE Id = :rep3.Id];
        rep3.Contract_Client_Spend_YT__c = 1000;
        rep3.Contract_Gross_Profit_YT__c = 100;
        ConSalesRepExpCommissionCalculator.SALES_REP_EXPECTED_COMMISSIONS_RECALCULATED = false;
        update rep3;
        Test.stopTest();
        System.assert(ConSalesRepExpCommissionCalculator.SALES_REP_EXPECTED_COMMISSIONS_RECALCULATED == true);
    }
    
    @IsTest public static void deleteSharedRep() {
        Account account = new Account(Name = 'TestAcc1', BillingCity = 'Chicago', BillingState = 'Michigan');
        insert account;
            
        Project__c contract1 = TestHelper.createContract(account.Id);
        
		Commission_Profile__c profile1 = TestHelper.createSalesCommissionProfile_Shared();
        Commission_Profile__c profile2 = TestHelper.createSalesCommissionProfile_Shared();
		Commission_Profile__c profile3 = TestHelper.createSalesCommissionProfile_Shared();

        Contract_Sales_Rep__c rep1 = TestHelper.createContractSalesRepNoInsert(contract1.Id, profile1.Id);
        rep1.Commission_Profile__c = profile1.Id;        
        
        insert rep1;
        delete rep1;

        List<Contract_Sales_Rep__c> sharedReps = [SELECT Id, Commission_Profile__c FROM Contract_Sales_Rep__c WHERE Contract__c = :contract1.Id];
        System.assert(sharedReps.size() == 2);
        System.assert((sharedReps[0].Commission_Profile__c == profile2.Id && sharedReps[1].Commission_Profile__c == profile3.Id)
                       ||
                       (sharedReps[0].Commission_Profile__c == profile3.Id && sharedReps[1].Commission_Profile__c == profile2.Id));
    }
    
    @IsTest public static void updateSharedRepDontAddMissing() {
        Account account = new Account(Name = 'TestAcc1', BillingCity = 'Chicago', BillingState = 'Michigan');
        insert account;
            
        Project__c contract = TestHelper.createContract(account.Id);
        
		Commission_Profile__c profile1 = TestHelper.createSalesCommissionProfile_Shared();
        Commission_Profile__c profile2 = TestHelper.createSalesCommissionProfile_Shared();
		Commission_Profile__c profile3 = TestHelper.createSalesCommissionProfile_Shared();

        Contract_Sales_Rep__c rep1 = TestHelper.createContractSalesRepNoInsert(contract.Id, profile1.Id);
        rep1.Commission_Profile__c = profile1.Id;
        insert rep1;

        delete [SELECT Id FROM Contract_Sales_Rep__c WHERE Commission_Profile__c = :profile2.Id];
        rep1.Contract_Client_Spend_YT__c = 2000;
        update rep1;

        List<Contract_Sales_Rep__c>  sharedReps = [SELECT Id, Commission_Profile__c FROM Contract_Sales_Rep__c WHERE Contract__c = :contract.Id];
        System.assert(sharedReps.size() == 2);
        System.assert(sharedReps[0].Commission_Profile__c == profile1.Id && sharedReps[1].Commission_Profile__c == profile3.Id
                      ||
                       sharedReps[0].Commission_Profile__c == profile3.Id && sharedReps[1].Commission_Profile__c == profile1.Id);
    }
}