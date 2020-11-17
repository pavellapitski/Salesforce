@IsTest
private class MonthlyDistributionTest {

    static testMethod void willCreateMonhlyDistributionOnInsert() {
        Project__c contract = TestHelper.createContractNoInsert(TestHelper.createAccount().Id, 'testContract', null);
        contract.Start_Date__c = Date.newInstance(System.today().year(), 3, 1);
        contract.End_Date__c = contract.Start_Date__c.addMonths(4).addDays(-1);
        contract.Gaps_Exist_Between_Projects__c = true;
        contract.Client_Spend__c = 200;
        insert contract;

        delete [SELECT Id FROM Sub_Project__c];

        Sub_Project__c payment1 = TestHelper.createPaymentNoInsert(contract);
        payment1.End_Date__c = payment1.Start_Date__c.addMonths(1).addDays(15);
        payment1.Client_Spend__c = 100;

        Sub_Project__c payment2 = TestHelper.createPaymentNoInsert(contract);
        payment2.Start_Date__c = payment1.End_Date__c.addDays(1);
        payment2.Client_Spend__c = 100;

        Test.startTest();
        insert new List<Sub_Project__c> {payment1, payment2};
        Test.stopTest();

        List<Monthly_Distribution__c> payment1Distributions = [
            SELECT Id, Client_Spend__c, Actual_Gross_Profit__c, Expected_Gross_Profit__c, Expected_Revenue__c, Actual_Revenue__c
            FROM Monthly_Distribution__c
            WHERE Project__c IN (SELECT Id FROM Payment__c WHERE Payment__c= :payment1.Id)
            ORDER BY Start_Date__c
        ];
        List<Monthly_Distribution__c> payment2Distributions = [
            SELECT Id, Client_Spend__c, Actual_Gross_Profit__c, Expected_Gross_Profit__c, Expected_Revenue__c, Actual_Revenue__c
            FROM Monthly_Distribution__c
            WHERE Project__c IN (SELECT Id FROM Payment__c WHERE Payment__c= :payment2.Id)
            ORDER BY Start_Date__c
        ];

        System.assertEquals(2, payment1Distributions.size());
        System.assertEquals(3, payment2Distributions.size());

        Integer payment1Length = payment1.Start_Date__c.daysBetween(payment1.End_Date__c) + 1;
        Integer payment2Length = payment2.Start_Date__c.daysBetween(payment2.End_Date__c) + 1;

        System.assertEquals((payment1.Client_Spend__c/payment1Length*31).setScale(4, System.RoundingMode.HALF_DOWN), payment1Distributions[0].Client_Spend__c);
        System.assertEquals(payment1.Client_Spend__c, payment1Distributions[0].Client_Spend__c + payment1Distributions[1].Client_Spend__c);

        System.assertEquals((payment2.Client_Spend__c/payment2Length*31).setScale(4, System.RoundingMode.HALF_DOWN), payment2Distributions[1].Client_Spend__c);
        System.assertEquals(payment2.Client_Spend__c, payment2Distributions[0].Client_Spend__c + payment2Distributions[1].Client_Spend__c + payment2Distributions[2].Client_Spend__c);
    }

    static testMethod void willUpdateMonhlyDistribution() {
        Project__c contract = TestHelper.createContractNoInsert(TestHelper.createAccount().Id, 'testContract', null);
        contract.Start_Date__c = Date.newInstance(System.today().year(), 3, 1);
        contract.End_Date__c = contract.Start_Date__c.addMonths(1).addDays(-1);
        contract.Gaps_Exist_Between_Projects__c = true;
        insert contract;

        List<Sub_Project__c> payments = [SELECT Id, Client_Spend__c, Project__c FROM Sub_Project__c];

        Test.startTest();
        contract.Client_Spend__c = 200;
        update contract;
        Test.stopTest();

        List<Monthly_Distribution__c> paymentDistributions = [
            SELECT Id, Client_Spend__c, Actual_Gross_Profit__c, Expected_Gross_Profit__c, Expected_Revenue__c, Actual_Revenue__c
            FROM Monthly_Distribution__c
            WHERE Project__c IN (SELECT Id FROM Payment__c WHERE Payment__c= :payments[0].Id)
            ORDER BY Start_Date__c
        ];
        System.assertEquals(contract.Client_Spend__c, [SELECT Client_Spend__c FROM Payment__c WHERE Payment__c = :payments[0].Id].Client_Spend__c);
        System.assertEquals(contract.Client_Spend__c, paymentDistributions[0].Client_Spend__c);
    }

    static testMethod void willAssignSalesRepMonthlyDistributionOnSalesRepInsert() {
        Project__c contract1 = TestHelper.createContractNoInsert(TestHelper.createAccount().Id, 'testContract1', null);
        contract1.Start_Date__c = Date.newInstance(System.today().year(), 3, 1);
        contract1.End_Date__c = contract1.Start_Date__c.addMonths(1).addDays(-1);
        insert contract1;

        Test.startTest();
        Contract_Sales_Rep__c salesRepContract1 = TestHelper.createContractSalesRepNoInsert(contract1.Id);
        insert salesRepContract1;
        Test.stopTest();

        List<Sales_Rep_MD__c> salesRepContract1Assignments = [
            SELECT Id
            FROM Sales_Rep_MD__c
            WHERE Sales_Rep__c = :salesRepContract1.Id AND Monthly_Distribution__r.Project__r.Payment__r.Project__c = :contract1.Id
        ];
        System.assertEquals(1, salesRepContract1Assignments.size());
    }

    static testMethod void willAssignSalesRepMonthlyDistributionOnMonthlyDistributionInsert() {
        Project__c contract1 = TestHelper.createContractNoInsert(TestHelper.createAccount().Id, 'testContract1', null);
        contract1.Start_Date__c = Date.newInstance(System.today().year(), 3, 1);
        contract1.End_Date__c = contract1.Start_Date__c.addMonths(1).addDays(-1);
        contract1.Gaps_Exist_Between_Projects__c = true;
        contract1.Client_Spend__c = 100;
        insert contract1;

        Contract_Sales_Rep__c salesRepContract1 = TestHelper.createContractSalesRepNoInsert(contract1.Id);
        insert salesRepContract1;

        delete [SELECT Id FROM Sub_Project__c];

        Test.startTest();
        Sub_Project__c paymentContract1 = TestHelper.createPaymentNoInsert(contract1);
        paymentContract1.Start_Date__c = contract1.Start_Date__c;
        paymentContract1.End_Date__c = contract1.End_Date__c;
        paymentContract1.Client_Spend__c = 100;
        insert new List<Sub_Project__c> {paymentContract1};
        Test.stopTest();

        List<Sales_Rep_MD__c> salesRepContract1Assignments = [
            SELECT Id
            FROM Sales_Rep_MD__c
            WHERE Sales_Rep__c = :salesRepContract1.Id AND Monthly_Distribution__r.Project__r.Payment__r.Project__c = :contract1.Id
        ];
    }

    @IsTest static void beforeInsert_setBrandLookup(){
        Project__c contract = TestHelper.createContractNoInsert(TestHelper.createAccount().Id, 'testContract', null);
        contract.Start_Date__c = Date.newInstance(System.today().year(), 3, 1);
        contract.End_Date__c = contract.Start_Date__c.addMonths(4).addDays(-1);
        contract.Gaps_Exist_Between_Projects__c = true;
        contract.Client_Spend__c = 200;

        Test.startTest();
        insert contract;
        Test.stopTest();

        Monthly_Distribution__c result = [SELECT Brand_Lookup__c FROM Monthly_Distribution__c LIMIT 1];
        Project__c expected = [SELECT Brand__r.Id FROM Project__c WHERE Id=:contract.Id];
        System.assertEquals(expected.Brand__r.Id, result.Brand_Lookup__c);
    }
}