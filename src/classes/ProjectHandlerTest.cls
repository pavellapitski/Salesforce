@IsTest
private class ProjectHandlerTest {

    @IsTest static void testSalesReps() {
        User usr = TestHelper.createUser();
        Account acc = TestHelper.createAccount();
        Opportunity oppObject = TestHelper.createOpportunity(usr, acc);
        insert oppObject;

        Platform__c platformTV = TestHelper.getTrueViewPlatform();
        OpportunityPlatform__c oppPlatform = TestHelper.createOpportunityPlatform(oppObject.Id, platformTV.Id);
        insert oppPlatform;

        Test.startTest();
            oppObject.StageName = 'Closed Won';
            oppObject.Brand__c = TestHelper.createBrand('testBrand').Id;
            update oppObject;
        Test.stopTest();

        List<Project__c> contracts = [SELECT Id, Opportunity__c FROM Project__c WHERE Opportunity__c = :oppObject.Id];
        System.assert(contracts.size() > 0);
    }

    @IsTest static void testInsertListOfContracts() {
        XeroSettings__c xs = TestHelper.createXeroEntity();
        Brand__c testBrand = TestHelper.createBrand('testBrand');
        String newXeroId = 'New_Xero_Id';

        Account acc = TestHelper.createAccount('ParentAcc', false);
        acc.Xero_Id__c = 'Some_Xero_Id';
        acc.Xero_Entity__c = xs.Id;
        insert acc;

        Date startDate = Date.valueOf('2015-01-01');
        Date endDate = startDate.addDays(40);

        List<Project__c> projects = new List<Project__c>();
        projects.add(new Project__c(
            Account__c           = acc.Id,
            Account_Type__c      = 'Strike',
            BillingCondition__c = TestHelper.createBillingCondition('Normal').Id,
            Brand__c             = testBrand.Id,
            Client_Spend__c      = 1234.12,
            CurrencyIsoCode      = 'USD',
            End_Date__c          = endDate,
            Geo__c               = 'Test Geo',
            Margin__c            = 0.1,
            Name                 = 'Test Contract',
            Start_Date__c        = startDate
        ));
        projects.add(new Project__c(
            Account__c           = acc.Id,
            Account_Type__c      = 'Strike',
            BillingCondition__c = TestHelper.createBillingCondition('Normal').Id,
            Brand__c             = testBrand.Id,
            Client_Spend__c      = 1234.12,
            CurrencyIsoCode      = 'USD',
            End_Date__c          = endDate,
            Geo__c               = 'Test Geo',
            Margin__c            = 0.1,
            Name                 = 'Test Contract1',
            Start_Date__c        = startDate,
            Xero_Id__c           = newXeroId
        ));
        projects.add(new Project__c(
            Account__c           = acc.Id,
            Account_Type__c      = 'Strike',
            BillingCondition__c = TestHelper.createBillingCondition('Normal').Id,
            Brand__c             = testBrand.Id,
            Client_Spend__c      = 1234.12,
            CurrencyIsoCode      = 'USD',
            End_Date__c          = endDate,
            Geo__c               = 'Test Geo',
            Margin__c            = 0.1,
            Name                 = 'Test Contract2',
            Start_Date__c        = startDate
        ));

        Test.startTest();
            insert projects;
        Test.stopTest();

        List<Project__c> afterInsert = [SELECT Id, Name, Account__c, Xero_Id__c, Xero_Entity__c FROM Project__c WHERE Account__c =: acc.Id];
        for (Project__c contract :afterInsert) {
            if (contract.Name == 'TestContract' || contract.Name == 'TestContract2') {
                System.assertEquals(acc.Xero_Id__c, contract.Xero_Id__c);
                System.assertEquals(xs.Id, contract.Xero_Entity__c);
            } else if (contract.Name == 'TestContract1') {
                System.assertEquals(newXeroId, contract.Xero_Id__c);
                System.assertEquals(null, contract.Xero_Entity__c);
            }
        }
    }

    @IsTest static void willCreateAndAssignBrandAccountWhenDoesNotExist() {
        Project__c contract = TestHelper.createContract('Test Contract', null, null, false);

        Test.startTest();
        contract.Brand__c = TestHelper.createBrand('NewTestBrand', true).Id;
        insert contract;
        Test.stopTest();

        System.assert(String.isBlank(contract.BrandAccount__c));
        contract = [SELECT BrandAccount__c FROM Project__c WHERE Id = :contract.Id];
        System.assert(!String.isBlank(contract.BrandAccount__c));
    }

    @IsTest static void willAssignExistingBrandAccount() {
        Account acc = TestHelper.createAccount('Account');
        Brand__c brand = new Brand__c(Name = 'MyNewTestBrand');
        insert brand;
        Brand_Account__c brandAcc = TestHelper.createBrandAccount(acc.Id, brand.Id);

        Project__c contract = TestHelper.createContract('Test Contract', null, null, false);
        Test.startTest();

        contract.Account__c = acc.Id;
        contract.Brand__c = brand.Id;
        insert contract;
        Test.stopTest();

        contract = [SELECT Brand__c, BrandAccount__c FROM Project__c WHERE Id = :contract.Id];
        System.assertEquals(brandAcc.Id, contract.BrandAccount__c);
    }

    @IsTest static void willCreateNewBrandAccountWhenBrandIsChanged() {
        String newBrandName = 'brandNew';
        String accName = 'accNew';

        Account acc                 = TestHelper.createAccount(accName);
        Brand__c brand              = TestHelper.createBrand('testBrand');
        Brand__c brandNew           = TestHelper.createBrand(newBrandName);
        Brand_Account__c brandAcc   = TestHelper.createBrandAccount(acc.Id, brand.Id);
        Project__c contract         = TestHelper.createContractNoInsert(acc.Id, 'contractName', null);

        contract.Brand__c = brand.Id;
        insert contract;

        contract = [SELECT Id,BrandAccount__c FROM Project__c WHERE Id = :contract.Id];
        System.assertEquals(brandAcc.Id, contract.BrandAccount__c, 'BrandAccount should be assigned to Contract');

        Integer existingBrandAccountAmount = (new List<Brand_Account__c>{brandAcc}).size();
        System.assertEquals(existingBrandAccountAmount, [SELECT COUNT() FROM Brand_Account__c], 'There should be one existing BrandAccount');

        Test.startTest();
        contract.Brand__c = brandNew.Id;
        update contract;
        Test.stopTest();

        contract = [SELECT BrandAccount__c, BrandAccount__r.Brand_Account__c, BrandAccount__r.Name FROM Project__c WHERE Id = :contract.Id];
        System.assert(String.isNotBlank(contract.BrandAccount__c));
        String newBrandAccountName = newBrandName + ' / ' + accName;
        System.assertEquals(contract.BrandAccount__r.Brand_Account__c, newBrandAccountName, 'New BrandAccount name should be "'+newBrandAccountName+'"');
        System.assertEquals(contract.BrandAccount__r.Name, newBrandAccountName, 'New BrandAccount name should be "'+newBrandAccountName+'"');

        // a new BrandAccount has been created
        System.assertEquals(existingBrandAccountAmount+1, [SELECT COUNT() FROM Brand_Account__c], 'A new BrandAccount should be created');
    }

    @IsTest static void willCreateNewBrandAccountWhenAccountIsChanged() {
        String brandName = 'brandName';
        String newAccName = 'accNew';

        Account accObject          = TestHelper.createAccount();
        Account newAccObject       = TestHelper.createAccount(newAccName);
        Brand__c brand             = TestHelper.createBrand(brandName);
        Brand_Account__c brandAcc  = TestHelper.createBrandAccount(accObject.Id, brand.Id);
        Project__c contract        = TestHelper.createContractNoInsert(accObject.Id, 'contractName', null);

        contract.Brand__c = brand.Id;
        insert contract;

        contract = [SELECT Id,BrandAccount__c,BrandAccount__r.Brand_Account__c, BrandAccount__r.Name FROM Project__c WHERE Id = :contract.Id];
        System.assertEquals(brandAcc.Id, contract.BrandAccount__c, 'BrandAccount should be assigned to Contract');
        System.assertEquals(contract.BrandAccount__r.Brand_Account__c, brandName + ' / ' + accObject.Name, 'BrandAccount name should be equal to "'+brandName + ' / ' + accObject.Name+'"');

        Integer existingBrandAccountAmount = (new List<Brand_Account__c>{brandAcc}).size();
        System.assertEquals(existingBrandAccountAmount, [SELECT COUNT() FROM Brand_Account__c], 'There should be one existing BrandAccount');

        Test.startTest();
        contract.Account__c = newAccObject.Id;
        update contract;
        Test.stopTest();

        contract = [SELECT BrandAccount__c, BrandAccount__r.Brand_Account__c, BrandAccount__r.Name FROM Project__c WHERE Id = :contract.Id];
        System.assert(String.isNotBlank(contract.BrandAccount__c));
        String newBrandAccountName = brandName + ' / ' + newAccName;
        System.assertEquals(contract.BrandAccount__r.Brand_Account__c, newBrandAccountName, 'New BrandAccount name should be "'+newBrandAccountName+'"');
        System.assertEquals(contract.BrandAccount__r.Name, newBrandAccountName, 'New BrandAccount name should be "'+newBrandAccountName+'"');

        // a new BrandAccount has been created
        System.assertEquals(existingBrandAccountAmount+1, [SELECT COUNT() FROM Brand_Account__c], 'A new BrandAccount should be created');
    }

    @IsTest static void willUseExistingBrandAccountWhenBrandIsChanged() {
        String existingBrandName = 'brandNew';
        String accName = 'accNew';

        Account accObject                   = TestHelper.createAccount(accName);
        Brand__c brand                      = TestHelper.createBrand('testBrand');
        Brand__c existingBrand              = TestHelper.createBrand(existingBrandName);
        Brand_Account__c brandAcc           = TestHelper.createBrandAccount(accObject.Id, brand.Id);
        Brand_Account__c existingBrandAcc   = TestHelper.createBrandAccount(accObject.Id, existingBrand.Id);
        Project__c contract                 = TestHelper.createContractNoInsert(accObject.Id, 'contractName', null);

        contract.Brand__c = brand.Id;
        insert contract;

        contract = [SELECT Id,BrandAccount__c,BrandAccount__r.Brand_Account__c, BrandAccount__r.Name FROM Project__c WHERE Id = :contract.Id];
        System.assertEquals(brandAcc.Id, contract.BrandAccount__c, 'BrandAccount should be assigned to Contract');

        Integer existingBrandAccountAmount = (new List<Brand_Account__c>{brandAcc,existingBrandAcc}).size();
        System.assertEquals(existingBrandAccountAmount, [SELECT COUNT() FROM Brand_Account__c], 'There should be two BrandAccounts');

        Test.startTest();
        contract.Brand__c = existingBrand.Id;
        update contract;
        Test.stopTest();

        contract = [SELECT Id,BrandAccount__c,BrandAccount__r.Brand_Account__c, BrandAccount__r.Name FROM Project__c WHERE Id = :contract.Id];
        System.assert(String.isNotBlank(contract.BrandAccount__c));
        System.assertEquals(contract.BrandAccount__r.Brand_Account__c, existingBrandName + ' / ' + accName, 'New BrandAccount name should be "'+existingBrandName + ' / ' + accName+'"');
        System.assertEquals(contract.BrandAccount__c, existingBrandAcc.Id, 'Existing BrandAccount record should be assigned to Contract');

        // no new brandAccount is created
        System.assertEquals(existingBrandAccountAmount, [SELECT COUNT() FROM Brand_Account__c], 'No new BrandAccounts should be created');
    }

    @IsTest static void willUseExistingBrandAccountWhenAccountIsChanged() {
        String brandName = 'brandName';
        String newAccName = 'accNew';

        Account acc                         = TestHelper.createAccount();
        Account newAcc                      = TestHelper.createAccount(newAccName);
        Brand__c brand                      = TestHelper.createBrand(brandName);
        Brand_Account__c brandAcc           = TestHelper.createBrandAccount(acc.Id, brand.Id);
        Brand_Account__c existingBrandAcc   = TestHelper.createBrandAccount(newAcc.Id, brand.Id);
        Project__c contract                 = TestHelper.createContractNoInsert(acc.Id, 'contractName', null);

        contract.Brand__c = brand.Id;
        insert contract;

        contract = [SELECT Id,BrandAccount__c,BrandAccount__r.Brand_Account__c, BrandAccount__r.Name FROM Project__c WHERE Id = :contract.Id];
        System.assertEquals(brandAcc.Id, contract.BrandAccount__c, 'BrandAccount should be assigned to Contract');
        System.assertEquals(contract.BrandAccount__r.Brand_Account__c, brandName + ' / ' + acc.Name, 'BrandAccount name should be equal to "'+brandName+' / '+acc.Name+'"');

        Integer existingBrandAccountAmount = (new List<Brand_Account__c>{brandAcc,existingBrandAcc}).size();
        System.assertEquals(existingBrandAccountAmount, [SELECT COUNT() FROM Brand_Account__c], 'There should be two BrandAccounts');

        Test.startTest();
        contract.Account__c = newAcc.Id;
        update contract;
        Test.stopTest();

        contract = [SELECT Id,BrandAccount__c,BrandAccount__r.Brand_Account__c, BrandAccount__r.Name FROM Project__c WHERE Id = :contract.Id];
        System.assert(String.isNotBlank(contract.BrandAccount__c));
        System.assertEquals(contract.BrandAccount__r.Brand_Account__c, brandName + ' / ' + newAcc.Name, 'New BrandAccount name should be "'+brandName + ' / ' + newAcc.Name+'"');
        System.assertEquals(contract.BrandAccount__c, existingBrandAcc.Id, 'Existing BrandAccount record should be assigned to Contract');
        System.assertEquals(existingBrandAccountAmount, [SELECT COUNT() FROM Brand_Account__c], 'No new BrandAccounts should be created');
    }

    @IsTest static void willUseExistingBrandForOppWhenContractBrandIsChanged_OppBrandAccountWillChanged() {
        String existingBrandName = 'brandNew';
        String accName = 'accNew';

        Account accObject                   = TestHelper.createAccount(accName);
        Brand__c brand                      = TestHelper.createBrand('testBrand');
        Brand__c existingBrand              = TestHelper.createBrand(existingBrandName);
        Brand_Account__c brandAcc           = TestHelper.createBrandAccount(accObject.Id, brand.Id);
        Brand_Account__c existingBrandAcc   = TestHelper.createBrandAccount(accObject.Id, existingBrand.Id);
        Project__c contract                 = TestHelper.createContractNoInsert(accObject.Id, 'contractName', null);

        contract.Brand__c = brand.Id;
        insert contract;

        Opportunity opp = [SELECT Id, Brand__c, BrandAccount__c, AccountId FROM Opportunity WHERE Id = :contract.Opportunity__c];

        contract = [SELECT Id,BrandAccount__c,BrandAccount__r.Brand_Account__c, BrandAccount__r.Name, Brand__c, Account__c FROM Project__c WHERE Id = :contract.Id];
        System.assertEquals(brandAcc.Id, contract.BrandAccount__c, 'BrandAccount should be assigned to Contract');
        System.assertEquals(opp.Brand__c, contract.Brand__c, 'Opportunity and Contract Brands should be equal');
        System.assertEquals(opp.BrandAccount__c, contract.BrandAccount__c, 'Opportunity and Contract BrandAccounts should be equal');
        System.assertEquals(opp.AccountId, contract.Account__c, 'Opportunity and Contract Accounts should be equal');

        Integer existingBrandAccountAmount = (new List<Brand_Account__c>{brandAcc,existingBrandAcc}).size();
        System.assertEquals(existingBrandAccountAmount, [SELECT COUNT() FROM Brand_Account__c], 'There should be two BrandAccounts');

        Test.startTest();
        contract.Brand__c = existingBrand.Id;
        update contract;
        Test.stopTest();

        contract = [SELECT Id,BrandAccount__c,BrandAccount__r.Brand_Account__c, BrandAccount__r.Name, Brand__c, Account__c FROM Project__c WHERE Id = :contract.Id];
        System.assert(String.isNotBlank(contract.BrandAccount__c));
        System.assertEquals(contract.BrandAccount__r.Brand_Account__c, existingBrandName + ' / ' + accName, 'New BrandAccount name should be "'+existingBrandName + ' / ' + accName+'"');
        System.assertEquals(contract.BrandAccount__c, existingBrandAcc.Id, 'Existing BrandAccount record should be assigned to Contract');

        opp = [SELECT Id, Brand__c, BrandAccount__c, AccountId FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(opp.Brand__c, contract.Brand__c, 'Opportunity Brand should be updated');
        System.assertEquals(opp.BrandAccount__c, contract.BrandAccount__c, 'Opportunity BrandAccount should be updated');
        System.assertEquals(opp.AccountId, contract.Account__c, 'Opportunity Accounts should be updated');

        // no new brandAccount is created
        System.assertEquals(existingBrandAccountAmount, [SELECT COUNT() FROM Brand_Account__c], 'No new BrandAccounts should be created');
    }

    @IsTest static void willUseExistingBrandForOppWhenContractAccountIsChanged_OppBrandAccountWillChanged() {
        String brandName = 'brandName';
        String newAccName = 'accNew';

        Account acc                         = TestHelper.createAccount();
        Account newAcc                      = TestHelper.createAccount(newAccName);
        Brand__c brand                      = TestHelper.createBrand(brandName);
        Brand_Account__c brandAcc           = TestHelper.createBrandAccount(acc.Id, brand.Id);
        Brand_Account__c existingBrandAcc   = TestHelper.createBrandAccount(newAcc.Id, brand.Id);
        Project__c contract                 = TestHelper.createContractNoInsert(acc.Id, 'contractName', null);

        contract.Brand__c = brand.Id;
        insert contract;

        Opportunity opp = [SELECT Id, Brand__c, BrandAccount__c, AccountId FROM Opportunity WHERE Id = :contract.Opportunity__c];

        contract = [SELECT Id,BrandAccount__c,BrandAccount__r.Brand_Account__c, BrandAccount__r.Name, Brand__c, Account__c FROM Project__c WHERE Id = :contract.Id];
        System.assertEquals(brandAcc.Id, contract.BrandAccount__c, 'BrandAccount should be assigned to Contract');
        System.assertEquals(opp.Brand__c, contract.Brand__c, 'Opportunity and Contract Brands should be equal');
        System.assertEquals(opp.BrandAccount__c, contract.BrandAccount__c, 'Opportunity and Contract BrandAccounts should be equal');
        System.assertEquals(opp.AccountId, contract.Account__c, 'Opportunity and Contract Accounts should be equal');

        Integer existingBrandAccountAmount = (new List<Brand_Account__c>{brandAcc,existingBrandAcc}).size();
        System.assertEquals(existingBrandAccountAmount, [SELECT COUNT() FROM Brand_Account__c], 'There should be two BrandAccounts');

        Test.startTest();
        contract.Account__c = newAcc.Id;
        update contract;
        Test.stopTest();

        contract = [SELECT Id,BrandAccount__c,BrandAccount__r.Brand_Account__c, BrandAccount__r.Name, Brand__c, Account__c FROM Project__c WHERE Id = :contract.Id];
        System.assert(String.isNotBlank(contract.BrandAccount__c));
        System.assertEquals(contract.BrandAccount__r.Brand_Account__c, brandName + ' / ' + newAcc.Name, 'New BrandAccount name should be "'+brandName + ' / ' + newAcc.Name+'"');
        System.assertEquals(contract.BrandAccount__c, existingBrandAcc.Id, 'Existing BrandAccount record should be assigned to Contract');

        opp = [SELECT Id, Brand__c, BrandAccount__c, AccountId FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(opp.Brand__c, contract.Brand__c, 'Opportunity Brand should be updated');
        System.assertEquals(opp.BrandAccount__c, contract.BrandAccount__c, 'Opportunity BrandAccount should be updated');
        System.assertEquals(opp.AccountId, contract.Account__c, 'Opportunity Accounts should be updated');
        System.assertEquals(existingBrandAccountAmount, [SELECT COUNT() FROM Brand_Account__c], 'No new BrandAccounts should be created');
    }

    /*@IsTest static void willUpdateSalesRepCommissionWhenPaid() {
        Project__c contract = TestHelper.createContract('TestContract', null, null, true);

        ConSalesRepExpCommissionCalculator.SALES_REP_EXPECTED_COMMISSIONS_RECALCULATED = false;
        Contract_Sales_Rep__c contractSalesRep = TestHelper.createContractSalesRepNoInsert(contract.Id);
        contractSalesRep.ExpectedCommission__c = 10;
        contractSalesRep.Commission__c = 5;
        insert contractSalesRep;

        Test.startTest();
        contractSalesRep = [SELECT Commission__c, ExpectedCommission__c FROM Contract_Sales_Rep__c WHERE Id = :contractSalesRep.Id];
        System.assert(contractSalesRep.ExpectedCommission__c > 0);
        System.assert(contractSalesRep.Commission__c != contractSalesRep.ExpectedCommission__c);
        List<Sub_Project__c> payments = [SELECT Id FROM Sub_Project__c WHERE Project__c = :contract.Id];
        for (Sub_Project__c payment :payments) {
            payment.Paid__c = true;
        }
        update payments;
        Test.stopTest();

        contractSalesRep = [SELECT Commission__c, ExpectedCommission__c FROM Contract_Sales_Rep__c WHERE Id = :contractSalesRep.Id];
        System.assertEquals(contractSalesRep.ExpectedCommission__c, contractSalesRep.Commission__c);
    }*/

    @IsTest static void willUpdatePaymentDatesWhenContractIsUpdated() {
        Date sDate = Date.newInstance(System.today().year(), 3, 1),
            eDate = sDate.addMonths(2).addDays(-1);

        Project__c contract = TestHelper.createContract('TestContract', sDate, eDate, false);
        contract.Gaps_Exist_Between_Projects__c = true;
        contract.Client_Spend__c = 200;
        insert contract;

        delete [SELECT Id FROM Sub_Project__c];

        Sub_Project__c payment1 = TestHelper.createPayment(contract, false);
        payment1.Start_Date__c = sDate;
        payment1.End_Date__c = payment1.Start_Date__c.addMonths(1).addDays(-1);
        payment1.Client_Spend__c = 100;

        Sub_Project__c payment2 = TestHelper.createPayment(contract, false);
        payment2.Start_Date__c = payment1.End_Date__c.addDays(1);
        payment2.End_Date__c = contract.End_Date__c;
        payment2.Client_Spend__c = 100;

        Test.startTest();
        insert new List<Sub_Project__c> {payment1, payment2};

        contract.Start_Date__c = contract.Start_Date__c.addDays(3);
        contract.End_Date__c = contract.End_Date__c.addDays(-4);
        update contract;
        Test.stopTest();

        System.assertEquals(contract.Start_Date__c, [SELECT Start_Date__c FROM Sub_Project__c WHERE Id = :payment1.Id].Start_Date__c);
        System.assertEquals(contract.End_Date__c, [SELECT End_Date__c FROM Sub_Project__c WHERE Id = :payment2.Id].End_Date__c);
    }

    @IsTest static void willUpdatePaymentClientSpendWhenContractIsUpdated() {
        Date sDate = Date.newInstance(System.today().year(), 3, 1),
                eDate = sDate.addMonths(2).addDays(-1);

        Project__c contract = TestHelper.createContract('TestContract', sDate, eDate, false);
        contract.Gaps_Exist_Between_Projects__c = true;
        contract.Client_Spend__c = 100;
        insert contract;

        delete [SELECT Id FROM Sub_Project__c];

        Test.startTest();
        Sub_Project__c payment = TestHelper.createPayment(contract, false);
        payment.Start_Date__c = sDate;
        payment.End_Date__c = eDate;
        insert payment;

        contract.Client_Spend__c = 200;
        update contract;
        Test.stopTest();

        System.assertEquals(contract.Client_Spend__c, [SELECT Client_Spend__c FROM Sub_Project__c WHERE Id = :payment.Id].Client_Spend__c);
        System.assertEquals(payment.Id, new List<Id> (ProjectHandler.paymentsWithClientSpendUpdated)[0]);
    }

    @IsTest static void errorWhenTryingToEditContractClientSpendWhenMultiplePaymentsExist() {
        Date sDate = Date.newInstance(System.today().year(), 3, 1),
                eDate = sDate.addMonths(2).addDays(-1);

        Project__c contract = TestHelper.createContract('TestContract', sDate, eDate, false);
        contract.Gaps_Exist_Between_Projects__c = true;
        contract.Client_Spend__c = 200;

        Test.startTest();
        insert contract;

        delete [SELECT Id FROM Sub_Project__c];

        Sub_Project__c payment1 = TestHelper.createPayment(contract, false);
        payment1.Start_Date__c = sDate;
        payment1.End_Date__c = payment1.Start_Date__c.addMonths(1).addDays(-1);
        payment1.Client_Spend__c = 100;

        Sub_Project__c payment2 = TestHelper.createPayment(contract, false);
        payment2.Start_Date__c = payment1.End_Date__c.addDays(1);
        payment2.End_Date__c = eDate;
        payment2.Client_Spend__c = 100;
        insert new List<Sub_Project__c> {payment1, payment2};

        Boolean cannotEditContractClientSpendWhenMultiplePaymentsExist = false;
        try {
            contract.Client_Spend__c = 400;
            update contract;
        } catch (Exception ex) {
            if (ex.getMessage().contains(Label.ContractHasMultiplePaymentsCannotEditClientSpend)) {
                cannotEditContractClientSpendWhenMultiplePaymentsExist = true;
            }
        }
        ProjectHandler.canEditClientSpendMode.add(contract.Id);
        contract.Client_Spend__c = 400;
        update contract;
		Test.stopTest();
        
        System.assert(cannotEditContractClientSpendWhenMultiplePaymentsExist);
    }

    @IsTest static void errorWhenContractStartDateBiggerThanFirstPaymentEndDate() {
        Date sDate = Date.newInstance(System.today().year(), 3, 1),
                eDate = sDate.addMonths(2).addDays(-1);

        Project__c contract = TestHelper.createContract('TestContract', sDate, eDate, false);
        contract.Gaps_Exist_Between_Projects__c = true;
        contract.Client_Spend__c = 200;
        insert contract;

        delete [SELECT Id FROM Sub_Project__c];

        Sub_Project__c payment1 = TestHelper.createPayment(contract, false);
        payment1.Start_Date__c = contract.Start_Date__c;
        payment1.End_Date__c = payment1.Start_Date__c.addMonths(1).addDays(-1);
        payment1.Client_Spend__c = 100;

        Sub_Project__c payment2 = TestHelper.createPayment(contract, false);
        payment2.Start_Date__c = payment1.End_Date__c.addDays(1);
        payment2.End_Date__c = contract.End_Date__c;
        payment2.Client_Spend__c = 100;

        Test.startTest();
        insert new List<Sub_Project__c> {payment1, payment2};

        Boolean contractStartDateCannotBeBiggerThanFirstPaymentEndDate = false;
        try {
            contract.Start_Date__c = payment1.End_Date__c.addDays(2);
            update contract;
        } catch (Exception ex) {
            if (ex.getMessage().contains(Label.ContractStartDateBiggerThanFirstPaymentEndDate)) {
                contractStartDateCannotBeBiggerThanFirstPaymentEndDate = true;
            }
        }
        Test.stopTest();
        System.assert(contractStartDateCannotBeBiggerThanFirstPaymentEndDate);
    }

    @IsTest static void errorWhenContractEndDateLowerThanLastPaymentStartDate() {
        Date sDate = Date.newInstance(System.today().year(), 3, 1),
                eDate = sDate.addMonths(2).addDays(-1);

        Project__c contract = TestHelper.createContract('TestContract', sDate, eDate, false);
        contract.Gaps_Exist_Between_Projects__c = true;
        contract.Client_Spend__c = 200;
        insert contract;

        delete [SELECT Id FROM Sub_Project__c];

        Sub_Project__c payment1 = TestHelper.createPayment(contract, false);
        payment1.Start_Date__c = contract.Start_Date__c;
        payment1.End_Date__c = payment1.Start_Date__c.addMonths(1).addDays(-1);
        payment1.Client_Spend__c = 100;

        Sub_Project__c payment2 = TestHelper.createPayment(contract, false);
        payment2.Start_Date__c = payment1.End_Date__c.addDays(1);
        payment2.End_Date__c = contract.End_Date__c;
        payment2.Client_Spend__c = 100;

        Test.startTest();
        insert new List<Sub_Project__c> {payment1, payment2};

        Boolean contractEndDateCannotBeLowerThanLastPaymentStartDate = false;
        try {
          contract.End_Date__c = payment2.Start_Date__c.addDays(-2);
          update contract;
        } catch (Exception ex) {
            if (ex.getMessage().contains(Label.ContractEndDateLowerThanLastPaymenStartDate )) {
                contractEndDateCannotBeLowerThanLastPaymentStartDate = true;
            }
        }
        Test.stopTest();
        System.assert(contractEndDateCannotBeLowerThanLastPaymentStartDate);
    }

    @IsTest static void willSetPaymentType() {
        Date sDate = Date.newInstance(System.today().year(), 3, 1),
                eDate = sDate.addMonths(2).addDays(-1);

        Project__c contractRecord = TestHelper.createContract('TestContract', sDate, eDate, true);

        Test.startTest();
        contractRecord.Payment_Type__c = Contract.PAYMENT_TYPE_NET_30;
        update contractRecord;
        System.assertEquals(Contract.PAYMENT_TYPE_NET_30, [SELECT Payment_Type__c FROM Project__c WHERE Id = :contractRecord.Id].Payment_Type__c);

        BillingCondition__c rebateBillingCondition = TestHelper.createBillingCondition(Contract.BILLING_CONDITION_EXTECH, true) ;
        PaymentHandler.billingConditions = null;

        contractRecord.BillingCondition__c = rebateBillingCondition.Id;
        update contractRecord;
        System.assertEquals(Contract.PAYMENT_TYPE_NET_45, [SELECT Payment_Type__c FROM Project__c WHERE Id = :contractRecord.Id].Payment_Type__c);

        contractRecord.Payment_Type__c = Contract.PAYMENT_TYPE_NET_30;
        update contractRecord;
        Test.stopTest();
        System.assertEquals(Contract.PAYMENT_TYPE_NET_45, [SELECT Payment_Type__c FROM Project__c WHERE Id = :contractRecord.Id].Payment_Type__c);
    }

    @IsTest static void willSetPerformMMSync() {
        Date sDate = Date.newInstance(System.today().year(), 3, 1),
                eDate = sDate.addMonths(2).addDays(-1);

        Project__c contractSynced = TestHelper.createContract('TestContract Synced', sDate, eDate, false);
        contractSynced.Sync_with_MM__c = System.now();

        Project__c contractNotSynced = TestHelper.createContract('TestContract NOT Synced', sDate, eDate, false);
        insert new List<Project__c> { contractSynced, contractNotSynced };

        contractSynced.PerformMMSync__c = false;
        update contractSynced;

        Test.startTest();
        System.assertEquals(false, [SELECT PerformMMSync__c FROM Project__c WHERE Id = :contractNotSynced.Id].PerformMMSync__c);
        contractSynced.Name += '123';
        contractNotSynced.Name += '345';
        update new List<Project__c> { contractSynced, contractNotSynced };
        Test.stopTest();

        System.assertEquals(true, [SELECT PerformMMSync__c FROM Project__c WHERE Id = :contractSynced.Id].PerformMMSync__c);
        System.assertEquals(false, [SELECT PerformMMSync__c FROM Project__c WHERE Id = :contractNotSynced.Id].PerformMMSync__c);
    }

    @IsTest static void willSetXeroIdBasedOnBillingProfile() {
        XeroContact__c xeroContact = new XeroContact__c();
        xeroContact.XeroId__c = 'testXeroId';
        xeroContact.BillingCondition__c = Contract.BILLING_CONDITION_EXTECH;
        xeroContact.XeroSettings__c = TestHelper.createXeroEntity().Id;
        insert xeroContact;

        Date sDate = Date.newInstance(System.today().year(), 3, 1),
                eDate = sDate.addMonths(2).addDays(-1);

        BillingCondition__c rebateBillingCondition = TestHelper.createBillingCondition(Contract.BILLING_CONDITION_EXTECH, true) ;
        BillingCondition__c normalBillingCondition = TestHelper.createBillingCondition(Contract.BILLING_CONDITION_NORMAL, true) ;
        PaymentHandler.billingConditions = null;

        Project__c contractExtech = TestHelper.createContract('TestContract Extech', sDate, eDate, false);
        contractExtech.BillingCondition__c = rebateBillingCondition.Id;

        Project__c contractNormal = TestHelper.createContract('TestContract Normal', sDate, eDate, false);
        contractNormal.BillingCondition__c = normalBillingCondition.Id;

        Test.startTest();
        insert new List<Project__c> {contractNormal, contractExtech};

        contractNormal.Xero_Id__c = null;
        contractExtech.Xero_Id__c = null;
        update new List<Project__c> {contractNormal, contractExtech};
        Test.stopTest();

        contractExtech = [SELECT Xero_Id__c, Xero_Entity__c FROM Project__c WHERE Id = :contractExtech.Id];
        contractNormal = [SELECT Xero_Id__c, Xero_Entity__c FROM Project__c WHERE Id = :contractNormal.Id];

        System.assertEquals(xeroContact.XeroId__c, contractExtech.Xero_Id__c);
        System.assertEquals(xeroContact.XeroSettings__c, contractExtech.Xero_Entity__c);

        System.assertEquals(null, contractNormal.Xero_Id__c);
        System.assertEquals(null, contractNormal.Xero_Entity__c);
    }

    @IsTest static void willSetXeroContactBasedOnXeroId() {
         XeroSettings__c xs = TestHelper.createXeroEntity();

         Project__c contract1 = TestHelper.createContract('TestContract 1', null, null, false);
         Project__c contract2 = TestHelper.createContract('TestContract 1', null, null, false);
         Project__c contract3 = TestHelper.createContract('TestContract 1', null, null, false);
         insert new List<Project__c> {contract1, contract2, contract3};

         XeroEntity__c xeroContact1 = TestHelper.createXeroObject(xs);
         xeroContact1.XeroId__c = '127ac1df-9d07-4e27-a0b1-7d439f756845';
         XeroEntity__c xeroContact2 = TestHelper.createXeroObject(xs);
         xeroContact2.XeroId__c = '3284aa6b-a492-4b75-a84b-3821327498e0';
         insert new List<XeroEntity__c> {xeroContact1, xeroContact2};

         Test.startTest();
            contract1.Xero_Id__c = xeroContact1.XeroId__c;
            contract2.Xero_Id__c = xeroContact1.XeroId__c;
            contract3.Xero_Id__c = xeroContact2.XeroId__c;
            update new List<Project__c> {contract1, contract2, contract3};
         Test.stopTest();

         System.assertEquals(xeroContact1.Id, [SELECT XeroObject__c FROM Project__c WHERE Id = :contract1.Id].XeroObject__c);
         System.assertEquals(xeroContact1.Id, [SELECT XeroObject__c FROM Project__c WHERE Id = :contract2.Id].XeroObject__c);
         System.assertEquals(xeroContact2.Id, [SELECT XeroObject__c FROM Project__c WHERE Id = :contract3.Id].XeroObject__c);
    }

    @IsTest static void willCreatePaymentsForInvoiceType() {
        Date startDate = Date.newInstance(System.today().year() + 1, 1, 1);
        Date endDate = Date.newInstance(startDate.year(), 12, 31);
        Integer monthBetween = startDate.monthsBetween(endDate) + 1;

        Platform__c platformTV = TestHelper.createTrueViewPlatform();
        insert platformTV;

        Opportunity oppMonthlyInvoice = TestHelper.createOpportunity(startDate, endDate, platformTV, Utility.BILLING_PROFILES.Strike, false);
        oppMonthlyInvoice.Amount = 120000;

        Opportunity oppOneInvoice = TestHelper.createOpportunity(startDate, endDate, platformTV, Utility.BILLING_PROFILES.Strike, false);
        oppOneInvoice.Amount = 120000;
        oppOneInvoice.InvoicingType__c = Contract.INVOICING_TYPE_ONE;
        insert new List<Opportunity> {oppMonthlyInvoice, oppOneInvoice};

        OpportunityPlatform__c oppPlatform1 = TestHelper.createOpportunityPlatform(oppMonthlyInvoice.Id, platformTV.Id);
        OpportunityPlatform__c oppPlatform2 = TestHelper.createOpportunityPlatform(oppOneInvoice.Id, platformTV.Id);
        insert new List<OpportunityPlatform__c> {oppPlatform1, oppPlatform2};

        Test.startTest();
        oppMonthlyInvoice.StageName = 'Closed Won';
        oppOneInvoice.StageName = 'Closed Won';
        update new List<Opportunity> {oppMonthlyInvoice, oppOneInvoice};
        Test.stopTest();

        List<Sub_Project__c> paymentsMonthly = [SELECT Id, Client_Spend__c FROM Sub_Project__c WHERE Project__r.Opportunity__c = :oppMonthlyInvoice.Id ORDER BY Start_Date__c];
        List<Sub_Project__c> paymentsOne = [SELECT Id, Client_Spend__c FROM Sub_Project__c WHERE Project__r.Opportunity__c = :oppOneInvoice.Id];

        System.assertEquals(monthBetween, paymentsMonthly.size());
        System.assert((10000 < paymentsMonthly[0].Client_Spend__c) && (paymentsMonthly[0].Client_Spend__c < 11000));
        System.assertEquals(1, paymentsOne.size());
        System.assertEquals(paymentsOne[0].Client_Spend__c, oppOneInvoice.Amount);
    }

    @IsTest static void changeCurrencyOnContractTest() {
        // It should change currencyISOCode on all children objects: Payment__c , Sub_Project__c, Monthly_Distribution__c
        Date startDate = Date.valueOf('2019-05-22'), endDate = startDate.addDays(40);
        String initialCurrencyCode = 'USD', newCurrencyCode = 'EUR';

        Project__c contract = TestHelper.createContract('TestContract 1', startDate, endDate, false);
        contract.CurrencyIsoCode = initialCurrencyCode;
        insert contract;

        Project__c contractWithSubProjects = [
            SELECT Client_Spend__c, CurrencyIsoCode, (SELECT Client_Spend__c FROM Sub_Projects__r)
            FROM Project__c
            WHERE Id = :contract.Id
        ];
        System.assertEquals(contractWithSubProjects.CurrencyIsoCode, initialCurrencyCode);

        Set<Id> paymentIDs = new Set<Id>();
        for (Sub_Project__c payment :contractWithSubProjects.Sub_Projects__r) {
            paymentIDs.add(payment.Id);
        }
        List<Sub_Project__c> payments = [
            SELECT Client_Spend__c, CurrencyIsoCode, (SELECT Client_Spend__c, Start_Date__c, End_Date__c, CurrencyIsoCode FROM Projects__r)
            FROM Sub_Project__c
            WHERE Id IN :paymentIds
        ];
        for (Sub_Project__c payment :payments) {
            System.assertEquals(payment.CurrencyIsoCode, initialCurrencyCode);
            for (Payment__c project :payment.Projects__r) {
                System.assertEquals(project.CurrencyIsoCode, initialCurrencyCode);
            }
        }

        Test.startTest();
            contract.CurrencyIsoCode = newCurrencyCode;
            update contract;

            contractWithSubProjects = [
                SELECT Client_Spend__c, CurrencyIsoCode, (SELECT Client_Spend__c FROM Sub_Projects__r)
                FROM Project__c
                WHERE Id = :contract.Id
            ];
            System.assertEquals(contractWithSubProjects.CurrencyIsoCode, newCurrencyCode);

            paymentIDs = new Set<Id>();
            for (Sub_Project__c payment :contractWithSubProjects.Sub_Projects__r) {
                paymentIDs.add(payment.Id);
            }
        Test.stopTest();

        // re select payments after async action is completed
        payments = [
            SELECT Client_Spend__c, CurrencyIsoCode, (SELECT Client_Spend__c, Start_Date__c, End_Date__c, CurrencyIsoCode FROM Projects__r)
            FROM Sub_Project__c
            WHERE Id IN :paymentIDs
        ];
        for (Sub_Project__c payment :payments) {
            System.assertEquals(payment.CurrencyIsoCode, newCurrencyCode);
            for (Payment__c project :payment.Projects__r) {
                System.assertEquals(project.CurrencyIsoCode, newCurrencyCode);
            }
        }
    }

    @IsTest static void updateProjectAndPaymentMarginTypeIfContractMarginTypeIsChanged() {
        Date sDate = Date.newInstance(System.today().year(), System.today().addMonths(1).month(), 1),
                eDate = sDate.addMonths(1).addDays(-1);

        Project__c contractRecord = TestHelper.createContract(false);
        contractRecord.Margin_Type__c = '% of Budget';
        contractRecord.Start_Date__c = sDate;
        contractRecord.End_Date__c = eDate;
        insert contractRecord;

        List<Sub_Project__c> payments  = [SELECT Margin_Type__c FROM Sub_Project__c WHERE Project__c = :contractRecord.Id];
        List<Payment__c> projects = [SELECT Margin_Type__c FROM Payment__c WHERE Project__c = :contractRecord.Id];
        System.assert(payments.size() > 0);
        System.assert(projects.size() > 0);

        for (Sub_Project__c payment :payments) {
            System.assertEquals('% of Budget', payment.Margin_Type__c, 'Type had to be copied to payment.');
        }
        for (Payment__c project :projects) {
            System.assertEquals('% of Budget', project.Margin_Type__c, 'Type had to be copied to project.');
        }

        Test.startTest();
        contractRecord.Margin_Type__c = '% of Media';
        update contractRecord;
        Test.stopTest();

        payments  = [SELECT Margin_Type__c FROM Sub_Project__c WHERE Project__c = :contractRecord.Id];
        projects = [SELECT Margin_Type__c FROM Payment__c WHERE Project__c = :contractRecord.Id];
        for (Sub_Project__c payment :payments) {
            System.assertEquals('% of Media', payment.Margin_Type__c, 'Type had to be updated on payment.');
        }
        for (Payment__c project :projects) {
            System.assertEquals('% of Media', project.Margin_Type__c, 'Type had to be updated on project.');
        }
    }

    @IsTest static void updatePaymentInvoiceAmountIfContractBillingConditionIsChanged_NoCostStructure() {
        Date sDate = Date.newInstance(System.today().year(), System.today().addMonths(1).month(), 1),
                eDate = sDate.addMonths(1).addDays(-1);

        Platform__c platformTrueView = TestHelper.createTrueViewPlatform();
        insert platformTrueView;

        Opportunity opp = TestHelper.createOpportunity(sDate, eDate, platformTrueView, Utility.BILLING_PROFILES.Strike, false);
        insert opp;
        System.assertEquals(opp.Id, TestHelper.opportunityRecord.Id);

        OpportunityPlatform__c opPlatform = TestHelper.createOpportunityPlatform(opp.Id, platformTrueView);
        opPlatform.CostStructure__c = '';
        opPlatform.CPV__c = 0;
        opPlatform.NoCostStructure__c = true;
        insert opPlatform;

        Project__c contractRecord = TestHelper.createContract('Test Contract', sDate, eDate, false);
        contractRecord.Client_Spend__c = 100;
        contractRecord.Margin__c = 50;
        insert contractRecord;

        BillingCondition__c initialBC = TestHelper.billingConditionRecord;
        System.assertEquals(contractRecord.BillingCondition__c, initialBC.Id);

        List<Payment__c> projects = [SELECT BillingCondition__c, CostStructure__c, Quantity__c, AmountDelivered__c, AdWordsSpend__c FROM Payment__c WHERE Project__c = :contractRecord.Id];
        System.assert(projects.size() > 0);
        for (Payment__c project :projects) {
            System.assertEquals(project.BillingCondition__c, initialBC.Name);
        }

        TestHelper.createMediaSpend(projects[0].Id, 600, 100, 0);

        List<Sub_Project__c> payments  = [SELECT Billing_Conditions__c, Invoice_Amount__c FROM Sub_Project__c WHERE Project__c = :contractRecord.Id];
        System.assert(payments.size() > 0);

        Decimal initialInvoiceAmount = 0;
        for (Sub_Project__c payment :payments) {
            System.assertEquals(payment.Billing_Conditions__c, initialBC.Name);
            initialInvoiceAmount += payment.Invoice_Amount__c;
        }
        System.assert(initialInvoiceAmount > 0);

        Test.startTest();
        BillingCondition__c newBC = TestHelper.createBillingCondition('Instant Rebate', true);
        PaymentHandler.billingConditions = null;
        contractRecord.BillingCondition__c = newBC.Id;
        update contractRecord;
        Test.stopTest();

        payments  = [SELECT Billing_Conditions__c, Invoice_Amount__c FROM Sub_Project__c WHERE Project__c = :contractRecord.Id];
        System.assert(payments.size() > 0);
        Decimal changedInvoiceAmount = 0;
        for (Sub_Project__c payment :payments) {
            System.assertEquals(payment.Billing_Conditions__c, newBC.Name);
            changedInvoiceAmount += payment.Invoice_Amount__c;
        }

        System.assertNotEquals(initialInvoiceAmount, changedInvoiceAmount);
    }

    @IsTest static void updatePaymentInvoiceAmountIfBillingConditionStrikeProfitUpdated() {
        Date todayPlusMonth = System.today().addMonths(1);
        Date sDate = Date.newInstance(todayPlusMonth.year(), todayPlusMonth.month(), 1),
                eDate = sDate.addMonths(1).addDays(-1);

        BillingCondition__c initialBC = TestHelper.createBillingCondition('Instant Rebate 50:50 / 50%', false);
        initialBC.Rebate_Rate__c = null;
        initialBC.Strike_Profit__c = 50;
        initialBC.Rebate_Type__c = 'Instant';
        initialBC.RecordTypeId = Schema.SObjectType.BillingCondition__c.getRecordTypeInfosByName().get('Rebate').getRecordTypeId();
        insert initialBC;

        Platform__c platformTrueView = TestHelper.createTrueViewPlatform();
        insert platformTrueView;

        Opportunity opp = TestHelper.createOpportunity(sDate, eDate, platformTrueView, Utility.BILLING_PROFILES.Strike, false);
        insert opp;
        System.assertEquals(opp.Id, TestHelper.opportunityRecord.Id);

        OpportunityPlatform__c opPlatform = TestHelper.createOpportunityPlatform(opp.Id, platformTrueView);
        opPlatform.CostStructure__c = '';
        opPlatform.CPV__c = 0;
        opPlatform.NoCostStructure__c = true;
        insert opPlatform;

        Project__c contractRecord = TestHelper.createContract('Test Contract', sDate, eDate, false);
        contractRecord.Client_Spend__c = 100;
        contractRecord.Margin__c = 50;
        insert contractRecord;

        System.assertEquals(contractRecord.BillingCondition__c, initialBC.Id);

        List<Payment__c> projects = [SELECT BillingCondition__c, CostStructure__c, Quantity__c, AmountDelivered__c, AdWordsSpend__c, Client_Spend__c FROM Payment__c WHERE Project__c = :contractRecord.Id];
        System.assert(projects.size() > 0);
        for (Payment__c project :projects) {
            System.assertEquals(project.BillingCondition__c, initialBC.Name);
        }

        Double amount = 600;
        TestHelper.createMediaSpend(projects[0].Id, amount, 100, 0);

        List<Sub_Project__c> payments  = [SELECT Billing_Conditions__c, Invoice_Amount__c FROM Sub_Project__c WHERE Project__c = :contractRecord.Id];
        System.assert(payments.size() > 0);

        Decimal initialInvoiceAmount = 0;
        for (Sub_Project__c payment :payments) {
            System.assertEquals(payment.Billing_Conditions__c, initialBC.Name);
            initialInvoiceAmount += payment.Invoice_Amount__c;
        }
        System.assert(initialInvoiceAmount > 0);
        Decimal strikeProfit = initialBC.Strike_Profit__c/100,
                mediaSpend = amount,
                expectedInvoiceAmount = (projects[0].Client_Spend__c - mediaSpend) * strikeProfit + mediaSpend;

        System.assert(initialInvoiceAmount == expectedInvoiceAmount);

        Test.startTest();
        PaymentHandler.billingConditions = null;
        initialBC.Strike_Profit__c = initialBC.Strike_Profit__c + 10;
        update initialBC;
        Test.stopTest();

        payments  = [SELECT Billing_Conditions__c, Invoice_Amount__c FROM Sub_Project__c WHERE Project__c = :contractRecord.Id];
        System.assert(payments.size() > 0);
        Decimal changedInvoiceAmount = 0;
        for (Sub_Project__c payment :payments) {
            changedInvoiceAmount += payment.Invoice_Amount__c;
        }
        System.assertNotEquals(initialInvoiceAmount, changedInvoiceAmount);
        System.assertEquals(changedInvoiceAmount, (projects[0].Client_Spend__c - mediaSpend) * (initialBC.Strike_Profit__c/100) + mediaSpend);
    }
}