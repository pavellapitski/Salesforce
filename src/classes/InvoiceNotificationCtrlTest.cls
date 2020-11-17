@isTest
private class InvoiceNotificationCtrlTest {

    static testMethod void testDisplayInvoices() {
        Account acc = TestHelper.createAccount();
        User usr = TestHelper.createUser();

        Opportunity opp1 = TestHelper.createOpportunity(usr, acc);
        Opportunity opp2 = TestHelper.createOpportunity(usr, acc);
        insert new List<Opportunity> {opp1, opp2};

        Project__c contract1 = TestHelper.createContractNoInsert(acc.Id, 'contract1', opp1.Id);
        contract1.Gaps_Exist_Between_Projects__c = true;

        Project__c contract2 = TestHelper.createContractNoInsert(acc.Id, 'contract2', opp2.Id);
        contract2.Gaps_Exist_Between_Projects__c = true;
        contract2.ClientServicesRep__c = TestHelper.createClientServiceUser().Id;
        insert new List<Project__c> {contract1, contract2};

        Test.startTest();
            delete [SELECT Id FROM Sub_Project__c];

            Sub_Project__c payment1 = TestHelper.createPaymentNoInsert(contract1);
            Sub_Project__c payment2 = TestHelper.createPaymentNoInsert(contract2);
            insert new List<Sub_Project__c> {payment1, payment2};

            MM_Spendings__c mmSpending1 = TestHelper.createMediaSpendings(contract1.Id, contract1.End_Date__c);
            MM_Spendings__c mmSpending2 = TestHelper.createMediaSpendings(contract2.Id, contract2.End_Date__c);
            insert new List<MM_Spendings__c>{mmSpending1, mmSpending2};

            InvoiceNotificationCtrl ctrl = new InvoiceNotificationCtrl();
            ctrl.ClientService = contract2.ClientServicesRep__c;
        Test.stopTest();

        System.assertEquals(1, ctrl.getPayments().size());
    }
}