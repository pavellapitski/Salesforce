@isTest
private class CreditNotesNotificationCtrlTest {

    static testMethod void willDisplayPendingCreditNotes() 
    {
        Account acc = TestHelper.createAccount();
        Project__c contract = TestHelper.createContract(acc.Id);
        
        Sub_Project__c payment = [SELECT Id FROM Sub_Project__c WHERE Project__c = :contract.Id LIMIT 1];
        payment.XeroStatus__c = SubProject.XERO_STATUS_SUBMITTED;
        update payment;
        
        CreditNote__c creditNotePending = TestHelper.createCreditNoteNoInsert(payment.Id);         
        CreditNote__c creditNoteApproved = TestHelper.createCreditNoteNoInsert(payment.Id);
        creditNotePending.Status__c = CreditNote.STATUS_SUBMITTED;
        creditNoteApproved.Status__c = CreditNote.STATUS_AUTHORISED;
        
        insert new List<CreditNote__c> { creditNotePending, creditNoteApproved };
        
        test.startTest();
        
            CreditNotesNotificationCtrl ctrl = new CreditNotesNotificationCtrl();
        
        test.stopTest();
        
        System.assertEquals(1, ctrl.creditNotes.size());
        System.assertEquals(1, ctrl.payments.size());
    }
}