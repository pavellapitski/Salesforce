global class CreditNote {
    
    public static String STATUS_SUBMITTED = 'Submitted';
    public static String STATUS_AUTHORISED = 'Authorised';
    public static String STATUS_PAID = 'Paid';

    // DEPRECATED
    /*public static Map<Id, XeroWrappers.XeroCreditNoteAllocationResponse> allocateCreditNotes(Set<Id> creditNoteIds) {
        Map<Id, CreditNote__c> creditNotes = new Map<Id, CreditNote__c>(CreditNoteRepository.getCreditNotesById(creditNoteIds));
        Map<Id, List<CreditNote__c>> creditNotesForXeroEntity = new Map<Id, List<CreditNote__c>>();

        for (CreditNote__c creditNote :creditNotes.values()) {
            if (!creditNotesForXeroEntity.containsKey(creditNote.XeroEntity__c)) {
                creditNotesForXeroEntity.put(creditNote.XeroEntity__c, new List<CreditNote__c> { creditNote });                    
            } else {
               creditNotesForXeroEntity.get(creditNote.XeroEntity__c).add(creditNote);                 
            }
        }
        
        Map<Id, XeroSettings__c> xeroEntities = new Map<Id, XeroSettings__c> ([
            SELECT ConsumerKey__c, ConsumerSecret__c, PrivateKey__c, Name
            FROM XeroSettings__c
            WHERE Id IN :creditNotesForXeroEntity.keySet()
        ]);

        Map<Id, XeroWrappers.XeroCreditNoteAllocationResponse> allocationResults = new Map<Id, XeroWrappers.XeroCreditNoteAllocationResponse>();
        for (Id xeroEntityId : xeroEntities.keySet()) {
            allocationResults.putAll(allocateCreditNotes(creditNotesForXeroEntity.get(xeroEntityId), xeroEntities.get(xeroEntityId)));
        }

        List<CreditNote__c> creditNotesToUpdate = new List<CreditNote__c>();
        List<Sub_Project__c> paymentsToUpdate = new List<Sub_Project__c>();
        for (Id creditNoteId :allocationResults.keySet()) {
            XeroWrappers.XeroCreditNoteAllocationResponse response = allocationResults.get(creditNoteId);
            
            if (response.xeroCreditNoteAllocations[0].ValidationErrors.isEmpty()) {
                CreditNote__c creditNote = creditNotes.get(creditNoteId);
                CreditNote__c creditNoteToUpdate = creditNote;
                creditNoteToUpdate.Status__c = 'Approved';
                creditNotesToUpdate.add(creditNoteToUpdate);  
                
                Sub_Project__c paymentToUpdate = new Sub_Project__c(Id = creditNote.Payment__c);
                paymentToUpdate.Invoice_Amount__c = creditNote.Payment__r.Invoice_Amount__c - creditNote.Amount__c;
                paymentsToUpdate.add(paymentToUpdate);
            }
        }
        update creditNotesToUpdate;
        update paymentsToUpdate;
        return allocationResults;
    }

    private static Map<Id, XeroWrappers.XeroCreditNoteAllocationResponse> allocateCreditNotes(List<CreditNote__c> creditNotes, XeroSettings__c xeroEntity) {
         Map<Id, XeroWrappers.XeroCreditNoteAllocationResponse> retVal = new Map<Id, XeroWrappers.XeroCreditNoteAllocationResponse>();
         for (CreditNote__c creditNote :creditNotes) {
            XeroWrappers.XeroCreditNoteAllocation creditNoteAlloc = new XeroWrappers.XeroCreditNoteAllocation(creditNote);
            XeroWrappers.XeroCreditNoteAllocationResponse response = XeroAPI.putCreditNoteAllocation(creditNoteAlloc, xeroEntity, creditNote);
            retVal.put(creditNote.Id, response);
         }
         return retVal;
    }
    */
    
    public static Map<Id, XeroWrappers.XeroCreditNote> sendCreditNotes(Set<Id> creditNoteIds) {
         Map<Id, CreditNote__c> creditNotes = new Map<Id, CreditNote__c> (CreditNoteRepository.getCreditNotesById(creditNoteIds));    
         Map<Id, XeroWrappers.XeroCreditNote> creditNoteResponse = sendCreditNotes(creditNotes.values());
         List<CreditNote__c> creditNotesToUpdate = new List<CreditNote__c>();        
         
        for (Id creditNoteId :creditNoteResponse.keySet()) {
            CreditNote__c creditNote = creditNotes.get(creditNoteId);
            if (creditNoteResponse.get(creditNoteId).ValidationErrors.isEmpty()) {
                creditNote.XeroId__c = creditNoteResponse.get(creditNoteId).CreditNoteId;
                creditNote.XeroNumber__c = creditNoteResponse.get(creditNoteId).CreditNoteNumber; 
                creditNote.Status__c = STATUS_SUBMITTED;                
                creditNotesToUpdate.add(creditNote);
            }
        }
        update creditNotesToUpdate;
        return creditNoteResponse;
    }           
    
    private static Map<Id, XeroWrappers.XeroCreditNote> sendCreditNotes(List<CreditNote__c> creditNotes) {
        Map<String, List<XeroWrappers.XeroCreditNote>> xeroCreditNotesForXeroEntity = new Map<String, List<XeroWrappers.XeroCreditNote>>();
        for (CreditNote__c creditNote : creditNotes) {
            XeroWrappers.XeroCreditNote xeroCreditNote = new XeroWrappers.XeroCreditNote(creditNote);
            if (!xeroCreditNotesForXeroEntity.containsKey(creditNote.XeroEntity__c)) {
                xeroCreditNotesForXeroEntity.put(creditNote.XeroEntity__c, new List<XeroWrappers.XeroCreditNote> { xeroCreditNote });                      
            } else {
               xeroCreditNotesForXeroEntity.get(creditNote.XeroEntity__c).add(xeroCreditNote);                 
            }
        }
        
        Map<Id, XeroSettings__c> xeroEntities = new Map<Id, XeroSettings__c> ([
            SELECT ConsumerKey__c, ConsumerSecret__c, PrivateKey__c, Name
            FROM XeroSettings__c
            WHERE Id IN :xeroCreditNotesForXeroEntity.keySet()
        ]);

        Map<Id, XeroWrappers.XeroCreditNote> retVal = new Map<Id, XeroWrappers.XeroCreditNote>();
        for (String xeroEntityId : xeroCreditNotesForXeroEntity.keySet()) {
            XeroWrappers.XeroCreditNoteResponse cnResponse = XeroAPI.postCreditNotes(xeroCreditNotesForXeroEntity.get(xeroEntityId), xeroEntities.get(xeroEntityId));
            if (cnResponse.StatusCode == 200 || cnResponse.StatusCode == 201) {
                for (XeroWrappers.XeroCreditNote xcn :cnResponse.xeroCreditNotes) {
                    retVal.put(creditNotes[0].Id, xcn);
                }
            }  
        }
        return retVal;        
    }
}