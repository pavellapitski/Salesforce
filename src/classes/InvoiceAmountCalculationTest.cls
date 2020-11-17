/**
 * Created by Pavel Lapitski on 2020-04-24.
 */

@IsTest
private class InvoiceAmountCalculationTest {

    private static final Decimal CLIENT_SPEND = 100000;
    private static final Decimal CPM_UNIT_COST = 20;
    private static final Integer PROJECT_LENGTH_IN_DAYS = 25;
    private static final Decimal DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND = 5000;

    private static Platform__c adWordPlatform { get {
        if (adWordPlatform == null) {
            adWordPlatform = TestHelper.createAdWordsPlatform();
            insert adWordPlatform;
        }
        return adWordPlatform;
    } set; }

    private static BillingCondition__c normalBillingCondition { get {
        if (normalBillingCondition == null) {
            normalBillingCondition = TestHelper.createBillingCondition('Normal', true);
        }
        normalBillingCondition.Rebate_Type__c = 'Normal';
        return normalBillingCondition;
    } set; }

    private static BillingCondition__c rebateBillingCondition { get {
        if (rebateBillingCondition == null) {
            rebateBillingCondition = TestHelper.createBillingCondition('Rebate 10%/30%', false);
            rebateBillingCondition.Rebate_Rate__c = 10.00;
            rebateBillingCondition.Default_Margin__c = 30.00;
            rebateBillingCondition.Strike_Profit__c = 0;
            rebateBillingCondition.Rebate_Type__c = 'Normal';
            insert rebateBillingCondition;
        }
        return rebateBillingCondition;
    } set; }

    private static BillingCondition__c instantRebateBillingCondition { get {
        if (instantRebateBillingCondition == null) {
            instantRebateBillingCondition = TestHelper.createBillingCondition('Instant Rebate 50:50 / 50%', false);
            instantRebateBillingCondition.Rebate_Rate__c = null;
            instantRebateBillingCondition.Default_Margin__c = 50.00;
            instantRebateBillingCondition.Rebate_Type__c = 'Instant';
            instantRebateBillingCondition.Strike_Profit__c = 50.00;
            insert instantRebateBillingCondition;
        }
        return instantRebateBillingCondition;
    } set; }

    private static BillingCondition__c marginSplitBillingCondition { get {
        if (marginSplitBillingCondition == null) {
            marginSplitBillingCondition = TestHelper.createBillingCondition('Margin Split 50:50 / 30%', false);
            marginSplitBillingCondition.Rebate_Rate__c = 15.00;
            marginSplitBillingCondition.Default_Margin__c = 30.00;
            marginSplitBillingCondition.Strike_Profit__c = 50.00;
            marginSplitBillingCondition.Rebate_Type__c = 'Normal';
            insert marginSplitBillingCondition;
        }
        return marginSplitBillingCondition;
    } set; }

    private static Project__c getContractByOppId(Id opportunityId) {
        return ContractRepository.getContractByOppIdWithPaymentsAndProjects(opportunityId);
    }

    private static Decimal getMediaOrder(String marginType, Decimal clientSpend, Decimal margin) {
        Decimal mediaOrdered = 0;
        if (marginType == '% of Media') {
            mediaOrdered = clientSpend / (1 + margin/100);
        } else if (marginType == '% of Budget') {
            mediaOrdered = clientSpend * (1  - margin/100);
        }
        return mediaOrdered.setScale(2);
    }

    private static Opportunity createMeetingOppWithoutOppPlatform(String bp, BillingCondition__c bc, Decimal clientSpend, Decimal margin, String marginType, Boolean doInsert) {
        Date startDate = Date.newInstance(System.today().addMonths(-1).year(), System.today().addMonths(-1).month(), 1),
            endDate = startDate.addDays(PROJECT_LENGTH_IN_DAYS);

        Utility.BILLING_PROFILES billingProfile;
        if (bp == 'Strike') billingProfile = Utility.BILLING_PROFILES.Strike;
        if (bp == 'Client') billingProfile = Utility.BILLING_PROFILES.Client;

        Opportunity opportunityRecord = TestHelper.createOpportunity(billingProfile);
        opportunityRecord.Amount = clientSpend;
        opportunityRecord.BillingCondition__c = bc.Id;
        opportunityRecord.Percent_Margin__c = margin;
        opportunityRecord.Payment_Type__c = 'Net 30';
        opportunityRecord.Flight_Start__c = startDate;
        opportunityRecord.Flight_End__c = endDate;
        opportunityRecord.StageName = 'Meeting';
        opportunityRecord.Margin_Type__c = marginType;

        if (doInsert) insert opportunityRecord;
        return opportunityRecord;
    }

    private static OpportunityPlatform__c createOpportunityPlatform_CPM_OR_NoCostStructure(Id oppId, Decimal unitCost, Boolean doInsert) {
        OpportunityPlatform__c oppPlatform = new OpportunityPlatform__c(Opportunity__c = oppId, Platform__c = adWordPlatform.Id, CTA_Overlay_Text__c = 'Text', Pixel_Tracking__c = 'Yes', KPI__c = 'KPI');
        if (unitCost == null) {
            oppPlatform.NoCostStructure__c = true;
            oppPlatform.CPM__c = 0;
            oppPlatform.CostStructure__c = '';
        } else {
            oppPlatform.CPM__c = unitCost;
            oppPlatform.CostStructure__c = 'CPM';
            oppPlatform.NoCostStructure__c = false;
        }
        if (doInsert) insert oppPlatform;
        return oppPlatform;
    }

    // NORMAL BILLING CONDITION
    @IsTest static void testInvoiceCalculation_Custom1() {
        // Billing Profile: Strike // Billing Condition: Normal // Margin: 25%
        // maxCPA: null, i.e. No Cost Structure // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Media';
        Decimal margin = 25, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, normalBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, normalBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, normalBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is null, there is no need to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units

        // Check a condition in which MediaOrder = MediaSpend
        Integer delivered = 1;
        Decimal mediaSpend = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];//getPaymentById(payment.Id);

        Decimal expectedInvoiceAmount = mediaSpend * (1 + margin/100),
                actualInvoiceAmount = payment.Invoice_Amount__c.round(System.RoundingMode.HALF_UP);

        System.assertEquals(expectedInvoiceAmount, actualInvoiceAmount);
        System.assertEquals(CLIENT_SPEND, actualInvoiceAmount);
        System.debug('### Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM1 Expected: ' + expectedInvoiceAmount + ' Actual: ' + actualInvoiceAmount);
    }

    @IsTest static void testInvoiceCalculation_Custom2() {
        // Billing Profile: Strike // Billing Condition: Normal // Margin: 25%
        // maxCPA: null, i.e. No Cost Structure // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Budget';
        Decimal margin = 25, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, normalBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, normalBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, normalBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is null, there is no need to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units

        // Check a condition in which MediaOrder = MediaSpend
        Integer delivered = 1;
        Decimal mediaSpend = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend / (1 - margin/100),
                actualInvoiceAmount = payment.Invoice_Amount__c.round(System.RoundingMode.HALF_UP);
        System.assertEquals(expectedInvoiceAmount, actualInvoiceAmount);
        System.debug('### Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM2 Expected: ' + expectedInvoiceAmount + ' Actual: ' + actualInvoiceAmount);
    }

    @IsTest static void testInvoiceCalculation_Custom3() {
        // Billing Profile: Client // Billing Condition: Normal // Margin: 25%
        // maxCPA: null, i.e. No Cost Structure // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Budget';
        Decimal margin = 25, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, normalBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, normalBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, normalBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is null, there is no need to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units

        // Check a condition in which MediaOrder = MediaSpend
        Integer delivered = 1;
        Decimal mediaSpend = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = CLIENT_SPEND - mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c.round(System.RoundingMode.HALF_UP);
        System.assertEquals(expectedInvoiceAmount, actualInvoiceAmount);
        System.debug('### Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM3 Expected: ' + expectedInvoiceAmount + ' Actual: ' + actualInvoiceAmount);
    }

    @IsTest static void testInvoiceCalculation_Custom4() {
        // Billing Profile: Client // Billing Condition: Normal // Margin: 25%
        // maxCPA: null, i.e. No Cost Structure // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Media';
        Decimal margin = 25, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, normalBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, normalBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, normalBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is null, there is no need to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units

        // Check a condition in which MediaOrder = MediaSpend
        Integer delivered = 1;
        Decimal mediaSpend = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = CLIENT_SPEND - mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c.round(System.RoundingMode.HALF_UP);
        System.assertEquals(expectedInvoiceAmount, actualInvoiceAmount);
        System.debug('### Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM4 Expected: ' + expectedInvoiceAmount + ' Actual: ' + actualInvoiceAmount);
    }

    @IsTest static void testInvoiceCalculation_Custom5() {
        // Billing Profile: Client // Billing Condition: Normal // Margin: 25%
        // maxCPA: null, i.e. No Cost Structure // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Media';
        Decimal margin = 25, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, normalBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, normalBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, normalBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is null, there is no need to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units

        // Check a condition in which MediaOrder > MediaSpend
        Integer delivered = 1;
        Decimal mediaSpend = project.Media_Order__c - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * margin/100, // (80,000 - 5,000) * 0.25 = 18,750
                actualInvoiceAmount = payment.Invoice_Amount__c.round(System.RoundingMode.HALF_UP);
        System.assertEquals(expectedInvoiceAmount, actualInvoiceAmount);
        System.debug('### Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM5 Expected: ' + expectedInvoiceAmount + ' Actual: ' + actualInvoiceAmount);
    }

    @IsTest static void testInvoiceCalculation_Custom6() {
        // Billing Profile: Client // Billing Condition: Normal // Margin: 25%
        // maxCPA: null, i.e. No Cost Structure // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Budget';
        Decimal margin = 25, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, normalBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, normalBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, normalBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is null, there is no need to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units

        // Check a condition in which MediaOrder > MediaSpend
        Integer delivered = 1;
        Decimal mediaSpend = project.Media_Order__c - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * (margin/100/(1-margin/100)), // (75,000 - 5,000) * 0.25 * (1/0.75)
                actualInvoiceAmount = payment.Invoice_Amount__c;
        System.debug('### Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM6 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom7() {
        // Billing Profile: Strike // Billing Condition: Normal // Margin: 25%
        // maxCPA: null, i.e. No Cost Structure // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Budget';
        Decimal margin = 25, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, normalBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, normalBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, normalBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is null, there is no need to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units

        // Check a condition in which MediaOrder > MediaSpend
        Integer delivered = 1;
        Decimal mediaSpend = project.Media_Order__c - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * 1/(1-margin/100), // (75,000 - 5,000) * (1/0.75)
                actualInvoiceAmount = payment.Invoice_Amount__c;
        System.debug('### Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM7 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom8() {
        // Billing Profile: Strike // Billing Condition: Normal // Margin: 25%
        // maxCPA: null, i.e. No Cost Structure // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Media';
        Decimal margin = 25, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, normalBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, normalBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, normalBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is null, there is no need to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units

        // Check a condition in which MediaOrder > MediaSpend
        Integer delivered = 1;
        Decimal mediaSpend = project.Media_Order__c - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * (1 + margin/100), // (80,000 - 5,000) * (1 + 0.25)
                actualInvoiceAmount = payment.Invoice_Amount__c;
        System.debug('### Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM8 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom9() {
        // Billing Profile: Strike // Billing Condition: Normal // Margin: 25%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Budget';
        Decimal margin = 25, unitCost = CPM_UNIT_COST;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, normalBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, normalBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, normalBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        // Check a condition in which Delivered > Ordered
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 10;
        Decimal mediaSpend = project.Media_Order__c;//delivered * CPM_UNIT_COST; // ?? project.Media_Order__c

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = CLIENT_SPEND,
                actualInvoiceAmount = payment.Invoice_Amount__c;
        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM9 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom10() {
        // Billing Profile: Strike // Billing Condition: Normal // Margin: 25%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Budget';
        Decimal margin = 25, unitCost = CPM_UNIT_COST;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, normalBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, normalBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, normalBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        // Check a condition in which Delivered < Ordered
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaSpend = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = delivered * CPM_UNIT_COST / 1000,
                actualInvoiceAmount = payment.Invoice_Amount__c;
        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM10 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom11() {
        // Billing Profile: Client // Billing Condition: Normal // Margin: 25%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Budget';
        Decimal margin = 25, unitCost = CPM_UNIT_COST;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, normalBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, normalBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, normalBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaSpend = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = (CLIENT_SPEND * delivered / ordered) - mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;
        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM11 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom12() {
        // Billing Profile: Client // Billing Condition: Normal // Margin: 25%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Budget';
        Decimal margin = 25, unitCost = CPM_UNIT_COST;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, normalBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, normalBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, normalBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaSpend = project.Media_Order__c - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * margin/100 /(1-margin/100),
                actualInvoiceAmount = payment.Invoice_Amount__c;
        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM12 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom13() {
        // Billing Profile: Client // Billing Condition: Normal // Margin: 25%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Budget';
        Decimal margin = 25, unitCost = CPM_UNIT_COST;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, normalBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, normalBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, normalBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaSpend = project.Media_Order__c - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * margin/100 / (1 - margin/100),
                actualInvoiceAmount = payment.Invoice_Amount__c;
        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM13 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom14() {
        // Billing Profile: Client // Billing Condition: Normal // Margin: 25%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Budget';
        Decimal margin = 25, unitCost = CPM_UNIT_COST;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, normalBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, normalBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, normalBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaSpend = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * margin/100 / (1 - margin/100),
                actualInvoiceAmount = payment.Invoice_Amount__c;
        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM14 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom15() {
        // Billing Profile: Client // Billing Condition: Normal // Margin: 25%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Media';
        Decimal margin = 25, unitCost = CPM_UNIT_COST;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, normalBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, normalBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, normalBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaSpend = project.Media_Order__c - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = margin/100 * mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;
        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM15 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom16() {
        // Billing Profile: Client // Billing Condition: Normal // Margin: 25%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Media';
        Decimal margin = 25, unitCost = CPM_UNIT_COST;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, normalBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, normalBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, normalBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaSpend = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = CLIENT_SPEND - mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;
        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM16 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom17() {
        // Billing Profile: Client // Billing Condition: Normal // Margin: 25%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Media';
        Decimal margin = 25, unitCost = CPM_UNIT_COST;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, normalBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, normalBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, normalBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaSpend = project.Media_Order__c - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * margin/100 * (1 + margin/100),
                actualInvoiceAmount = payment.Invoice_Amount__c;
        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM17 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom18() {
        // Billing Profile: Client // Billing Condition: Normal // Margin: 25%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Media';
        Decimal margin = 25, unitCost = CPM_UNIT_COST;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, normalBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, normalBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, normalBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaSpend = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = CLIENT_SPEND * delivered/ordered - mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;
        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM18 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }




    // REBATE 10%/30% BILLING CONDITION, i.e. Margin: 30%
    @IsTest static void testInvoiceCalculation_Custom19() {
        // Billing Profile: Client // Billing Condition: Rebate 10%/30%
        // maxCPA: null // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Media';
        Decimal margin = 30, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, rebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, rebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, rebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer delivered = 1;
        Decimal mediaSpend = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = CLIENT_SPEND - mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM19 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom20() {
        // Billing Profile: Client // Billing Condition: Rebate 10%/30%
        // maxCPA: null // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Budget';
        Decimal margin = 30, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, rebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, rebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, rebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer delivered = 1;
        Decimal mediaSpend = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = CLIENT_SPEND - mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM20 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom21() {
        // Billing Profile: Client // Billing Condition: Rebate 10%/30%
        // maxCPA: null // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Budget';
        Decimal margin = 30, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, rebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, rebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, rebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer delivered = 1;
        Decimal mediaSpend = project.Media_Order__c - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * margin/100 / (1 - margin/100),
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM21 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom22() {
        // Billing Profile: Client // Billing Condition: Rebate 10%/30%
        // maxCPA: null // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Media';
        Decimal margin = 30, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, rebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, rebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, rebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer delivered = 1;
        Decimal mediaSpend = project.Media_Order__c - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * margin/100,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM22 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom23() {
        // Billing Profile: Strike // Billing Condition: Rebate 10%/30%
        // maxCPA: null // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Media';
        Decimal margin = 30, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, rebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, rebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, rebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer delivered = 1;
        Decimal mediaSpend = project.Media_Order__c - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * (1 + margin/100),
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM23 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom24() {
        // Billing Profile: Strike // Billing Condition: Rebate 10%/30%
        // maxCPA: null // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Budget';
        Decimal margin = 30, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, rebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, rebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, rebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer delivered = 1;
        Decimal mediaSpend = project.Media_Order__c - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * 1/(1-margin/100),
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM24 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom25() {
        // Billing Profile: Strike // Billing Condition: Rebate 10%/30%
        // maxCPA: null // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Budget';
        Decimal margin = 30, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, rebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, rebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, rebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer delivered = 1;
        Decimal mediaSpend = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * 1/(1-margin/100),
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM25 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom26() {
        // Billing Profile: Strike // Billing Condition: Rebate 10%/30%
        // maxCPA: null // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Media';
        Decimal margin = 30, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, rebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, rebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, rebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer delivered = 1;
        Decimal mediaSpend = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * (1 + margin/100),
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM26 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom27() {
        // Billing Profile: Client // Billing Condition: Rebate 10%/30%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Media';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, rebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, rebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, rebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaSpend = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = (CLIENT_SPEND - mediaSpend),
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM27 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom28() {
        // Billing Profile: Client // Billing Condition: Rebate 10%/30%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Budget';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, rebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, rebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, rebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaSpend = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = (CLIENT_SPEND - mediaSpend),
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM28 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom29() {
        // Billing Profile: Client // Billing Condition: Rebate 10%/30%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Budget';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, rebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, rebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, rebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaSpend = project.Media_Order__c - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND,
                mediaOrder = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * margin/100 / (1 - margin/100),
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM29 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom30() {
        // Billing Profile: Client // Billing Condition: Rebate 10%/30%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Media';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, rebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, rebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, rebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaSpend = project.Media_Order__c - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND,
                mediaOrder = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * margin/100,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM30 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom31() {
        // Billing Profile: Client // Billing Condition: Rebate 10%/30%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Media';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, rebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, rebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, rebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaSpend = project.Media_Order__c,
                mediaOrder = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = CLIENT_SPEND * delivered/ordered - mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM31 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom32() {
        // Billing Profile: Client // Billing Condition: Rebate 10%/30%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Budget';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, rebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, rebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, rebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaSpend = project.Media_Order__c,
                mediaOrder = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = CLIENT_SPEND * delivered/ordered - mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM32 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom33() {
        // Billing Profile: Client // Billing Condition: Rebate 10%/30%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Budget';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, rebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, rebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, rebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaSpend = project.Media_Order__c - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND,
                mediaOrder = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * margin/100 / (1-margin/100),
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM33 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom34() {
        // Billing Profile: Client // Billing Condition: Rebate 10%/30%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Media';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, rebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, rebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, rebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaSpend = project.Media_Order__c - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND,
                mediaOrder = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * margin/100 * (1 + margin/100),
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM34 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom35() {
        // Billing Profile: Strike // Billing Condition: Rebate 10%/30%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Media';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, rebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, rebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, rebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaSpend = project.Media_Order__c - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND,
                mediaOrder = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = delivered * unitCost/1000,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM35 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom36() {
        // Billing Profile: Strike // Billing Condition: Rebate 10%/30%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Budget';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, rebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, rebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, rebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaSpend = project.Media_Order__c - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND,
                mediaOrder = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = delivered * unitCost/1000,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM36 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom37() {
        // Billing Profile: Strike // Billing Condition: Rebate 10%/30%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Budget';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, rebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, rebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, rebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaSpend = project.Media_Order__c,
                mediaOrder = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = delivered * unitCost/1000,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM37 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom38() {
        // Billing Profile: Strike // Billing Condition: Rebate 10%/30%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Media';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, rebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, rebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, rebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaSpend = project.Media_Order__c,
                mediaOrder = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = delivered * unitCost/1000,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM38 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom39() {
        // Billing Profile: Strike // Billing Condition: Rebate 10%/30%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Media';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, rebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, rebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, rebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaSpend = project.Media_Order__c,
                mediaOrder = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = CLIENT_SPEND,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM39 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom40() {
        // Billing Profile: Strike // Billing Condition: Rebate 10%/30%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Budget';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, rebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, rebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, rebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaSpend = project.Media_Order__c,
                mediaOrder = project.Media_Order__c;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = CLIENT_SPEND,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM40 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom41() {
        // Billing Profile: Strike // Billing Condition: Rebate 10%/30%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Budget';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, rebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, rebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, rebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = CLIENT_SPEND,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM41 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom42() {
        // Billing Profile: Strike // Billing Condition: Rebate 10%/30%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Media';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, rebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, rebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, rebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = CLIENT_SPEND,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM42 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }



    // Margin Split 50:50 / 30% // Margin: 30%
    @IsTest static void testInvoiceCalculation_Custom43() {
        // Billing Profile: Strike // Billing Condition: Margin Split 50:50 / 30%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Media';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, marginSplitBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, marginSplitBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = CLIENT_SPEND,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM43 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom44() {
        // Billing Profile: Strike // Billing Condition: Margin Split 50:50 / 30%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Budget';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, marginSplitBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, marginSplitBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = CLIENT_SPEND,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM44 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom45() {
        // Billing Profile: Strike // Billing Condition: Margin Split 50:50 / 30%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Budget';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, marginSplitBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, marginSplitBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = delivered * unitCost / 1000,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM45 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom46() {
        // Billing Profile: Strike // Billing Condition: Margin Split 50:50 / 30%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Media';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, marginSplitBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, marginSplitBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        //payment.Checked__c = true;
        update new Sub_Project__c(Id = payment.Id, Checked__c = true);
        Test.stopTest();

        System.debug('### TEST STOP');

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = delivered * unitCost / 1000,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM46 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom47() {
        // Billing Profile: Client // Billing Condition: Margin Split 50:50 / 30%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Budget';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, marginSplitBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, marginSplitBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * margin/100 / (1 - margin/100),
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM47 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom48() {
        // Billing Profile: Client // Billing Condition: Margin Split 50:50 / 30%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Media';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, marginSplitBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, marginSplitBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * margin/100 * (1 + margin/100),
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM48 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom49() {
        // Billing Profile: Client // Billing Condition: Margin Split 50:50 / 30%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Budget';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, marginSplitBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, marginSplitBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * margin/100 / (1-margin/100),
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM49 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom50() {
        // Billing Profile: Client // Billing Condition: Margin Split 50:50 / 30%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Media';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, marginSplitBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, marginSplitBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * margin/100,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM50 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom51() {
        // Billing Profile: Client // Billing Condition: Margin Split 50:50 / 30%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Budget';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, marginSplitBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, marginSplitBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = CLIENT_SPEND - mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM51 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom52() {
        // Billing Profile: Client // Billing Condition: Margin Split 50:50 / 30%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Media';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, marginSplitBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, marginSplitBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = CLIENT_SPEND - mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM52 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom53() {
        // Billing Profile: Client // Billing Condition: Margin Split 50:50 / 30%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Budget';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, marginSplitBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, marginSplitBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = CLIENT_SPEND * delivered/ordered - mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM53 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom54() {
        // Billing Profile: Client // Billing Condition: Margin Split 50:50 / 30%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Media';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, marginSplitBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, marginSplitBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = CLIENT_SPEND * delivered/ordered - mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM54 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom55() {
        // Billing Profile: Strike // Billing Condition: Margin Split 50:50 / 30%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Budget';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, marginSplitBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, marginSplitBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = delivered * unitCost / 1000,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM55 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom56() {
        // Billing Profile: Strike // Billing Condition: Margin Split 50:50 / 30%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Media';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, marginSplitBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, marginSplitBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = delivered * unitCost / 1000,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM56 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom57() {
        // Billing Profile: Strike // Billing Condition: Margin Split 50:50 / 30%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Budget';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, marginSplitBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, marginSplitBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = CLIENT_SPEND,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM57 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom58() {
        // Billing Profile: Strike // Billing Condition: Margin Split 50:50 / 30%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Media';
        Decimal margin = 30, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, marginSplitBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, marginSplitBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = CLIENT_SPEND,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM58 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom59() {
        // Billing Profile: Strike // Billing Condition: Margin Split 50:50 / 30%
        // maxCPA: null // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Budget';
        Decimal margin = 30, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, marginSplitBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, marginSplitBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = 1;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * 1 / (1 - margin/100),
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM59 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom60() {
        // Billing Profile: Strike // Billing Condition: Margin Split 50:50 / 30%
        // maxCPA: null // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Media';
        Decimal margin = 30, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, marginSplitBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, marginSplitBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = 1;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * (1 + margin/100),
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM60 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom61() {
        // Billing Profile: Strike // Billing Condition: Margin Split 50:50 / 30%
        // maxCPA: null // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Budget';
        Decimal margin = 30, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, marginSplitBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, marginSplitBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = 1;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * 1 / (1 - margin/100),
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM61 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom62() {
        // Billing Profile: Strike // Billing Condition: Margin Split 50:50 / 30%
        // maxCPA: null // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Media';
        Decimal margin = 30, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, marginSplitBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, marginSplitBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = 1;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * (1 + margin/100),
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM62 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom63() {
        // Billing Profile: Client // Billing Condition: Margin Split 50:50 / 30%
        // maxCPA: null // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Budget';
        Decimal margin = 30, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, marginSplitBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, marginSplitBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = 1;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * margin/100 / (1 - margin/100),
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM63 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom64() {
        // Billing Profile: Client // Billing Condition: Margin Split 50:50 / 30%
        // maxCPA: null // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Media';
        Decimal margin = 30, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, marginSplitBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, marginSplitBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = 1;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * margin/100,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM64 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom65() {
        // Billing Profile: Client // Billing Condition: Margin Split 50:50 / 30%
        // maxCPA: null // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Budget';
        Decimal margin = 30, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, marginSplitBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, marginSplitBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = 1;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = CLIENT_SPEND - mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM65 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom66() {
        // Billing Profile: Client // Billing Condition: Margin Split 50:50 / 30%
        // maxCPA: null // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Media';
        Decimal margin = 30, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, marginSplitBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, marginSplitBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, marginSplitBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = 1;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = CLIENT_SPEND - mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM66 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }



    // Instant Rebate 50:50 / 50%, i.e. Margin 50%
    @IsTest static void testInvoiceCalculation_Custom67() {
        // Billing Profile: Client // Billing Condition: Instant Rebate 50:50 / 50%
        // maxCPA: null // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Media';
        Decimal margin = 50, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, instantRebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, instantRebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = 1;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = (CLIENT_SPEND - mediaSpend) * instantRebateBillingCondition.Strike_Profit__c/100,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM67 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom68() {
        // Billing Profile: Client // Billing Condition: Instant Rebate 50:50 / 50%
        // maxCPA: null // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Budget';
        Decimal margin = 50, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, instantRebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, instantRebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = 1;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = (CLIENT_SPEND - mediaSpend) * instantRebateBillingCondition.Strike_Profit__c/100,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM68 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom69() {
        // Billing Profile: Client // Billing Condition: Instant Rebate 50:50 / 50%
        // maxCPA: null // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Media';
        Decimal margin = 50, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, instantRebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, instantRebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = 1;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * margin/100 * instantRebateBillingCondition.Strike_Profit__c/100,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM69 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom70() {
        // Billing Profile: Client // Billing Condition: Instant Rebate 50:50 / 50%
        // maxCPA: null // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Budget';
        Decimal margin = 50, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, instantRebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, instantRebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = 1;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = mediaSpend * margin/100 / (1-margin/100) * instantRebateBillingCondition.Strike_Profit__c/100,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM70 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom71() {
        // Billing Profile: Strike // Billing Condition: Instant Rebate 50:50 / 50%
        // maxCPA: null // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Media';
        Decimal margin = 50, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, instantRebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, instantRebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = 1;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = (CLIENT_SPEND - mediaSpend) * instantRebateBillingCondition.Strike_Profit__c/100 + mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM71 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom72() {
        // Billing Profile: Strike // Billing Condition: Instant Rebate 50:50 / 50%
        // maxCPA: null // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Budget';
        Decimal margin = 50, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, instantRebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, instantRebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = 1;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = (CLIENT_SPEND - mediaSpend) * instantRebateBillingCondition.Strike_Profit__c/100 + mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM72 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom73() {
        // Billing Profile: Strike // Billing Condition: Instant Rebate 50:50 / 50%
        // maxCPA: null // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Media';
        Decimal margin = 50, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, instantRebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, instantRebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = 1;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];

        Decimal expectedInvoiceAmount = (CLIENT_SPEND - mediaSpend) * instantRebateBillingCondition.Strike_Profit__c/100 + mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM73 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom74() {
        // Billing Profile: Strike // Billing Condition: Instant Rebate 50:50 / 50%
        // maxCPA: null // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Budget';
        Decimal margin = 50, unitCost = null;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, instantRebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, instantRebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = 1;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = (CLIENT_SPEND - mediaSpend) * instantRebateBillingCondition.Strike_Profit__c/100 + mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM74 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom75() {
        // Billing Profile: Strike // Billing Condition: Instant Rebate 50:50 / 50%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Media';
        Decimal margin = 50, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, instantRebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, instantRebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = (CLIENT_SPEND - mediaSpend) * instantRebateBillingCondition.Strike_Profit__c/100 + mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM75 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom76() {
        // Billing Profile: Strike // Billing Condition: Instant Rebate 50:50 / 50%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Budget';
        Decimal margin = 50, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, instantRebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, instantRebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = (CLIENT_SPEND - mediaSpend) * instantRebateBillingCondition.Strike_Profit__c/100 + mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM76 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom77() {
        // Billing Profile: Strike // Billing Condition: Instant Rebate 50:50 / 50%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Media';
        Decimal margin = 50, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, instantRebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, instantRebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = (CLIENT_SPEND - mediaSpend) * instantRebateBillingCondition.Strike_Profit__c/100 + mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM77 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom78() {
        // Billing Profile: Strike // Billing Condition: Instant Rebate 50:50 / 50%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Budget';
        Decimal margin = 50, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, instantRebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, instantRebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = (CLIENT_SPEND - mediaSpend) * instantRebateBillingCondition.Strike_Profit__c/100 + mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM78 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom79() {
        // Billing Profile: Strike // Billing Condition: Instant Rebate 50:50 / 50%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Media';
        Decimal margin = 50, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, instantRebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, instantRebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = (CLIENT_SPEND - mediaSpend) * instantRebateBillingCondition.Strike_Profit__c/100 + mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM79 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom80() {
        // Billing Profile: Strike // Billing Condition: Instant Rebate 50:50 / 50%
        // maxCPA: 20% // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Budget';
        Decimal margin = 50, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, instantRebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, instantRebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = (CLIENT_SPEND - mediaSpend) * instantRebateBillingCondition.Strike_Profit__c/100 + mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM80 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom81() {
        // Billing Profile: Strike // Billing Condition: Instant Rebate 50:50 / 50%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Media';
        Decimal margin = 50, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, instantRebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, instantRebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = (CLIENT_SPEND - mediaSpend) * instantRebateBillingCondition.Strike_Profit__c/100 + mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM81 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom82() {
        // Billing Profile: Strike // Billing Condition: Instant Rebate 50:50 / 50%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Strike', marginType = '% of Budget';
        Decimal margin = 50, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, instantRebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, instantRebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = (CLIENT_SPEND - mediaSpend) * instantRebateBillingCondition.Strike_Profit__c/100 + mediaSpend,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM82 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom83() {
        // Billing Profile: Client // Billing Condition: Instant Rebate 50:50 / 50%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Media';
        Decimal margin = 50, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, instantRebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, instantRebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = (CLIENT_SPEND - mediaSpend) * instantRebateBillingCondition.Strike_Profit__c/100,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM83 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom84() {
        // Billing Profile: Client // Billing Condition: Instant Rebate 50:50 / 50%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Budget';
        Decimal margin = 50, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, instantRebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, instantRebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = (CLIENT_SPEND - mediaSpend) * instantRebateBillingCondition.Strike_Profit__c/100,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM84 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom85() {
        // Billing Profile: Client // Billing Condition: Instant Rebate 50:50 / 50%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Media';
        Decimal margin = 50, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, instantRebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, instantRebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = (CLIENT_SPEND - mediaSpend) * instantRebateBillingCondition.Strike_Profit__c/100,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM85 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom86() {
        // Billing Profile: Client // Billing Condition: Instant Rebate 50:50 / 50%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Budget';
        Decimal margin = 50, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, instantRebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, instantRebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered + 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = (CLIENT_SPEND - mediaSpend) * instantRebateBillingCondition.Strike_Profit__c/100,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM86 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom87() {
        // Billing Profile: Client // Billing Condition: Instant Rebate 50:50 / 50%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Media';
        Decimal margin = 50, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, instantRebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, instantRebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = (CLIENT_SPEND - mediaSpend) * instantRebateBillingCondition.Strike_Profit__c/100,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM79 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom88() {
        // Billing Profile: Client // Billing Condition: Instant Rebate 50:50 / 50%
        // maxCPA: 20% // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Budget';
        Decimal margin = 50, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, instantRebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, instantRebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = (CLIENT_SPEND - mediaSpend) * instantRebateBillingCondition.Strike_Profit__c/100,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM80 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom89() {
        // Billing Profile: Client // Billing Condition: Instant Rebate 50:50 / 50%
        // maxCPA: 20$ // Margin Type: '% of Media'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Media';
        Decimal margin = 50, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, instantRebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, instantRebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = (CLIENT_SPEND - mediaSpend) * instantRebateBillingCondition.Strike_Profit__c/100,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM81 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    @IsTest static void testInvoiceCalculation_Custom90() {
        // Billing Profile: Client // Billing Condition: Instant Rebate 50:50 / 50%
        // maxCPA: 20$ // Margin Type: '% of Budget'

        // INITIAL DATA:
        String billingProfile = 'Client', marginType = '% of Budget';
        Decimal margin = 50, unitCost = 20;

        Opportunity opp = createMeetingOppWithoutOppPlatform(billingProfile, instantRebateBillingCondition, CLIENT_SPEND, margin, marginType, true );
        createOpportunityPlatform_CPM_OR_NoCostStructure(opp.Id, unitCost, true);

        // Create related Contract (Campaign)
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;

        // Check Contract (Campaign) data
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);
        System.assertEquals(contract.BillingCondition__c, instantRebateBillingCondition.Id);
        System.assertEquals(contract.Account_Type__c, billingProfile);
        System.assertEquals(contract.Margin__c, margin);

        // Check Payment data
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        System.assertEquals(payment.Margin_Type__c, marginType);
        System.assertEquals(payment.Billing_Profile__c, billingProfile);
        System.assertEquals(payment.Contract_Billing_Condition_Id__c, instantRebateBillingCondition.Id);

        // Check Project data
        Payment__c project = contract.Payments__r[0];
        System.assertEquals(marginType, project.Margin_Type__c);
        System.assertEquals(unitCost, project.UnitCost__c);
        System.assertEquals(PROJECT_LENGTH_IN_DAYS, project.Start_Date__c.daysBetween(project.End_Date__c));
        System.debug('### project: ' + project);
        System.assertEquals(getMediaOrder(marginType, project.Client_Spend__c, margin), project.Media_Order__c);

        // if CPA is NOT null, it is required to compare Ordered (project.Quantity__c) and Delivered (Sum of MediaSpend.Delivered__c) units
        Integer ordered = (Integer) project.Quantity__c, delivered = ordered - 100;
        Decimal mediaOrder = project.Media_Order__c,
                mediaSpend = mediaOrder - DIFFERENCE_MEDIA_ORDER_TO_MEDIA_SPEND;

        Test.startTest();
        insert TestHelper.createMediaSpendings(contract.Id, project.End_Date__c, delivered, mediaSpend, adWordPlatform.Id, '');
        payment.Checked__c = true;
        update payment;
        Test.stopTest();

        contract = getContractByOppId(opp.Id);
        payment = contract.Sub_Projects__r[0];
        Decimal expectedInvoiceAmount = (CLIENT_SPEND - mediaSpend) * instantRebateBillingCondition.Strike_Profit__c/100,
                actualInvoiceAmount = payment.Invoice_Amount__c;

        System.debug('### Ordered: ' +  ordered + ' Actual Rebate: ' + contract.Actual_Rebate__c);
        System.debug('### GrossProfit Expected: ' +  contract.Gross_Profit__c  + ' Actual: ' + contract.Actual_Gross_Profit__c);
        System.debug('### CUSTOM82 Expected: ' + expectedInvoiceAmount.setScale(2) + ' Actual: ' + actualInvoiceAmount.setScale(2));
        System.assertEquals(expectedInvoiceAmount.setScale(2), actualInvoiceAmount.setScale(2));
    }

    // OLD SCENARIOS
    private static Sub_Project__c getPaymentById(Id paymentId) {
        return SubProjectRepository.getSubProjectsByIDs(new Set<Id>{paymentId})[0];
    }

    private static Opportunity create1MonthOpportunityWithoutOppPlatform(Utility.BILLING_PROFILES billingProfile, BillingCondition__c bc, Decimal clientSpend, Decimal margin, String marginType) {
        if (bc == null) bc = TestHelper.createBillingCondition('Normal');
        if (bc.Id == null) insert bc;

        Date startDate = Date.newInstance(System.today().addMonths(1).year(), System.today().addMonths(1).month(), 1),
                endDate = startDate.addMonths(1).addDays(-1);

        Opportunity opportunityRecord = TestHelper.createOpportunity(billingProfile);
        opportunityRecord.Amount = clientSpend;
        opportunityRecord.BillingCondition__c = bc.Id;
        opportunityRecord.Percent_Margin__c = margin;
        opportunityRecord.Payment_Type__c = 'Net 30';
        opportunityRecord.Flight_Start__c = startDate;
        opportunityRecord.Flight_End__c = endDate;
        opportunityRecord.StageName = 'Meeting';
        opportunityRecord.Margin_Type__c = marginType;

        return opportunityRecord;
    }

    private static Opportunity prepare1MonthOpportunity(Utility.BILLING_PROFILES billingProfile, String costStructure, String stage, BillingCondition__c bc) {
        Platform__c platform;
        if (costStructure == 'CPV') {
            platform = TestHelper.createTrueViewPlatform();
        } else {
            platform = TestHelper.createAdWordsPlatform();
        }
        insert platform;

        if (bc == null) bc = TestHelper.createBillingCondition('Normal');
        if (bc.Id == null) insert bc;

        Date startDate = Date.newInstance(System.today().addMonths(1).year(), System.today().addMonths(1).month(), 1),
                endDate = startDate.addMonths(1).addDays(-1);

        Opportunity opportunityRecord = TestHelper.createOpportunity(billingProfile);
        opportunityRecord.Amount = 100;
        opportunityRecord.BillingCondition__c = bc.Id;
        opportunityRecord.Percent_Margin__c = 21;
        opportunityRecord.Payment_Type__c = 'Net 30';
        opportunityRecord.Flight_Start__c = startDate;
        opportunityRecord.Flight_End__c = endDate;
        opportunityRecord.StageName = 'Meeting';
        insert opportunityRecord;

        OpportunityPlatform__c oppPlatformRecord = new OpportunityPlatform__c(
                Opportunity__c = opportunityRecord.Id,
                Platform__c = platform.Id,
                CostStructure__c = costStructure,
                CTA_Overlay_Text__c = 'CTA Test Text',
                Pixel_Tracking__c = 'Yes',
                KPI__c = 'Test KPI'
        );
        if (costStructure == 'CPV') {
            oppPlatformRecord.CPV__c = 0.1;
        } else {
            oppPlatformRecord.CPM__c = 200;
        }
        insert oppPlatformRecord;

        // Please assign platform before closing opportunity.
        opportunityRecord.StageName = stage;
        update opportunityRecord;

        return opportunityRecord;
    }

    @IsTest static void testInvoiceAmountRecalculationForActiveNotCheckedPayments_ByChangingBillingCondition() {
        Platform__c platform = TestHelper.createAdWordsPlatform();
        insert platform;

        BillingCondition__c rebate = TestHelper.createBillingCondition('Instant Rebate', true);

        Decimal clientSpend = 1000, margin = 10, unitCost = 200;
        String marginType = '% of Media';
        Integer paymentsAmount = 4;

        Opportunity oppWith4Payments = create1MonthOpportunityWithoutOppPlatform(Utility.BILLING_PROFILES.Client, rebate, clientSpend, margin, marginType);
        oppWith4Payments.Flight_Start__c = Date.newInstance(System.today().year(), System.today().addMonths(-2).month(), 1);
        oppWith4Payments.Flight_End__c = oppWith4Payments.Flight_Start__c.addMonths(paymentsAmount).addDays(-1);
        insert oppWith4Payments;

        OpportunityPlatform__c oppPlatform = new OpportunityPlatform__c(
                Opportunity__c = oppWith4Payments.Id, CPV__c = 0, CPM__c = 0, CostStructure__c = '', NoCostStructure__c = true,
                CTA_Overlay_Text__c = 'Text', Pixel_Tracking__c = 'Yes', KPI__c = 'KPI', Platform__c = platform.Id
        );
        insert oppPlatform;

        // create related contract record;
        oppWith4Payments.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update oppWith4Payments;

        Project__c contract = getContractByOppId(oppWith4Payments.Id);
        System.assertEquals(contract.Margin_Type__c, marginType);

        List<Payment__c> projects = contract.Payments__r;
        List<Sub_Project__c> payments = contract.Sub_Projects__r;
        System.assertEquals(payments.size(), paymentsAmount);
        System.assertEquals(projects.size(), paymentsAmount);

        List<Project_Media_Spend__c> cmsToInsert = new List<Project_Media_Spend__c>();
        // add one ContractMediaSpend for each month during campaign run
        for (Integer i = 0; i < paymentsAmount; i++) {
            Decimal delivered = projects[i].Quantity__c + 10,
                    mediaSpend = payments[i].Media_Order__c - 10;

            cmsToInsert.add(TestHelper.createMediaSpend(projects[i].Id, mediaSpend, delivered));
        }
        insert cmsToInsert;


        contract = getContractByOppId(oppWith4Payments.Id);
        payments = contract.Sub_Projects__r;
        // check that for all payments Invoice Amount != 0
        Map<Id, Decimal> paymentIdToInvoiceAmount = new Map<Id, Decimal>();
        Map<Id, Boolean> paymentIdToCheckedStatus = new Map<Id, Boolean>();
        Date beginningOfCurrentMonth = Date.newInstance(System.today().year(), System.today().month(), 1);
        for (Sub_Project__c payment :payments) {
            System.assert(payment.Invoice_Amount__c != 0);
            paymentIdToInvoiceAmount.put(payment.Id, payment.Invoice_Amount__c);
            if (payment.Start_Date__c < beginningOfCurrentMonth) {
                // the Checked__c doesn't allow to change invoice amount
                payment.Checked__c = true;
            }
            paymentIdToCheckedStatus.put(payment.Id, payment.Checked__c);
        }
        // setting Checked__c status;
        update payments;

        Test.startTest();
        BillingCondition__c normal = TestHelper.createBillingCondition('Normal', true);
        contract.BillingCondition__c = normal.Id;
        PaymentHandler.billingConditions = null;
        update contract;
        Test.stopTest();

        contract = getContractByOppId(oppWith4Payments.Id);
        projects = contract.Payments__r;
        payments = contract.Sub_Projects__r;
        System.assertEquals(payments.size(), paymentsAmount);
        System.assertEquals(projects.size(), paymentsAmount);

        for (Sub_Project__c payment :payments) {
            if (paymentIdToCheckedStatus.get(payment.Id)) {
                System.assertEquals(payment.Invoice_Amount__c, paymentIdToInvoiceAmount.get(payment.Id), 'Invoice Amount should not be recalculate for Checked payments.');
            } else {
                System.assertNotEquals(payment.Invoice_Amount__c, paymentIdToInvoiceAmount.get(payment.Id), 'Invoice Amount should be recalculate for Checked payments.');
            }
        }
    }

    @IsTest static void testInvoiceCalculationCPVScenario1Strike() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;
        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Strike, 'CPV', OpportunityRepository.STAGE_CLOSED_WON, normalBC);

        Project__c contract = getContractByOppId(opp.Id);
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];
        Double amount = 600,
                views = project.Quantity__c + 10,
                impressions = project.Quantity__c + 100;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        System.assertEquals(after.Client_Spend__c, after.Invoice_Amount__c);
    }

    @IsTest static void testInvoiceCalculationCPVScenario2Strike() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;
        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Strike, 'CPV', OpportunityRepository.STAGE_CLOSED_WON, normalBC);
        OpportunityPlatform__c opportunityPlatform = [SELECT CPV__c FROM OpportunityPlatform__c WHERE Opportunity__c = :opp.Id LIMIT 1];

        Project__c contract = getContractByOppId(opp.Id);
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];
        Double amount = 10, views = project.Quantity__c, impressions = 0;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        Decimal result = after.Delivered__c * opportunityPlatform.CPV__c ;
        System.assertEquals((result * 100).round() / 100, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPVScenario3Strike() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;
        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Strike, 'CPV', OpportunityRepository.STAGE_CLOSED_WON, normalBC);
        OpportunityPlatform__c opportunityPlatform = [SELECT CPV__c FROM OpportunityPlatform__c WHERE Opportunity__c = :opp.Id LIMIT 1];
        opportunityPlatform.CPV__c = null;
        update opportunityPlatform;

        Project__c contract = getContractByOppId(opp.Id);
        Payment__c project = contract.Payments__r[0];
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Double amount = 600, views = project.Quantity__c, impressions = 0;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        Decimal result = after.AdWordsSpend__c / (1 - payment.Margin__c / 100);
        System.assertEquals((result * 100).round() / 100, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPVScenario4Client() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;
        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Client, 'CPV', OpportunityRepository.STAGE_CLOSED_WON, normalBC);
        //OpportunityPlatform__c opportunityPlatform = [SELECT CPV__c FROM OpportunityPlatform__c WHERE Opportunity__c = :opp.Id LIMIT 1];

        Project__c contract = getContractByOppId(opp.Id);
        Payment__c project = contract.Payments__r[0];
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Double amount = payment.Media_Order__c + 1, views = project.Quantity__c + 100, impressions = 0;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        Decimal result = after.Client_Spend__c - after.AdWordsSpend__c;
        System.assertEquals((result * 100).round() / 100, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPVScenario5Client() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;
        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Client, 'CPV', OpportunityRepository.STAGE_CLOSED_WON, normalBC);
        //OpportunityPlatform__c opportunityPlatform = [SELECT CPV__c FROM OpportunityPlatform__c WHERE Opportunity__c = :opp.Id LIMIT 1];

        Project__c contract = getContractByOppId(opp.Id);
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];
        Double amount = 2, views = project.Quantity__c + 1, impressions = 0;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        Decimal result = after.AdWordsSpend__c * (payment.Margin__c / 100) / (1 - payment.Margin__c / 100);
        System.assertEquals((result * 100).round() / 100, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPVScenario7Client() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;
        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Client, 'CPV', OpportunityRepository.STAGE_CLOSED_WON, normalBC);

        //OpportunityPlatform__c opportunityPlatform = [SELECT CPV__c FROM OpportunityPlatform__c WHERE Opportunity__c = :opp.Id LIMIT 1];

        Project__c contract = getContractByOppId(opp.Id);
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];
        Double amount = 1, views = project.Quantity__c - 1, impressions = 0;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        Decimal result = after.AdWordsSpend__c * (after.Margin__c / 100) / (1 - after.Margin__c / 100);
        System.assertEquals((result * 100).round() / 100, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPVScenario6Client() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;
        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Client, 'CPV', OpportunityRepository.STAGE_CLOSED_WON, normalBC);

        OpportunityPlatform__c opportunityPlatform = [SELECT CPV__c FROM OpportunityPlatform__c WHERE Opportunity__c = :opp.Id LIMIT 1];
        Project__c contract = getContractByOppId(opp.Id);
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];
        Double amount = (project.Quantity__c - 10) * opportunityPlatform.CPV__c * (1 - payment.Margin__c/100) + 1,
                views = project.Quantity__c - 10,
                impressions = 0;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        Decimal result = after.Delivered__c * opportunityPlatform.CPV__c  - after.AdWordsSpend__c;
        System.assertEquals((result * 100).round() / 100, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPVScenario8Client() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;
        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Client, 'CPV', OpportunityRepository.STAGE_CLOSED_WON, normalBC);

        OpportunityPlatform__c opportunityPlatform = [SELECT CPV__c FROM OpportunityPlatform__c WHERE Opportunity__c = :opp.Id LIMIT 1];
        opportunityPlatform.CPV__c = null;
        update opportunityPlatform;

        Project__c contract = getContractByOppId(opp.Id);
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];
        Double amount = payment.Media_Order__c + 1,
                views = project.Quantity__c - 10,
                impressions = 0;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        Decimal result = after.Client_Spend__c - after.AdWordsSpend__c;
        System.assertEquals((result * 100).round() / 100, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPVScenario9Client() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;
        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Client, 'CPV', OpportunityRepository.STAGE_CLOSED_WON, normalBC);

        OpportunityPlatform__c opportunityPlatform = [SELECT CPV__c FROM OpportunityPlatform__c WHERE Opportunity__c = :opp.Id LIMIT 1];
        opportunityPlatform.CPV__c = null;
        update opportunityPlatform;

        Project__c contract = getContractByOppId(opp.Id);
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];
        Double amount = payment.Media_Order__c - 1,
                views = project.Quantity__c - 1,
                impressions = 0;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        Decimal result = after.AdWordsSpend__c * (payment.Margin__c / 100) / (1 - payment.Margin__c / 100);
        System.assertEquals((result * 100).round() / 100, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPVScenario16Strike() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;
        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Strike, 'CPV', OpportunityRepository.STAGE_CLOSED_WON, normalBC);

        //OpportunityPlatform__c opportunityPlatform = [SELECT CPV__c FROM OpportunityPlatform__c WHERE Opportunity__c = :opp.Id LIMIT 1];
        Project__c contract = getContractByOppId(opp.Id);
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];
        Double amount = payment.Media_Order__c + 10,
                views = project.Quantity__c + 10,
                impressions = 0;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        //Decimal result = (after.Client_Spend__c - after.AdWordsSpend__c) * 2 / 3 + after.AdWordsSpend__c;
        System.assertEquals(100, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPVScenario17Strike() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;
        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Strike, 'CPV', OpportunityRepository.STAGE_CLOSED_WON, normalBC);

        //OpportunityPlatform__c opportunityPlatform = [SELECT CPV__c FROM OpportunityPlatform__c WHERE Opportunity__c = :opp.Id LIMIT 1];
        Project__c contract = getContractByOppId(opp.Id);
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];
        Double amount = payment.Media_Order__c - 1,
                views = project.Quantity__c + 1,
                impressions = 0;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        //Decimal result = (after.AdWordsSpend__c * (payment.Margin__c / 100) / (1 - payment.Margin__c / 100)) * 2 / 3 + after.AdWordsSpend__c;
        System.assertEquals(100, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPVScenario18Strike() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;
        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Strike, 'CPV', OpportunityRepository.STAGE_CLOSED_WON, normalBC);

        OpportunityPlatform__c opportunityPlatform = [SELECT CPV__c FROM OpportunityPlatform__c WHERE Opportunity__c = :opp.Id LIMIT 1];
        Project__c contract = getContractByOppId(opp.Id);
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];
        Double amount = (project.Quantity__c - 10) * opportunityPlatform.CPV__c  * (1 - payment.Margin__c/100) + 1,
                views = project.Quantity__c,
                impressions = 0;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        //Decimal result = (after.Delivered__c * oppPlatform.CPV__c - after.AdWordsSpend__c) * 2 / 3 + after.AdWordsSpend__c;
        System.assertEquals(100, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPVScenario19Strike() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;
        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Strike, 'CPV', OpportunityRepository.STAGE_CLOSED_WON, normalBC);

        OpportunityPlatform__c opportunityPlatform = [SELECT CPV__c FROM OpportunityPlatform__c WHERE Opportunity__c = :opp.Id LIMIT 1];
        Project__c contract = getContractByOppId(opp.Id);
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];

        Double amount = (project.Quantity__c - 10) * opportunityPlatform.CPV__c  * (1 - payment.Margin__c/100) - 1,
                views = project.Quantity__c,
                impressions = 0;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        //Decimal result = (after.AdWordsSpend__c * (payment.Margin__c / 100) / ( 1 - payment.Margin__c / 100)) * 2 / 3 + after.AdWordsSpend__c;
        System.assertEquals(100, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPVScenario20Strike() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;
        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Strike, 'CPV', OpportunityRepository.STAGE_CLOSED_WON, normalBC);

        OpportunityPlatform__c opportunityPlatform = [SELECT CPV__c FROM OpportunityPlatform__c WHERE Opportunity__c = :opp.Id LIMIT 1];
        opportunityPlatform.CPV__c = null;
        update opportunityPlatform;

        Project__c contract = getContractByOppId(opp.Id);
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];
        Double amount = payment.Media_Order__c + 10,
                views = project.Quantity__c - 10,
                impressions = 0;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        //Decimal result = (after.Client_Spend__c - after.AdWordsSpend__c) * 2 / 3 + after.AdWordsSpend__c;
        System.assertEquals(112, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPVScenario21Strike() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;
        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Strike, 'CPV', OpportunityRepository.STAGE_CLOSED_WON, normalBC);

        OpportunityPlatform__c opportunityPlatform = [SELECT CPV__c FROM OpportunityPlatform__c WHERE Opportunity__c = :opp.Id LIMIT 1];
        opportunityPlatform.CPV__c = null;
        update opportunityPlatform;

        Project__c contract = getContractByOppId(opp.Id);
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];
        Double amount = payment.Media_Order__c - 1,
                views = project.Quantity__c - 1,
                impressions = 0;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        //Decimal result = (after.AdWordsSpend__c * (payment.Margin__c / 100) / (1 - payment.Margin__c / 100)) * 2 / 3 + after.AdWordsSpend__c;
        System.assertEquals(98, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPMScenario1Strike() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;
        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Strike, 'CPM', OpportunityRepository.STAGE_CLOSED_WON, normalBC);

        Project__c contract = getContractByOppId(opp.Id);
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];
        Double amount = 600,
                views = 0,
                impressions = project.Quantity__c + 100;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        System.assertEquals(after.Client_Spend__c, after.Invoice_Amount__c);
    }

    @IsTest static void testInvoiceCalculationCPMScenario2Strike() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;
        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Strike, 'CPM', OpportunityRepository.STAGE_CLOSED_WON, normalBC);

        OpportunityPlatform__c opportunityPlatform = [SELECT CPM__c FROM OpportunityPlatform__c WHERE Opportunity__c = :opp.Id LIMIT 1];
        Project__c contract = getContractByOppId(opp.Id);
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];
        Double amount = 600,
                views = 0,
                impressions = project.Quantity__c;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        Decimal result = after.Delivered__c * opportunityPlatform.CPM__c / 1000;
        System.assertEquals((result * 100).round() / 100, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPMScenario3Strike() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;
        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Strike, 'CPM', OpportunityRepository.STAGE_CLOSED_WON, normalBC);

        OpportunityPlatform__c opportunityPlatform = [SELECT CPM__c FROM OpportunityPlatform__c WHERE Opportunity__c = :opp.Id LIMIT 1];
        opportunityPlatform.CPM__c = null;
        update opportunityPlatform;

        Project__c contract = getContractByOppId(opp.Id);
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];
        Double amount = 600,
                views = 0,
                impressions = project.Quantity__c - 1;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        update project;

        Sub_Project__c after = getPaymentById(payment.Id);
        Decimal result = after.AdWordsSpend__c / (1 - payment.Margin__c / 100);
        System.assertEquals((result * 100).round() / 100, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPMScenario4Client() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;
        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Client, 'CPM', OpportunityRepository.STAGE_CLOSED_WON, normalBC);

        Project__c contract = getContractByOppId(opp.Id);
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];
        Double amount = payment.Media_Order__c + 1,
                views = 0,
                impressions = project.Quantity__c + 100;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        Decimal result = after.Client_Spend__c - after.AdWordsSpend__c;
        System.assertEquals((result * 100).round() / 100, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPMScenario5Client() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;
        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Client, 'CPM', OpportunityRepository.STAGE_CLOSED_WON, normalBC);

        Project__c contract = getContractByOppId(opp.Id);
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];
        Double amount = 2,
                views = 0,
                impressions = project.Quantity__c + 1;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        Decimal result = after.AdWordsSpend__c * (payment.Margin__c / 100) / (1 - payment.Margin__c / 100);
        System.assertEquals((result * 100).round() / 100, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPMScenario7Client() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;
        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Client, 'CPM', OpportunityRepository.STAGE_CLOSED_WON, normalBC);

        Project__c contract = getContractByOppId(opp.Id);
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];
        Double amount = 1,
                views = 0,
                impressions = project.Quantity__c - 1;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        Decimal result = after.AdWordsSpend__c * (payment.Margin__c / 100) / (1 - payment.Margin__c / 100);
        System.assertEquals((result * 100).round() / 100, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPMScenario6Client() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;
        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Client, 'CPM', 'Meeting', normalBC);

        Test.startTest();
        opp.StageName = OpportunityRepository.STAGE_CLOSED_WON;
        update opp;
        Test.stopTest();

        OpportunityPlatform__c opportunityPlatform = [SELECT CPM__c FROM OpportunityPlatform__c WHERE Opportunity__c = :opp.Id LIMIT 1];

        Project__c contract = getContractByOppId(opp.Id);
        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Decimal result = payment.Delivered__c * opportunityPlatform.CPM__c / 1000 - payment.AdWordsSpend__c;
        System.assertEquals((result * 100).round() / 100, (payment.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPMScenario8Client() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;

        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Client, 'CPM', OpportunityRepository.STAGE_CLOSED_WON, normalBC);
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(opp.BillingCondition__c, normalBC.Id);
        System.assertEquals(contract.BillingCondition__c, normalBC.Id);

        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];
        Double amount = payment.Media_Order__c + 1,
                views = 0,
                impressions = project.Quantity__c;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        Decimal result = after.Client_Spend__c - after.AdWordsSpend__c;
        System.assertEquals((result * 100).round() / 100, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPMScenario9Client() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;

        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Client, 'CPM', OpportunityRepository.STAGE_CLOSED_WON, normalBC);
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(opp.BillingCondition__c, normalBC.Id);
        System.assertEquals(contract.BillingCondition__c, normalBC.Id);

        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];
        Double amount = payment.Media_Order__c - 1,
                views = 0,
                impressions = project.Quantity__c - 1;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        Decimal result = after.AdWordsSpend__c * (payment.Margin__c / 100) / (1 - payment.Margin__c / 100);
        System.assertEquals((result * 100).round() / 100, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPMScenario16Strike() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;

        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Strike, 'CPM', OpportunityRepository.STAGE_CLOSED_WON, normalBC);
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(opp.BillingCondition__c, normalBC.Id);
        System.assertEquals(contract.BillingCondition__c, normalBC.Id);

        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];
        Double amount = payment.Media_Order__c + 10,
                views = 0,
                impressions = project.Quantity__c + 10;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        Decimal result = (after.Client_Spend__c - after.AdWordsSpend__c) * 2 / 3 + after.AdWordsSpend__c;
        System.assertEquals(100, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPMScenario17Strike() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;

        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Strike, 'CPM', OpportunityRepository.STAGE_CLOSED_WON, normalBC);
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(opp.BillingCondition__c, normalBC.Id);
        System.assertEquals(contract.BillingCondition__c, normalBC.Id);

        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];
        Double amount = payment.Media_Order__c,
                views = 0,
                impressions = project.Quantity__c + 10;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        Decimal result = (after.AdWordsSpend__c * (payment.Margin__c / 100) / (1 - payment.Margin__c / 100)) * 2 / 3 + after.AdWordsSpend__c;
        System.assertEquals(100, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPMScenario18Strike() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;

        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Strike, 'CPM', OpportunityRepository.STAGE_CLOSED_WON, normalBC);
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(opp.BillingCondition__c, normalBC.Id);
        System.assertEquals(contract.BillingCondition__c, normalBC.Id);

        OpportunityPlatform__c opportunityPlatform = [SELECT CPM__c FROM OpportunityPlatform__c WHERE Opportunity__c = :opp.Id LIMIT 1];

        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];
        Double amount = (project.Quantity__c - 10) * opportunityPlatform.CPM__c / 1000 * (1 - payment.Margin__c/100) + 1,
                views = 0,
                impressions = project.Quantity__c - 10;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        Decimal result = (after.Delivered__c * opportunityPlatform.CPM__c/1000 - after.AdWordsSpend__c) * 2 / 3 + after.AdWordsSpend__c;
        System.assertEquals(98, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPMScenario19Strike() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;

        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Strike, 'CPM', OpportunityRepository.STAGE_CLOSED_WON, normalBC);
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(opp.BillingCondition__c, normalBC.Id);
        System.assertEquals(contract.BillingCondition__c, normalBC.Id);

        OpportunityPlatform__c opportunityPlatform = [SELECT CPM__c FROM OpportunityPlatform__c WHERE Opportunity__c = :opp.Id LIMIT 1];

        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];
        Double amount = (project.Quantity__c - 10) * opportunityPlatform.CPM__c / 1000 * (1 - payment.Margin__c/100) - 1, views = 0, impressions = project.Quantity__c - 10;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        Decimal result = (after.AdWordsSpend__c * (payment.Margin__c / 100) / ( 1 - payment.Margin__c / 100)) * 2 / 3 + after.AdWordsSpend__c;
        System.assertEquals(98, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPMScenario20Strike() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;

        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Strike, 'CPM', OpportunityRepository.STAGE_CLOSED_WON, normalBC);
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(opp.BillingCondition__c, normalBC.Id);
        System.assertEquals(contract.BillingCondition__c, normalBC.Id);

        OpportunityPlatform__c opportunityPlatform = [SELECT CPM__c FROM OpportunityPlatform__c WHERE Opportunity__c = :opp.Id LIMIT 1];
        opportunityPlatform.CPM__c = null;
        update opportunityPlatform;

        Sub_Project__c payment = contract.Sub_Projects__r[0];
        Payment__c project = contract.Payments__r[0];
        Double amount = payment.Media_Order__c + 10, views = 0, impressions = project.Quantity__c;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        Decimal result = (after.Client_Spend__c - after.AdWordsSpend__c) * 2 / 3 + after.AdWordsSpend__c;
        System.assertEquals(112, (after.Invoice_Amount__c * 100).round() / 100);
    }

    @IsTest static void testInvoiceCalculationCPMScenario21Strike() {
        BillingCondition__c normalBC = TestHelper.createBillingCondition('Normal', false);
        insert normalBC;

        Opportunity opp = prepare1MonthOpportunity(Utility.BILLING_PROFILES.Strike, 'CPM', OpportunityRepository.STAGE_CLOSED_WON, normalBC);
        Project__c contract = getContractByOppId(opp.Id);
        System.assertEquals(opp.BillingCondition__c, normalBC.Id);
        System.assertEquals(contract.BillingCondition__c, normalBC.Id);

        Sub_Project__c payment = contract.Sub_Projects__r[0];

        Payment__c project = contract.Payments__r[0];
        Double amount = payment.Media_Order__c, views = 0, impressions = project.Quantity__c;

        Test.startTest();
        TestHelper.createMediaSpend(project.Id, amount, views, impressions);
        Test.stopTest();

        Sub_Project__c after = getPaymentById(payment.Id);
        Decimal result = (after.AdWordsSpend__c * (payment.Margin__c / 100) / (1 - payment.Margin__c / 100)) * 2 / 3 + after.AdWordsSpend__c;
        System.assertEquals(100, (after.Invoice_Amount__c * 100).round() / 100);
    }
}