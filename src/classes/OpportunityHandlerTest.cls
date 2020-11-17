@IsTest
private class OpportunityHandlerTest {

    @IsTest static void updateOpportunityStageNameClosedWon() {
        User usr = TestHelper.createUser();
        Account acc = TestHelper.createAccount();
        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        insert opp;

        Platform__c platformTV = TestHelper.createPlatform('TrueView', 'TV');
        upsert platformTV;

        OpportunityPlatform__c oppPlatform = TestHelper.createOpportunityPlatform(opp.Id, platformTV.Id);
        insert oppPlatform;

        List<Project__c> contracts = [SELECT Id, Opportunity__c FROM Project__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(contracts.size(), 0, 'No Contract should NOT exist for NOT Closed Won opportunity.');

        Test.startTest();
        opp.StageName = ContactOpportunityHandler.CLOSED_WON;
        opp.Brand__c = TestHelper.createBrand('TestBrand').Id;
        update opp;
        Test.stopTest();
        System.assertEquals(contracts.size() + 1, [SELECT COUNT() FROM Project__c WHERE Opportunity__c =: opp.Id], 'A Contract should be created for Closed Won opportunity.');
    }

    @IsTest static void willCreateAndAssignBrandAccountWhenDoesNotExistOnInsert() {
        User usr = TestHelper.createUser();
        Account acc = TestHelper.createAccount();
        Opportunity opp = TestHelper.createOpportunity(usr, acc);

        Test.startTest();
        opp.Brand__c = TestHelper.createBrand('TestBrand').Id;
        opp.BrandAccount__c = null;
        insert opp;
        Test.stopTest();
        
        opp = [SELECT BrandAccount__c FROM Opportunity WHERE Id = :opp.Id];
        System.assert(String.isNotBlank(opp.BrandAccount__c));
    }

    @IsTest static void willCreateAndAssignBrandAccountWhenDoesNotExistOnUpdate() {
        User usr = TestHelper.createUser();
        Account acc = TestHelper.createAccount();
        Opportunity opp = TestHelper.createOpportunity(usr, acc);

        Test.startTest();
        insert opp;
        System.assert(String.isBlank([SELECT BrandAccount__c FROM Opportunity WHERE Id = :opp.Id].BrandAccount__c));

        opp.Brand__c = TestHelper.createBrand('testBrand').Id;
        update opp;
        Test.stopTest();
        
        opp = [SELECT BrandAccount__c FROM Opportunity WHERE Id = :opp.Id];
        System.assert(String.isNotBlank(opp.BrandAccount__c));
    }

    @IsTest static void willAssignExistingBrandAccount() {
        User usr = TestHelper.createUser();
        Account acc = TestHelper.createAccount();
        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        Brand__c brand = TestHelper.createBrand('testBrand');
        Brand_Account__c brandAcc = TestHelper.createBrandAccount(acc.Id, brand.Id);

        Test.startTest();
        opp.Brand__c = brand.Id;
        insert opp;
        Test.stopTest();
        
        opp = [SELECT BrandAccount__c FROM Opportunity WHERE Id = :opp.Id];
        System.assert(String.isNotBlank(opp.BrandAccount__c));
        System.assertEquals(brandAcc.Id, opp.BrandAccount__c);
    }

    @IsTest static void willCreateNewBrandAccountWhenBrandIsChanged() {
        String newBrandName = 'brandNew';
        String accName = 'accNew';

        User usr = TestHelper.createUser();
        Account acc = TestHelper.createAccount(accName);
        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        Brand__c brand = TestHelper.createBrand('testBrand');
        Brand__c brandNew = TestHelper.createBrand(newBrandName);
        Brand_Account__c brandAcc  = TestHelper.createBrandAccount(acc.Id, brand.Id);

        opp.Brand__c = brand.Id;
        insert opp;

        opp = [SELECT Id,BrandAccount__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(brandAcc.Id, opp.BrandAccount__c, 'BrandAccount should be assigned to Opportunity');

        Integer existingBrandAccountAmount = (new List<Brand_Account__c>{brandAcc}).size();
        System.assertEquals(existingBrandAccountAmount, [SELECT COUNT() FROM Brand_Account__c], 'There should be one existing BrandAccount');

        Test.startTest();
        opp.Brand__c = brandNew.Id;
        update opp;
        Test.stopTest();

        opp = [SELECT BrandAccount__c, BrandAccount__r.Brand_Account__c, BrandAccount__r.Name FROM Opportunity WHERE Id = :opp.Id];
        System.assert(String.isNotBlank(opp.BrandAccount__c));
        String newBrandAccountName = newBrandName + ' / ' + accName;
        System.assertEquals(opp.BrandAccount__r.Brand_Account__c, newBrandAccountName, 'New BrandAccount name should be "'+newBrandAccountName+'"');
        System.assertEquals(opp.BrandAccount__r.Name, newBrandAccountName, 'New BrandAccount name should be "'+newBrandAccountName+'"');
        System.assertEquals(existingBrandAccountAmount+1, [SELECT COUNT() FROM Brand_Account__c], 'There should be two BrandAccounts');
    }

    @IsTest static void willCreateNewBrandAccountWhenAccountIsChanged() {
        String brandName = 'brandName';
        String newAccName = 'accNew';

        User usr = TestHelper.createUser();
        Account acc = TestHelper.createAccount();
        Account newAccObject = TestHelper.createAccount(newAccName);
        Opportunity oppObject = TestHelper.createOpportunity(usr, acc);
        Brand__c brand = TestHelper.createBrand(brandName);
        Brand_Account__c brandAcc = TestHelper.createBrandAccount(acc.Id, brand.Id);

        oppObject.Brand__c = brand.Id;
        insert oppObject;

        oppObject = [SELECT Id,BrandAccount__c,BrandAccount__r.Brand_Account__c, BrandAccount__r.Name FROM Opportunity WHERE Id = :oppObject.Id];
        System.assertEquals(brandAcc.Id, oppObject.BrandAccount__c, 'BrandAccount should be assigned to Opportunity');
        System.assertEquals(oppObject.BrandAccount__r.Brand_Account__c, brandName + ' / ' + acc.Name, 'BrandAccount name should be equal to "'+brandName+' / '+acc.Name+'"');

        Integer brandAccountAmount = (new List<Brand_Account__c>{brandAcc}).size();
        System.assertEquals(brandAccountAmount, [SELECT COUNT() FROM Brand_Account__c], 'There should be one existing BrandAccount');

        Test.startTest();
        oppObject.AccountId = newAccObject.Id;
        update oppObject;
        Test.stopTest();

        Opportunity opp = [SELECT BrandAccount__c, BrandAccount__r.Brand_Account__c, BrandAccount__r.Name FROM Opportunity WHERE Id = :oppObject.Id];
        System.assert(String.isNotBlank(opp.BrandAccount__c));
        String newBrandAccountName = brandName + ' / ' + newAccName;
        System.assertEquals(opp.BrandAccount__r.Brand_Account__c, newBrandAccountName, 'New BrandAccount name should be "'+newBrandAccountName+'"');
        System.assertEquals(opp.BrandAccount__r.Name, newBrandAccountName, 'New BrandAccount name should be "'+newBrandAccountName+'"');

        // one new brandAccount is created
        System.assertEquals(brandAccountAmount+1, [SELECT COUNT() FROM Brand_Account__c], 'There should be two BrandAccounts');
    }

    @IsTest static void willUseExistingBrandAccountWhenBrandIsChanged() {
        String existingBrandName = 'brandNew';
        String accName = 'accNew';

        User usr = TestHelper.createUser();
        Account accObject = TestHelper.createAccount(accName);
        Brand__c brand = TestHelper.createBrand('testBrand');
        Brand__c existingBrand = TestHelper.createBrand(existingBrandName);
        Brand_Account__c brandAcc = TestHelper.createBrandAccount(accObject.Id, brand.Id);
        Brand_Account__c existingBrandAcc = TestHelper.createBrandAccount(accObject.Id, existingBrand.Id);
        Opportunity oppObject = TestHelper.createOpportunity(usr, accObject);

        oppObject.Brand__c = brand.Id;
        insert oppObject;

        Integer brandAccountAmount = (new List<Brand_Account__c>{brandAcc, existingBrandAcc}).size();

        oppObject = [SELECT Id,BrandAccount__c FROM Opportunity WHERE Id = :oppObject.Id];
        System.assertEquals(brandAcc.Id, oppObject.BrandAccount__c, 'BrandAccount should be assigned to Opportunity');
        System.assertEquals(brandAccountAmount, [SELECT COUNT() FROM Brand_Account__c], 'There should be two BrandAccounts');

        Test.startTest();
        oppObject.Brand__c = existingBrand.Id;
        update oppObject;
        Test.stopTest();

        Opportunity opp = [SELECT BrandAccount__c, BrandAccount__r.Brand_Account__c, BrandAccount__r.Name FROM Opportunity WHERE Id = :oppObject.Id];
        System.assert(String.isNotBlank(opp.BrandAccount__c));
        System.assertEquals(opp.BrandAccount__r.Brand_Account__c, existingBrandName + ' / ' + accName, 'New BrandAccount name should be "'+existingBrandName + ' / ' + accName+'"');
        System.assertEquals(opp.BrandAccount__c, existingBrandAcc.Id, 'Existing BrandAccount record should be assiged to Contract');
        // no new brandAccount is created
        System.assertEquals(brandAccountAmount, [SELECT COUNT() FROM Brand_Account__c], 'No new BrandAccounts should be created');
    }

    @IsTest static void willUseExistingBrandAccountWhenAccountIsChanged() {
        String brandName = 'brandName';
        String newAccName = 'accNew';

        User usr = TestHelper.createUser();
        Account acc = TestHelper.createAccount();
        Account newAcc = TestHelper.createAccount(newAccName);
        Brand__c brand = TestHelper.createBrand(brandName);
        Brand_Account__c brandAcc = TestHelper.createBrandAccount(acc.Id, brand.Id);
        Brand_Account__c existingBrandAcc = TestHelper.createBrandAccount(newAcc.Id, brand.Id);
        Opportunity opp = TestHelper.createOpportunity(usr, acc);

        opp.Brand__c = brand.Id;
        insert opp;

        opp = [SELECT Id,BrandAccount__c,BrandAccount__r.Brand_Account__c, BrandAccount__r.Name FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(brandAcc.Id, opp.BrandAccount__c, 'BrandAccount should be assigned to Opportunity');
        System.assertEquals(opp.BrandAccount__r.Brand_Account__c, brandName + ' / ' + acc.Name, 'BrandAccount name should be equal to "'+brandName+' / '+acc.Name+'"');

        Integer brandAccountAmount = (new List<Brand_Account__c>{brandAcc, existingBrandAcc}).size();
        System.assertEquals(brandAccountAmount, [SELECT COUNT() FROM Brand_Account__c], 'There should be two BrandAccounts');

        Test.startTest();
        opp.AccountId = newAcc.Id;
        update opp;
        Test.stopTest();

        opp = [SELECT BrandAccount__c, BrandAccount__r.Brand_Account__c, BrandAccount__r.Name FROM Opportunity WHERE Id = :opp.Id];
        System.assert(String.isNotBlank(opp.BrandAccount__c));
        System.assertEquals(opp.BrandAccount__r.Brand_Account__c, brandName + ' / ' + newAcc.Name, 'New BrandAccount name should be "'+brandName + ' / ' + newAcc.Name+'"');
        System.assertEquals(opp.BrandAccount__c, existingBrandAcc.Id, 'Existing BrandAccount record should be assiged to Contract');
        // no new brandAccount is created
        System.assertEquals(brandAccountAmount, [SELECT COUNT() FROM Brand_Account__c], 'No new BrandAccounts should be created');
    }

    @IsTest static void willSetPaymentType() {
        User usr = TestHelper.createUser();
        Account accObject = TestHelper.createAccount();

        Account accNet30 = TestHelper.createAccount('AccountNet30', false);
        accNet30.DefaultPaymentType__c = Contract.PAYMENT_TYPE_NET_30;
        Account accNet45 = TestHelper.createAccount('AccountNet45', false);
        accNet45.DefaultPaymentType__c = Contract.PAYMENT_TYPE_NET_45;
        insert new List<Account> {accNet30, accNet45};

        Opportunity oppObject      = TestHelper.createOpportunity(usr, accObject);
        Opportunity oppNet30 = TestHelper.createOpportunity(usr, accNet30);
        oppNet30.Payment_Type__c = '';
        Opportunity oppNet45 = TestHelper.createOpportunity(usr, accNet45);
        oppNet45.Payment_Type__c = '';

        insert new List<Opportunity> {oppObject, oppNet30, oppNet45};

        Test.startTest();
        oppObject.Payment_Type__c = Contract.PAYMENT_TYPE_NET_30;
        update oppObject;

        System.assertEquals(Contract.PAYMENT_TYPE_NET_30, [SELECT Payment_Type__c FROM Opportunity WHERE Id = :oppObject.Id].Payment_Type__c);

        oppObject.BillingCondition__c = TestHelper.createBillingCondition(Contract.BILLING_CONDITION_EXTECH).Id;
        update oppObject;

        System.assertEquals(Contract.PAYMENT_TYPE_NET_45, [SELECT Payment_Type__c FROM Opportunity WHERE Id = :oppObject.Id].Payment_Type__c);

        oppObject.Payment_Type__c = Contract.PAYMENT_TYPE_NET_30;
        update oppObject;
        Test.stopTest();

        //will override for Extech
        System.assertEquals(Contract.PAYMENT_TYPE_NET_45, [SELECT Payment_Type__c FROM Opportunity WHERE Id = :oppObject.Id].Payment_Type__c);
        System.assertEquals(Contract.PAYMENT_TYPE_NET_30, [SELECT Payment_Type__c FROM Opportunity WHERE Id = :oppNet30.Id].Payment_Type__c);
        System.assertEquals(Contract.PAYMENT_TYPE_NET_45, [SELECT Payment_Type__c FROM Opportunity WHERE Id = :oppNet45.Id].Payment_Type__c);
    }
}