public class CreditNoteHandler implements ITrigger {
    public CreditNoteHandler() {}
    
    public void bulkBefore() {}

    public void bulkAfter() {}

    public void beforeInsert(List<SObject> so) {
        List<CreditNote__c> creditNotes = (List<CreditNote__c>)so;
        Map<Id, List<CreditNote__c>> paymentCreditNotes = new Map<Id, List<CreditNote__c>>();
        for (CreditNote__c creditNote : creditNotes) {
            if (!paymentCreditNotes.containsKey(creditNote.Payment__c)) {
                paymentCreditNotes.put(creditNote.Payment__c, new List<CreditNote__c> {creditNote});
            } else {
                paymentCreditNotes.get(creditNote.Payment__c).add(creditNote);
            }
        }
        
        for (Sub_Project__c payment : [SELECT Id, CurrencyIsoCode, Invoice_Amount__c FROM Sub_Project__c WHERE Id IN :paymentCreditNotes.keySet()]) {
            for (CreditNote__c creditNote :paymentCreditNotes.get(payment.Id)) {
                creditNote.XeroAmount__c = payment.Invoice_Amount__c - creditNote.Amount__c;
                creditNote.CurrencyIsoCode = payment.CurrencyIsoCode;
            }
        }
    }

    public void beforeUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) { 
        Map<Id, CreditNote__c> newMap = (Map<Id, CreditNote__c>)so;
        for (CreditNote__c creditNote :newMap.values()) {
            if (creditNote.XeroAmount__c == NULL && creditNote.Payment__r.Invoice_Amount__c != NULL) {
                creditNote.XeroAmount__c = creditNote.Payment__r.Invoice_Amount__c - creditNote.Amount__c;
            }
        }
    }
    
    public void beforeDelete(List<SObject> so) {}

    public void afterInsert(List<SObject> so) {}
    
    public void afterUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {}
        
    public void afterDelete(List<SObject> so) {}

    public void andFinally() {} 
    
}