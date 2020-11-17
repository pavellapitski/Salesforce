public with sharing class CreditNoteEditCtrl {
    
    private ApexPages.StandardController stdController;
    
    public CreditNote__c creditNote {get; set;}
    public Boolean isSuccess {get; set;}
    
    public CreditNoteEditCtrl(ApexPages.StandardController stdController) {
        this.stdController = stdController;  
        this.creditNote = (CreditNote__c)stdController.getRecord();  
        
        if (String.isNotBlank(creditNote.Id)) {
        	creditNote = CreditNoteRepository.getCreditNoteById(creditNote.Id);                
        }
        if (ApexPages.currentPage().getParameters().containsKey('paymentId')) {
            creditNote.Payment__c = ApexPages.currentPage().getParameters().get('paymentId');            
        }
        isSuccess = true;
    }
    
    public void saveCreditNote() {
    	Savepoint sp = Database.setSavepoint();
        isSuccess = true;
        
        try {
        	upsert creditNote;
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(1)));
            Database.rollback(sp);
            isSuccess = false;
        }
    }
    
    public void sendCreditNote() {
        List<XeroSync.InvoiceWrapper> responses = XeroSync.sendCreditNotes(new List<Id>{creditNote.Id});
            
        for (XeroSync.InvoiceWrapper response :responses) {
            if (response.status.equals(XeroSync.STATUS_SUCCESS)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, response.message));
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, response.message));
            }
        }
        creditNote = CreditNoteRepository.getCreditNoteById(creditNote.Id);       
    }
}