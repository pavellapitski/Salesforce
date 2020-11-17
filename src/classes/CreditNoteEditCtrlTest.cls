@IsTest
public class CreditNoteEditCtrlTest {

    @IsTest static void testSendCreditNote() {
        xeroSettings__c xs = TestHelper.createXeroEntity();
        Project__c contract = TestHelper.createContract(TestHelper.createAccount().Id); 
        contract.Xero_Entity__c = xs.Id;
        
        Sub_Project__c payment = [SELECT Id, Project__c FROM Sub_Project__c LIMIT 1];
        payment.Xero_Id__c ='TESTXEROID1234';
        update payment;
        update contract;

        CreditNote__c creditNoteObj = TestHelper.createCreditNoteNoInsert(payment.Id);
        creditNoteObj.XeroId__c = '';
        creditNoteObj.Status__c = '';
        insert creditNoteObj;
        
        Test.startTest();
        XeroWrappers.XeroCreditNote xeroCreditNote = XeroTestHelper.createXeroCreditNote(CreditNoteRepository.getCreditNoteById(creditNoteObj.Id));
        xeroCreditNote.CreditNoteId = 'testCreditNoteXeroId';
        xeroCreditNote.Status = XeroWrappers.XeroCreditNoteStatus.SUBMITTED;

        XeroTestHelper.xeroCreditNotes.add(xeroCreditNote);

        Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());

        ApexPages.StandardController stdController = new ApexPages.StandardController(creditNoteObj);
        CreditNoteEditCtrl controller = new CreditNoteEditCtrl(stdController);
        controller.sendCreditNote();
        Test.stopTest();
        
        creditNoteObj = [SELECT Status__c, XeroId__c FROM CreditNote__c WHERE Id = :creditNoteObj.Id];
        System.assertEquals(xeroCreditNote.CreditNoteId, creditNoteObj.XeroId__c);
        System.assertEquals(CreditNote.STATUS_SUBMITTED, creditNoteObj.Status__c);
    }

    @IsTest static void testSaveCreditNote() {
        Account acc = TestHelper.createAccount();
        Project__c contract = TestHelper.createContract(acc.Id);
        
        Sub_Project__c payment = [SELECT Id FROM Sub_Project__c LIMIT 1];
        
        Test.startTest();
        System.assertEquals(0, [SELECT Id FROM CreditNote__c].size());
        PageReference pageRef = Page.CreditNoteEdit;
        ApexPages.currentPage().getParameters().put('paymentId', payment.Id);
        CreditNote__c creditNoteObj = new CreditNote__c();

        CreditNoteEditCtrl controller = new CreditNoteEditCtrl(new ApexPages.StandardController(creditNoteObj));
        controller.creditNote.Description__c = 'Description';
        controller.creditNote.Amount__c = 100;
        controller.saveCreditNote();
		Test.stopTest();
        
        System.assertEquals(100, [SELECT Amount__c FROM CreditNote__c LIMIT 1].Amount__c);
    }
}