@IsTest
private class ContractCtrlTest {

    @IsTest static void testEditReady() {
        TestHelper.prepareData(false);

        Project__c contract = TestHelper.contractRecord;
        PageReference p = Page.ContractEdit;
        p.getParameters().put('id', contract.Id);
        Test.setCurrentPage(p);

        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(contract);
        ContractCtrl controller = new ContractCtrl(stdCtrl);

        Test.startTest();
        controller.onEditReady();
        Test.stopTest();
        System.assertEquals(false, controller.saveAndNew);
    }

    @IsTest static void testSaveRecord() {
        TestHelper.prepareData(false);

        Project__c contract = TestHelper.contractRecord;
        PageReference p = Page.ContractEdit;
        p.getParameters().put('id', contract.Id);
        Test.setCurrentPage(p);

        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(contract);
        ContractCtrl controller = new ContractCtrl(stdCtrl);
        controller.onEditReady();

        Test.startTest();
        controller.contract.Client_Spend_Defined_on_IO__c = true;
        controller.save();
        Test.stopTest();
        System.assertEquals(false, controller.saveAndNew);
    }

    @IsTest static void testChangedClientSpend() {
        TestHelper.prepareData(false);

        Project__c contract = TestHelper.contractRecord;
        contract.Gaps_Exist_Between_Projects__c = true;
        update contract;

        Sub_Project__c payment = [SELECT Id FROM Sub_Project__c WHERE Project__c = :contract.Id LIMIT 1];
        delete [SELECT Id FROM Sub_Project__c WHERE Id != :payment.Id];

        PageReference p = Page.ContractEdit;
        p.getParameters().put('id', contract.Id);
        Test.setCurrentPage(p);

        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(contract);
        ContractCtrl controller = new ContractCtrl(stdCtrl);
        controller.onEditReady();

        Test.startTest();
        controller.contract.Client_Spend_Defined_on_IO__c = true;
        controller.contract.Client_Spend__c = 20000;
        controller.save();
        System.assertEquals(false, controller.saveAndNew);

        controller.save();
        Test.stopTest();

        System.assertEquals(false, controller.saveAndNew);
        Project__c contractAfter = [SELECT Id, Client_Spend__c, Client_Spend_Defined_on_IO__c FROM Project__c WHERE Id =: contract.Id LIMIT 1];
        System.assertEquals(true, contractAfter.Client_Spend_Defined_on_IO__c);
        System.assertEquals(20000, contractAfter.Client_Spend__c);
    }

    @IsTest  static void testPageRedirect() {
        TestHelper.prepareData(false);

        Project__c contract = TestHelper.contractRecord;
        contract.Gaps_Exist_Between_Projects__c = true;
        update contract;

        Sub_Project__c payment = [SELECT Id FROM Sub_Project__c WHERE Project__c = :contract.Id LIMIT 1];
        delete [SELECT Id FROM Sub_Project__c WHERE Id != :payment.Id];

        PageReference p = Page.ContractEdit;
        p.getParameters().put('id', contract.Id);
        Test.setCurrentPage(p);

        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(contract);
        ContractCtrl controller = new ContractCtrl(stdCtrl);
        controller.onEditReady();

        Test.startTest();
        controller.saveAndNew  = true;
        controller.contract.Client_Spend__c = 20000;
        PageReference result = controller.save();
        System.assert(result.getUrl().contains(contract.Id) == false);

        controller.contract.Client_Spend__c = 23000;
        controller.contract.Client_Spend_Defined_on_IO__c = true;
        controller.save();
        System.assert(result.getUrl().contains(contract.Id) == false);

        controller.saveAndNew = false;
        controller.contract.Client_Spend__c = 30000;
        controller.contract.Client_Spend_Defined_on_IO__c = false;
        result = controller.save();
        System.assert(result.getUrl().contains(contract.Id) == true);
        Test.stopTest();
    }

    @IsTest private static void willCreateNewBrand() {
        PageReference contractPage = Page.ContractEdit;
        Test.setCurrentPage(contractPage);

        Account acc = TestHelper.createAccount();
        User usr = TestHelper.createUser();
        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        Project__c contract = TestHelper.createContractNoInsert(acc.Id, 'testContract', opp.Id);
        contract.Brand__c = null;

        Test.startTest();
        ContractCtrl contractController = new ContractCtrl(new ApexPages.StandardController(contract));
        contractController.onEditReady();
        contractController.createBrand();
        contractController.cancelCreateBrand();
        contractController.brandUpdated();
        contractController.createBrand();
        contractController.brand.Name = 'testBrand';
        contractController.save();
        Test.stopTest();

        System.assertEquals(contractController.brand.Name, [SELECT Brand__r.Name FROM Project__c WHERE Id = :contractController.contract.Id].Brand__r.Name);
    }

    @IsTest private static void willCreateVideoUrl() {
        PageReference contractPage = Page.OpportunityEdit;
        Test.setCurrentPage(contractPage);

        Project__c contract = TestHelper.createContract('Test Contract', null, null, true);

        VideoUrl__c videoUrl = TestHelper.createVideoUrl();
        videoUrl.Contract__c = contract.Id;
        videoUrl.Platform__c = 'TrueView';
        videoUrl.Format__c = 'Video';
        videoUrl.StartDate__c = contract.Start_Date__c;
        videoUrl.EndDate__c = contract.End_Date__c;
        insert videoUrl;

        Test.startTest();
        ContractCtrl controller = new ContractCtrl(new ApexPages.StandardController(contract));
        controller.onEditReady();
        System.assertEquals(1, controller.videoURLs.size());

        controller.videoUrlRow = 0;
        controller.deleteVideoUrl();
        System.assertEquals(0, controller.videoURLs.size());

        controller.addNewVideoUrl();
        System.assertEquals(1, controller.videoURLs.size());

        controller.videoURLs[0].Name = 'Placeholder';
        controller.videoURLs[0].IsPlaceholder__c = true;
        controller.videoURLs[0].Platform__c = 'TrueView';
        controller.videoURLs[0].Format__c = 'Video';
        controller.videoURLs[0].StartDate__c = contract.Start_Date__c;
        controller.videoURLs[0].EndDate__c = contract.End_Date__c;
        controller.save();
        Test.stopTest();

        List<VideoUrl__c> insertedUrl = [SELECT IsPlaceholder__c FROM VideoUrl__c WHERE Contract__c = :contract.Id];

        System.assertEquals(1, insertedUrl.size());
        System.assertEquals(true, insertedUrl[0].IsPlaceholder__c);
    }

    @IsTest public static void contractHistoryWrapper_constructor() {
        TestHelper.createContract('Test Contract', null, null, true);

        Project__History history = new Project__History();
        history.Field = 'Owner';
        ContractCtrl.ContractHistoryWrapper historyWrapper = new ContractCtrl.ContractHistoryWrapper (history);

        System.assertEquals(history, historyWrapper.history);
        System.assertEquals(true, historyWrapper.action.startsWith('Changed'));
    }

    @IsTest public static void getRecordHistory() {
        Project__c contract = TestHelper.createContract('Test Contract', null, null, true);
        ContractCtrl ctrl = new ContractCtrl (new ApexPages.StandardController (contract));
        Project__History history1 = new Project__History(), history2 = new Project__History();
        ctrl.getRecordHistory(new List <Project__History> {history1,history2});
    }

    @IsTest
    public static void getPlatforms() {
        Project__c contract = TestHelper.createContract('Test Contract', null, null, true);
        ContractCtrl ctrl = new ContractCtrl (new ApexPages.StandardController (contract));

        List<PlatformWrapper> platforms = ctrl.getPlatforms();
        System.assertEquals('TrueView', platforms [0].oppPlatform.Platform__r.Name);
    }

    @IsTest
    public static void savePlatforms() {
        TestHelper.prepare1MonthOpportunityWith4Platforms(Utility.BILLING_PROFILES.Strike, ContactOpportunityHandler.CLOSED_WON, null);

        Test.startTest();
        ContractCtrl ctrl = new ContractCtrl(new ApexPages.StandardController([SELECT Id FROM Project__c LIMIT 1]));
        ctrl.savePlatforms();
        System.assertEquals(true, ApexPages.getMessages()[0].getSummary().contains('successfully'));
        Test.stopTest();
    }

    @IsTest
    public static void savePlatformsError() {
        TestHelper.prepare1MonthOpportunityWith4Platforms(Utility.BILLING_PROFILES.Strike, ContactOpportunityHandler.CLOSED_WON, null);

        Test.startTest();
        ContractCtrl ctrl = new ContractCtrl(new ApexPages.StandardController([SELECT Id FROM Project__c][0]));
        ctrl.platformsMap = null;
        ctrl.savePlatforms();
        System.assertEquals(true, ApexPages.hasMessages(ApexPages.Severity.ERROR));
        Test.stopTest();
    }

    @IsTest static void showClientSpendDifferenceMessageTest() {
        String initialCurrencyCode = 'USD', newCurrencyCode = 'EUR';

        Date sDate = Date.valueOf(Date.today().year() + '-' + Date.today().addMonths(-1).month() + '-01'),
                eDate = sDate.addDays(70);

        Platform__c adWordsPlatform = TestHelper.createTrueViewPlatform();
        insert adWordsPlatform;

        TestHelper.createOpportunity(sDate, eDate, adWordsPlatform, Utility.BILLING_PROFILES.Strike, false);
        insert TestHelper.opportunityRecord;

        OpportunityPlatform__c opPlatform = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, adWordsPlatform);
        opPlatform.PlatformAccount__c = StrikeDataAPIMock.accountId;
        insert opPlatform;

        Project__c contract = TestHelper.createContract('Test Contract', sDate, eDate, false);
        contract.SpendRefreshDate__c = null;
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = TRUE LIMIT 1].Id;
        contract.CurrencyIsoCode = initialCurrencyCode;
        insert contract;

        Test.startTest();
        ContractCtrl contractDetailsCtrl = new ContractCtrl(new ApexPages.StandardController(contract));
        System.assertEquals(false, contractDetailsCtrl.showPaymentClientSpendDifferenceMsg);
        System.assertEquals(false, contractDetailsCtrl.showProjectClientSpendDifferenceMsg);
        // by changing CurrencyISOCode I expect that Project/Payment client spend will be different after currency recalculation
        contract.CurrencyIsoCode = newCurrencyCode;
        update contract;
        Test.stopTest();

        contractDetailsCtrl = new ContractCtrl(new ApexPages.StandardController(contract));
        System.assertEquals(true, contractDetailsCtrl.showPaymentClientSpendDifferenceMsg);
        // projects Client Spend are recalculated by changes on payments in CurrencyISOCode field
        System.assertEquals(false, contractDetailsCtrl.showProjectClientSpendDifferenceMsg);
    }

    @IsTest static void getAllSpendsTest() {
        TestHelper.createAppSettings();

        Date sDate = Date.valueOf(Date.today().year() + '-' + Date.today().addMonths(-1).month() + '-01'),
                eDate = sDate.addDays(70);

        Platform__c adWordsPlatform = TestHelper.createTrueViewPlatform();
        insert adWordsPlatform;

        TestHelper.createOpportunity(sDate, eDate, adWordsPlatform, Utility.BILLING_PROFILES.Strike, false);
        insert TestHelper.opportunityRecord;

        OpportunityPlatform__c opPlatform = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, adWordsPlatform);
        opPlatform.PlatformAccount__c = StrikeDataAPIMock.accountId;
        insert opPlatform;

        Project__c contract = TestHelper.createContract('Test Contract', sDate, eDate, false);
        contract.SpendRefreshDate__c = null;
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = TRUE LIMIT 1].Id;
        insert contract;

        List<Payment__c> projects = [SELECT StrikeId__c, Start_Date__c, End_Date__c FROM Payment__c WHERE Project__c = :contract.Id];
        String projectName = '';
        for (Payment__c project :projects) {
            projectName = project.StrikeId__c;
        }
        System.assert(String.isNotBlank(projectName), 'At least one project should exist.');

        Test.startTest();
        ContractCtrl controller = new ContractCtrl(new ApexPages.StandardController(contract));

        StrikeDataAPIMock.setRandomMetrics = true;
        StrikeDataAPIMock.projectNames = new List<String>{projectName};
        StrikeDataAPIMock.accountIDs = new List<String>{StrikeDataAPIMock.accountId};

        Test.setMock(HttpCalloutMock.class, new StrikeDataAPIMock(projectName, StrikeDataAPI.PackageType.ADWORDS));
        controller.getAllSpends();
        Test.stopTest();
        System.debug('### TEST MESSAGES: ' + ApexPages.getMessages()[0].getDetail());
        System.assert(ApexPages.getMessages()[0].getDetail().contains('Spends imported successfully for: ' + projectName + '.'));
        System.assertEquals(ApexPages.getMessages()[0].getSeverity(), ApexPages.Severity.CONFIRM);
    }

    @IsTest static void getAllSpendsTest_ExpectingError() {
        TestHelper.createAppSettings();

        Date sDate = Date.valueOf(Date.today().year() + '-' + Date.today().addMonths(-1).month() + '-01'),
                eDate = sDate.addDays(70);

        Platform__c adWordsPlatform = TestHelper.createTrueViewPlatform();
        insert adWordsPlatform;

        TestHelper.createOpportunity(sDate, eDate, adWordsPlatform, Utility.BILLING_PROFILES.Strike, false);
        insert TestHelper.opportunityRecord;

        OpportunityPlatform__c opPlatform = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, adWordsPlatform);
        opPlatform.PlatformAccount__c = StrikeDataAPIMock.accountId;
        insert opPlatform;

        Project__c contract = TestHelper.createContract('Test Contract', sDate, eDate, false);
        contract.SpendRefreshDate__c = null;
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = TRUE LIMIT 1].Id;
        insert contract;

        List<Payment__c> projects = [SELECT StrikeId__c, Start_Date__c, End_Date__c FROM Payment__c WHERE Project__c = :contract.Id];
        String projectName = '';
        for (Payment__c project :projects) {
            projectName = project.StrikeId__c;
        }
        System.assert(String.isNotBlank(projectName), 'At least one project should exist.');

        Test.startTest();
        ContractCtrl controller = new ContractCtrl(new ApexPages.StandardController(contract));

        StrikeDataAPIMock.setEmptyMetrics = true;
        StrikeDataAPIMock.setRandomMetrics = true;
        Test.setMock(HttpCalloutMock.class, new StrikeDataAPIMock(projectName, StrikeDataAPI.PackageType.ADWORDS));
        controller.getAllSpends();
        Test.stopTest();
        System.debug('### TEST MESSAGES: ' + ApexPages.getMessages()[0].getDetail());
        System.assert(ApexPages.getMessages()[0].getDetail().contains('No data received for: ' + projectName));
        System.assertEquals(ApexPages.getMessages()[0].getSeverity(), ApexPages.Severity.ERROR);
    }

    @IsTest static void syncWithDataWarehouseTest() {
        TestHelper.createAppSettings();

        Date sDate = Date.valueOf(Date.today().year() + '-' + Date.today().addMonths(-1).month() + '-01'),
                eDate = sDate.addDays(70);

        Platform__c adWordsPlatform = TestHelper.createTrueViewPlatform();
        insert adWordsPlatform;

        TestHelper.createOpportunity(sDate, eDate, adWordsPlatform, Utility.BILLING_PROFILES.Strike, false);
        insert TestHelper.opportunityRecord;

        OpportunityPlatform__c opPlatform = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, adWordsPlatform);
        opPlatform.PlatformAccount__c = StrikeDataAPIMock.accountId;
        insert opPlatform;

        AdPlacement__c adPlacement = new AdPlacement__c(Platform__c = adWordsPlatform.Id, Name = 'TestAdPlacement');
        insert adPlacement;

        insert new OpportunityAdPlacement__c(OpportunityPlatform__c = opPlatform.Id, AdPlacement__c = adPlacement.Id, Opportunity__c = TestHelper.opportunityRecord.Id);

        Project__c contract = TestHelper.createContract('Test Contract', sDate, eDate, false);
        contract.SpendRefreshDate__c = null;
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = TRUE LIMIT 1].Id;
        insert contract;

        Test.startTest();

        Test.setCurrentPage(Page.ContractDetails);
        Test.setMock(HttpCalloutMock.class, new StrikeDataAPIMock.SyncContractCalloutMock());

        ContractCtrl controller = new ContractCtrl(new ApexPages.StandardController(contract));
        controller.syncWithDataWarehouse();

        System.debug('### ApexPages.getMessages(): ' + ApexPages.getMessages());
        System.assertEquals(0, ApexPages.getMessages().size(), 'No error appear');
        Test.stopTest();
    }

}