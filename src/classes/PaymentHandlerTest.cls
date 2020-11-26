@IsTest private class PaymentHandlerTest {

    @IsTest static void cannotChangeEndDate() {
        TestHelper.prepareData(false);

        List<Payment__c> payments = [SELECT Id, End_Date__c, Start_Date__c, Project__c, Name FROM Payment__c WHERE Project__c =: TestHelper.contractRecord.Id];
        String oldName = payments[0].Name;
        Date endDate = payments[0].End_Date__c;

        Test.startTest();
        try  {
            payments[0].End_Date__c = endDate.addDays(10);
            update payments[0];
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains(Label.LatestProjectEndDateNotEqualPaymentEndDate));
        }
        Test.stopTest();
        System.assertEquals(oldName, [SELECT Name, Id FROM Payment__c WHERE Id = :payments[0].Id].Name);
    }

    @IsTest static void cannotDeleteLastProject() {
        Date nextMonth = System.today().addMonths(1);
        Date sDate = Date.newInstance(nextMonth.year(), nextMonth.month(), 1);
        Date eDate = sDate.addMonths(1).addDays(-1);

        Project__c contract = TestHelper.createContract('TestContract', sDate, eDate, true);

        Payment__c project1 ,project2;
        project1 = [SELECT Id, Client_Spend__c, End_Date__c, Start_Date__c, Payment__c FROM Payment__c WHERE Payment__r.Project__c = :contract.Id];
        project2 = TestHelper.createProject(contract, contract.Start_Date__c, contract.End_Date__c, false);
        project2.Payment__c = project1.Payment__c;
        project2.Client_Spend__c = 0;
        insert project2;

        Boolean cannotDeleteAllProjectsAtOnce = false;
        Boolean cannotDeleteLastProject = false;
        Test.startTest();
        try {
            delete new List<Payment__c>{project1, project2};
        } catch (Exception ex) {
            if (ex.getMessage().contains(Label.CannotRemoveLastProject)) {
                cannotDeleteAllProjectsAtOnce = true;
            }
        }
        delete project2;

        try {
            delete project1;
        } catch(Exception ex) {
            if (ex.getMessage().contains(Label.CannotRemoveLastProject)) {
                cannotDeleteLastProject = true;
            }
        }
        Test.stopTest();
        System.assert(cannotDeleteAllProjectsAtOnce);
        System.assert(cannotDeleteLastProject);
    }

    @IsTest static void cannotRemoveStartedProject() {
        Date sDate = System.today().addMonths(-1);
        Date eDate = System.today().addMonths(1);

        Project__c contract = TestHelper.createContract('TestContract', sDate, eDate, false);
        contract.Gaps_Exist_Between_Projects__c = true;
        insert contract;

        delete [SELECT Id FROM Sub_Project__c];

        Test.startTest();
        Sub_Project__c payment = TestHelper.createPayment(contract, true);

        Payment__c projectAlreadyStarted = TestHelper.createProject(contract, sDate, System.today().addDays(-1), false);
        projectAlreadyStarted.Payment__c = payment.Id;
        projectAlreadyStarted.Client_Spend__c = 0;

        Payment__c projectStartingToday  = TestHelper.createProject(contract, System.today(), System.today().addDays(3), false);
        projectStartingToday.Payment__c = payment.Id;
        projectStartingToday.Client_Spend__c = 0;

        Payment__c projectNotYetStarted  = TestHelper.createProject(contract, System.today().addDays(4), eDate, false);
        projectNotYetStarted.Payment__c = payment.Id;
        projectNotYetStarted.Client_Spend__c = 0;

        insert new List<Payment__c> {projectAlreadyStarted, projectStartingToday, projectNotYetStarted};

        Boolean projectAlreadyStartedCannotBeRemoved = false;
        Boolean projectStartingTodayCannotBeRemoved = false;
        Boolean projectNotYetStartedCannotBeRemoved = false;
        try {
            delete projectAlreadyStarted;
        } catch (Exception ex) {
            if (ex.getMessage().contains(Label.CannotRemoveStartedProject)) {
                projectAlreadyStartedCannotBeRemoved = true;
            }
        }
        try {
            delete projectStartingToday;
        } catch (Exception ex) {
            if (ex.getMessage().contains(Label.CannotRemoveStartedProject)) {
                projectStartingTodayCannotBeRemoved = true;
            }
        }
        try {
            delete projectNotYetStarted;
        }  catch (Exception ex) {
            projectNotYetStartedCannotBeRemoved = true;
        }
        Test.stopTest();

        System.assert(projectAlreadyStartedCannotBeRemoved);
        System.assert(projectStartingTodayCannotBeRemoved);
        System.assert(!projectNotYetStartedCannotBeRemoved);
    }

    @IsTest static void validateProjectDates() {
        TestHelper.prepareData(false);

        Sub_Project__c payment = [SELECT Project__c, End_Date__c, Start_Date__c, Client_Spend__c FROM Sub_Project__c WHERE Project__c =: TestHelper.contractRecord.Id][0];

        PaymentHandler.skipUpdateValidation = true;
        Payment__c project = [SELECT Id, Payment__c, Start_Date__c, End_Date__c FROM Payment__c WHERE Payment__c =: payment.Id];
        project.End_Date__c = payment.End_Date__c.addDays(-10);
        project.Client_Spend__c = payment.Client_Spend__c / 2;
        update project;
        PaymentHandler.skipUpdateValidation = false;

        Test.startTest();
        Payment__c projectNew = TestHelper.createProject(TestHelper.contractRecord, payment.End_Date__c.addDays(-9), payment.End_Date__c, false);
        projectNew.Payment__c = payment.Id;
        projectNew.Client_Spend__c = payment.Client_Spend__c - project.Client_Spend__c;
        insert projectNew;

        Boolean invalidStartDate = false, invalidEndDate = false;
        try {
            project.Start_Date__c = project.Start_Date__c.addDays(-10);
            update project;
        } catch (Exception ex) {
            if (ex.getMessage().contains(Label.EarliestProjectStartDateNotEqualPaymentStartDate)) {
                invalidStartDate = true;
            }
        }
        System.assert(invalidStartDate);

        try {
            projectNew.End_Date__c = projectNew.End_Date__c.addDays(11);
            update projectNew;
        } catch (Exception ex) {
            if (ex.getMessage().contains(Label.LatestProjectEndDateNotEqualPaymentEndDate)) {
                invalidEndDate = true;
            }
        }
        System.assert(invalidEndDate);
        Test.stopTest();
    }

    @IsTest static void validateProjectClientSpend() {
        TestHelper.prepareData(false);

        Sub_Project__c payment = [SELECT Id, Project__c, End_Date__c, Start_Date__c, Client_Spend__c FROM Sub_Project__c WHERE Project__c =: TestHelper.contractRecord.Id][0];

        List<Payment__c> projects = [SELECT Id, Payment__c, Start_Date__c, End_Date__c FROM Payment__c WHERE Payment__c =: payment.Id];
        projects[0].End_Date__c = (payment.End_Date__c).addDays(-10);
        projects[0].Client_Spend__c = payment.Client_Spend__c / 2;

        Payment__c projectNew = TestHelper.createProject(TestHelper.contractRecord, payment.End_Date__c.addDays(-9), payment.End_Date__c, false);
        projectNew.Payment__c = payment.Id;
        projectNew.Client_Spend__c = payment.Client_Spend__c - projects[0].Client_Spend__c;

        Test.startTest();
        PaymentHandler.skipUpdateValidation = true;
        update projects[0];
        PaymentHandler.skipUpdateValidation = false;
        insert projectNew;

        Boolean invalidClientSpend = false;
        try {
            projects[0].Client_Spend__c = payment.Client_Spend__c / 2 + 10;
            update projects[0];
        } catch (Exception ex) {
            if (ex.getMessage().contains(Label.SumProjectClientSpendNotEqualPaymentClientSpend)) {
                invalidClientSpend = true;
            }
        }
        System.assert(invalidClientSpend);
        Test.stopTest();
    }

    @IsTest static void validateProjectsWithGaps() {
        TestHelper.prepareData(false);

        Project__c contract = TestHelper.contractRecord;
        Sub_Project__c payment = [SELECT Id, Project__c, End_Date__c, Start_Date__c, Client_Spend__c FROM Sub_Project__c WHERE Project__c =: contract.Id][0];

        List<Payment__c> projects = [SELECT Id, Payment__c, Start_Date__c, End_Date__c FROM Payment__c WHERE Payment__c =: payment.Id];
        projects[0].End_Date__c = (payment.End_Date__c).addDays(-10);
        projects[0].Client_Spend__c = payment.Client_Spend__c / 2;

        Payment__c projectNew = TestHelper.createProject(contract, (payment.End_Date__c).addDays(-9), payment.End_Date__c, false);
        projectNew.Payment__c = payment.Id;
        projectNew.Client_Spend__c = payment.Client_Spend__c - projects[0].Client_Spend__c;

        Test.startTest();
        PaymentHandler.skipUpdateValidation = true;
        update projects[0];
        PaymentHandler.skipUpdateValidation = false;
        insert projectNew;

        Boolean projectsWithGaps = false;
        try {
            projectNew.Start_Date__c = (payment.End_Date__c).addDays(-8);
            update projectNew;
        } catch (Exception ex) {
            if (ex.getMessage().contains(Label.ProjectGaps)) {
                projectsWithGaps = true;
            }
        }
        System.assert(projectsWithGaps);

        contract.Gaps_Exist_Between_Projects__c = true;
        update contract;

        projectNew.Start_Date__c = (payment.End_Date__c).addDays(-8);
        update projectNew;

        System.assertEquals((payment.End_Date__c).addDays(-8), [SELECT Id, Start_Date__c FROM Payment__c WHERE Id =: projectNew.Id].Start_Date__c);
        Test.stopTest();
    }

    @IsTest static void willSetPerformMMSyncOnInsert() {
        insert TestHelper.accountRecord;

        Date nextMonth = System.today().addMonths(1);
        Date sDate = Date.newInstance(nextMonth.year(), nextMonth.month(), 1),
            eDate = sDate.addMonths(1).addDays(-1);

        Project__c contractSynced = TestHelper.createContract('Synced Contract', sDate, eDate, false);
        contractSynced.Sync_with_MM__c = System.now();

        Project__c contractNotSynced = TestHelper.createContract('Synced NOT Contract', contractSynced.Start_Date__c.addDays(1), contractSynced.End_Date__c, false);
        contractSynced.PerformMMSync__c = true;

        insert new List<Project__c>{contractSynced, contractNotSynced};

        contractSynced.PerformMMSync__c = false;
        update contractSynced;

        List<Sub_Project__c> payments = [SELECT Id, Client_Spend__c, Project__c, End_Date__c, Start_Date__c FROM Sub_Project__c WHERE Project__c = :contractSynced.Id OR Project__c = :contractNotSynced.Id ORDER BY Project__r.Start_Date__c];

        PaymentHandler.skipDeleteValidation = true;
        delete [SELECT Id FROM Payment__c WHERE Payment__c IN :payments];
        PaymentHandler.skipDeleteValidation = false;

        Test.startTest();
        insert new List<Payment__c>{
            TestHelper.createProjectBasedOnPayment(contractSynced, payments[0], false),
            TestHelper.createProjectBasedOnPayment(contractNotSynced, payments[1], false)
        };
        Test.stopTest();

        System.assertEquals(true, [SELECT PerformMMSync__c FROM Project__c WHERE Id = :contractSynced.Id].PerformMMSync__c);
        System.assertEquals(false, [SELECT PerformMMSync__c FROM Project__c WHERE Id = :contractNotSynced.Id].PerformMMSync__c);
    }

    @IsTest static void willSetPerformMMSyncOnUpdate() {
        insert TestHelper.accountRecord;
        insert TestHelper.brandRecord;
        insert TestHelper.salesRepUser;

        Platform__c platformTV = TestHelper.createTrueViewPlatform();
        insert platformTV;

        Date nextMonth = System.today().addMonths(1);
        Date sDate = Date.newInstance(nextMonth.year(), nextMonth.month(), 1),
            eDate = sDate.addMonths(1).addDays(-1);

        Opportunity opp1 = TestHelper.createOpportunity(sDate, eDate, platformTV, Utility.BILLING_PROFILES.Strike, false);
        Opportunity opp2 = TestHelper.createOpportunity(sDate, eDate, platformTV, Utility.BILLING_PROFILES.Strike, false);
        Opportunity opp3 = TestHelper.createOpportunity(sDate, eDate, platformTV, Utility.BILLING_PROFILES.Strike, false);

        List<Opportunity> opportunities = new List<Opportunity> {opp1, opp2, opp3};
        insert opportunities;

        List<OpportunityPlatform__c> oppPlatforms = new List<OpportunityPlatform__c>();
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>(opportunities);
        for (Opportunity opp :opportunities) {
            oppPlatforms.add(TestHelper.createOpportunityPlatform(opp.Id, platformTV.Id));
            opp.StageName = 'Closed Won';
        }
        insert oppPlatforms;
        update opportunities;

        Map<Id, Project__c> contractsMap = new Map<Id, Project__c>();
        for (Project__c contract :[SELECT Id, Opportunity__c FROM Project__c WHERE Opportunity__c IN :opportunityMap.keySet()]) {
            contractsMap.put(contract.Opportunity__c, contract);
        }

        Project__c contractSynced1 = contractsMap.get(opp1.Id);
        contractSynced1.Sync_with_MM__c = System.now();
        Project__c contractSynced2 = contractsMap.get(opp2.Id);
        contractSynced2.Sync_with_MM__c = System.now();
        update new List<Project__c> {contractSynced1, contractSynced2};

        Project__c contractNotSynced = contractsMap.get(opp3.Id);

        Test.startTest();
        contractSynced1.PerformMMSync__c = false;
        contractSynced2.PerformMMSync__c = false;
        contractNotSynced.PerformMMSync__c = false;
        update new List<Project__c>{contractSynced1, contractSynced2, contractNotSynced};

        Payment__c project1 = [SELECT Id, StrikeId__c, Project__r.PerformMMSync__c, ShouldSyncWithMM__c FROM Payment__c WHERE Project__c = :contractSynced1.Id];
        Payment__c project2 = [SELECT Id, StrikeId__c, Project__r.PerformMMSync__c, ShouldSyncWithMM__c FROM Payment__c WHERE Project__c = :contractSynced2.Id];
        Payment__c project3 = [SELECT Id, StrikeId__c, Project__r.PerformMMSync__c, ShouldSyncWithMM__c FROM Payment__c WHERE Project__c = :contractNotSynced.Id];

        System.assertEquals(true, project1.ShouldSyncWithMM__c);
        System.assertEquals(true, project2.ShouldSyncWithMM__c);
        System.assertEquals(false, project3.ShouldSyncWithMM__c, 'Sync_with_MM__c should not be set for a parent contract');

        System.assertEquals(false, project1.Project__r.PerformMMSync__c);
        System.assertEquals(false, project2.Project__r.PerformMMSync__c);
        System.assertEquals(false, project3.Project__r.PerformMMSync__c);

        project1.StrikeId__c += '123';
        project3.StrikeId__c += '456';

        update new List<Payment__c>{project1, project2, project3 };
        Test.stopTest();

        System.assertEquals(true, [SELECT PerformMMSync__c FROM Project__c WHERE Id = :contractSynced1.Id].PerformMMSync__c, 'ShouldSyncWithMM__c is TRUE for changed StrikeId__c field');
        System.assertEquals(false, [SELECT PerformMMSync__c FROM Project__c WHERE Id = :contractSynced2.Id].PerformMMSync__c, 'ShouldSyncWithMM__c is TRUE though StrikeId__c wasn\'t changed');
        System.assertEquals(false, [SELECT PerformMMSync__c FROM Project__c WHERE Id = :contractNotSynced.Id].PerformMMSync__c, 'ShouldSyncWithMM__c is FALSE for changed StrikeId__c field');
    }

    @IsTest
    static void testSetStrikeIdOnInsert() {
        Project__c contract = TestHelper.createContract('Test Contract', null, null, false);
        contract.Gaps_Exist_Between_Projects__c = true;
        insert contract;

        List<Sub_Project__c> payments = [SELECT Start_Date__c, End_Date__c, Client_Spend__c FROM Sub_Project__c WHERE Project__c = :contract.Id];

        PaymentHandler.skipDeleteValidation = true;
        delete [SELECT Id FROM Payment__c WHERE Payment__c IN :payments];
        PaymentHandler.skipDeleteValidation = false;

        Platform__c platformTV = TestHelper.createTrueViewPlatform();
        Platform__c platformFB = TestHelper.createFacebookPlatform();
        insert new List<Platform__c> {platformTV, platformFB};

        OpportunityPlatform__c oppPlatformFB = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, platformFB.Id);
        OpportunityPlatform__c oppPlatformTV = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, platformTV.Id);
        insert new List<OpportunityPlatform__c> {oppPlatformTV, oppPlatformFB};

        Test.startTest();
        Payment__c projectTV1 = TestHelper.createProjectBasedOnPayment(contract, payments[0], false);
        projectTV1.End_Date__c = payments[0].End_Date__c.addDays(-10);
        projectTV1.Client_Spend__c = payments[0].Client_Spend__c / 4;
        projectTV1.OpportunityPlatform__c = oppPlatformTV.Id;

        Payment__c projectTV2 = TestHelper.createProjectBasedOnPayment(contract, payments[0], false);
        projectTV2.Start_Date__c = payments[0].End_Date__c.addDays(-15);
        projectTV2.Client_Spend__c = payments[0].Client_Spend__c / 4;
        projectTV2.Payment__c = payments[0].Id;
        projectTV2.OpportunityPlatform__c = oppPlatformTV.Id;

        Payment__c projectFB1 = TestHelper.createProjectBasedOnPayment(contract, payments[0], false);
        projectFB1.End_Date__c = payments[0].End_Date__c.addDays(-10);
        projectFB1.Client_Spend__c = payments[0].Client_Spend__c/4;
        projectFB1.OpportunityPlatform__c = oppPlatformFB.Id;

        Payment__c projectFB2 = TestHelper.createProjectBasedOnPayment(contract, payments[0], false);
        projectFB2.Start_Date__c = payments[0].End_Date__c.addDays(-15);
        projectFB2.Client_Spend__c = payments[0].Client_Spend__c/4;
        projectFB2.OpportunityPlatform__c = oppPlatformFB.Id;

        insert new List<Payment__c>{projectTV1, projectTV2, projectFB1, projectFB2};
        Test.stopTest();

        String contractStrikeId = [SELECT Project_ID__c FROM Project__c WHERE Id = :contract.Id].Project_ID__c;
        System.assertEquals(platformTV.Prefix__c + contractStrikeId + 'A', [SELECT StrikeId__c FROM Payment__c WHERE Id = :projectTV1.Id].StrikeId__c);
        System.assertEquals(platformTV.Prefix__c + contractStrikeId + 'B', [SELECT StrikeId__c FROM Payment__c WHERE Id = :projectTV2.Id].StrikeId__c);
        System.assertEquals(platformFB.Prefix__c + contractStrikeId + 'A', [SELECT StrikeId__c FROM Payment__c WHERE Id = :projectFB1.Id].StrikeId__c);
        System.assertEquals(platformFB.Prefix__c + contractStrikeId + 'B', [SELECT StrikeId__c FROM Payment__c WHERE Id = :projectFB2.Id].StrikeId__c);
    }

    @IsTest static void testSetStrikeIdOnSplit() {
        Project__c contract = TestHelper.createContract('Test Contract', null, null, false);
        contract.Gaps_Exist_Between_Projects__c = true;
        insert contract;

        Platform__c platformTV = TestHelper.createTrueViewPlatform();
        insert platformTV;

        OpportunityPlatform__c oppPlatformTV = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, platformTV.Id);
        oppPlatformTV.Contract__c = contract.Id;
        insert oppPlatformTV;

        Sub_Project__c payment = [SELECT Start_Date__c, End_Date__c, Client_Spend__c FROM Sub_Project__c WHERE Project__c = :contract.Id LIMIT 1];

        PaymentHandler.skipDeleteValidation = true;
        delete [SELECT Id FROM Payment__c WHERE Payment__c = :payment.Id];
        PaymentHandler.skipDeleteValidation = false;

        Test.startTest();
        Payment__c project1 = TestHelper.createProjectBasedOnPayment(contract, payment, false);
        project1.Client_Spend__c = payment.Client_Spend__c;
        project1.OpportunityPlatform__c = oppPlatformTV.Id;
        project1.Payment__c = payment.Id;
        insert project1;

        PaymentHandler.skipUpdateValidation = true;
        project1.End_Date__c = payment.End_Date__c.addDays(-10);
        PaymentHandler.skipUpdateValidation = false;

        Payment__c project2 = TestHelper.createProjectBasedOnPayment(contract, payment, false);
        project2.Start_Date__c = payment.End_Date__c.addDays(-15);
        project2.Client_Spend__c = 0;
        project2.OpportunityPlatform__c = oppPlatformTV.Id;
        insert project2;
        Test.stopTest();

        String contractStrikeId = [SELECT Project_ID__c FROM Project__c WHERE Id = :contract.Id].Project_ID__c;
        System.assertEquals('TV' + contractStrikeId + 'A', [SELECT StrikeId__c FROM Payment__c WHERE Id = :project1.Id].StrikeId__c);
        System.assertEquals('TV' + contractStrikeId + 'B', [SELECT StrikeId__c FROM Payment__c WHERE Id = :project2.Id].StrikeId__c);
    }

    @IsTest static void willSetIsOverlapping() {
        Project__c contract = TestHelper.createContract('Test Contract', null, null, true);

        Platform__c platformTV = TestHelper.createTrueViewPlatform();
        insert platformTV;

        OpportunityPlatform__c oppPlatformTV = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, platformTV.Id);
        oppPlatformTV.Contract__c = contract.Id;
        insert oppPlatformTV;

        Sub_Project__c payment = [SELECT Start_Date__c, End_Date__c, Client_Spend__c FROM Sub_Project__c WHERE Project__c = :contract.Id LIMIT 1];

        PaymentHandler.skipDeleteValidation = true;
        delete [SELECT Id FROM Payment__c WHERE Payment__c = :payment.Id];
        PaymentHandler.skipDeleteValidation = false;

        Test.startTest();
        Payment__c project1 = TestHelper.createProjectBasedOnPayment(contract, payment, false);
        project1.Client_Spend__c = payment.Client_Spend__c;
        project1.OpportunityPlatform__c = oppPlatformTV.Id;
        insert project1;

        Payment__c project2 = TestHelper.createProjectBasedOnPayment(contract, payment, false);
        project2.End_Date__c = payment.Start_Date__c.addDays(5);
        project2.Client_Spend__c = 0;
        project2.OpportunityPlatform__c = oppPlatformTV.Id;
        insert project2;

        PaymentHandler.calculateIsOverlapping = true;
        update new List<Payment__c> {project1, project2};
        Test.stopTest();

        Map<Id, Payment__c> projects = new Map<Id, Payment__c> ([SELECT Id, Name, IsOverlapping__c, StrikeId__c, ProjectID__c FROM Payment__c WHERE Payment__c = :payment.Id]);
        System.assertEquals(2, projects.size());
        for (Payment__c project : projects.values()) {
            System.assert(project.IsOverlapping__c);
        }
        project2 = projects.get(project2.Id);
        System.assertEquals(project2.ProjectID__c + 'B', project2.StrikeId__c);
        System.assert(project2.Name.contains(project2.StrikeId__c));
    }

    @IsTest static void willSetVariableUnitCostOnProject() {
        Project__c contract = TestHelper.createContract('Test Contract', null, null, true);

        Platform__c platformTV = TestHelper.createTrueViewPlatform();
        Platform__c platformFB = TestHelper.createFacebookPlatform();
        insert new List<Platform__c> { platformTV, platformFB };

        OpportunityPlatform__c oppPlatformTV = new OpportunityPlatform__c ();
        oppPlatformTV.CostStructure__c = 'CPV';
        oppPlatformTV.Opportunity__c = contract.Opportunity__c;
        oppPlatformTV.Platform__c =  platformTV.Id;
        oppPlatformTV.Contract__c = contract.Id;
        oppPlatformTV.CPV__c = 0.88;
        oppPlatformTV.CTA_Overlay_Text__c = 'TRUE VIEW CPV';
        oppPlatformTV.Companion_Banner__c = 'Yes';
        oppPlatformTV.Pixel_Tracking__c = 'Yes';
        oppPlatformTV.VariableCPV__c = true;
        oppPlatformTV.VariableCPM__c = true;
        oppPlatformTV.KPI__c = 'KPI KPI';

        OpportunityPlatform__c oppPlatformFB = new OpportunityPlatform__c ();
        oppPlatformFB.CostStructure__c = 'CPM';
        oppPlatformFB.Opportunity__c = contract.Opportunity__c;
        oppPlatformFB.Platform__c = platformFB.Id;
        oppPlatformFB.Contract__c = contract.Id;
        oppPlatformFB.CPV__c = 0.88;
        oppPlatformFB.CTA_Overlay_Text__c = 'FACEBOOK CPM';
        oppPlatformFB.Companion_Banner__c = 'Yes';
        oppPlatformFB.Pixel_Tracking__c = 'Yes';
        oppPlatformFB.VariableCPV__c = false;
        oppPlatformFB.VariableCPM__c = false;
        oppPlatformFB.KPI__c = 'KPI KPI';
        insert new List<OpportunityPlatform__c> {oppPlatformTV, oppPlatformFB};

        Sub_Project__c payment = [SELECT Start_Date__c, End_Date__c, Client_Spend__c FROM Sub_Project__c WHERE Project__c = :contract.Id LIMIT 1];

        Test.startTest();
        Payment__c project1 = TestHelper.createProjectBasedOnPayment(contract, payment, false);
        project1.CostStructure__c = oppPlatformTV.CostStructure__c;
        project1.OpportunityPlatform__c = oppPlatformTV.Id;
        project1.Client_Spend__c = 0;

        Payment__c project2 = TestHelper.createProjectBasedOnPayment(contract, payment, false);
        project2.Client_Spend__c = 0;
        project2.CostStructure__c = oppPlatformFB.CostStructure__c;
        project2.OpportunityPlatform__c = oppPlatformFB.Id;

        insert new List<Payment__c>{project1, project2};
        Map<Id, Payment__c> projectsAfterInsert = new Map<Id, Payment__c> ([SELECT Id, VariableUnitCost__c FROM Payment__c WHERE Payment__c = :payment.Id]);
        System.assertEquals(true, projectsAfterInsert.get(project1.Id).VariableUnitCost__c);
        System.assertEquals(false, projectsAfterInsert.get(project2.Id).VariableUnitCost__c);

        project1.CostStructure__c = oppPlatformFB.CostStructure__c; //'CPM';
        project2.CostStructure__c = oppPlatformTV.CostStructure__c; //'CPV';
        update new List<Payment__c>{project1, project2};

        Map<Id, Payment__c> projectsAfterUpdate = new Map<Id, Payment__c>([SELECT Id, VariableUnitCost__c FROM Payment__c WHERE Payment__c = :payment.Id]);
        System.assert(projectsAfterUpdate.get(project1.Id).VariableUnitCost__c);
        System.assert(!projectsAfterUpdate.get(project2.Id).VariableUnitCost__c);
        Test.stopTest();
    }

    @IsTest static void CopyFieldsFromOppPlatformToProject() {
        Project__c contract = TestHelper.createContract('Test Contract', null, null, true);

        Platform__c platformTV = TestHelper.createTrueViewPlatform();
        Platform__c platformFB = TestHelper.createFacebookPlatform();
        insert new List<Platform__c> { platformFB, platformTV };

        OpportunityPlatform__c oppPlatformTV = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, platformTV.Id);
        oppPlatformTV.Contract__c = contract.Id;
        oppPlatformTV.VariableCPV__c = true;
        oppPlatformTV.VariableCPM__c = false;
        oppPlatformTV.CTA_Overlay_Text__c = 'TV Text';
        oppPlatformTV.KPI__c='KPI TV';

        OpportunityPlatform__c oppPlatformFB = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, platformFB.Id);
        oppPlatformFB.Contract__c = contract.Id;
        oppPlatformFB.VariableCPV__c = true;
        oppPlatformFB.VariableCPM__c = false;
        oppPlatformFB.CTA_Overlay_Text__c = 'FB Text';
        oppPlatformFB.KPI__c='KPI FB';
        insert new List<OpportunityPlatform__c>{ oppPlatformFB, oppPlatformTV };

        Sub_Project__c payment = [SELECT Start_Date__c, End_Date__c, Client_Spend__c FROM Sub_Project__c WHERE Project__c = :contract.Id LIMIT 1];

        Test.startTest();
        Payment__c project1 = TestHelper.createProjectBasedOnPayment(contract, payment, false);
        project1.CostStructure__c = oppPlatformTV.CostStructure__c;
        project1.OpportunityPlatform__c = oppPlatformTV.Id;
        project1.Client_Spend__c = 0;
        project1.Age__c = '1';

        Payment__c project2 = TestHelper.createProjectBasedOnPayment(contract, payment, false);
        project2.Client_Spend__c = 0;
        project2.CostStructure__c = 'CPM';
        project2.OpportunityPlatform__c = oppPlatformFB.Id;
        project2.Age__c = '2';
        insert new List<Payment__c>{project1, project2};

        Map<Id, Payment__c> projectsAfterInsert = new Map<Id, Payment__c> ([
            SELECT Id, Action_Type__c, Age__c, Age_Max__c, Age_Min__c, Brand_Lift_Study__c, Companion_Banner__c, CostStructure__c,
            			Facebook_page__c, Gender__c, IsOverlapping__c, Name, Objectives__c, Opportunity_Ad_Placement__c,
            			Pixel_Tracking__c, ProjectID__c, StrikeId__c, VariableUnitCost__c, KPI__c, CTA_Overlay_Text__c
            FROM Payment__c
            WHERE Payment__c = :payment.Id
        ]);
        Test.stopTest();

        project1 = projectsAfterInsert.get(project1.Id);
        project2 = projectsAfterInsert.get(project2.Id);

        System.assertEquals(oppPlatformTV.CTA_Overlay_Text__c, project1.CTA_Overlay_Text__c);
        System.assertEquals(oppPlatformFB.CTA_Overlay_Text__c, project2.CTA_Overlay_Text__c);
        System.assertEquals(oppPlatformTV.KPI__c, project1.KPI__c);
        System.assertEquals(oppPlatformFB.KPI__c, project2.KPI__c);
        System.assertEquals(oppPlatformTV.Companion_Banner__c, project1.Companion_Banner__c);
        System.assertEquals(oppPlatformFB.Companion_Banner__c, project2.Companion_Banner__c);
        System.assertEquals(oppPlatformTV.Pixel_Tracking__c, project1.Pixel_Tracking__c);
        System.assertEquals(oppPlatformFB.Pixel_Tracking__c, project2.Pixel_Tracking__c);
    }

    /*@IsTest static void actualGrossProfitNewShouldBeEqualToActualGrossProfitWhenContractIsCreated() {
        // The method is made to make sure that new field "Actual_Gross_Profit_New__c" computes value correctly
        Project__c contract = TestHelper.createContract('Test Contract', null, null, false);

        Test.startTest();
        insert contract;
        Test.stopTest();

        List<Payment__c> projects = [SELECT Id, Actual_Gross_Profit__c, Actual_Gross_Profit_New__c FROM Payment__c WHERE Project__c = :contract.Id];
        for (Payment__c project :projects) {
            System.assertEquals(project.Actual_Gross_Profit__c, project.Actual_Gross_Profit_New__c);
        }
    }*/

    /*@IsTest static void actualGrossProfitCurrencyShouldBeEqualToActualGrossProfitWhenClientSpendIsChanged() {
        // The method is made to make sure that new field "Actual_Gross_Profit_New__c" computes value correctly
        Project__c contract = TestHelper.createContract('Test Contract', null, null, true);

        Integer monthsBetween = contract.Start_Date__c.monthsBetween(contract.End_Date__c) + 1;
        Decimal clientSpendOnContract = contract.Client_Spend__c, clientSpendsOnPayments = 0;

        List<Sub_Project__c> payments = [SELECT Id, Client_Spend__c, Checked__c FROM Sub_Project__c WHERE Project__c = :contract.Id];
        for (Sub_Project__c payment :payments) {
            clientSpendsOnPayments += payment.Client_Spend__c;
            System.assertEquals(payment.Checked__c, false);
        }
        System.assertEquals(clientSpendOnContract, clientSpendsOnPayments);
        System.assertEquals(monthsBetween, payments.size());
        System.assert(1 < payments.size(), 'Amount of Payments (Sub_Project records) should be more that 1 and equal to "monthsBetween" variable.');

        List<Payment__c> projects = [SELECT Actual_Gross_Profit__c, Actual_Gross_Profit_New__c, Client_Spend__c FROM Payment__c WHERE Project__c = :contract.Id];
        for (Payment__c project :projects) {
            System.assertEquals(project.Actual_Gross_Profit__c, project.Actual_Gross_Profit_New__c);
        }

        Test.startTest();
        payments[0].Client_Spend__c = payments[0].Client_Spend__c + 50;
        payments[1].Client_Spend__c = payments[1].Client_Spend__c - 50;
        update payments;
        Test.stopTest();

        projects = [SELECT Actual_Gross_Profit__c, Actual_Gross_Profit_New__c, Client_Spend__c FROM Payment__c WHERE Project__c = :contract.Id];
        for (Payment__c project :projects) {
            System.assertEquals(project.Actual_Gross_Profit__c, project.Actual_Gross_Profit_New__c);
        }
    }*/

    /*@IsTest static void actualGrossProfitCurrencyShouldBeEqualToActualGrossProfitWhenBillingConditionIsChanged() {
        Project__c contract = TestHelper.createContract('Test Contract', null, null, false);
        contract.Client_Spend__c = 2000;
        insert contract;

        List<Payment__c> projects = [SELECT Id, Actual_Gross_Profit__c, Actual_Gross_Profit_New__c FROM Payment__c WHERE Project__c = :contract.Id];
        Map<Id, Decimal> projectIdToActualGrossProfit = new Map<Id, Decimal>();
        for (Payment__c project :projects) {
            projectIdToActualGrossProfit.put(project.Id, project.Actual_Gross_Profit__c);
        }

        BillingCondition__c billingConditionNew = TestHelper.createBillingCondition('New Billing Condition', true);

        Test.startTest();
        PaymentHandler.billingConditions = null;
        contract.BillingCondition__c = billingConditionNew.Id;
        update contract;
        Test.stopTest();

        projects = [SELECT Id, Actual_Gross_Profit__c, Actual_Gross_Profit_New__c, Client_Spend__c FROM Payment__c WHERE Project__c = :contract.Id];
        for (Payment__c project :projects) {
            System.assertNotEquals(project.Actual_Gross_Profit__c, projectIdToActualGrossProfit.get(project.Id), 'Actual_Gross_Profit__c should be different after Billing Condition is changed for Contract.');
            System.assertEquals(project.Actual_Gross_Profit__c, project.Actual_Gross_Profit_New__c);
        }
    }*/

    /*@IsTest static void actualGrossProfitCurrencyShouldBeEqualToActualGrossProfitWhenSyncWithXero() {
        Date sDate = Date.newInstance(System.today().year(), 3, 1).addYears(1),
            eDate = Date.newInstance(System.today().year(), 4, 30).addYears(1);
        Project__c contract = TestHelper.createContract('Test Contract', sDate, eDate, true);
        Integer monthsBetween = contract.Start_Date__c.monthsBetween(contract.End_Date__c) + 1;

        List<Payment__c> projects = [SELECT Id, Actual_Gross_Profit__c, Actual_Gross_Profit_New__c FROM Payment__c WHERE Project__c = :contract.Id];
        Map<Id,Decimal> projectIdToActualGrossProfit = new Map<Id,Decimal>();
        for (Payment__c project :projects) {
            projectIdToActualGrossProfit.put(project.Id, project.Actual_Gross_Profit__c);
        }

        Decimal clientSpendOnContract = contract.Client_Spend__c, clientSpendsOnPayments = 0;
        List<Sub_Project__c> payments = [SELECT Id, Client_Spend__c, Checked__c, Synced_with_Xero__c FROM Sub_Project__c WHERE Project__c = :contract.Id];
        System.assertEquals(monthsBetween, payments.size());
        System.assert(1 < payments.size(), 'Amount of Payments (Sub_Project records) should be more that 1 and equal to "monthsBetween" variable.');
        for (Sub_Project__c payment :payments) {
            clientSpendsOnPayments += payment.Client_Spend__c;
            System.assertEquals(payment.Checked__c, false);
            System.assertEquals(payment.Synced_with_Xero__c, false);
            payment.Xero_ID__c = '1234567890newXeroId';
        }
        System.assertEquals(clientSpendOnContract, clientSpendsOnPayments);

        Test.startTest();
        update payments;
        Test.stopTest();

        payments = [SELECT Id, Client_Spend__c, Checked__c, Synced_with_Xero__c FROM Sub_Project__c WHERE Id IN :payments];
        for (Sub_Project__c payment :payments) {
            System.assertEquals(payment.Synced_with_Xero__c, true);
        }

        projects = [SELECT Id, Actual_Gross_Profit__c, Actual_Gross_Profit_New__c, Client_Spend__c FROM Payment__c WHERE Project__c = :contract.Id];
        for (Payment__c project :projects) {
            System.assertNotEquals(project.Actual_Gross_Profit__c, projectIdToActualGrossProfit.get(project.Id), 'Actual_Gross_Profit__c should be different.');
            System.assertEquals(project.Actual_Gross_Profit__c, project.Actual_Gross_Profit_New__c);
        }
    }*/

    @IsTest static void metricsUpdatedByChangingProjectCostStructure() {
        Account acc = TestHelper.createAccountByRecType(AccountHandler.RT_ID_BRAND_DIRECT, true);
        User owner = TestHelper.createUser('testopportunitycontacthandler@test.com');
        Brand__c brand = TestHelper.createBrand('MyNewBrand');

        Platform__c platformFB = TestHelper.createPlatform('Facebook', 'FB');
        insert platformFB;

        Opportunity opp = TestHelper.createOpportunity(owner, acc);
        opp.Brand__c = brand.Id;
        insert opp;

        OpportunityPlatform__c oppPlatform = TestHelper.createOpportunityPlatform(opp.Id, platformFB.Id);
        oppPlatform.CostStructure__c = 'CPC; CPE';
        insert oppPlatform;

        System.assert(String.isNotBlank(oppPlatform.CostStructure__c), 'Cost Structure for OppPlatform should be selected.');
        System.assert(String.isBlank(oppPlatform.Cost_Structure_Metrics__c), 'No metric for OppPlatform should be selected');

        Project__c contract = TestHelper.createContractNoInsert(acc.Id, 'Contract', opp.Id);
        contract.Start_Date__c = Date.newInstance(System.today().year(), 3, 1).addYears(1);
        contract.End_Date__c = Date.newInstance(System.today().year(), 4, 30).addYears(1);
        insert contract;

        List<Payment__c> projects = [SELECT Id, Name, OpportunityPlatform__c, CostStructure__c, Metric__c FROM Payment__c WHERE Project__c = :contract.Id];
        for (Payment__c project :projects) {
            System.assert(String.isBlank(project.Metric__c), 'No metric should be assigned.');
            System.assert(oppPlatform.CostStructure__c.contains(project.CostStructure__c), 'Project should have one of Cost Structures allowed in OppPlatfrom.');
        }

        System.assert(!Platform.METRICS_MDT.isEmpty(), 'There should be Metrics Meta Data records');
        Test.startTest();

        // avoid null
        oppPlatform.Cost_Structure_Metrics__c = (String.isBlank(oppPlatform.Cost_Structure_Metrics__c)) ? '' : oppPlatform.Cost_Structure_Metrics__c;
        // avoid multiple metrics for one CostStructure Name
        Map<String, String> csNameToMetricName = new Map<String, String>();
        for (Cost_Structure_Metric__mdt metric :Platform.METRICS_MDT) {
            csNameToMetricName.put(metric.Cost_Structure__c, metric.Label);
        }

        for (String csName :csNameToMetricName.keySet()) {
            if (oppPlatform.CostStructure__c.contains(csName)) {
                String metricLabel = csNameToMetricName.get(csName);
                oppPlatform.Cost_Structure_Metrics__c += (String.isBlank(oppPlatform.Cost_Structure_Metrics__c)) ? metricLabel : PlatformWrapper.CC_METRIC_SEPARATOR + metricLabel;
            }
        }
        // update OppPlatforms with selected metrics for specific Cost Structure
        update oppPlatform;

        projects = [SELECT Id, Name, OpportunityPlatform__c, Metric__c, CostStructure__c FROM Payment__c WHERE Project__c = :contract.Id];
        String oneCommonCostStructure = projects[0].CostStructure__c;
        for (Payment__c project :projects) {
            for (String csName :csNameToMetricName.keySet()) {
                if (project.CostStructure__c == csName) {
                    String metricLabel = csNameToMetricName.get(csName);
                    System.assertEquals(project.Metric__c, metricLabel, 'Metric should be assigned correctly.');
                }
            }
            // change project Cost Structure to test the logic
            project.CostStructure__c = oneCommonCostStructure;
        }
        update projects;

        projects = [SELECT Id, Name, OpportunityPlatform__c, Metric__c, CostStructure__c FROM Payment__c WHERE Project__c = :contract.Id];
        String oneCommonMetricToExpect = csNameToMetricName.get(oneCommonCostStructure);
        System.assert(String.isNotBlank(oneCommonMetricToExpect), 'Expected metrics should not be empty or null.');
        for (Payment__c project :projects) {
            System.assertEquals(project.Metric__c, oneCommonMetricToExpect, 'Metric should be changed.');
        }
    }

    @IsTest static void metricsPopulatedOnProjectInsert() {
        Account acc = TestHelper.createAccountByRecType(AccountHandler.RT_ID_BRAND_DIRECT, true);
        User owner = TestHelper.createUser('testopportunitycontacthandler@test.com');
        Brand__c brand = TestHelper.createBrand('MyNewBrand');

        Platform__c platformTV = TestHelper.createPlatform('TrueView', 'TV');
        upsert platformTV;

        Opportunity opp = TestHelper.createOpportunity(owner, acc);
        opp.Brand__c = brand.Id;
        insert opp;

        System.assert(!Platform.METRICS_MDT.isEmpty(), 'There should be Metrics Meta Data records');

        OpportunityPlatform__c oppPlatform = TestHelper.createOpportunityPlatform(opp.Id, platformTV.Id);
        for (Cost_Structure_Metric__mdt metric :Platform.METRICS_MDT) {
            if (oppPlatform.CostStructure__c == metric.Cost_Structure__c) {
                oppPlatform.Cost_Structure_Metrics__c = metric.Label;
            }
        }
        insert oppPlatform;
        System.assert(String.isNotBlank(oppPlatform.CostStructure__c), 'Cost Structure for OppPlatform should be selected.');
        System.assert(String.isNotBlank(oppPlatform.Cost_Structure_Metrics__c), 'No metric for OppPlatform should be selected');


        Test.startTest();
        Project__c contract = TestHelper.createContractNoInsert(acc.Id, 'Contract', opp.Id);
        contract.Start_Date__c = Date.newInstance(System.today().year(), 3, 1).addYears(1);
        contract.End_Date__c = Date.newInstance(System.today().year(), 4, 30).addYears(1);
        insert contract;

        List<Payment__c> projects = [SELECT Id, Name, OpportunityPlatform__c, CostStructure__c, Metric__c FROM Payment__c WHERE Project__c = :contract.Id];
        for (Payment__c project :projects) {
            System.assertEquals(project.Metric__c, oppPlatform.Cost_Structure_Metrics__c, 'Metric value should be copied to Project on record Insert.');
            System.assertEquals(project.CostStructure__c, oppPlatform.CostStructure__c, 'Cost Structure for Project and OppPlatform should be the same.');
        }
    }

    @IsTest static void metricsAndCostStructureUpdatedByChangingOppPlatformCostStructure_Test1() {
        List<Cost_Structure_Metric__mdt> metricsMDT = Platform.METRICS_MDT;
        System.assert(!metricsMDT.isEmpty(), 'Records should exist');

        Account acc = TestHelper.createAccountByRecType(AccountHandler.RT_ID_BRAND_DIRECT, true);
        User owner = TestHelper.createUser('testopportunitycontacthandler@test.com');
        Brand__c brand = TestHelper.createBrand('MyNewBrand');

        Platform__c platformFB = TestHelper.createPlatform('Facebook', 'FB');
        insert platformFB;

        Opportunity opp = TestHelper.createOpportunity(owner, acc);
        opp.Brand__c = brand.Id;
        insert opp;

        OpportunityPlatform__c oppPlatform = TestHelper.createOpportunityPlatform(opp.Id, platformFB.Id);
        oppPlatform.CostStructure__c = 'CPC;CPV';
        oppPlatform.CPV__c = 0.78;
        oppPlatform.CPC__c = 0.88;
        oppPlatform.VariableCPV__c = true;
        oppPlatform.VariableCPC__c = false;

        Map<String, String> costStructureToMetrics = new Map<String, String>();
        for (String costStructure :oppPlatform.CostStructure__c.split(';')) {
            for (Cost_Structure_Metric__mdt csMetric :metricsMDT) {
                if (costStructure == csMetric.Cost_Structure__c) {
                    costStructureToMetrics.put(csMetric.Cost_Structure__c,csMetric.Label);
                    break;
                }
            }
        }
        oppPlatform.Cost_Structure_Metrics__c = String.join(costStructureToMetrics.values(), ';');
        insert oppPlatform;

        System.assert(String.isNotBlank(oppPlatform.CostStructure__c), 'Cost Structure for OppPlatform should be selected');
        System.assert(String.isNotBlank(oppPlatform.Cost_Structure_Metrics__c), 'Some metric for OppPlatform should be assigned');


        Project__c contract = TestHelper.createContractNoInsert(acc.Id, 'Contract', opp.Id);
        contract.Start_Date__c = Date.newInstance(System.today().year(), 3, 1).addYears(1);
        contract.End_Date__c = Date.newInstance(System.today().year(), 4, 30).addYears(1);
        insert contract;

        List<Payment__c> projects = [SELECT Id, Name, OpportunityPlatform__c, CostStructure__c, Metric__c FROM Payment__c WHERE Project__c = :contract.Id];
        for (Payment__c project :projects) {
            System.assert(oppPlatform.CostStructure__c.contains(project.CostStructure__c), 'Project should have one of Cost Structures allowed in OppPlatfrom');
            System.assertEquals(project.Metric__c, costStructureToMetrics.get(project.CostStructure__c), 'Metric should be assigned');
        }

        Test.startTest();
        // change Cost Structure on Platform tab
        oppPlatform.CostStructure__c = 'CPE';
        oppPlatform.CPV__c = 0;
        oppPlatform.CPC__c = 0;
        oppPlatform.CPE__c = 0.05;
        oppPlatform.VariableCPV__c = false;
        oppPlatform.VariableCPC__c = false;
        oppPlatform.VariableCPE__c = true;

        List<String> costStructureToMetricsForCPE = new List<String>();
        for (String costStructure :oppPlatform.CostStructure__c.split(';')) {
            for (Cost_Structure_Metric__mdt csMetric :metricsMDT) {
                if (costStructure == csMetric.Cost_Structure__c) {
                    costStructureToMetricsForCPE.add(csMetric.Label);
                }
            }
        }
        if (costStructureToMetricsForCPE.size() > 1) {
            oppPlatform.Cost_Structure_Metrics__c = costStructureToMetricsForCPE[1];
        } else {
            oppPlatform.Cost_Structure_Metrics__c = costStructureToMetricsForCPE[0];
        }
        update oppPlatform;
        Test.stopTest();

        projects = [SELECT Id, Name, OpportunityPlatform__c, Metric__c, CostStructure__c, UnitCost__c FROM Payment__c WHERE Project__c = :contract.Id];
        for (Payment__c project :projects) {
            System.assertEquals(project.Metric__c, oppPlatform.Cost_Structure_Metrics__c, 'Metric should be changed.');
            System.assertEquals(project.CostStructure__c, oppPlatform.CostStructure__c, 'Cost Structure should be changed.');
            System.assertEquals(project.UnitCost__c, oppPlatform.CPE__c, 'Unit Cost should be changed.');
        }
    }

    @IsTest static void metricsAndCostStructureUpdatedByChangingOppPlatformCostStructure_Test2() {
        List<Cost_Structure_Metric__mdt> metricsMDT = Platform.METRICS_MDT;
        System.assert(!metricsMDT.isEmpty(), 'Records should exist');

        Account acc = TestHelper.createAccountByRecType(AccountHandler.RT_ID_BRAND_DIRECT, true);
        User owner = TestHelper.createUser('testopportunitycontacthandler@test.com');
        Brand__c brand = TestHelper.createBrand('MyNewBrand');

        Platform__c platformFB = TestHelper.createPlatform('Facebook', 'FB');
        insert platformFB;

        Opportunity opp = TestHelper.createOpportunity(owner, acc);
        opp.Brand__c = brand.Id;
        insert opp;

        OpportunityPlatform__c oppPlatform = TestHelper.createOpportunityPlatform(opp.Id, platformFB.Id);
        oppPlatform.CostStructure__c = 'CPC';
        oppPlatform.CPC__c = 0.88;
        oppPlatform.VariableCPC__c = false;

        Map<String, String> costStructureToMetrics = new Map<String, String>();
        for (String costStructure :oppPlatform.CostStructure__c.split(';')) {
            for (Cost_Structure_Metric__mdt csMetric :metricsMDT) {
                if (costStructure == csMetric.Cost_Structure__c) {
                    costStructureToMetrics.put(csMetric.Cost_Structure__c,csMetric.Label);
                    break;
                }
            }
        }
        oppPlatform.Cost_Structure_Metrics__c = String.join(costStructureToMetrics.values(), ';');
        insert oppPlatform;

        System.assert(String.isNotBlank(oppPlatform.CostStructure__c), 'Cost Structure for OppPlatform should be selected');
        System.assert(String.isNotBlank(oppPlatform.Cost_Structure_Metrics__c), 'Some metric for OppPlatform should be assigned');


        Project__c contract = TestHelper.createContractNoInsert(acc.Id, 'Contract', opp.Id);
        contract.Start_Date__c = Date.newInstance(System.today().year(), 3, 1).addYears(1);
        contract.End_Date__c = Date.newInstance(System.today().year(), 4, 30).addYears(1);
        insert contract;

        List<Payment__c> projects = [SELECT Id, Name, OpportunityPlatform__c, CostStructure__c, Metric__c FROM Payment__c WHERE Project__c = :contract.Id];
        for (Payment__c project :projects) {
            System.assert(oppPlatform.CostStructure__c.contains(project.CostStructure__c), 'Project should have one of Cost Structures allowed in OppPlatfrom');
            System.assertEquals(project.Metric__c, costStructureToMetrics.get(project.CostStructure__c), 'Metric should be assigned');
        }

        Test.startTest();
        // change Cost Structure on Platform tab
        oppPlatform.CostStructure__c = 'CPE;CPV';
        oppPlatform.CPC__c = 0;
        oppPlatform.CPV__c = 0.04;
        oppPlatform.CPE__c = 0.05;
        oppPlatform.VariableCPV__c = false;
        oppPlatform.VariableCPC__c = false;
        oppPlatform.VariableCPE__c = true;

        costStructureToMetrics = new Map<String, String>();
        for (String costStructure :oppPlatform.CostStructure__c.split(';')) {
            for (Cost_Structure_Metric__mdt csMetric :metricsMDT) {
                if (costStructure == csMetric.Cost_Structure__c) {
                    costStructureToMetrics.put(csMetric.Cost_Structure__c,csMetric.Label);
                    break;
                }
            }
        }
        oppPlatform.Cost_Structure_Metrics__c = String.join(costStructureToMetrics.values(), ';');
        update oppPlatform;
        Test.stopTest();
        System.debug('### Metrics: ' + oppPlatform.Cost_Structure_Metrics__c);

        projects = [SELECT Id, Name, OpportunityPlatform__c, Metric__c, CostStructure__c, UnitCost__c FROM Payment__c WHERE Project__c = :contract.Id];
        for (Payment__c project :projects) {
            System.assert(oppPlatform.Cost_Structure_Metrics__c.contains(project.Metric__c), 'Metrics should be changed');
            System.assert(oppPlatform.CostStructure__c.contains(project.CostStructure__c), 'Cost Structure should be changed');
            if (project.CostStructure__c == 'CPE') {
                System.assertEquals(project.UnitCost__c, oppPlatform.CPE__c, 'Unit Cost should be changed');
            } else if (project.CostStructure__c == 'CPV') {
                System.assertEquals(project.UnitCost__c, oppPlatform.CPV__c, 'Unit Cost should be changed');
            }
        }
    }
}