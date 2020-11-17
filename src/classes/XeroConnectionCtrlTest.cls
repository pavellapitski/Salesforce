@isTest private class XeroConnectionCtrlTest {

    @isTest static void testAllowedXeroEntitiesBasedOnCurrencyForContractOnly() {
        User standardUser = TestHelper.createUser(TestHelper.generateUniqueEmail());

        XeroSettings__c xsUSDEUR = TestHelper.createXeroEntityByRegion('NA', false);
        xsUSDEUR.Currency__c = 'USD;EUR';
        xsUSDEUR.Name = 'xsUSDEUR';

        XeroSettings__c xsNZDJPYEUR = TestHelper.createXeroEntityByRegion('NA', false);
        xsNZDJPYEUR.Currency__c = 'NZD;JPY;EUR';
        xsNZDJPYEUR.Name = 'xsNZDJPYEUR';

        XeroSettings__c xsNZDPHP = TestHelper.createXeroEntityByRegion('NA', false);
        xsNZDPHP.Currency__c = 'NZD;PHP';
        xsNZDPHP.Name = 'xsNZDPHP';

        XeroSettings__c xsPHPSGD = TestHelper.createXeroEntityByRegion('NA', false);
        xsPHPSGD.Currency__c = 'SGD;PHP';
        xsPHPSGD.Name = 'xsPHPSGD';

        insert new List<XeroSettings__c>{xsUSDEUR,xsNZDJPYEUR,xsNZDPHP,xsPHPSGD};

        System.runAs(standardUser) {
            Account account = TestHelper.createAccount('TestAccountName', false);
            account.Region__c = 'EMEA';
            account.Phone = '(12)121212';
            account.Fax = '(12)444444544';
            insert account;

            Project__c contract = TestHelper.createContractNoInsert(account.Id, 'TestContractName', null);
            contract.Start_Date__c = Date.valueOf('2019-01-01');
            contract.End_Date__c = Date.valueOf('2019-01-01').addDays(100);
            contract.CurrencyIsoCode = 'EUR';
            insert contract;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
            PageReference xeroConnectionPage = Page.XeroConnection;
            xeroConnectionPage.getParameters().put('contractId', contract.Id);
            Test.setCurrentPage(xeroConnectionPage);

            XeroConnectionCtrl ctrl = new XeroConnectionCtrl();
            System.assertEquals(ctrl.getXeroEntities().size(), 3, 'There should be two Xero Entities and one "None" option available for EUR currency.');

            Test.stopTest();
        }
    }

    @isTest static void testAllowedXeroEntitiesBasedOnRegionForAccountOnly() {
        User standardUser = TestHelper.createUser(TestHelper.generateUniqueEmail());

        XeroSettings__c xsUSDEUR = TestHelper.createXeroEntityByRegion('NA', false);
        xsUSDEUR.Currency__c = 'USD;EUR';
        xsUSDEUR.Name = 'xsUSDEUR';

        XeroSettings__c xsNZDJPYEUR = TestHelper.createXeroEntityByRegion('NA', false);
        xsNZDJPYEUR.Currency__c = 'NZD;JPY;EUR';
        xsNZDJPYEUR.Name = 'xsNZDJPYEUR';

        XeroSettings__c xsNZDPHP = TestHelper.createXeroEntityByRegion('NA', false);
        xsNZDPHP.Currency__c = 'NZD;PHP';
        xsNZDPHP.Name = 'xsNZDPHP';

        XeroSettings__c xsPHPSGD = TestHelper.createXeroEntityByRegion('NA', false);
        xsPHPSGD.Currency__c = 'SGD;PHP';
        xsPHPSGD.Name = 'xsPHPSGD';

        insert new List<XeroSettings__c>{xsUSDEUR,xsNZDJPYEUR,xsNZDPHP,xsPHPSGD};

        System.runAs(standardUser) {
            Account account = TestHelper.createAccount('TestAccountName', false);
            account.Region__c = 'NA';
            account.Phone = '(12)121212';
            account.Fax = '(12)444444544';
            insert account;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
            PageReference xeroConnectionPage = Page.XeroConnection;
            xeroConnectionPage.getParameters().put('accountId', account.Id);
            Test.setCurrentPage(xeroConnectionPage);

            XeroConnectionCtrl ctrl = new XeroConnectionCtrl();
            System.assertEquals(ctrl.getXeroEntities().size(), 5, 'There should be all inserted Xero Entities and one "None" option available for "NA" region.');

            Test.stopTest();
        }
    }

    // new unit tests
    @isTest static void selectXeroContactTest() {
        String region = 'NA';
        Date sDate = Date.valueOf('2019-01-01');
        Date eDate = sDate.addDays(40);

        User standardUser = TestHelper.createUser(TestHelper.generateUniqueEmail());
        XeroSettings__c xsUSDEUR = TestHelper.createXeroEntityByRegion('NA', false);
        xsUSDEUR.Currency__c = 'USD;EUR';
        xsUSDEUR.Name = 'xsUSDEUR';
        insert xsUSDEUR;

        System.runAs(standardUser) {
            Account account = TestHelper.createAccount('TestAccountName', false);
            account.Region__c = region;
            account.Phone = '(12)121212';
            account.Fax = '(12)444444544';
            insert account;

            Project__c contract = TestHelper.createContractNoInsert(account.Id, 'TestContractName', null);
            contract.Start_Date__c = sDate;
            contract.End_Date__c = eDate;
            insert contract;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
            PageReference xeroConnectionPage = Page.XeroConnection;
            xeroConnectionPage.getParameters().put('contractId', contract.Id);
            Test.setCurrentPage(xeroConnectionPage);

            XeroConnectionCtrl ctrl = new XeroConnectionCtrl();
            ctrl.xeroId = xsUSDEUR.Id;
            ctrl.selectXeroContact();
            XeroWrappers.XeroContact xeroContact = ctrl.selectedContact;

            Test.stopTest();
            XeroWrappers.XeroContact expectingXeroContact = XeroTestHelper.createXeroContact();
            System.assertNotEquals(xeroContact, null);
            System.assertEquals(expectingXeroContact.ContactID, xeroContact.ContactID);
        }
    }

    @isTest static void displayRelatedContactForContractTest() {
        // Display Xero Contact Info for Contract
        String region = 'NA';
        Date sDate = Date.valueOf('2019-01-01');
        Date eDate = sDate.addDays(40);

        User standardUser = TestHelper.createUser(TestHelper.generateUniqueEmail());
        XeroSettings__c xsUSDEUR = TestHelper.createXeroEntityByRegion('NA', false);
        xsUSDEUR.Currency__c = 'USD;EUR';
        xsUSDEUR.Name = 'xsUSDEUR';
        insert xsUSDEUR;

        System.runAs(standardUser) {
            Account account = TestHelper.createAccount('TestAccountName', false);
            account.Region__c = region;
            account.Phone = '(12)121212';
            account.Fax = '(12)444444544';
            insert account;

            XeroWrappers.XeroContact expectingXeroContact = XeroTestHelper.createXeroContact();

            Project__c contract = TestHelper.createContractNoInsert(account.Id, 'TestContractName', null);
            contract.Start_Date__c = sDate;
            contract.End_Date__c = eDate;
            contract.Xero_Entity__c = xsUSDEUR.Id;
            contract.Xero_Id__c = expectingXeroContact.ContactID;
            insert contract;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
            PageReference xeroConnectionPage = Page.XeroConnection;
            xeroConnectionPage.getParameters().put('contractId', contract.Id);
            Test.setCurrentPage(xeroConnectionPage);

            XeroConnectionCtrl ctrl = new XeroConnectionCtrl();
            ctrl.xeroId = null;
            ctrl.selectedContact = null;
            ctrl.displayRelatedContact();

            System.assertEquals(ctrl.xeroId, contract.Xero_Entity__c);
            System.assertEquals(ctrl.selectedContact.ContactID, contract.Xero_Id__c);
            Test.stopTest();
        }
    }

    @isTest static void displayRelatedContactForAccountTest() {
        // Display Xero Contact Info for Account
        String region = 'NA';

        User standardUser = TestHelper.createUser(TestHelper.generateUniqueEmail());
        XeroWrappers.XeroContact expectingXeroContact = XeroTestHelper.createXeroContact();
        XeroSettings__c xs = TestHelper.createXeroEntity();

        System.runAs(standardUser) {
            Account account = TestHelper.createAccount('TestAccountName', false);
            account.Region__c = region;
            account.Phone = '(12)121212';
            account.Fax = '(12)444444544';
            account.Xero_Entity__c = xs.Id;
            account.Xero_Id__c = expectingXeroContact.ContactID;
            insert account;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
            PageReference xeroConnectionPage = Page.XeroConnection;
            xeroConnectionPage.getParameters().put('accountId', account.Id);
            Test.setCurrentPage(xeroConnectionPage);

            XeroConnectionCtrl ctrl = new XeroConnectionCtrl();
            ctrl.xeroId = null;
            ctrl.selectedContact = null;
            ctrl.displayRelatedContact();

            System.assertEquals(ctrl.xeroId, account.Xero_Entity__c);
            System.assertEquals(ctrl.selectedContact.ContactID, account.Xero_Id__c);
            Test.stopTest();
        }
    }

    @isTest static void createNewXeroContactForContractTest() {
        String region = 'NA';
        Date sDate = Date.valueOf('2019-01-01');
        Date eDate = sDate.addDays(40);

        User standardUser = TestHelper.createUser(TestHelper.generateUniqueEmail());
        XeroSettings__c xsUSDEUR = TestHelper.createXeroEntityByRegion('NA', false);
        xsUSDEUR.Currency__c = 'USD;EUR';
        xsUSDEUR.Name = 'xsUSDEUR';
        insert xsUSDEUR;

        System.runAs(standardUser) {
            Account account = TestHelper.createAccount('TestAccountName', false);
            account.Region__c = region;
            account.Phone = '(12)121212';
            account.Fax = '(12)444444544';
            insert account;

            Project__c contract = TestHelper.createContractNoInsert(account.Id, 'TestContractName', null);
            contract.Start_Date__c = sDate;
            contract.End_Date__c = eDate;
            insert contract;
            System.assertEquals(contract.Xero_Entity__c, null, 'Xero Settings shouldn\'t be linked for now');
            System.assertEquals(contract.Xero_Id__c, null, 'Xero Contract shouldn\'t be linked for now');

            Test.startTest();

            XeroWrappers.XeroContact expectingXeroContact = XeroTestHelper.createXeroContact();

            Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
            PageReference xeroConnectionPage = Page.XeroConnection;
            xeroConnectionPage.getParameters().put('contractId', contract.Id);
            Test.setCurrentPage(xeroConnectionPage);

            XeroConnectionCtrl ctrl = new XeroConnectionCtrl();
            List<SelectOption> xeroSettingOptions = ctrl.getXeroEntities();
            ctrl.xeroId = xsUSDEUR.Id;
            ctrl.createXeroAccount();

            Test.stopTest();

            contract = [SELECT Xero_Entity__c, Xero_ID__c FROM Project__c WHERE Id = :contract.Id];
            System.assertEquals(contract.Xero_Entity__c, xsUSDEUR.Id, 'Xero Settings should be linked');
            System.assertEquals(contract.Xero_Id__c, expectingXeroContact.ContactID, 'Xero Contract shouldbe linked');
        }
    }

    @isTest static void createNewXeroContactForAccountTest() {
        String region = 'NA';
        Date sDate = Date.valueOf('2019-01-01');
        Date eDate = sDate.addDays(40);

        User standardUser = TestHelper.createUser(TestHelper.generateUniqueEmail());
        XeroSettings__c xs = TestHelper.createXeroEntity();

        System.runAs(standardUser) {
            Account account = TestHelper.createAccount('TestAccountName', false);
            account.Region__c = region;
            account.Phone = '(12)121212';
            account.Fax = '(12)444444544';
            insert account;

            System.assertEquals(account.Xero_Entity__c, null, 'Xero Settings shouldn\'t be linked for now');
            System.assertEquals(account.Xero_Id__c, null, 'Xero Contract shouldn\'t be linked for now');

            Test.startTest();

            XeroWrappers.XeroContact expectingXeroContact = XeroTestHelper.createXeroContact();

            Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
            PageReference xeroConnectionPage = Page.XeroConnection;
            xeroConnectionPage.getParameters().put('accountId', account.Id);
            Test.setCurrentPage(xeroConnectionPage);

            XeroConnectionCtrl ctrl = new XeroConnectionCtrl();
            ctrl.xeroId = xs.Id;
            ctrl.createXeroAccount();

            Test.stopTest();

            account = [SELECT Xero_Entity__c, Xero_ID__c FROM Account WHERE Id = :account.Id];
            System.assertEquals(account.Xero_Entity__c, xs.Id, 'Xero Settings should be linked');
            System.assertEquals(account.Xero_Id__c, expectingXeroContact.ContactID, 'Xero Settings should be linked');
        }
    }

    @isTest private static void disconnectContractTest() {
        String region = 'NA';

        User standardUser = TestHelper.createUser(TestHelper.generateUniqueEmail());

        Account account = TestHelper.createAccount('TestAccountName', false);
        account.Region__c = region;
        insert account;

        XeroSettings__c xs = TestHelper.createXeroEntityByRegion(region, true);
        Project__c contract;

        Test.startTest();
        System.runAs(standardUser) {
            contract = TestHelper.createContractNoInsert(account.Id, 'TestContract', NULL);
            insert contract;

            PageReference xeroConnectionPage = Page.XeroConnection;
            xeroConnectionPage.getParameters().put('contractId', contract.Id);
            Test.setCurrentPage(xeroConnectionPage);

            XeroConnectionCtrl ctrl = new XeroConnectionCtrl();
            ctrl.xeroId = xs.Id;
            ctrl.connectWithXero();
            ctrl.selectedContact = XeroTestHelper.createXeroContact();
            ctrl.connectWithXeroContact();

            contract = [SELECT Xero_Id__c, Xero_Entity__c FROM Project__c WHERE Id = :contract.Id];
            System.assert(String.isNotBlank(contract.Xero_Id__c), 'Contract should be connected!');
            System.assert(String.isNotBlank(contract.Xero_Entity__c), 'Contract should be connected!');

            ctrl.disconnect();
        }
        Test.stopTest();

        contract = [SELECT Xero_Id__c, Xero_Entity__c FROM Project__c WHERE Id = :contract.Id];

        System.assert(String.isBlank(contract.Xero_Id__c), 'Contract should be disconnected!');
        System.assert(String.isBlank(contract.Xero_Entity__c), 'Contract should be disconnected!');
    }

    @isTest private static void disconnectAccountTest() {
        String region = 'NA';

        User standardUser = TestHelper.createUser(TestHelper.generateUniqueEmail());

        Account account = TestHelper.createAccount('TestAccountName', false);
        account.Region__c = region;
        insert account;

        XeroSettings__c xs = TestHelper.createXeroEntityByRegion(region, true);

        Test.startTest();
        System.runAs(standardUser) {
            PageReference xeroConnectionPage = Page.XeroConnection;
            xeroConnectionPage.getParameters().put('accountId', account.Id);
            Test.setCurrentPage(xeroConnectionPage);

            XeroConnectionCtrl ctrl = new XeroConnectionCtrl();
            ctrl.xeroId = xs.Id;
            ctrl.connectWithXero();
            ctrl.selectedContact = XeroTestHelper.createXeroContact();
            ctrl.connectWithXeroContact();

            account = [SELECT Xero_Id__c, Xero_Entity__c FROM Account WHERE Id = :account.Id];
            System.assert(String.isNotBlank(account.Xero_Id__c), 'Account should be connected!');
            System.assert(String.isNotBlank(account.Xero_Entity__c), 'Account should be connected!');

            ctrl.disconnect();
        }
        Test.stopTest();

        account = [SELECT Xero_Id__c, Xero_Entity__c FROM Account WHERE Id = :account.Id];

        System.assert(String.isBlank(account.Xero_Id__c), 'Account should be disconnected!');
        System.assert(String.isBlank(account.Xero_Entity__c), 'Account should be disconnected!');
    }

    @isTest private static void connectContractTest() {
        String region = 'NA';

        User standardUser = TestHelper.createUser(TestHelper.generateUniqueEmail());

        Account account = TestHelper.createAccount('TestAccountName', false);
        account.Region__c = region;
        insert account;

        XeroSettings__c xs = TestHelper.createXeroEntityByRegion(region, true);

        Project__c contract;

        Test.startTest();
        System.runAs(standardUser) {
            contract = TestHelper.createContractNoInsert(account.Id, 'testContract', null);
            contract.Xero_Id__c = null;
            contract.Xero_Entity__c = null;
            insert contract;

            PageReference xeroConnectionPage = Page.XeroConnection;
            xeroConnectionPage.getParameters().put('contractId', contract.Id);
            Test.setCurrentPage(xeroConnectionPage);

            XeroConnectionCtrl ctrl = new XeroConnectionCtrl();
            ctrl.createNewXeroContactChanged(); // just to cover the empty method
            ctrl.xeroId = xs.Id;
            ctrl.connectWithXero();
            ctrl.selectedContact = XeroTestHelper.createXeroContact();
            ctrl.connectWithXeroContact();
        }
        Test.stopTest();

        contract = [SELECT Xero_ID__c, Xero_Entity__c FROM Project__c WHERE Id = :contract.Id];
        System.assert(String.isNotBlank(contract.Xero_Id__c));
        System.assert(String.isNotBlank(contract.Xero_Entity__c));
    }

    @isTest private static void redirectBackAccountTest() {
        String region = 'NA';

        User standardUser = TestHelper.createUser(TestHelper.generateUniqueEmail());

        Account account = TestHelper.createAccount('TestAccountName', false);
        account.Region__c = region;
        insert account;

        Test.startTest();
        System.runAs(standardUser) {
            PageReference xeroConnectionPage = Page.XeroConnection;
            xeroConnectionPage.getParameters().put('accountId', account.Id);
            Test.setCurrentPage(xeroConnectionPage);

            XeroConnectionCtrl ctrl = new XeroConnectionCtrl();
            PageReference redirectPage = ctrl.redirectBack();

            System.assert(redirectPage.getUrl().endsWith('/' + account.Id));
        }
        Test.stopTest();
    }

    @isTest private static void redirectBackContractTest() {
        String region = 'NA';

        User standardUser = TestHelper.createUser(TestHelper.generateUniqueEmail());

        Account account = TestHelper.createAccount('TestAccountName', false);
        account.Region__c = region;
        insert account;

        Test.startTest();
        System.runAs(standardUser) {
            Project__c contract = TestHelper.createContractNoInsert(account.Id, 'testContract', null);
            insert contract;

            PageReference xeroConnectionPage = Page.XeroConnection;
            xeroConnectionPage.getParameters().put('contractId', contract.Id);
            Test.setCurrentPage(xeroConnectionPage);

            XeroConnectionCtrl ctrl = new XeroConnectionCtrl();
            PageReference redirectPage = ctrl.redirectBack();

            System.assert(redirectPage.getUrl().endsWith('/' + contract.Id));
        }
        Test.stopTest();
    }

    // Unit Tests for XeroConnection.cmp
    @isTest private static void actualiseXeroContactTest() {
        List<String> regions = new List<String>{'EMEA'};

        User standardUser = TestHelper.createUser(TestHelper.generateUniqueEmail());
        Account account = TestHelper.createAccount('TestAccountName', false);
        account.Region__c = regions[0];
        insert account;

        XeroSettings__c xs = TestHelper.createXeroEntityByRegion(regions[0], true);

        System.runAs(standardUser) {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());

            XeroConnectionCtrl.Contract xeroContract = XeroConnectionCtrl.fetchContract(account.Id);

            System.assertEquals(xeroContract.xeroEntityId, null);
            System.assertEquals(xeroContract.recordId, account.Id);
            System.assertEquals(xeroContract.xeroId, null);
            System.assertEquals(xeroContract.xeroEntities.size(), regions.size() + 1); // "+1" means the blank option, i.e. "--None--"
            System.assert(String.isNotBlank(xeroContract.xeroEntities[1].xeroEntityId));

            System.assertEquals([SELECT Count() FROM XeroEntity__c], 0, 'No XeroEntity__c records should exist.');
            XeroConnectionCtrl.actualiseXeroContact(xeroContract.xeroEntities[1].xeroEntityId);
            List<XeroEntity__c> xContracts = [SELECT Id, XeroSettings__c, XeroName__c, XeroId__c, ObjectType__c FROM XeroEntity__c];
            System.assertNotEquals(xContracts.size(), 0, 'At least one XeroEntity__c record should exist.');

            XeroWrappers.XeroContact expectingXeroContact = XeroTestHelper.createXeroContact();
            System.assertEquals(xContracts[0].XeroSettings__c, xeroContract.xeroEntities[1].xeroEntityId);
            System.assertEquals(xContracts[0].XeroName__c, expectingXeroContact.Name);
            System.assertEquals(xContracts[0].XeroId__c, expectingXeroContact.ContactID);
            System.assertEquals(xContracts[0].ObjectType__c, 'Contact');
            Test.stopTest();
        }
    }

    @isTest private static void getXeroContactInfoTest() {
        List<String> regions = new List<String>{'EMEA'};

        User standardUser = TestHelper.createUser(TestHelper.generateUniqueEmail());
        Account account = TestHelper.createAccount('TestAccountName', false);
        XeroSettings__c xs = TestHelper.createXeroEntityByRegion(regions[0], true);

        System.runAs(standardUser) {
            XeroWrappers.XeroContact existingXeroContact = XeroTestHelper.createXeroContact();

            account.Region__c = regions[0];
            account.Xero_Entity__c = xs.Id;
            account.Xero_Id__c = existingXeroContact.ContactID;
            insert account;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());

            XeroWrappers.XeroContact xContact = XeroConnectionCtrl.getXeroContactInfo(account.Xero_Entity__c, account.Xero_Id__c);
            System.assertEquals(existingXeroContact.ContactID, xContact.ContactID);
            Test.stopTest();
        }
    }

    @isTest private static void establishXeroConnectionTest() {
        List<String> regions = new List<String>{'EMEA'};

        User standardUser = TestHelper.createUser(TestHelper.generateUniqueEmail());
        Account account = TestHelper.createAccount('TestAccountName', false);
        account.Region__c = regions[0];
        insert account;

        XeroSettings__c xs = TestHelper.createXeroEntityByRegion(regions[0], true);

        System.runAs(standardUser) {
            XeroConnectionCtrl.Contract xeroContract = XeroConnectionCtrl.fetchContract(account.Id);
            System.assertEquals(account.Xero_Entity__c, null);
            System.assertEquals(account.Xero_Id__c, null);

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
            XeroConnectionCtrl.actualiseXeroContact(xs.Id);
            List<XeroEntity__c> xContracts = [SELECT Id, XeroSettings__c, XeroName__c, XeroId__c, ObjectType__c FROM XeroEntity__c];

            XeroConnectionCtrl.AuraResponse response = XeroConnectionCtrl.establishXeroConnection(JSON.serialize(xeroContract), xContracts[0].XeroId__c, xs.Id);
            System.assertEquals(true, response.isSuccess);

            account = [SELECT Id,Xero_Entity__c,Xero_Id__c FROM Account WHERE Id = :account.Id];
            System.assertEquals(account.Xero_Entity__c, xs.Id);
            System.assertEquals(account.Xero_Id__c, xContracts[0].XeroId__c);
            Test.stopTest();
        }
    }

    @isTest private static void unlinkXeroConnectionTest() {
        List<String> regions = new List<String>{'EMEA'};

        User standardUser = TestHelper.createUser(TestHelper.generateUniqueEmail());
        Account account = TestHelper.createAccount('TestAccountName', false);
        account.Region__c = regions[0];

        XeroSettings__c xs = TestHelper.createXeroEntityByRegion(regions[0], true);

        System.runAs(standardUser) {
            XeroWrappers.XeroContact existingXeroContact = XeroTestHelper.createXeroContact();

            account.Xero_Entity__c = xs.Id;
            account.Xero_Id__c = existingXeroContact.ContactID;
            insert account;

            Test.startTest();
            XeroConnectionCtrl.Contract xeroContract = XeroConnectionCtrl.fetchContract(account.Id);
            XeroConnectionCtrl.AuraResponse response = XeroConnectionCtrl.unlinkXeroConnection(JSON.serialize(xeroContract));

            System.assertEquals(true, response.isSuccess);

            account = [SELECT Id,Xero_Entity__c,Xero_Id__c FROM Account WHERE Id = :account.Id];
            System.assertEquals(account.Xero_Entity__c, null);
            System.assertEquals(account.Xero_Id__c, null);
            Test.stopTest();
        }
    }

    @isTest private static void createXeroRecordTest() {
        List<String> regions = new List<String>{'EMEA'};

        User standardUser = TestHelper.createUser(TestHelper.generateUniqueEmail());
        Account account = TestHelper.createAccount('TestAccountName', false);
        account.Region__c = regions[0];
        account.Phone = '9998877644';
        account.Fax = '18277494334';
        insert account;

        XeroSettings__c xs = TestHelper.createXeroEntityByRegion(regions[0], true);

        System.runAs(standardUser) {
            System.assertEquals(account.Xero_Entity__c, null);
            System.assertEquals(account.Xero_Id__c, null);
            XeroConnectionCtrl.Contract xeroContract = XeroConnectionCtrl.fetchContract(account.Id);

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
            // set Xero Entity
            xeroContract.xeroEntityId = xs.Id;

            String newName = 'NewContractName';
            String newEmail = 'newemail@gmail.com';
            XeroConnectionCtrl.AuraResponse response = XeroConnectionCtrl.createXeroRecord(newName, newEmail, JSON.serialize(xeroContract));

            System.assertEquals(true, response.isSuccess);


            XeroWrappers.XeroContact createdContact = XeroTestHelper.createXeroContact();
            account = [SELECT Id,Xero_Entity__c,Xero_Id__c FROM Account WHERE Id = :account.Id];
            System.assertEquals(account.Xero_Entity__c, xs.Id);
            System.assertEquals(account.Xero_Id__c, createdContact.ContactID);

            Test.stopTest();
        }
    }

}