@IsTest
private class OpportunityPlatformHandlerTest {

    @IsTest static void willAssignToContractOnInsertWhenOpportunityDefined() {
        User usr = TestHelper.createUser();
        Account acc = TestHelper.createAccount();
        
        Opportunity opp = TestHelper.createOpportunity(usr, acc);        
        insert opp;
        
        Project__c contract = TestHelper.createContract(acc.Id, 'testContract', opp.Id);
        Test.startTest();
        Platform__c platform = TestHelper.createPlatform('TrueView', 'TV');

        OpportunityPlatform__c oppPlatform = TestHelper.createOpportunityPlatform(opp.Id, platform.Id);
        insert oppPlatform;
        Test.stopTest();
        System.assertEquals(contract.Id, [SELECT Contract__c FROM OpportunityPlatform__c WHERE Id = :oppPlatform.Id].Contract__c);
    }

    @IsTest static void willAssignToOpportunityOnInsertWhenContractDefined() {
        User usr = TestHelper.createUser();
        Account acc = TestHelper.createAccount();
        
        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        insert opp;
        
        Project__c contract = TestHelper.createContract(acc.Id, 'testContract', opp.Id);
        Test.startTest();
        Platform__c platform = TestHelper.createPlatform('TrueView', 'TV');

        OpportunityPlatform__c oppPlatform = TestHelper.createOpportunityPlatform(null, platform.Id);
        oppPlatform.Contract__c = contract.Id;
        insert oppPlatform;
        Test.stopTest();
        System.assertEquals(opp.Id, [SELECT Opportunity__c FROM OpportunityPlatform__c WHERE Id = :oppPlatform.Id].Opportunity__c);
    }

    @IsTest static void willUpdateProjectUnitCostWhenContractPlatformUnitCostUpdated() {
        User usr = TestHelper.createUser();
        Account acc = TestHelper.createAccount();
    
        Opportunity opp = TestHelper.createOpportunity(usr, acc);        
        insert opp;
        
        Platform__c platformTV = TestHelper.getTrueViewPlatform();
        Platform__c platformFB = TestHelper.getFacebookPlatform();

        OpportunityPlatform__c oppPlatformTV = TestHelper.createOpportunityPlatform(opp.Id, platformTV.Id);
        oppPlatformTV.CostStructure__c = 'CPV';
        oppPlatformTV.CPV__c = 0.6;
        insert oppPlatformTV;  
        
        OpportunityPlatform__c oppPlatformFB = TestHelper.createOpportunityPlatform(opp.Id, platformFB.Id);
        oppPlatformFB.CostStructure__c = 'CPC';
        oppPlatformFB.CPC__c = 0.8;
        oppPlatformFB.VariableCPC__c = true;
        insert oppPlatformFB;  
        
        opp.Brand__c = TestHelper.createBrand('testBrand').Id;
        opp.StageName = 'Closed Won';
        update opp;
        
        Project__c contract = [SELECT Id FROM Project__c WHERE Opportunity__c = :opp.Id];
        Test.startTest();
        List<Payment__c> projectsTV = [SELECT Id, UnitCost__c FROM Payment__c WHERE PlatformPrefix__c = 'TV' AND Project__c = :contract.Id];
        List<Payment__c> projectsFB = [SELECT Id, CostStructure__c, UnitCost__c FROM Payment__c WHERE PlatformPrefix__c = 'FB' AND Project__c = :contract.Id ORDER BY CostStructure__c];

        System.assert(!projectsTV.isEmpty());
        System.assertEquals(1, projectsFB.size());

        Payment__c projectTV = projectsTV[0];
        Payment__c projectFB_CPC = projectsFB[0];

        oppPlatformTV.CPV__c = projectTV.UnitCost__c + 0.1;
        oppPlatformFB.CPC__c = projectFB_CPC.UnitCost__c + 0.3;

        update new List<OpportunityPlatform__c> { oppPlatformTV, oppPlatformFB };
        Test.stopTest();

        System.assertEquals(oppPlatformTV.CPV__c, [SELECT UnitCost__c FROM Payment__c WHERE Id = :projectTV.Id].UnitCost__c);
    }

    @IsTest static void updateContract() {
        User usr = TestHelper.createUser();
        Account acc = TestHelper.createAccount();
    
        Opportunity opp = TestHelper.createOpportunity(usr, acc);        
        insert opp;
        
        Platform__c platformTV = TestHelper.getTrueViewPlatform();
        Platform__c platformFB = TestHelper.getFacebookPlatform();

        OpportunityPlatform__c oppPlatformTV = TestHelper.createOpportunityPlatform(opp.Id, platformTV.Id);
        oppPlatformTV.CostStructure__c = 'CPV';
        oppPlatformTV.CPV__c = 0.6;

        Test.startTest();
        insert oppPlatformTV;

        opp.Brand__c = TestHelper.createBrand('testBrand').Id;
        opp.StageName = 'Closed Won';
        update opp;

        Project__c contract = [SELECT Id, Platforms__c FROM Project__c WHERE Opportunity__c = :opp.Id];

        System.assertEquals ('TrueView', [SELECT Platforms__c FROM Opportunity WHERE Id = :opp.Id].Platforms__c);
        OpportunityPlatform__c oppPlatformFB = TestHelper.createOpportunityPlatform(opp.Id, platformFB.Id);
        oppPlatformFB.CostStructure__c = 'CPC';
        oppPlatformFB.CPC__c = 0.8;
        oppPlatformFB.VariableCPC__c = true;
        OpportunityPlatformHandler.run = true;
        insert oppPlatformFB;
        Test.stopTest();

        System.assertEquals ('Facebook; TrueView', [SELECT Platforms__c FROM Opportunity WHERE Id = :opp.Id].Platforms__c);
        System.assertEquals ('Facebook; TrueView', [SELECT Platforms__c FROM Project__c WHERE Id = :contract.Id].Platforms__c);
    }

    @IsTest static void willAssignSalesforceId() {
        User usr = TestHelper.createUser();
        Account acc = TestHelper.createAccount();
    
        Opportunity opp = TestHelper.createOpportunity(usr, acc);        
        insert opp;
        
        Platform__c platformTV = TestHelper.getTrueViewPlatform();
        OpportunityPlatform__c oppPlatformTV = TestHelper.createOpportunityPlatform(opp.Id, platformTV.Id);
        oppPlatformTV.CostStructure__c = 'CPV';
        oppPlatformTV.CPV__c = 0.6;
        
        Test.startTest();
            insert oppPlatformTV;
        Test.stopTest();
 		System.assert(String.isBlank(oppPlatformTV.Salesforce_ID__c));
        
        oppPlatformTV = [SELECT Id, Salesforce_ID__c FROM OpportunityPlatform__c WHERE Id = :oppPlatformTV.Id];
        System.assert(!String.isBlank(oppPlatformTV.Salesforce_ID__c));
        System.assertEquals(oppPlatformTV.Id, oppPlatformTV.Salesforce_ID__c);
    }

    @IsTest static void attemptToDeleteOpportunityPlatform() {
        User usr = TestHelper.createUser();
        Account acc = TestHelper.createAccount();

        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        insert opp;

        Platform__c platformTV = TestHelper.getTrueViewPlatform();
        Platform__c platformFB = TestHelper.getFacebookPlatform();

        OpportunityPlatform__c oppPlatformTV = TestHelper.createOpportunityPlatform(opp.Id, platformTV.Id);
        oppPlatformTV.CostStructure__c = 'CPV';
        oppPlatformTV.CPV__c = 0.6;

        Test.startTest();
        // EXPECTING an Exception
        insert oppPlatformTV;
        oppPlatformTV  = [SELECT Id, Name FROM OpportunityPlatform__c WHERE Id = :oppPlatformTV.Id];

        opp.Brand__c = TestHelper.createBrand('testBrand').Id;
        opp.StageName = 'Closed Won';
        update opp;

        Project__c contract = [SELECT Id, (SELECT Id, Name, OpportunityPlatform__c FROM Payments__r) FROM Project__c WHERE Opportunity__c = :opp.Id];
        String projectName = '';
        System.assertEquals(1, contract.Payments__r.size(), 'There should be one project.');
        for (Payment__c project :contract.Payments__r) {
            System.assertEquals(project.OpportunityPlatform__c, oppPlatformTV.Id, 'Platform should be linked to Project.');
            projectName = project.Name;
        }

        Boolean isExceptionOccurred = false;
        try {
            delete oppPlatformTV;
        } catch (System.DmlException ex) {
            isExceptionOccurred = true;
            String error = ex.getMessage();
            String expectedError = String.format(OpportunityPlatformHandler.EX_PLATFORM_USED_PATTERN, new List<String>{oppPlatformTV.Name, projectName});
            System.assert(error.containsIgnoreCase(expectedError));
        }
        System.assertEquals(isExceptionOccurred, true);

        // EXPECTING no Exception
        OpportunityPlatform__c oppPlatformFB = TestHelper.createOpportunityPlatform(opp.Id, platformFB.Id);
        oppPlatformTV.CostStructure__c = 'CPV';
        oppPlatformTV.CPV__c = 0.8;
        insert oppPlatformFB;

        delete oppPlatformFB;

        List<OpportunityPlatform__c> deletedOppPlatformFB = [SELECT Id FROM OpportunityPlatform__c WHERE Id = :platformFB.Id];
        System.assertEquals(deletedOppPlatformFB.size(), 0, 'Platform should be deleted successfully.');
        Test.stopTest();
    }

    @IsTest static void metricsUpdatesByChangingOppPlatformCostStructureMetrics() {
        Account acc = TestHelper.createAccountByRecType(AccountHandler.RT_ID_BRAND_DIRECT, true);
        User owner = TestHelper.createUser('testopportunitycontacthandler@test.com');
        Brand__c brand = TestHelper.createBrand('MyNewBrand');

        Platform__c platformTV = TestHelper.createPlatform('TrueView', 'TV');
        upsert platformTV;

        Opportunity opp = TestHelper.createOpportunity(owner, acc);
        opp.Brand__c = brand.Id;
        insert opp;

        OpportunityPlatform__c oppPlatform = TestHelper.createOpportunityPlatform(opp.Id, platformTV.Id);
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
            System.assertEquals(project.CostStructure__c, oppPlatform.CostStructure__c, 'Cost Structure for Project and OppPlatform should be the same.');
        }

        System.assert(!Platform.METRICS_MDT.isEmpty(), 'There should be Metrics Meta Data records');
        Test.startTest();
        for (Cost_Structure_Metric__mdt metric :Platform.METRICS_MDT) {
            if (oppPlatform.CostStructure__c == metric.Cost_Structure__c) {
                oppPlatform.Cost_Structure_Metrics__c = metric.Label;
            }
        }
        update oppPlatform;

        Test.stopTest();
        projects = [SELECT Id, Name, OpportunityPlatform__c, Metric__c FROM Payment__c WHERE Project__c = :contract.Id];
        for (Payment__c project :projects) {
            System.assertEquals(project.Metric__c, oppPlatform.Cost_Structure_Metrics__c, 'Metric value should be copied to Project record.');
        }
    }

    @IsTest static void selectingNoCostStructure() {
        Account acc = TestHelper.createAccountByRecType(AccountHandler.RT_ID_BRAND_DIRECT, true);
        User owner = TestHelper.createUser('testopportunitycontacthandler@test.com');
        Brand__c brand = TestHelper.createBrand('MyNewBrand');

        Platform__c platformTV = TestHelper.createPlatform('TrueView', 'TV');
        upsert platformTV;

        Opportunity opp = TestHelper.createOpportunity(owner, acc);
        opp.Brand__c = brand.Id;
        insert opp;

        OpportunityPlatform__c oppPlatform = TestHelper.createOpportunityPlatform(opp.Id, platformTV.Id);
        insert oppPlatform;
        System.assert(String.isNotBlank(oppPlatform.CostStructure__c), 'Cost Structure for OppPlatform should be selected.');
        System.assert(oppPlatform.CPV__c != null, 'CPV for OppPlatform should be set.');

        Test.startTest();
        oppPlatform.NoCostStructure__c = true;
        update oppPlatform;
        Test.stopTest();

        oppPlatform = [SELECT CostStructure__c, NoCostStructure__c, CPV__c FROM OpportunityPlatform__c WHERE Id = :oppPlatform.Id];
        System.assert(String.isBlank(oppPlatform.CostStructure__c));
        System.assert(oppPlatform.NoCostStructure__c == true);
        System.assert(oppPlatform.CPV__c == null);
    }

    @IsTest static void changePlatformToCheckCostStructureOnProject() {
        User usr = TestHelper.createUser();
        Account acc = TestHelper.createAccount();

        Platform__c platformFB = TestHelper.createFacebookPlatform(), platformTV = TestHelper.createTrueViewPlatform();
        insert new List<Platform__c>{platformTV, platformFB};

        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        insert opp;

        OpportunityPlatform__c oppPlatformTV = TestHelper.createOpportunityPlatform(opp.Id, platformTV.Id);
        oppPlatformTV.CostStructure__c = 'CPV';
        oppPlatformTV.CPV__c = 0.6;
        insert oppPlatformTV;

        // Create Contract by closing Opportunity
        opp.Brand__c = TestHelper.createBrand('testBrand').Id;
        opp.StageName = 'Closed Won';
        update opp;

        Project__c contract = [SELECT Id FROM Project__c WHERE Opportunity__c = :opp.Id];
        Test.startTest();
        List<Payment__c> projects = [SELECT Id, CostStructure__c, OpportunityPlatform__c FROM Payment__c WHERE Project__c = :contract.Id];
        System.assertEquals(projects.isEmpty(), false);
        for (Payment__c project :projects) {
            System.assertEquals(project.CostStructure__c, oppPlatformTV.CostStructure__c);
        }

        OpportunityPlatform__c oppPlatformFB = TestHelper.createOpportunityPlatform(opp.Id, platformFB.Id);
        oppPlatformFB.CostStructure__c = 'CPV';
        oppPlatformFB.CPV__c = 0.8;
        oppPlatformFB.VariableCPV__c = false;
        insert oppPlatformFB;

        // change Id to be able to delete oppPlatformTV
        for (Payment__c project :projects) {
            project.OpportunityPlatform__c = oppPlatformFB.Id;
        }
        update projects;

        // to fire OpportunityPlatformHandler trigger handler
        update oppPlatformFB;

        delete oppPlatformTV;

        projects = [SELECT Id, CostStructure__c, UnitCost__c, Name FROM Payment__c WHERE Project__c = :contract.Id];
        System.assertEquals(projects.isEmpty(), false);
        for (Payment__c project :projects) {
            System.assertEquals(project.CostStructure__c, oppPlatformFB.CostStructure__c);
            System.assertEquals(project.UnitCost__c, oppPlatformFB.CPV__c);
        }
        Test.stopTest();
    }


    @IsTest static void changeCCsOnPlatformToCheckCostStructureOnProject() {
        User usr = TestHelper.createUser();
        Account acc = TestHelper.createAccount();

        Platform__c platformFB = TestHelper.createFacebookPlatform(), platformTV = TestHelper.createTrueViewPlatform();
        insert new List<Platform__c>{platformTV, platformFB};

        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        insert opp;

        OpportunityPlatform__c oppPlatformFB = TestHelper.createOpportunityPlatform(opp.Id, platformFB.Id);
        oppPlatformFB.CostStructure__c = 'CPV';
        oppPlatformFB.CPV__c = 0.8;
        oppPlatformFB.VariableCPV__c = false;
        insert oppPlatformFB;

        // Create Contract by closing Opportunity
        opp.Brand__c = TestHelper.createBrand('testBrand').Id;
        opp.StageName = 'Closed Won';
        update opp;

        Project__c contract = [SELECT Id FROM Project__c WHERE Opportunity__c = :opp.Id];
        Test.startTest();
        List<Payment__c> projects = [SELECT Id, CostStructure__c, OpportunityPlatform__c FROM Payment__c WHERE Project__c = :contract.Id];
        System.assertEquals(projects.isEmpty(), false);
        for (Payment__c project :projects) {
            System.assertEquals(project.CostStructure__c, oppPlatformFB.CostStructure__c);
        }

        // adding two new CCs
        oppPlatformFB.CostStructure__c = 'CPC;CPM';
        oppPlatformFB.CPV__c = 0;
        oppPlatformFB.VariableCPV__c = false;
        oppPlatformFB.CPC__c = 0.4;
        oppPlatformFB.CPM__c = 0.5;
        update oppPlatformFB;

        projects = [SELECT Id, CostStructure__c, UnitCost__c FROM Payment__c WHERE Project__c = :contract.Id];
        System.assertEquals(projects.isEmpty(), false);
        for (Payment__c project :projects) {
            System.assertEquals(oppPlatformFB.CostStructure__c.split(';')[0], project.CostStructure__c /*, 'Should be equal to the first in the list of CCs. First one is CPC'*/);
            System.assertEquals(project.UnitCost__c, oppPlatformFB.CPC__c);
        }

        Test.stopTest();
    }

    @IsTest static void changeCCOnPlatformToCheckCostStructureOnProject() {
        User usr = TestHelper.createUser();
        Account acc = TestHelper.createAccount();

        Platform__c platformFB = TestHelper.createFacebookPlatform(), platformTV = TestHelper.createTrueViewPlatform();
        insert new List<Platform__c>{platformTV, platformFB};

        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        insert opp;

        OpportunityPlatform__c oppPlatformFB = TestHelper.createOpportunityPlatform(opp.Id, platformFB.Id);
        oppPlatformFB.CostStructure__c = 'CPV';
        oppPlatformFB.CPV__c = 0.8;
        oppPlatformFB.VariableCPV__c = false;
        insert oppPlatformFB;

        // Create Contract by closing Opportunity
        opp.Brand__c = TestHelper.createBrand('testBrand').Id;
        opp.StageName = 'Closed Won';
        update opp;

        Project__c contract = [SELECT Id FROM Project__c WHERE Opportunity__c = :opp.Id];
        Test.startTest();
        List<Payment__c> projects = [SELECT Id, CostStructure__c, OpportunityPlatform__c FROM Payment__c WHERE Project__c = :contract.Id];
        System.assertEquals(projects.isEmpty(), false);
        for (Payment__c project :projects) {
            System.assertEquals(project.CostStructure__c, oppPlatformFB.CostStructure__c);
        }

        // adding new CC
        String initialCC = oppPlatformFB.CostStructure__c;
        oppPlatformFB.CostStructure__c = 'CPC;CPV;CPM';
        oppPlatformFB.CPC__c = 0.4;
        oppPlatformFB.CPM__c = 0.5;
        update oppPlatformFB;

        projects = [SELECT Id, CostStructure__c, UnitCost__c FROM Payment__c WHERE Project__c = :contract.Id];
        System.assertEquals(projects.isEmpty(), false);
        for (Payment__c project :projects) {
            System.assertEquals(project.CostStructure__c, initialCC);
            System.assertEquals(project.UnitCost__c, oppPlatformFB.CPV__c);
        }

        Test.stopTest();
    }
}