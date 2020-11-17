@IsTest
private class PlanComponentCtrlTest {

    private static final String SUB_PROJECT_OBJECT_TYPE = SubProjectRepository.API_NAME;
    private static final String PROJECT_OBJECT_TYPE = SubProjectRepository.API_NAME;

    @IsTest static void subProjectAddNewRowTest() {
        TestHelper.prepareData(false);
        Project__c contract = TestHelper.contractRecord;
        contract.Gaps_Exist_Between_Projects__c = true;
        update contract;
               
        delete [SELECT Id, Project__c FROM Sub_Project__c WHERE Project__c =: contract.Id];
        
        PlanComponentCtrl ctrl = new PlanComponentCtrl();
        ctrl.objType = SUB_PROJECT_OBJECT_TYPE;
        ctrl.contractId = contract.Id;
        ctrl.getPaymentsList();

        Test.startTest();
        ctrl.addNewPayment();
        ctrl.newPayments[ctrl.newPayments.size() - 1].Start_Date__c = contract.Start_Date__c;
        ctrl.newPayments[ctrl.newPayments.size() - 1].End_Date__c = contract.End_Date__c;
        ctrl.newPayments[ctrl.newPayments.size() - 1].Client_Spend__c = contract.Client_Spend__c;
        ctrl.saveObjects();
        ctrl.getPaymentsList();
        Test.stopTest();

        System.assertEquals(1, [SELECT Id, Project__c FROM Sub_Project__c WHERE Project__c =: contract.Id].size());
    }
    
    @IsTest static void paymentsSaveTest() {
        TestHelper.prepareData(false);
        
        PlanComponentCtrl ctrl = new PlanComponentCtrl();
        ctrl.objType = SUB_PROJECT_OBJECT_TYPE;
        ctrl.contractId = TestHelper.contractRecord.Id;
        ctrl.getPaymentsList();
        List<Sub_Project__c> payments = [SELECT Id, Project__c FROM Sub_Project__c WHERE Project__c =: TestHelper.contractRecord.Id];

        Test.startTest();
        payments[0].Start_Date__c = System.today();
        ctrl.saveObjects();
        Test.stopTest();

        System.assertEquals(payments.size(), [SELECT Id, Project__c FROM Sub_Project__c WHERE Project__c =: TestHelper.contractRecord.Id].size());
        System.assertEquals(ctrl.errorOccurred, false);
    }
    
    @IsTest static void projectsSaveTest() {
        Date sDate = System.today().addMonths(-1),
                eDate = System.today().addMonths(1);
        
        Project__c contract = TestHelper.createContract('Test Contract', sDate, eDate, true);// NoInsert(acc.Id, 'testContract', null);

        PlanComponentCtrl ctrl = new PlanComponentCtrl();
        ctrl.objType = PROJECT_OBJECT_TYPE;
        ctrl.contractId = contract.Id;
        ctrl.getPaymentsList();

        List<Payment__c> projects = [SELECT Id, Project__c FROM Payment__c WHERE Project__c =: contract.Id];

        Test.startTest();
        projects[0].Start_Date__c = System.today();
        ctrl.saveObjects();
        Test.stopTest();

        System.assertEquals(projects.size(), [SELECT Id, Project__c FROM Payment__c WHERE Project__c =: contract.Id].size());
        System.assertEquals(ctrl.errorOccurred, false);
    }

    @IsTest static void paymentsRecreateTest() {
        TestHelper.prepareData(false);

        PlanComponentCtrl ctrl = new PlanComponentCtrl();
        ctrl.objType = SUB_PROJECT_OBJECT_TYPE;
        ctrl.contractId = TestHelper.contractRecord.Id;
        ctrl.getPaymentsList();

        List<Sub_Project__c> payments = [SELECT Id, Project__c FROM Sub_Project__c WHERE Project__c =: TestHelper.contractRecord.Id];
        Test.startTest();
        ctrl.recreateSobjects();
        Test.stopTest();

        System.assertEquals(payments.size(), [SELECT Id, Project__c FROM Sub_Project__c WHERE Project__c =: TestHelper.contractRecord.Id].size());
        // TODO: What does it test?
    }

    @IsTest static void projectsRecreateTest() {
        TestHelper.prepareData(false);

        PlanComponentCtrl ctrl = new PlanComponentCtrl();
        ctrl.objType = PROJECT_OBJECT_TYPE;
        ctrl.contractId = TestHelper.contractRecord.Id;
        ctrl.getPaymentsList();

        Test.startTest();
        try {
            ctrl.recreateSobjects();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('This project has already started, cannot be removed'));
        }
        Test.stopTest();
        // TODO: What does it test?
    }

    @IsTest static void changeClientSpendOnPayment() {
        TestHelper.prepareData(false);

        PlanComponentCtrl ctrl = new PlanComponentCtrl();
        ctrl.objType = SUB_PROJECT_OBJECT_TYPE;
        ctrl.contractId = TestHelper.contractRecord.Id;
        ctrl.getPaymentsList();

        List<Sub_Project__c> payments = [SELECT Id, Project__c FROM Sub_Project__c WHERE Project__c =: TestHelper.contractRecord.Id];

        TestHelper.contractRecord.Client_Spend_Defined_on_IO__c = true;
        update TestHelper.contractRecord;

        Test.startTest();
        payments[0].Client_Spend__c = 300;
        ctrl.recIdWithChangedClientSpend = payments[0].Id;
        ctrl.onClientSpendChange();
        Test.stopTest();
        System.assert(ctrl.recordsWithInvoiceAmountUpdate.size() > 0);
    }

    @IsTest static void testCancelOfChanges() {
        TestHelper.prepareData(false);

        PlanComponentCtrl ctrl = new PlanComponentCtrl();
        ctrl.objType = SUB_PROJECT_OBJECT_TYPE;
        ctrl.contractId = TestHelper.contractRecord.Id;
        ctrl.getPaymentsList();
        List<Sub_Project__c> payments = [SELECT Id, Client_Spend__c, Project__c FROM Sub_Project__c WHERE Project__c =: TestHelper.contractRecord.Id];

        Double clientSpendBefore = payments[0].Client_Spend__c;
        TestHelper.contractRecord.Client_Spend_Defined_on_IO__c = true;
        update TestHelper.contractRecord;

        Test.startTest();
        payments[0].Client_Spend__c = 300;
        ctrl.recIdWithChangedClientSpend = payments[0].Id;
        ctrl.onClientSpendChange();
        Test.stopTest();

        System.assertEquals(clientSpendBefore, [SELECT Id, Client_Spend__c FROM Sub_Project__c WHERE Id =: payments[0].Id].Client_Spend__c);
    }

    @IsTest static void testSendInvoice() {
        Project__c contract = TestHelper.createContract('Test Contract', null, null, false);
        contract.Gaps_Exist_Between_Projects__c = true;
        insert contract;

        PlanComponentCtrl ctrl = new PlanComponentCtrl();
        ctrl.objType = SUB_PROJECT_OBJECT_TYPE;
        ctrl.contractId = contract.Id;

        Test.startTest();
        Sub_Project__c payment = ctrl.getPaymentsList()[0].payment;
        ctrl.paymentToInvoice = payment.Id;
        ctrl.sendInvoice();
        Test.stopTest();
        // TODO: What does it test?
    }

    @IsTest static void testCancelNewProject() {
        TestHelper.prepareData(false);

        TestHelper.contractRecord.Gaps_Exist_Between_Projects__c = true;
        update TestHelper.contractRecord;

        PlanComponentCtrl ctrl = new PlanComponentCtrl();
        ctrl.objType = SUB_PROJECT_OBJECT_TYPE;
        ctrl.contractId = TestHelper.contractRecord.Id;
        ctrl.getPaymentsList();

        Test.startTest();
        Sub_Project__c payment = ctrl.getPaymentsList()[0].payment;

        Payment__c project = TestHelper.createProjectBasedOnPayment(TestHelper.contractRecord, payment, false);
        project.Client_Spend__c = 0;

        PaymentHandler.skipUpdateValidation = true;
        insert project;
        PaymentHandler.skipUpdateValidation = false;

        ctrl.getAvailablePlatforms();

        ctrl.paymentId = payment.Id;
        ctrl.showProjectsForPayment();
        System.assertEquals(2, ctrl.expandedProjectsByPaymentId.get(payment.Id).size());

        ctrl.paymentId = payment.Id;
        ctrl.addNewProject();
        System.assertEquals(3, ctrl.expandedProjectsByPaymentId.get(payment.Id).size());

        ctrl.projectRow = ctrl.expandedProjectsByPaymentId.get(payment.Id).size()-1;
        ctrl.cancelNewProject();
        System.assertEquals(2, ctrl.expandedProjectsByPaymentId.get(payment.Id).size());
        Test.stopTest();
    }

    @IsTest static void testAddingProject() {
        TestHelper.prepareData(false);

        TestHelper.contractRecord.Gaps_Exist_Between_Projects__c = true;
        update TestHelper.contractRecord;

        PlanComponentCtrl ctrl = new PlanComponentCtrl();
        ctrl.objType = SUB_PROJECT_OBJECT_TYPE;
        ctrl.contractId = TestHelper.contractRecord.Id;

        Sub_Project__c payment = ctrl.getPaymentsList()[0].payment;
        ctrl.paymentId = payment.Id;
        ctrl.showProjectsForPayment();
        ctrl.getAvailablePlatforms();

        Integer sizeBefore = ctrl.expandedProjectsByPaymentId.get(payment.Id).size();
        System.assertEquals(1, sizeBefore);

        Test.startTest();
        ctrl.showProjectsForPayment();
        ctrl.addNewProject();
        Test.stopTest();

        System.assertEquals(sizeBefore + 1, ctrl.expandedProjectsByPaymentId.get(payment.Id).size());
    }

    @IsTest static void testSaveNewProject() {
        Date sDate = Date.newInstance(System.today().year(), 2, 1),
            eDate = Date.newInstance(System.today().year(), 3, 31);
        Project__c contract = TestHelper.createContract('Test Contract', sDate, eDate, true);

        Test.startTest();
        PlanComponentCtrl ctrl = new PlanComponentCtrl();
        ctrl.objType = SUB_PROJECT_OBJECT_TYPE;
        ctrl.contractId = contract.Id;

        List<SubProject.PaymentWrapper> payments = ctrl.getPaymentsList();
        Sub_Project__c payment1 = payments[0].payment;

        ctrl.paymentId = payment1.Id;
        ctrl.showProjectsForPayment();
        ctrl.getAvailablePlatforms();

        List<PlanComponentCtrl.ProjectWrapper> projects = ctrl.expandedProjectsByPaymentId.get(ctrl.paymentId);
        System.assertEquals(2, payments.size());
        System.assertEquals(1, projects.size());

        ctrl.addNewProject();
        System.assertEquals(2, projects.size());

        projects[1].project.Client_Spend__c = 10000;
        projects[1].project.Start_Date__c = projects[0].project.Start_Date__c;
        projects[1].project.End_Date__c = projects[0].project.End_Date__c;
        projects[1].project.CostStructure__c = 'CPV';
        projects[1].project.UnitCost__c = 0.07;

        payment1.Client_Spend__c += 10000;
        ctrl.project.Client_Spend__c += 10000;
        ctrl.saveObjects();
        Test.stopTest();

        System.assertEquals(2, [SELECT Id FROM Payment__c WHERE Payment__c = :payment1.Id].size());
    }

    @IsTest static void testSaveNewPayment() {
        Date sDate = Date.newInstance(System.today().year(), 2, 1),
                eDate = Date.newInstance(System.today().year(), 3, 31);
        Project__c contract = TestHelper.createContract('Test Contract', sDate, eDate, true);


        Test.startTest();
        PlanComponentCtrl ctrl = new PlanComponentCtrl();
        ctrl.objType = SUB_PROJECT_OBJECT_TYPE;
        ctrl.contractId = contract.Id;

        List<SubProject.PaymentWrapper> payments = ctrl.getPaymentsList();
        ctrl.addNewPayment();

        System.assertEquals(3, payments.size());

        Sub_Project__c newPayment = payments[2].payment;
        newPayment.Start_Date__c = payments[1].payment.End_Date__c.addDays(1);
        newPayment.End_Date__c = newPayment.Start_Date__c.addMonths(1);
        newPayment.Client_Spend__c = 5000;

        ctrl.project.End_Date__c = newPayment.End_Date__c;
        ctrl.project.Client_Spend__c += 5000;
        ctrl.saveObjects();
        Test.stopTest();

        System.assertEquals(3, [SELECT Id FROM Sub_Project__c WHERE Project__c = :contract.Id].size());
    }

    @IsTest static void testExpandAllProjects() {
        Account acc = TestHelper.createAccount();
        User usr = TestHelper.createUser();
        Date todayDate = System.today();

        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        opp.Brand__c = TestHelper.createBrand('testBrand').Id;
        opp.Flight_Start__c = Date.newInstance(todayDate.year() + 1, 1, 1);
        opp.Flight_End__c = Date.newInstance(todayDate.year() + 1, 3, 31);
        insert opp;

        OpportunityPlatform__c oppPlatform = TestHelper.createOpportunityPlatform(opp.Id, TestHelper.getTrueViewPlatform().Id);
        oppPlatform.NoCostStructure__c = true;
        insert oppPlatform;

        opp.StageName = 'Closed Won';
        update opp;

        PlanComponentCtrl ctrl = new PlanComponentCtrl();
        ctrl.objType = SUB_PROJECT_OBJECT_TYPE;
        ctrl.contractId = [SELECT Id FROM Project__c WHERE Opportunity__c = :opp.Id].Id;
        ctrl.getPaymentsList();

        Test.startTest();
            System.assertEquals(0, ctrl.expandedProjectsByPaymentId.size());
            ctrl.showProjectsForAllPayments();
        Test.stopTest();
        
        System.assertEquals(3, ctrl.expandedProjectsByPaymentId.size());
    }

    @IsTest static void checkCreativesPerProject() {
        insert TestHelper.accountRecord;
        insert TestHelper.brandRecord;
        insert TestHelper.salesRepUser;

        Platform__c adWordsPlatform = TestHelper.createTrueViewPlatform();
        insert adWordsPlatform;

        TestHelper.createOpportunity(null, null, adWordsPlatform, Utility.BILLING_PROFILES.Strike, true);
        System.assertNotEquals(TestHelper.opportunityRecord.Id, null, 'Opportunity should be inserted.');

        Project__c contract = TestHelper.createContract('Test Contract', null, null, false);
        contract.SpendRefreshDate__c = null;
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = TRUE LIMIT 1].Id;
        contract.CurrencyIsoCode = 'AUD';
        insert contract;

        List<Payment__c> projects = [SELECT Id, Start_Date__c, End_Date__c, Payment__c FROM Payment__c WHERE Project__c = :contract.Id];
        Integer monthBetween = contract.Start_Date__c.monthsBetween(contract.End_Date__c);
        System.assertEquals((monthBetween + 1), projects.size());

        Integer amountOfCreatives = 3;
        List<VideoUrl__c> creatives = new List<VideoUrl__c>();
        for (Integer i = 0; i < amountOfCreatives; i++) {
            VideoUrl__c creative = TestHelper.createVideoUrl();
            creative.Name = 'creative' + i;
            creative.Contract__c = contract.Id;
            creative.Platform__c = adWordsPlatform.Name;
            creative.Format__c = 'Video';
            creative.StartDate__c = projects[0].Start_Date__c.addDays(-1);
            creative.EndDate__c = projects[0].End_Date__c.addDays(1);
            creatives.add(creative);
        }
        insert creatives;

        Test.startTest();
        PlanComponentCtrl ctrl = new PlanComponentCtrl();
        ctrl.objType = PROJECT_OBJECT_TYPE;
        ctrl.project = contract;
        ctrl.contractId = contract.Id;
        ctrl.paymentId = projects[0].Payment__c;
        ctrl.showProjectsForPayment();
        System.assertEquals(1, ctrl.expandedProjectsByPaymentId.size(), 'Expecting 1 record');
        Test.stopTest();

        PlanComponentCtrl.ProjectWrapper wrappedProjectRecord = ctrl.expandedProjectsByPaymentId.values()[0][0];
        System.assertEquals(wrappedProjectRecord.creativesOptions.size(), creatives.size());
    }

    @IsTest static void checkCreativesPerProjectEmptyCheckboxList() {
        insert TestHelper.accountRecord;
        insert TestHelper.brandRecord;
        insert TestHelper.salesRepUser;

        Platform__c adWordsPlatform = TestHelper.createTrueViewPlatform();
        insert adWordsPlatform;

        TestHelper.createOpportunity(null, null, adWordsPlatform, Utility.BILLING_PROFILES.Strike, true);
        System.assertNotEquals(TestHelper.opportunityRecord.Id, null, 'Opportunity should be inserted.');

        Project__c contract = TestHelper.createContract('Test Contract', null, null, false);
        contract.SpendRefreshDate__c = null;
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = TRUE LIMIT 1].Id;
        contract.CurrencyIsoCode = 'AUD';
        insert contract;

        List<Payment__c> projects = [SELECT Id, Start_Date__c, End_Date__c, Payment__c FROM Payment__c WHERE Project__c = :contract.Id];
        Integer monthBetween = contract.Start_Date__c.monthsBetween(contract.End_Date__c);
        System.assertEquals((monthBetween + 1), projects.size());

        Integer amountOfCreatives = 3;
        List<VideoUrl__c> creatives = new List<VideoUrl__c>();
        for (Integer i = 0; i < amountOfCreatives; i++) {
            VideoUrl__c creative = TestHelper.createVideoUrl();
            creative.Name = 'creative' + i;
            creative.Contract__c = contract.Id;
            creative.Platform__c = adWordsPlatform.Name;
            creative.Format__c = 'Video';
            creative.StartDate__c = projects[0].Start_Date__c.addDays(-10);
            creative.EndDate__c = projects[0].Start_Date__c.addDays(-2);
            creatives.add(creative);
        }
        insert creatives;

        Test.startTest();
        PlanComponentCtrl ctrl = new PlanComponentCtrl();
        ctrl.objType = PROJECT_OBJECT_TYPE;
        ctrl.project = contract;
        ctrl.contractId = contract.Id;
        ctrl.paymentId = projects[0].Payment__c;
        ctrl.showProjectsForPayment();
        System.assertEquals(1, ctrl.expandedProjectsByPaymentId.size(), 'Expecting 1 record');
        Test.stopTest();

        PlanComponentCtrl.ProjectWrapper wrappedProjectRecord = ctrl.expandedProjectsByPaymentId.values()[0][0];
        System.assertEquals(wrappedProjectRecord.creativesOptions.size(), 0);
    }

    @IsTest static void noCreativesForNewProjectRow() {
        insert TestHelper.accountRecord;
        insert TestHelper.brandRecord;
        insert TestHelper.salesRepUser;

        Platform__c adWordsPlatform = TestHelper.createTrueViewPlatform();
        insert adWordsPlatform;

        TestHelper.createOpportunity(null, null, adWordsPlatform, Utility.BILLING_PROFILES.Strike, true);
        System.assertNotEquals(TestHelper.opportunityRecord.Id, null, 'Opportunity should be inserted.');

        Project__c contract = TestHelper.createContract('Test Contract', null, null, false);
        contract.SpendRefreshDate__c = null;
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = TRUE LIMIT 1].Id;
        contract.CurrencyIsoCode = 'AUD';
        insert contract;

        List<Payment__c> projects = [SELECT Id, Start_Date__c, End_Date__c, Payment__c FROM Payment__c WHERE Project__c = :contract.Id];
        Integer monthBetween = contract.Start_Date__c.monthsBetween(contract.End_Date__c);
        System.assertEquals((monthBetween + 1), projects.size());

        Integer amountOfCreatives = 3;
        List<VideoUrl__c> creatives = new List<VideoUrl__c>();
        for (Integer i = 0; i < amountOfCreatives; i++) {
            VideoUrl__c creative = TestHelper.createVideoUrl();
            creative.Name = 'creative' + i;
            creative.Contract__c = contract.Id;
            creative.Platform__c = adWordsPlatform.Name;
            creative.Format__c = 'Video';
            creative.StartDate__c = projects[0].Start_Date__c.addDays(-1);
            creative.EndDate__c = projects[0].End_Date__c.addDays(1);
            creatives.add(creative);
        }
        insert creatives;

        contract = [
            SELECT End_Date__c, Start_Date__c, Client_Spend__c, SpendRefreshDate__c, CurrencyIsoCode, ClientServicesRep__c,
                Account__c, Margin__c, Margin_Type__c, Opportunity__c,
                (SELECT Start_Date__c, End_Date__c, Client_Spend__c FROM Sub_Projects__r)
            FROM Project__c
            WHERE Id = :contract.Id
        ];

        Test.startTest();
        PlanComponentCtrl ctrl = new PlanComponentCtrl();
        ctrl.objType = PROJECT_OBJECT_TYPE;
        ctrl.project = contract;
        ctrl.contractId = contract.Id;
        ctrl.paymentId = projects[0].Payment__c;
        ctrl.getAvailablePlatforms();
        ctrl.showProjectsForPayment();
        System.assertEquals(1, ctrl.expandedProjectsByPaymentId.values()[0].size(), 'Expecting 1 record');

        ctrl.addNewProject();
        System.assertEquals(2, ctrl.expandedProjectsByPaymentId.values()[0].size(), 'Expecting 2 records');
        Test.stopTest();

        PlanComponentCtrl.ProjectWrapper wrappedProjectRecordNewRow = ctrl.expandedProjectsByPaymentId.values()[0][1];
        System.assertEquals(wrappedProjectRecordNewRow.creativesOptions.size(), 0);
    }

    @IsTest static void invoiceActionForInconsistentSpends_ScenarioWithDuplicateSpend() {
        insert TestHelper.accountRecord;
        insert TestHelper.brandRecord;
        insert TestHelper.salesRepUser;

        Platform__c adWordsPlatform = TestHelper.createTrueViewPlatform();
        insert adWordsPlatform;

        TestHelper.createOpportunity(null, null, adWordsPlatform, Utility.BILLING_PROFILES.Strike, true);
        System.assertNotEquals(TestHelper.opportunityRecord.Id, null, 'Opportunity should be inserted.');

        Project__c contract = TestHelper.createContract('Test Contract', null, null, false);
        contract.SpendRefreshDate__c = null;
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = TRUE LIMIT 1].Id;
        contract.CurrencyIsoCode = 'AUD';
        insert contract;

        List<Payment__c> projects = [SELECT StrikeId__c, Start_Date__c FROM Payment__c WHERE Project__c = :contract.Id];
        List<Sub_Project__c> payments = [SELECT Id FROM Sub_Project__c WHERE Project__c = :contract.Id];

        List<MM_Spendings__c> spends = new List<MM_Spendings__c>();
        // create 5 MM_Spendings__c, it will create 5 Project_Media_Spend__c records
        Integer spendsAmount = 5;
        for (Integer i = 0; i < spendsAmount; i++) {
            spends.add(new MM_Spendings__c(
                StrikeId__c = projects[0].StrikeId__c,
                Date__c = projects[0].Start_Date__c.addDays(i),
                Delivered__c = 100,
                Media_Spend__c = 100,
                CurrencyIsoCode = 'AUD',
                Contract__c = contract.Id,
                Is_Sync__c = true
            ));
        }
        insert spends;

        // check that Project_Media_Spend__c records amount is the same
        List<Project_Media_Spend__c> contractSpends = [
            SELECT Project__c, StrikeId__c, Date__c, Delivered__c, CurrencyIsoCode, Amount__c
            FROM Project_Media_Spend__c
            WHERE MMSpending__c IN :spends
        ];
        System.assertEquals(spendsAmount, contractSpends.size());

        Project_Media_Spend__c duplicateCSpend = new Project_Media_Spend__c(
            Project__c = contractSpends[0].Project__c,
            Date__c = contractSpends[0].Date__c,
            Delivered__c = contractSpends[0].Delivered__c,
            CurrencyIsoCode = contractSpends[0].CurrencyIsoCode,
            Amount__c = contractSpends[0].Amount__c
        );
        insert duplicateCSpend;

        Test.startTest();
        PlanComponentCtrl ctrl = new PlanComponentCtrl();
        ctrl.project = contract;
        ctrl.contractId = contract.Id;
        ctrl.getPaymentsList();
        List<SubProject.PaymentWrapper> wPayments = ctrl.paymentWrappers;
        System.assertEquals(wPayments.size(), payments.size());
        System.assertEquals(wPayments[0].inconsistentSpends, true);

        delete duplicateCSpend;

        ctrl = new PlanComponentCtrl();
        ctrl.project = contract;
        ctrl.contractId = contract.Id;
        ctrl.getPaymentsList();
        wPayments = ctrl.paymentWrappers;
        System.assertEquals(wPayments[0].inconsistentSpends, false);
        Test.stopTest();
    }

    @IsTest static void invoiceActionForInconsistentSpends_ScenarioWithNotSyncSpends() {
        insert TestHelper.accountRecord;
        insert TestHelper.brandRecord;
        insert TestHelper.salesRepUser;

        Platform__c adWordsPlatform = TestHelper.createTrueViewPlatform();
        insert adWordsPlatform;

        TestHelper.createOpportunity(null, null, adWordsPlatform, Utility.BILLING_PROFILES.Strike, true);
        System.assertNotEquals(TestHelper.opportunityRecord.Id, null, 'Opportunity should be inserted.');

        Project__c contract = TestHelper.createContract('Test Contract', null, null, false);
        contract.SpendRefreshDate__c = null;
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = TRUE LIMIT 1].Id;
        contract.CurrencyIsoCode = 'AUD';
        insert contract;

        List<Payment__c> projects = [SELECT StrikeId__c, Start_Date__c FROM Payment__c WHERE Project__c = :contract.Id];
        List<Sub_Project__c> payments = [SELECT Id FROM Sub_Project__c WHERE Project__c = :contract.Id];

        List<MM_Spendings__c> spends = new List<MM_Spendings__c>();
        // create 5 MM_Spendings__c, it will create 5 Project_Media_Spend__c records
        Integer spendsAmount = 5;
        for (Integer i = 0; i < spendsAmount; i++) {
            spends.add(new MM_Spendings__c(
                StrikeId__c = projects[0].StrikeId__c,
                Date__c = projects[0].Start_Date__c.addDays(i),
                Delivered__c = 100,
                Media_Spend__c = 100,
                CurrencyIsoCode = 'AUD',
                Contract__c = contract.Id,
                Is_Sync__c = false
            ));
        }
        insert spends;

        // check that Project_Media_Spend__c records amount is the same
        List<Project_Media_Spend__c> contractSpends = [
            SELECT Project__c, StrikeId__c, Date__c, Delivered__c, CurrencyIsoCode, Amount__c
            FROM Project_Media_Spend__c
            WHERE MMSpending__c IN :spends
        ];
        System.assertEquals(spendsAmount, contractSpends.size());

        Test.startTest();
        PlanComponentCtrl ctrl = new PlanComponentCtrl();
        ctrl.project = contract;
        ctrl.contractId = contract.Id;
        ctrl.getPaymentsList();
        List<SubProject.PaymentWrapper> wPayments = ctrl.paymentWrappers;
        System.assertEquals(wPayments.size(), payments.size());
        System.assertEquals(wPayments[0].inconsistentSpends, true);

        for (MM_Spendings__c spend :spends) {
            spend.Is_Sync__c = true;
        }
        update spends;

        ctrl = new PlanComponentCtrl();
        ctrl.project = contract;
        ctrl.contractId = contract.Id;
        ctrl.getPaymentsList();
        wPayments = ctrl.paymentWrappers;
        System.assertEquals(wPayments[0].inconsistentSpends, false);
        Test.stopTest();
    }

    @IsTest static void testValidateCostStructureOnPlatformChange() {
        Date todayDate = System.today();

        Opportunity opp = TestHelper.createOpportunity(TestHelper.createUser(), TestHelper.createAccount());
        opp.Brand__c = TestHelper.createBrand('testBrand').Id;
        opp.Flight_Start__c = Date.newInstance(todayDate.year() + 1, 1, 1);
        opp.Flight_End__c = Date.newInstance(todayDate.year() + 1, 2, 10);
        insert opp;

        OpportunityPlatform__c oppPlatformTrueView = TestHelper.createOpportunityPlatform(opp.Id, TestHelper.getTrueViewPlatform().Id);
        oppPlatformTrueView.CostStructure__c = 'CPC; CPM';
        oppPlatformTrueView.NoCostStructure__c = false;
        insert new List<OpportunityPlatform__c>{oppPlatformTrueView};

        opp.StageName = 'Closed Won';
        update opp;

        // add platform after to not create facebook projects
        OpportunityPlatform__c oppPlatformFacebook = TestHelper.createOpportunityPlatform(opp.Id, TestHelper.getFacebookPlatform().Id);
        oppPlatformFacebook.CostStructure__c = 'CPL; CPC; CPV';
        oppPlatformFacebook.NoCostStructure__c = false;
        insert oppPlatformFacebook;

        Project__c contract = [SELECT Id, (SELECT Id FROM Sub_Projects__r) FROM Project__c WHERE Opportunity__c = :opp.Id];
        Set<Id> paymentIds = new Set<Id>();
        for (Sub_Project__c payment :contract.Sub_Projects__r) {
            paymentIds.add(payment.Id);
        }

        PlanComponentCtrl ctrl = new PlanComponentCtrl();
        ctrl.objType = SUB_PROJECT_OBJECT_TYPE;
        ctrl.contractId = contract.Id;
        ctrl.project = contract;
        List<SubProject.PaymentWrapper> payments = ctrl.getPaymentsList();

        Test.startTest();
        ctrl.getAvailablePlatforms();
        ctrl.showProjectsForAllPayments();
        List<SelectOption> platforms = ctrl.getAvailablePlatforms();

        // get first [0] project
        ctrl.paymentId = ctrl.paymentWrappers[0].payment.Id;
        ctrl.projectRow = 0;
        // set new platform
        String platformToSet = '';
        for (SelectOption platform :platforms) {
            // platform to set should be different
            if (ctrl.expandedProjectsByPaymentId.get(ctrl.paymentId)[ctrl.projectRow].project.OpportunityPlatform__c == platform.getValue()) continue;
            platformToSet = platform.getValue();
            break;
        }
        ctrl.expandedProjectsByPaymentId.get(ctrl.paymentId)[ctrl.projectRow].project.OpportunityPlatform__c = platformToSet;
        ctrl.projectPlatformUpdated();
        // set new cost structure
        String ccToSet = '';
        for (SelectOption so :ctrl.expandedProjectsByPaymentId.get(ctrl.paymentId)[ctrl.projectRow].availableCostStructures) {
            if (String.isBlank(so.getValue())) continue;
            ccToSet = so.getValue();
            break;
        }
        ctrl.expandedProjectsByPaymentId.get(ctrl.paymentId)[ctrl.projectRow].project.CostStructure__c = ccToSet;
        ctrl.projectCostStructureUpdated();

        // should be no message
        System.assertEquals(ApexPages.getMessages().size(), 0, 'No message should be visible.');

        // save changes, should see NO error. New Platform doesn't conflict with CostStructures for old one
        ctrl.saveObjects();

        System.assertEquals(ctrl.errorOccurred, false, 'No errors expect');
        Boolean facebookPlatformFound = false;
        for (Sub_Project__c payment :SubProjectRepository.getPaymentsByIDsWithProjects(new Set<Id>{ctrl.paymentId})) {
            for (Payment__c project :payment.Projects__r) {
                if (project.OpportunityPlatform__c == oppPlatformFacebook.Id) {
                    facebookPlatformFound = true;
                }
            }
        }
        System.assertEquals(facebookPlatformFound, true, 'Platform for project should be changed.');
        Test.stopTest();
    }

    @IsTest static void testValidateCostStructureOnCostStructureChange() {
        Date todayDate = System.today();

        Opportunity opp = TestHelper.createOpportunity(TestHelper.createUser(), TestHelper.createAccount());
        opp.Brand__c = TestHelper.createBrand('testBrand').Id;
        opp.Flight_Start__c = Date.newInstance(todayDate.year() + 1, 1, 1);
        opp.Flight_End__c = Date.newInstance(todayDate.year() + 1, 2, 10);
        insert opp;

        OpportunityPlatform__c oppPlatformTrueView = TestHelper.createOpportunityPlatform(opp.Id, TestHelper.getTrueViewPlatform().Id);
        oppPlatformTrueView.CostStructure__c = 'CPC; CPM';
        oppPlatformTrueView.NoCostStructure__c = false;
        insert new List<OpportunityPlatform__c>{oppPlatformTrueView};

        opp.StageName = 'Closed Won';
        update opp;

        Project__c contract = [SELECT Id, (SELECT Id FROM Sub_Projects__r) FROM Project__c WHERE Opportunity__c = :opp.Id];
        Set<Id> paymentIds = new Set<Id>();
        for (Sub_Project__c payment :contract.Sub_Projects__r) {
            paymentIds.add(payment.Id);
        }

        PlanComponentCtrl ctrl = new PlanComponentCtrl();
        ctrl.objType = SUB_PROJECT_OBJECT_TYPE;
        ctrl.contractId = contract.Id;
        ctrl.project = contract;
        ctrl.getPaymentsList();

        Test.startTest();
        ctrl.getAvailablePlatforms();
        ctrl.showProjectsForAllPayments();
        ctrl.getAvailablePlatforms();

        // get first [0] project
        ctrl.paymentId = ctrl.paymentWrappers[0].payment.Id;
        ctrl.projectRow = 0;
        // set new cost structure
        String ccToSet = '';
        for (SelectOption so :ctrl.expandedProjectsByPaymentId.get(ctrl.paymentId)[ctrl.projectRow].availableCostStructures) {
            if (String.isBlank(so.getValue()) || ctrl.expandedProjectsByPaymentId.get(ctrl.paymentId)[ctrl.projectRow].project.CostStructure__c == so.getValue()) continue;
            // set new value to see warning
            ccToSet = so.getValue();
            break;
        }
        ctrl.expandedProjectsByPaymentId.get(ctrl.paymentId)[ctrl.projectRow].project.CostStructure__c = ccToSet;
        ctrl.projectCostStructureUpdated();

        // should be notifying message
        System.assertEquals(ApexPages.getMessages().size(), 1, 'Warning message should be visible');
        System.assert(ApexPages.getMessages()[0].getSummary().contains('Please create a new Project or revert your changes.'));

        // save changes, should see an error. New cost structure conflicts with CostStructures for other projects
        ctrl.saveObjects();

        System.assertEquals(ctrl.errorOccurred, true, 'Error is being expected');
        System.assert(ApexPages.getMessages()[1].getSummary().contains('Cost Structure should be the same for projects with platforms:'));
        Test.stopTest();
    }
}