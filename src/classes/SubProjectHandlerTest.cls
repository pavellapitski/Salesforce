@IsTest
global class SubProjectHandlerTest {

    private static OpportunityPlatform__c oppPlatform;
    private static Date today = System.today();

    private static Payment__c getProjectByPaymentId(Id paymentId) {
        return PaymentRepository.getPaymentsBySubProjectIDs(new Set<Id>{paymentId})[0];
    }

    private static Sub_Project__c getPaymentByContractId(Id contractId) {
        return SubProjectRepository.getPaymentsByContractId(contractId)[0];
    }
    
    private static List<Sub_Project__c> getPaymentsByContractId(Id contractId) {
        return SubProjectRepository.getPaymentsByContractId(contractId);
    }


    @IsTest static void testCannotDeletePaymentInsideContract() {
        Project__c contract = TestHelper.createContractNoInsert(TestHelper.createAccount().Id, 'testContract', null);
        contract.Start_Date__c = today.addDays(-10);
        contract.End_Date__c = today.addDays(10);
        contract.Gaps_Exist_Between_Projects__c = true;
        insert contract;

        delete getPaymentsByContractId(contract.Id);
        System.assertEquals(0, [SELECT Id FROM Sub_Project__c WHERE Project__c = :contract.Id].size());

        Test.startTest();
        Sub_Project__c paymentInsideContract = TestHelper.createPaymentNoInsert(contract);
        insert paymentInsideContract;

        Boolean cannotRemovePaymentInsideContract = false;
        contract.Gaps_Exist_Between_Projects__c = false;
        update contract;
        try {
            delete paymentInsideContract;
        } catch (Exception ex) {
            if (ex.getMessage().contains(Label.PaymentCannotBeRemoved)) {
                cannotRemovePaymentInsideContract = true;
            }
        }
        Test.stopTest();
        System.assert(cannotRemovePaymentInsideContract);
    }

    @IsTest static void testCanDeletePaymentInsideContractWhenGapsAllowed() {
        Project__c contract = TestHelper.createContractNoInsert(TestHelper.createAccount().Id, 'testContract', null);
        contract.Start_Date__c = today.addDays(-10);
        contract.End_Date__c = today.addDays(10);
        contract.Gaps_Exist_Between_Projects__c = true;
        insert contract;

        delete getPaymentsByContractId(contract.Id);
        System.assertEquals(0, [SELECT Id FROM Sub_Project__c WHERE Project__c = :contract.Id].size());

        Test.startTest();
        Sub_Project__c paymentInsideContract = TestHelper.createPaymentNoInsert(contract);
        insert paymentInsideContract;

        Boolean noException = true;
        delete paymentInsideContract;
        Test.stopTest();
        System.assert(noException);
    }

    @IsTest static void willUpdateProjectDatesWhenPaymentIsUpdated() {
        Project__c contract = TestHelper.createContract(false);
        contract.Gaps_Exist_Between_Projects__c = true;
        contract.Start_Date__c = Date.newInstance(today.year(), 3, 1);
        contract.End_Date__c = contract.Start_Date__c.addMonths(2);
        contract.Client_Spend__c = 200;
        insert contract;

        delete [SELECT Id FROM Sub_Project__c];

        Sub_Project__c payment1 = TestHelper.createPayment(contract, false);
        payment1.End_Date__c = contract.Start_Date__c.addMonths(1);
        payment1.Client_Spend__c = 100;

        Sub_Project__c payment2 = TestHelper.createPayment(contract, false);
        payment2.Start_Date__c = payment1.End_Date__c.addDays(1);
        payment2.Client_Spend__c = 100;

        Test.startTest();
        insert new List<Sub_Project__c> {payment1, payment2};

        Payment__c project1Payment1 = getProjectByPaymentId(payment1.Id);
        project1Payment1.Client_Spend__c = 25;

        Payment__c project2Payment1 = TestHelper.createProjectBasedOnPayment(contract, payment1,false);
        project2Payment1.Client_Spend__c = 25;

        Payment__c project3Payment1 = TestHelper.createProjectBasedOnPayment(contract, payment1,false);
        project3Payment1.Client_Spend__c = 25;
        project3Payment1.Start_Date__c = contract.Start_Date__c.addDays(5);

        Payment__c project4Payment1 = TestHelper.createProjectBasedOnPayment(contract, payment1,false);
        project4Payment1.Client_Spend__c = 25;
        project4Payment1.Start_Date__c = contract.Start_Date__c.addDays(2);

        Payment__c project1Payment2 = getProjectByPaymentId(payment2.Id);
        project1Payment2.Client_Spend__c = 25;

        Payment__c project2Payment2 = TestHelper.createProjectBasedOnPayment(contract, payment2,false);
        project2Payment2.Client_Spend__c = 25;

        Payment__c project3Payment2 = TestHelper.createProjectBasedOnPayment(contract, payment2,false);
        project3Payment2.Client_Spend__c = 25;
        project3Payment2.End_Date__c = contract.End_Date__c.addDays(-6);

        Payment__c project4Payment2 = TestHelper.createProjectBasedOnPayment(contract, payment2,false);
        project4Payment2.Client_Spend__c = 25;
        project4Payment2.End_Date__c = contract.End_Date__c.addDays(-3);

        PaymentHandler.skipUpdateValidation = true;
        update new List<Payment__c> {project1Payment1, project1Payment2};

        PaymentHandler.skipUpdateValidation = false;
        insert new List<Payment__c> {project2Payment1, project3Payment1, project2Payment2, project3Payment2, project4Payment1, project4Payment2 };

        contract.Start_Date__c = contract.Start_Date__c.addDays(3);
        contract.End_Date__c = contract.End_Date__c.addDays(-4);
        update contract;

        //Both start dates are equal to contract start date, so are updated
        System.assertEquals(contract.Start_Date__c, [SELECT Start_Date__c FROM Payment__c WHERE Id = :project1Payment1.Id].Start_Date__c);
        System.assertEquals(contract.Start_Date__c, [SELECT Start_Date__c FROM Payment__c WHERE Id = :project2Payment1.Id].Start_Date__c);
        //Both end dates are equal to contract end date, so are updated
        System.assertEquals(contract.End_Date__c, [SELECT End_Date__c FROM Payment__c WHERE Id = :project1Payment2.Id].End_Date__c);
        System.assertEquals(contract.End_Date__c, [SELECT End_Date__c FROM Payment__c WHERE Id = :project2Payment2.Id].End_Date__c);

        //Not updated, no need since start date was initially bigger than new contract start date, similar with end date
        System.assertEquals(project3Payment1.Start_Date__c, [SELECT Start_Date__c FROM Payment__c WHERE Id = :project3Payment1.Id].Start_Date__c);
        System.assertEquals(project3Payment2.End_Date__c, [SELECT End_Date__c FROM Payment__c WHERE Id = :project3Payment2.Id].End_Date__c);

        //Updated, because new contract start date is bigger than initial project start date, similar with end date
        System.assertEquals(contract.Start_Date__c, [SELECT Start_Date__c FROM Payment__c WHERE Id = :project4Payment1.Id].Start_Date__c);
        System.assertEquals(contract.End_Date__c, [SELECT End_Date__c FROM Payment__c WHERE Id = :project4Payment2.Id].End_Date__c);

        Test.stopTest();
    }

    @IsTest static void willUpdateProjectClientSpendWhenPaymentIsUpdated() {
        Account acc = TestHelper.createAccount();

        Project__c contract = TestHelper.createContractNoInsert(acc.Id, 'testContract', null);
        contract.Gaps_Exist_Between_Projects__c = true;
        insert contract;

        delete [SELECT Id FROM Sub_Project__c];

        Test.startTest();
        Sub_Project__c payment = TestHelper.createPaymentNoInsert(contract);
        insert payment;

        Payment__c project = getProjectByPaymentId(payment.Id);
        contract.Client_Spend__c = 400;
        update contract;
        Test.stopTest();

        System.assertEquals(contract.Client_Spend__c, [SELECT Client_Spend__c FROM Payment__c WHERE Id = :project.Id].Client_Spend__c);
        System.assertEquals(project.Id, new List<Id> (SubProjectHandler.projectsWithClientSpendUpdated)[0]);
    }

    @IsTest static void errorWhenTryingToEditPaymentClientSpendWhenMultipleProjectsExist() {
        TestHelper.prepareData(false);

        Project__c contract = TestHelper.contractRecord;
        Sub_Project__c payment = getPaymentByContractId(contract.Id);

        Payment__c project = getProjectByPaymentId(payment.Id);
        project.End_Date__c = (payment.End_Date__c).addDays(-10);
        project.Client_Spend__c = payment.Client_Spend__c / 2;

        Payment__c project2 = TestHelper.createProjectBasedOnPayment(contract, payment, false);
        project2.Start_Date__c = (payment.End_Date__c).addDays(-9);
        project2.Client_Spend__c = payment.Client_Spend__c - project.Client_Spend__c;

        Test.startTest();
        PaymentHandler.skipUpdateValidation = true;
        update project;
        PaymentHandler.skipUpdateValidation = false;
        insert project2;

        Boolean cannotEditPaymentClientSpendWhenMultipleProjectsExist = false;
        try {
            payment.Client_Spend__c = 400;
            update payment;
        } catch (Exception ex) {
            if (ex.getMessage().contains(Label.PaymentHasMultipleProjectsCannotEditClientSpend)) {
                cannotEditPaymentClientSpendWhenMultipleProjectsExist = true;
            }
        }
        Test.stopTest();
        System.assert(cannotEditPaymentClientSpendWhenMultipleProjectsExist);
    }

    @IsTest static void validatePaymentDates_StartDate() {
        Project__c contract = TestHelper.createContract(false);
        contract.Gaps_Exist_Between_Projects__c = true;
        contract.Start_Date__c = Date.newInstance(today.year(), 3, 1);
        contract.End_Date__c = contract.Start_Date__c.addMonths(2).addDays(-1);
        contract.Client_Spend__c = 200;
        insert contract;

        delete [SELECT Id FROM Sub_Project__c];

        Sub_Project__c payment1 = TestHelper.createPayment(contract, false);
        payment1.Client_Spend__c = 200;

        Test.startTest();
        insert payment1;

        Boolean invalidStartDate = false;
        try {
            payment1.Start_Date__c = payment1.Start_Date__c.addDays(-10);
            update payment1;
        } catch (Exception ex) {
            if (ex.getMessage().contains(Label.EarliestPaymentStartDateNotEqualContractStartDate)) {
                invalidStartDate = true;
            }
        }
        Test.stopTest();
        System.assert(invalidStartDate);
    }

    @IsTest static void validatePaymentDates_EndDate() {
        Project__c contract = TestHelper.createContract(false);
        contract.Gaps_Exist_Between_Projects__c = true;
        contract.Start_Date__c = Date.newInstance(today.year(), 3, 1);
        contract.End_Date__c = contract.Start_Date__c.addMonths(2).addDays(-1);
        contract.Client_Spend__c = 200;
        insert contract;

        delete [SELECT Id FROM Sub_Project__c];

        Sub_Project__c payment = TestHelper.createPayment(contract, false);
        payment.Client_Spend__c = 200;

        Test.startTest();
        insert payment;

        Boolean invalidEndDate = false;
        try {
            payment.End_Date__c = payment.End_Date__c.addDays(11);
            update payment;
        } catch (Exception ex) {
            if (ex.getMessage().contains(Label.LatestPaymentEndDateNotEqualContractEndDate)) {
                invalidEndDate = true;
            }
        }
        Test.stopTest();
        System.assert(invalidEndDate);
    }

    @IsTest static void validatePaymentClientSpend() {
        Project__c contract = TestHelper.createContract(false);
        contract.Gaps_Exist_Between_Projects__c = true;
        contract.Start_Date__c = Date.newInstance(today.year(), 3, 1);
        contract.End_Date__c = contract.Start_Date__c.addMonths(2).addDays(-1);
        contract.Client_Spend__c = 200;
        insert contract;

        delete [SELECT Id FROM Sub_Project__c];

        Sub_Project__c payment1 = TestHelper.createPayment(contract, false);
        payment1.Client_Spend__c = 200;

        Test.startTest();
        insert payment1;

        Boolean invalidClientSpend = false;
        try {
            payment1.Client_Spend__c = 500;
            update payment1;
        } catch (Exception ex) {
            if (ex.getMessage().contains(Label.SumPaymentClientSpendNotEqualContractClientSpend)) {
                invalidClientSpend = true;
            }
        }
        Test.stopTest();
        System.assert(invalidClientSpend);
    }

    @IsTest static void errorWhenPaymentStartDateBiggerThanFirstProjectEndDate() {
        TestHelper.prepareData(false);

        Project__c contract = TestHelper.contractRecord;
        Sub_Project__c payment = getPaymentByContractId(contract.Id);
        Payment__c project = getProjectByPaymentId(payment.Id);
        project.Client_Spend__c = payment.Client_Spend__c / 2;

        Payment__c project2 = TestHelper.createProjectBasedOnPayment(contract, payment, false);
        project2.End_Date__c = payment.End_Date__c.addDays(-9);
        project2.Client_Spend__c = payment.Client_Spend__c - project.Client_Spend__c;

        Test.startTest();
        PaymentHandler.skipUpdateValidation = true;
        update project;
        PaymentHandler.skipUpdateValidation = false;
        insert project2;

        Boolean paymentStartDateCannotBeBiggerThanFirstProjectEndDate = false;
        try {
          contract.Start_Date__c = payment.End_Date__c.addDays(-8);
          update contract;
        } catch (Exception ex) {
            if (ex.getMessage().contains(Label.PaymentStartDateBiggerThanFirstProjectEndDate)) {
                paymentStartDateCannotBeBiggerThanFirstProjectEndDate = true;
            }
        }
        Test.stopTest();
        System.assert(paymentStartDateCannotBeBiggerThanFirstProjectEndDate);
    }

    @IsTest static void errorWhenPaymentEndDateLowerThanLastProjectStartDate() {
        Project__c contract = TestHelper.createContract(false);
        contract.Gaps_Exist_Between_Projects__c = true;
        contract.Start_Date__c = Date.newInstance(today.year() + 1, 1, 1);
        contract.End_Date__c = Date.newInstance(today.year() + 1, 1, 31);
        contract.Client_Spend__c = 200;
        insert contract;

        Sub_Project__c payment = getPaymentByContractId(contract.Id);
        Payment__c project1 = getProjectByPaymentId(payment.Id);
        project1.Client_Spend__c   = payment.Client_Spend__c / 2;

        Payment__c project2 = TestHelper.createProjectBasedOnPayment(contract, payment, false);
        project2.Start_Date__c = (contract.End_Date__c).addDays(-5);
        project2.End_Date__c = contract.End_Date__c;
        project2.Client_Spend__c = payment.Client_Spend__c - project1.Client_Spend__c;

        Test.startTest();
        PaymentHandler.skipUpdateValidation = true;
        update project1;
        PaymentHandler.skipUpdateValidation = false;
        insert project2;

        Boolean paymentEndDateCannotBeLowerThanLastProjectStartDate = false;
        try {
            contract.End_Date__c = contract.End_Date__c.addDays(-7);
            update contract;
        } catch (Exception ex) {
            if (ex.getMessage().contains(Label.PaymentEndDateLowerThanLastProjectStartDate)) {
                paymentEndDateCannotBeLowerThanLastProjectStartDate = true;
            }
        }
        Test.stopTest();
        System.assert(paymentEndDateCannotBeLowerThanLastProjectStartDate);
    }

    @IsTest static void validateOverlappingPayments() {
        Project__c contract = TestHelper.createContract(false);
        contract.Gaps_Exist_Between_Projects__c = true;
        contract.Start_Date__c = Date.newInstance(today.year(), 3, 1);
        contract.End_Date__c = contract.Start_Date__c.addMonths(2).addDays(-1);
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

        Boolean overlappingPayments = false;
        try {
            payment1.End_Date__c = payment1.End_Date__c.addDays(5);
            update payment1;
        } catch (Exception ex) {
            if (ex.getMessage().contains(Label.PaymentsOverlapping)) {
                overlappingPayments = true;
            }
        }
        Test.stopTest();
        System.assert(overlappingPayments);
    }

    @IsTest static void willRemoveProjectsWhenPaymentIsDeleted() {
        TestHelper.prepareData(false);

        Project__c contract = TestHelper.contractRecord;
        contract.Gaps_Exist_Between_Projects__c = true;
        update contract;

        delete [SELECT Id FROM Sub_Project__c];

        Test.startTest();
        Sub_Project__c payment = TestHelper.createPayment(contract, true);

        Payment__c project = getProjectByPaymentId(payment.Id);
        System.assertNotEquals(null, project);
        delete payment;
        Test.stopTest();

        System.assertEquals(0, [SELECT Id FROM Payment__c WHERE Id = :project.Id].size());
    }

    /*@IsTest static void testInvoiceCalculationCPVScenarioStrike_PercentageOfMedia() {
        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Strike, 'CPV', 'Closed Won', null);

        //'% of Media'
        OpportunityPlatform__c opportunityPlatform = [SELECT CPV__c FROM OpportunityPlatform__c WHERE Opportunity__c = :opp.Id LIMIT 1];
        opportunityPlatform.CPV__c = null;
        update opportunityPlatform;

        Project__c contract = getContractByOppId(opp.Id);
        contract.Margin_Type__c = '% of Media';
        update contract;
        System.debug('### TEST contract: ' + getContractByOppId(opp.Id));

        Payment__c project = contract.Payments__r[0];
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Double amount = 600, views = project.Quantity__c, impressions = 0;

        Test.startTest();
        System.debug('### TEST START: ');
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        System.debug('### TEST END: ');
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        Decimal result = after.AdWordsSpend__c * (1 + payment.Margin__c / 100);
        System.assertEquals((result * 100).round() / 100, (after.Invoice_Amount__c * 100).round() / 100);
    }*/

}