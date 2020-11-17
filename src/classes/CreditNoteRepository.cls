public class CreditNoteRepository {
    
    public static CreditNote__c getCreditNoteById(String creditNoteId) {
        List<CreditNote__c> creditNotes = getCreditNotesById(new Set<Id>{creditNoteId});
        return (!creditNotes.isEmpty()) ?  creditNotes[0] : new CreditNote__c();
    }
    
    public static List<CreditNote__c> getCreditNotesById(Set<Id> creditNoteIds) {
        return [SELECT Amount__c, Description__c, Name, XeroEntity__c, Payment__c, Payment__r.Xero_Id__c, XeroId__c, Payment__r.CurrencyIsoCode, 
                       Payment__r.Invoice_Amount__c,
                       Payment__r.Project__r.Xero_Id__c, Payment__r.Project__r.Xero_Entity__c, XeroCreditNote__c,
                       Payment__r.Account__r.Xero_Id__c, Payment__r.Account__r.Xero_Entity__c, XeroAmount__c,
                       Payment__r.Project__r.Xero_Entity__r.AccountCode__c
                FROM CreditNote__c 
                WHERE Id IN :creditNoteIds];        
    }

    public static List<CreditNote__c> getUnpaidCreditNotes(Set<String> xeroIds) {
        return [SELECT XeroId__c, Status__c
            FROM CreditNote__c
            WHERE XeroId__c IN :xeroIds AND Status__c != :CreditNote.STATUS_PAID
        ];
    }
    
    public static List<CreditNote__c> getPendingCreditNotes(Integer offset, Integer pageSize, String orderBy, String orderDirection) {
        return getCreditNotes(CreditNote.STATUS_SUBMITTED, offset, pageSize, orderBy, orderDirection);         
    }
    
    private static List<CreditNote__c> getCreditNotes(String status, Integer offset, Integer pageSize, String orderBy, String orderDirection) {
        String query = 'SELECT Id, Amount__c, Description__c, Name, Payment__c, Payment__r.Name, Payment__r.Project__c, Payment__r.Project__r.Name, Status__c , CreatedBy.Name, XeroCreditNote__c, XeroId__c, XeroNumber__c ';
            query += 'FROM CreditNote__c WHERE Status__c = :status ';
        
        if (String.isNotBlank(orderBy)) {
            query += ' ORDER BY ' + orderBy;          
        }
        if (String.isNotBlank(orderDirection)) {
            query += ' ' + orderDirection;            
        }
        if (pageSize != null) {
            query += ' LIMIT :pageSize ';            
        }
        if (offset != null) {
            query += ' OFFSET :offset ';            
        }
        return Database.query(query);        
    }
}