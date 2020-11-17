/**
 * Created by pavel on 2020-07-29.
 */

@IsTest private class GrossProfitCalculationTest {

    private static BillingCondition__c rebateBC { get {
        if (rebateBC == null) {
            rebateBC = TestHelper.createBillingCondition('Rebate 10%/30%', false);
            rebateBC.Rebate_Rate__c = 10.00;
            rebateBC.Default_Margin__c = 30.00;
            rebateBC.Strike_Profit__c = 0;
            rebateBC.Rebate_Type__c = 'Normal';
            insert rebateBC;
        }
        return rebateBC;
    } set; }

    private static BillingCondition__c instantRebateBC { get {
        if (instantRebateBC == null) {
            instantRebateBC = TestHelper.createBillingCondition('Instant Rebate 50:50 / 50%', false);
            instantRebateBC.Rebate_Rate__c = null;
            instantRebateBC.Default_Margin__c = 50.00;
            instantRebateBC.Rebate_Type__c = 'Instant';
            instantRebateBC.Strike_Profit__c = 50.00;
            insert instantRebateBC;
        }
        return instantRebateBC;
    } set; }

    private static BillingCondition__c marginSplitBC { get {
        if (marginSplitBC == null) {
            marginSplitBC = TestHelper.createBillingCondition('Margin Split 50:50 / 30%', false);
            marginSplitBC.Rebate_Rate__c = 15.00;
            marginSplitBC.Default_Margin__c = 30.00;
            marginSplitBC.Strike_Profit__c = 50.00;
            marginSplitBC.Rebate_Type__c = 'Normal';
            insert marginSplitBC;
        }
        return marginSplitBC;
    } set; }

    private static Platform__c adWordPlatform { get {
        if (adWordPlatform == null) {
            adWordPlatform = TestHelper.createAdWordsPlatform();
            insert adWordPlatform;
        }
        return adWordPlatform;
    } set; }

    private static final Decimal CLIENT_SPEND = 100000;

    private static OpportunityPlatform__c createOpportunityPlatform_CPM_OR_NoCostStructure(Id oppId) {
        OpportunityPlatform__c oppPlatform = new OpportunityPlatform__c(Opportunity__c = oppId, Platform__c = adWordPlatform.Id, CTA_Overlay_Text__c = 'Text', Pixel_Tracking__c = 'Yes', KPI__c = 'KPI',
                NoCostStructure__c = true, CostStructure__c = '');
        insert oppPlatform;
        return oppPlatform;
    }

    // Instant Rebate billing condition
    @IsTest static void testGrossProfitCalculation_Custom1() {
        Decimal margin = instantRebateBC.Default_Margin__c;
        Utility.BILLING_PROFILES billingProfile = Utility.BILLING_PROFILES.Client;

        Opportunity opp = TestHelper.createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBC, CLIENT_SPEND, margin, '% of Media', true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id);

        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Verify Contract data
        Project__c contract = ContractRepository.getContractByOppIdWithPaymentsAndProjects(opp.Id);
        System.assertEquals(contract.BillingCondition__c, instantRebateBC.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile.name());
        System.assertEquals(contract.Margin__c, margin);

        // Verify Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, contract.Margin_Type__c);
        System.assertEquals(payment.Billing_Profile__c, contract.Account_Type__c);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, contract.BillingCondition__c);

        // Verify Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(contract.Margin_Type__c, project.Margin_Type__c);

        Integer delivered = 1;
        Decimal mediaSpend = CLIENT_SPEND * (1 - margin/100);

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = ContractRepository.getContractByOppIdWithPaymentsAndProjects(opp.Id);
        payment = contract.Sub_Projects__r[0];
        project = contract.Payments__r[0];

        System.debug('### CUSTOM1 MediaSpend: ' + project.AdWordsSpend__c + ' _ MediaOrder: ' + project.Media_Order__c);

        Decimal expectedActualRebate = (project.Client_Spend__c - project.AdWordsSpend__c) * (1 - instantRebateBC.Strike_Profit__c/100);
        System.assertEquals(expectedActualRebate.setScale(3), project.Actual_Rebate__c);
        System.debug('### CUSTOM1 ActualRebate: ' + project.Actual_Rebate__c + ' ? ' + expectedActualRebate);
    }

    @IsTest static void testGrossProfitCalculation_Custom2() {
        Decimal margin = instantRebateBC.Default_Margin__c;
        Utility.BILLING_PROFILES billingProfile = Utility.BILLING_PROFILES.Strike;

        Opportunity opp = TestHelper.createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBC, CLIENT_SPEND, margin, '% of Media', true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id);

        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Verify Contract data
        Project__c contract = ContractRepository.getContractByOppIdWithPaymentsAndProjects(opp.Id);
        System.assertEquals(contract.BillingCondition__c, instantRebateBC.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile.name());
        System.assertEquals(contract.Margin__c, margin);

        // Verify Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, contract.Margin_Type__c);
        System.assertEquals(payment.Billing_Profile__c, contract.Account_Type__c);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, contract.BillingCondition__c);

        // Verify Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(contract.Margin_Type__c, project.Margin_Type__c);

        Integer delivered = 1;
        Decimal mediaSpend = CLIENT_SPEND * (1 - margin/100);

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = ContractRepository.getContractByOppIdWithPaymentsAndProjects(opp.Id);
        payment = contract.Sub_Projects__r[0];
        project = contract.Payments__r[0];

        Decimal expectedActualRebate = (project.Client_Spend__c - project.AdWordsSpend__c) * (1 - instantRebateBC.Strike_Profit__c/100);
        System.assertEquals(expectedActualRebate.setScale(3), project.Actual_Rebate__c);
        System.debug('### CUSTOM2 ActualRebate: ' + project.Actual_Rebate__c + ' ? ' + expectedActualRebate);
    }

    @IsTest static void testGrossProfitCalculation_Custom3() {
        Decimal margin = instantRebateBC.Default_Margin__c;
        Utility.BILLING_PROFILES billingProfile = Utility.BILLING_PROFILES.Client;

        Opportunity opp = TestHelper.createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBC, CLIENT_SPEND, margin, '% of Budget', true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id);

        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Verify Contract data
        Project__c contract = ContractRepository.getContractByOppIdWithPaymentsAndProjects(opp.Id);
        System.assertEquals(contract.BillingCondition__c, instantRebateBC.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile.name());
        System.assertEquals(contract.Margin__c, margin);

        // Verify Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, contract.Margin_Type__c);
        System.assertEquals(payment.Billing_Profile__c, contract.Account_Type__c);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, contract.BillingCondition__c);

        // Verify Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(contract.Margin_Type__c, project.Margin_Type__c);

        Integer delivered = 1;
        Decimal mediaSpend = CLIENT_SPEND * (1 - margin/100);

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = ContractRepository.getContractByOppIdWithPaymentsAndProjects(opp.Id);
        payment = contract.Sub_Projects__r[0];
        project = contract.Payments__r[0];

        Decimal expectedActualRebate = (project.Client_Spend__c - project.AdWordsSpend__c) * (1 - instantRebateBC.Strike_Profit__c/100);
        System.assertEquals(expectedActualRebate.setScale(3), project.Actual_Rebate__c);
        System.debug('### CUSTOM3 ActualRebate: ' + project.Actual_Rebate__c + ' ? ' + expectedActualRebate);
    }

    @IsTest static void testGrossProfitCalculation_Custom4() {
        Decimal margin = instantRebateBC.Default_Margin__c;
        Utility.BILLING_PROFILES billingProfile = Utility.BILLING_PROFILES.Strike;

        Opportunity opp = TestHelper.createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBC, CLIENT_SPEND, margin, '% of Budget', true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id);

        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Verify Contract data
        Project__c contract = ContractRepository.getContractByOppIdWithPaymentsAndProjects(opp.Id);
        System.assertEquals(contract.BillingCondition__c, instantRebateBC.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile.name());
        System.assertEquals(contract.Margin__c, margin);

        // Verify Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, contract.Margin_Type__c);
        System.assertEquals(payment.Billing_Profile__c, contract.Account_Type__c);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, contract.BillingCondition__c);

        // Verify Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(contract.Margin_Type__c, project.Margin_Type__c);

        Integer delivered = 1;
        Decimal mediaSpend = CLIENT_SPEND * (1 - margin/100);

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = ContractRepository.getContractByOppIdWithPaymentsAndProjects(opp.Id);
        payment = contract.Sub_Projects__r[0];
        project = contract.Payments__r[0];

        Decimal expectedActualRebate = (project.Client_Spend__c - project.AdWordsSpend__c) * (1 - instantRebateBC.Strike_Profit__c/100);
        System.assertEquals(expectedActualRebate.setScale(3), project.Actual_Rebate__c);
        System.debug('### CUSTOM4 ActualRebate: ' + project.Actual_Rebate__c + ' ? ' + expectedActualRebate);
    }

    // Margin Split billing condition
    @IsTest static void testGrossProfitCalculation_Custom5() {
        Decimal margin = marginSplitBC.Default_Margin__c;
        Utility.BILLING_PROFILES billingProfile = Utility.BILLING_PROFILES.Strike;

        Opportunity opp = TestHelper.createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBC, CLIENT_SPEND, margin, '% of Budget', true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id);

        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Verify Contract data
        Project__c contract = ContractRepository.getContractByOppIdWithPaymentsAndProjects(opp.Id);
        System.assertEquals(contract.BillingCondition__c, marginSplitBC.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile.name());
        System.assertEquals(contract.Margin__c, margin);

        // Verify Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, contract.Margin_Type__c);
        System.assertEquals(payment.Billing_Profile__c, contract.Account_Type__c);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, contract.BillingCondition__c);

        // Verify Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(contract.Margin_Type__c, project.Margin_Type__c);

        Integer delivered = 1;
        Decimal mediaSpend = CLIENT_SPEND * (1 - margin/100);

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = ContractRepository.getContractByOppIdWithPaymentsAndProjects(opp.Id);
        payment = contract.Sub_Projects__r[0];
        project = contract.Payments__r[0];

        System.debug('### CUSTOM5 InvoiceAmount: ' + project.InvoiceAmount__c);
        Decimal expectedActualRebate = (project.InvoiceAmount__c - project.AdWordsSpend__c) * (1 - marginSplitBC.Strike_Profit__c/100);
        System.debug('### CUSTOM5 expectedActualRebate: ' + expectedActualRebate);
        System.debug('### CUSTOM5 ActualRebate: ' + project.Actual_Rebate__c + ' ? ' + expectedActualRebate);
        System.assertEquals(expectedActualRebate.setScale(3), project.Actual_Rebate__c.setScale(3));
    }

    @IsTest static void testGrossProfitCalculation_Custom6() {
        Decimal margin = marginSplitBC.Default_Margin__c;
        Utility.BILLING_PROFILES billingProfile = Utility.BILLING_PROFILES.Strike;

        Opportunity opp = TestHelper.createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBC, CLIENT_SPEND, margin, '% of Media', true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id);

        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Verify Contract data
        Project__c contract = ContractRepository.getContractByOppIdWithPaymentsAndProjects(opp.Id);
        System.assertEquals(contract.BillingCondition__c, marginSplitBC.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile.name());
        System.assertEquals(contract.Margin__c, margin);

        // Verify Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, contract.Margin_Type__c);
        System.assertEquals(payment.Billing_Profile__c, contract.Account_Type__c);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, contract.BillingCondition__c);

        // Verify Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(contract.Margin_Type__c, project.Margin_Type__c);

        Integer delivered = 1;
        Decimal mediaSpend = CLIENT_SPEND * (1 - margin/100);

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = ContractRepository.getContractByOppIdWithPaymentsAndProjects(opp.Id);
        payment = contract.Sub_Projects__r[0];
        project = contract.Payments__r[0];

        System.debug('### CUSTOM6 InvoiceAmount: ' + project.InvoiceAmount__c);
        Decimal expectedActualRebate = (project.InvoiceAmount__c - project.AdWordsSpend__c) * (1 - marginSplitBC.Strike_Profit__c/100);
        System.debug('### CUSTOM6 ActualRebate: ' + project.Actual_Rebate__c + ' ? ' + expectedActualRebate);
        System.assertEquals(expectedActualRebate.setScale(3), project.Actual_Rebate__c.setScale(3));
    }

    @IsTest static void testGrossProfitCalculation_Custom7() {
        Decimal margin = marginSplitBC.Default_Margin__c;
        Utility.BILLING_PROFILES billingProfile = Utility.BILLING_PROFILES.Client;

        Opportunity opp = TestHelper.createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBC, CLIENT_SPEND, margin, '% of Budget', true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id);

        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Verify Contract data
        Project__c contract = ContractRepository.getContractByOppIdWithPaymentsAndProjects(opp.Id);
        System.assertEquals(contract.BillingCondition__c, marginSplitBC.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile.name());
        System.assertEquals(contract.Margin__c, margin);

        // Verify Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, contract.Margin_Type__c);
        System.assertEquals(payment.Billing_Profile__c, contract.Account_Type__c);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, contract.BillingCondition__c);

        // Verify Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(contract.Margin_Type__c, project.Margin_Type__c);

        Integer delivered = 1;
        Decimal mediaSpend = CLIENT_SPEND * (1 - margin/100);

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = ContractRepository.getContractByOppIdWithPaymentsAndProjects(opp.Id);
        payment = contract.Sub_Projects__r[0];
        project = contract.Payments__r[0];

        System.debug('### CUSTOM7 InvoiceAmount: ' + project.InvoiceAmount__c);
        Decimal expectedActualRebate = project.InvoiceAmount__c * (1 - marginSplitBC.Strike_Profit__c/100);
        System.debug('### CUSTOM7 expectedActualRebate: ' + expectedActualRebate);
        System.debug('### CUSTOM7 ActualRebate: ' + project.Actual_Rebate__c + ' ? ' + expectedActualRebate);
        System.assertEquals(expectedActualRebate.setScale(3), project.Actual_Rebate__c.setScale(3));
    }

    @IsTest static void testGrossProfitCalculation_Custom8() {
        Decimal margin = marginSplitBC.Default_Margin__c;
        Utility.BILLING_PROFILES billingProfile = Utility.BILLING_PROFILES.Client;

        Opportunity opp = TestHelper.createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBC, CLIENT_SPEND, margin, '% of Media', true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id);

        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Verify Contract data
        Project__c contract = ContractRepository.getContractByOppIdWithPaymentsAndProjects(opp.Id);
        System.assertEquals(contract.BillingCondition__c, marginSplitBC.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile.name());
        System.assertEquals(contract.Margin__c, margin);

        // Verify Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, contract.Margin_Type__c);
        System.assertEquals(payment.Billing_Profile__c, contract.Account_Type__c);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, contract.BillingCondition__c);

        // Verify Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(contract.Margin_Type__c, project.Margin_Type__c);

        Integer delivered = 1;
        Decimal mediaSpend = CLIENT_SPEND * (1 - margin/100);

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = ContractRepository.getContractByOppIdWithPaymentsAndProjects(opp.Id);
        payment = contract.Sub_Projects__r[0];
        project = contract.Payments__r[0];

        System.debug('### CUSTOM8 InvoiceAmount: ' + project.InvoiceAmount__c);
        Decimal expectedActualRebate = project.InvoiceAmount__c * (1 - marginSplitBC.Strike_Profit__c/100);
        System.debug('### CUSTOM8 ActualRebate: ' + project.Actual_Rebate__c + ' ? ' + expectedActualRebate);
        System.assertEquals(expectedActualRebate.setScale(3), project.Actual_Rebate__c.setScale(3));
    }

    // Rebate billing condition
    @IsTest static void testGrossProfitCalculation_Custom9() {
        Decimal margin = rebateBC.Default_Margin__c;
        Utility.BILLING_PROFILES billingProfile = Utility.BILLING_PROFILES.Strike;

        Opportunity opp = TestHelper.createMeetingOppWithoutOppPlatform(billingProfile, rebateBC, CLIENT_SPEND, margin, '% of Budget', true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id);

        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Verify Contract data
        Project__c contract = ContractRepository.getContractByOppIdWithPaymentsAndProjects(opp.Id);
        System.assertEquals(contract.BillingCondition__c, rebateBC.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile.name());
        System.assertEquals(contract.Margin__c, margin);

        // Verify Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, contract.Margin_Type__c);
        System.assertEquals(payment.Billing_Profile__c, contract.Account_Type__c);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, contract.BillingCondition__c);

        // Verify Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(contract.Margin_Type__c, project.Margin_Type__c);

        Integer delivered = 1;
        Decimal mediaSpend = CLIENT_SPEND * (1 - margin/100);

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = ContractRepository.getContractByOppIdWithPaymentsAndProjects(opp.Id);
        payment = contract.Sub_Projects__r[0];
        project = contract.Payments__r[0];

        System.debug('### CUSTOM9 InvoiceAmount: ' + project.InvoiceAmount__c);
        Decimal expectedActualRebate = CLIENT_SPEND * rebateBC.Rebate_Rate__c/100;
        System.debug('### CUSTOM9 expectedActualRebate: ' + expectedActualRebate);
        System.debug('### CUSTOM9 ActualRebate: ' + project.Actual_Rebate__c + ' ? ' + expectedActualRebate);
        System.assertEquals(expectedActualRebate.setScale(3), project.Actual_Rebate__c.setScale(3));
    }

    @IsTest static void testGrossProfitCalculation_Custom10() {
        Decimal margin = rebateBC.Default_Margin__c;
        Utility.BILLING_PROFILES billingProfile = Utility.BILLING_PROFILES.Strike;

        Opportunity opp = TestHelper.createMeetingOppWithoutOppPlatform(billingProfile, rebateBC, CLIENT_SPEND, margin, '% of Media', true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id);

        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Verify Contract data
        Project__c contract = ContractRepository.getContractByOppIdWithPaymentsAndProjects(opp.Id);
        System.assertEquals(contract.BillingCondition__c, rebateBC.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile.name());
        System.assertEquals(contract.Margin__c, margin);

        // Verify Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, contract.Margin_Type__c);
        System.assertEquals(payment.Billing_Profile__c, contract.Account_Type__c);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, contract.BillingCondition__c);

        // Verify Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(contract.Margin_Type__c, project.Margin_Type__c);

        Integer delivered = 1;
        Decimal mediaSpend = 90000;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = ContractRepository.getContractByOppIdWithPaymentsAndProjects(opp.Id);
        payment = contract.Sub_Projects__r[0];
        project = contract.Payments__r[0];

        System.debug('### CUSTOM10 MediaSpend: ' + project.AdWordsSpend__c);
        Decimal expectedActualRebate = (project.AdWordsSpend__c + project.AdWordsSpend__c * margin/100) * rebateBC.Rebate_Rate__c/100;
        System.debug('### CUSTOM10 ActualRebate: ' + project.Actual_Rebate__c + ' ? ' + expectedActualRebate);
        System.assertEquals(expectedActualRebate.setScale(3), project.Actual_Rebate__c.setScale(3));
    }

    @IsTest static void testGrossProfitCalculation_Custom11() {
        Decimal margin = rebateBC.Default_Margin__c;
        Utility.BILLING_PROFILES billingProfile = Utility.BILLING_PROFILES.Client;

        Opportunity opp = TestHelper.createMeetingOppWithoutOppPlatform(billingProfile, rebateBC, CLIENT_SPEND, margin, '% of Budget', true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id);

        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Verify Contract data
        Project__c contract = ContractRepository.getContractByOppIdWithPaymentsAndProjects(opp.Id);
        System.assertEquals(contract.BillingCondition__c, rebateBC.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile.name());
        System.assertEquals(contract.Margin__c, margin);

        // Verify Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, contract.Margin_Type__c);
        System.assertEquals(payment.Billing_Profile__c, contract.Account_Type__c);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, contract.BillingCondition__c);

        // Verify Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(contract.Margin_Type__c, project.Margin_Type__c);

        Integer delivered = 1;
        Decimal mediaSpend = CLIENT_SPEND * (1 - margin/100);

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = ContractRepository.getContractByOppIdWithPaymentsAndProjects(opp.Id);
        payment = contract.Sub_Projects__r[0];
        project = contract.Payments__r[0];

        System.debug('### CUSTOM11 InvoiceAmount: ' + project.InvoiceAmount__c + '   mediaSpend: ' + mediaSpend);
        Decimal expectedActualRebate = (project.InvoiceAmount__c / (margin/100)) * rebateBC.Rebate_Rate__c/100;
        System.debug('### CUSTOM11 expectedActualRebate: ' + expectedActualRebate);
        System.debug('### CUSTOM11 ActualRebate: ' + project.Actual_Rebate__c + ' ? ' + expectedActualRebate);
        System.assertEquals(expectedActualRebate.setScale(3), project.Actual_Rebate__c.setScale(3));
    }

    @IsTest static void testGrossProfitCalculation_Custom12() {
        Decimal margin = rebateBC.Default_Margin__c;
        Utility.BILLING_PROFILES billingProfile = Utility.BILLING_PROFILES.Client;

        Opportunity opp = TestHelper.createMeetingOppWithoutOppPlatform(billingProfile, rebateBC, CLIENT_SPEND, margin, '% of Media', true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id);

        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Verify Contract data
        Project__c contract = ContractRepository.getContractByOppIdWithPaymentsAndProjects(opp.Id);
        System.assertEquals(contract.BillingCondition__c, rebateBC.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile.name());
        System.assertEquals(contract.Margin__c, margin);

        // Verify Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, contract.Margin_Type__c);
        System.assertEquals(payment.Billing_Profile__c, contract.Account_Type__c);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, contract.BillingCondition__c);

        // Verify Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(contract.Margin_Type__c, project.Margin_Type__c);

        Integer delivered = 1;
        Decimal mediaSpend = CLIENT_SPEND * (1 - margin/100);

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = ContractRepository.getContractByOppIdWithPaymentsAndProjects(opp.Id);
        payment = contract.Sub_Projects__r[0];
        project = contract.Payments__r[0];

        System.debug('### CUSTOM6 InvoiceAmount: ' + project.InvoiceAmount__c);
        Decimal expectedActualRebate = (project.AdWordsSpend__c + project.InvoiceAmount__c) * rebateBC.Rebate_Rate__c/100;
        System.debug('### CUSTOM6 ActualRebate: ' + project.Actual_Rebate__c + ' ? ' + expectedActualRebate);
        System.assertEquals(expectedActualRebate.setScale(3), project.Actual_Rebate__c.setScale(3));
    }
}