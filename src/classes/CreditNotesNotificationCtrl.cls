public class CreditNotesNotificationCtrl {

    public String instanceUrl {get; set;}
    public List<CreditNote__c> creditNotes {get; set;}
    public List<Sub_Project__c> payments {get; set;}
    
    public CreditNotesNotificationCtrl() {
    
        creditNotes = CreditNoteRepository.getPendingCreditNotes(NULL, NULL, 'CreatedDate', 'ASC');
        payments = SubProjectRepository.getPaymentsSubmittedToXero();
        instanceUrl = System.URL.getSalesforceBaseUrl().toExternalForm();
    }
}