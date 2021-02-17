global class XeroSync {
    public static final Integer MONTH_COUNT_DIFF = 2;
    public static String XERO_TYPE_CONTACT = 'Contact';
    public static String STATUS_SUCCESS = 'Success';
    public static String STATUS_FAILED = 'Failed';

    public static Boolean performSync = false;


    private static List<XeroSettings__c> xeroSettings { get {
        if (xeroSettings == null) {
            xeroSettings = [SELECT Name, ConsumerKey__c, ConsumerSecret__c, PrivateKey__c, Id, AccountCode__c FROM XeroSettings__c LIMIT 10];
        }
        return xeroSettings;
    } set; }

    public static List<XeroSettings__c> getXeroSettingsByIds(Set<Id> ids) {
        List<XeroSettings__c> xeroSetts = new List<XeroSettings__c>();
        for (XeroSettings__c xeroSett :xeroSettings) {
            if (ids.contains(xeroSett.Id)) {
                xeroSetts.add(xeroSett);
            }
        }
        return xeroSetts;
    }

    public static List<InvoiceWrapper> sendInvoice(String invoiceId) {
        List<Sub_Project__c> payments = SubProjectRepository.getInvoiceForXeroSubmission(invoiceId);

        Map<Id, List<XeroWrappers.XeroInvoice>> xeroToInvoicesMap = new Map<Id, List<XeroWrappers.XeroInvoice>>();
        List<InvoiceWrapper> response = new List<InvoiceWrapper>();
        String contactId;
        Id xeroId;
        try {
            for (Sub_Project__c payment :payments) {
                if (String.isNotBlank(payment.Project__r.Xero_Id__c) && String.isNotBlank(payment.Project__r.Xero_Entity__c)) {
                    contactId = payment.Project__r.Xero_Id__c;
                    xeroId = payment.Project__r.Xero_Entity__c;
                } else {
                    contactId = payment.Account__r.Xero_Id__c;
                    xeroId = payment.Account__r.Xero_Entity__c;
                }
                if (xeroId == null) throw new XeroAPI.XeroException('Xero Id is not defined');

                if (!xeroToInvoicesMap.containsKey(xeroId)) {
                    xeroToInvoicesMap.put(xeroId, new List<XeroWrappers.XeroInvoice>());
                }
                xeroToInvoicesMap.get(xeroId).add(Utility.mapPaymentToInvoice(payment, contactId, xeroId));
            }

            Map<Id, XeroSettings__c> settingsMap = new Map<Id, XeroSettings__c>(getXeroSettingsByIds(xeroToInvoicesMap.keySet()));
            XeroWrappers.XeroInvoiceResponse xir;
            List<XeroWrappers.XeroInvoice> submittedInvoices = new List<XeroWrappers.XeroInvoice>();
            if (!Test.isRunningTest()) {
                for (Id key : xeroToInvoicesMap.keySet()) {
                    xir = XeroAPI.postInvoices(xeroToInvoicesMap.get(key), settingsMap.get(key));
                    if (xir.StatusCode == 200 || xir.StatusCode == 201) {
                        for (XeroWrappers.XeroObject xo : xir.xeroObjects) {
                            submittedInvoices.add((XeroWrappers.XeroInvoice)xo);
                        }
                    } else {
                        System.debug('Error while posting payments: ' + xir);
                    }
                }
            }

            List<Sub_Project__c> paymentsToUpdate = new List<Sub_Project__c>();
            List<EventLog__c> eventLogs = new List<EventLog__c>();
            for (XeroWrappers.XeroInvoice xi: submittedInvoices) {
                if (xi.HasErrors == false) {
                    paymentsToUpdate.add(new Sub_Project__c(
                        Id = invoiceId,
                        Xero_Id__c = xi.InvoiceID,
                        Invoice__c = xi.InvoiceNumber,
                        XeroStatus__c = SubProject.XERO_STATUS_SUBMITTED
                    ));
                    response.add(new InvoiceWrapper(invoiceId, STATUS_SUCCESS, 'Invoice successfully created in Xero'));

                    EventLog__c log = EventLog.createEventLog('Invoice Submitted In Xero', EventLog.STATUS_INFO, EventLog.TYPE_XERO_SYNC);
                    log.Payment__c = invoiceId;
                    eventLogs.add(log);
                } else {
                    response.add(new InvoiceWrapper(invoiceId, STATUS_FAILED, String.join(xi.ValidationErrors, ' ')));
                }
            }

            update paymentsToUpdate;
            insert eventLogs;
        } catch (Exception ex) {
            response = new List<InvoiceWrapper>();
            response.add(new InvoiceWrapper(invoiceId, 'Failed', ex.getMessage()));
            System.debug('### XeroSync.sendInvoice ERROR: ' + ex.getStackTraceString() + '\n');
        }

        return response;
    }

    public static List<InvoiceWrapper> sendCreditNotes(List<Id> creditNoteIds) {
        List<XeroSync.InvoiceWrapper> retVal = new List<XeroSync.InvoiceWrapper>();
        try {
            Map<Id, XeroWrappers.XeroCreditNote> creditNoteResponse = CreditNote.sendCreditNotes(new Set<Id> (creditNoteIds));
            for (Id creditNoteId :creditNoteResponse.keySet()) {
                XeroWrappers.XeroCreditNote creditNote = creditNoteResponse.get(creditNoteId);
                if (!creditNote.ValidationErrors.isEmpty()) {
                     retVal.add(new XeroSync.InvoiceWrapper(creditNoteId, 'Failed', String.join(creditNote.ValidationErrors, ' ')));
                } else {
                     retVal.add(new XeroSync.InvoiceWrapper(creditNoteId, 'Success', 'Credit Note successfully created in Xero'));
                }
            }
        } catch (Exception ex) {
            retVal = new List<XeroSync.InvoiceWrapper>();
            for (Id creditNoteId : creditNoteIds) {
                retVal.add(new XeroSync.InvoiceWrapper(creditNoteId, 'Failed', ex.getMessage()));
            }
        }
        return retVal;
    }

    public static void syncXeroObjects(XeroSettings__c xeroSettings, String objectType) {
        List<XeroSync__c> xeroSync = [
            SELECT SyncDate__c
            FROM XeroSync__c
            WHERE XeroSettings__c = :xeroSettings.Id AND ObjectType__c = :objectType
        ];

        XeroSync__c syncLog;
        if (!xeroSync.isEmpty()) {
            syncLog = xeroSync[0];
            XeroAPI.lastModifiedDate = syncLog.SyncDate__c;
        } else {
            syncLog = new XeroSync__c(ObjectType__c = objectType, XeroSettings__c = xeroSettings.Id);
        }

        XeroWrappers.XeroContactResponse response = XeroAPI.getAllContacts(xeroSettings);
        List<XeroEntity__c> xeroEntities = new List<XeroEntity__c>();
        if (response.StatusCode == 200) {
            for (XeroWrappers.XeroObject obj :response.xeroObjects) {
                XeroWrappers.XeroContact contact = (XeroWrappers.XeroContact) obj;

                xeroEntities.add(new XeroEntity__c(
                    ObjectType__c = objectType,
                    XeroId__c = String.valueOf(contact.ContactID),
                    XeroName__c = String.valueOf(contact.Name),
                    XeroSettings__c = xeroSettings.Id
                ));
            }
            upsert xeroEntities XeroId__c;

            syncLog.SyncDate__c = System.now().addHours(-1);
            upsert syncLog;
        }
    }

    // Invoices
    @Future (Callout=true)
    public static void updateInvoiceFromXero() {
        XeroAPI.lastModifiedDate = System.today();

        Date greaterThanDate = Date.newInstance(
            System.today().addMonths(-1 * MONTH_COUNT_DIFF).year(),
            System.today().addMonths(-1 * MONTH_COUNT_DIFF).month(),
            01
        );

        Map<String, XeroWrappers.XeroInvoice> invoiceFromXero = new Map<String,XeroWrappers.XeroInvoice>();
        List<EventLog__c> logs = new List<EventLog__c>();
        for (XeroSettings__c xeroSetting :xeroSettings) {
            System.debug('### xeroSetting: ' + xeroSetting.Name);

            XeroWrappers.XeroInvoiceResponse response = XeroAPI.getInvoicesGreaterThanDate(xeroSetting, greaterThanDate);
            System.debug('### response: ' + response.statusCode + '   ' + response.xeroObjects.size());
            if (response.statusCode == 200) {
                for (XeroWrappers.XeroObject xo :response.xeroObjects) {
                    System.debug('### xo: ' + xo);
                    XeroWrappers.XeroInvoice invoice = (XeroWrappers.XeroInvoice) xo;
                    invoiceFromXero.put(invoice.invoiceID, invoice);
                }
            } else {
                logs.add(EventLog.createEventLog('Callout Failed', EventLog.STATUS_ERROR, EventLog.TYPE_XERO_SYNC));
            }
        }

        Map<String, Invoice__c> xeroIdToInvoice = new Map<String,Invoice__c>();
        for (Invoice__c invoice :[SELECT Id, Xero_Invoice_Id__c, Status__c FROM Invoice__c WHERE Status__c != 'Paid' AND Xero_Invoice_Id__c != NULL]) {
            xeroIdToInvoice.put(invoice.Xero_Invoice_Id__c, invoice);
        }

        System.debug('### xeroIdToInvoice: ' + xeroIdToInvoice);
        System.debug('### invoiceFromXero: ' + invoiceFromXero);
        List<Invoice__c> invoicesToUpdate = new List<Invoice__c>();
        for (String xeroId :invoiceFromXero.keySet()) {
            XeroWrappers.XeroInvoice xeroInvoice = invoiceFromXero.get(xeroId);
            Invoice__c invoice = xeroIdToInvoice.containsKey(xeroId) ? xeroIdToInvoice.get(xeroId) : null;
            if (invoice == null) {
                continue;
            }

            if (xeroInvoice.Status == XeroWrappers.XeroInvoiceStatus.AUTHORISED) {
                invoice.Status__c = XeroWrappers.XeroInvoiceStatus.AUTHORISED.name();
                invoicesToUpdate.add(invoice);
            }
            if (xeroInvoice.Status == XeroWrappers.XeroInvoiceStatus.PAID) {
                //invoice.Payment_Date__c = xeroInvoice.FullyPaidOnDate
                invoice.Status__c = XeroWrappers.XeroInvoiceStatus.PAID.name();
                invoicesToUpdate.add(invoice);
            }
        }

        System.debug('### invoicesToUpdate: ' + invoicesToUpdate);
        try {
            update invoicesToUpdate;
            insert logs;
        } catch (Exception ex) {
            insert EventLog.createEventLog('Payment Sync failed', EventLog.STATUS_ERROR, EventLog.TYPE_XERO_SYNC, ex.getMessage());
        }
    }

    // Payments
    public static Map<String, XeroWrappers.XeroInvoice> getUpdatedInvoices(XeroSettings__c service) {
        XeroAPI.lastModifiedDate = System.today().addDays(-3);
        Map<String, XeroWrappers.XeroInvoice> invoiceForPayment = new Map<String, XeroWrappers.XeroInvoice>();
        XeroWrappers.XeroInvoiceResponse response = XeroAPI.getAllInvoices(service);
        if (response.StatusCode == 200) {
            for (XeroWrappers.XeroObject obj :response.xeroObjects) {
                XeroWrappers.XeroInvoice invoice = (XeroWrappers.XeroInvoice) obj;
                invoiceForPayment.put(invoice.InvoiceID, invoice);
            }
        } else {
            insert EventLog.createEventLog('Callout failed', EventLog.STATUS_ERROR, EventLog.TYPE_XERO_SYNC);
        }
        return invoiceForPayment;
    }

    public static Map<String, XeroWrappers.XeroInvoice> getUpdatedInvoices() {
        Map<String, XeroWrappers.XeroInvoice> invoiceForPayment = new Map<String, XeroWrappers.XeroInvoice>();
        for (XeroSettings__c xeroSetting :xeroSettings) {
            invoiceForPayment.putAll(getUpdatedInvoices(xeroSetting));
        }
        return invoiceForPayment;
    }

    @Future (Callout=true)
    public static void handleInvoicesFromXero() {
        try {
            Map<String, XeroWrappers.XeroInvoice> invoiceForPayment = getUpdatedInvoices();
            Map<String, Sub_Project__c> xeroIdToPayment = new Map<String, Sub_Project__c>();
            for (Sub_Project__c payment :SubProjectRepository.getUnpaidPaymentsByXeroIds(invoiceForPayment.keySet())) {
                xeroIdToPayment.put(payment.Xero_ID__c, payment);
            }

            List<Sub_Project__c> paymentsToUpdate = new List<Sub_Project__c>();
            List<EventLog__c> logs = new List<EventLog__c>();
            for (String xeroId :invoiceForPayment.keySet()) {
                XeroWrappers.XeroInvoice xeroInvoice = invoiceForPayment.get(xeroId);

                if (xeroInvoice.Status == XeroWrappers.XeroInvoiceStatus.AUTHORISED) {
                    if (xeroIdToPayment.containsKey(xeroId) && xeroIdToPayment.get(xeroId).XeroStatus__c != SubProject.XERO_STATUS_AUTHORISED) {
                        Sub_Project__c payment = xeroIdToPayment.get(xeroId);
                        payment.XeroStatus__c = SubProject.XERO_STATUS_AUTHORISED;
                        paymentsToUpdate.add(payment);

                        logs.add(EventLog.createEventLog('Invoice Approved in Xero', EventLog.STATUS_INFO, EventLog.TYPE_XERO_SYNC, payment.Id));
                    }
                }

                if (xeroInvoice.Status == XeroWrappers.XeroInvoiceStatus.PAID) {
                    if (xeroIdToPayment.containsKey(xeroId) && xeroIdToPayment.get(xeroId).XeroStatus__c != SubProject.XERO_STATUS_PAID) {
                        Sub_Project__c payment = xeroIdToPayment.get(xeroId);
                        payment.Paid__c = true;
                        payment.Payment_Date__c = xeroInvoice.FullyPaidOnDate;
                        payment.XeroStatus__c = SubProject.XERO_STATUS_PAID;
                        paymentsToUpdate.add(payment);

                        logs.add(EventLog.createEventLog('Invoice Paid', EventLog.STATUS_INFO, EventLog.TYPE_XERO_SYNC, payment.Id));
                    }
                }
            }
            update paymentsToUpdate;
            insert logs;
        } catch (Exception ex) {
            insert EventLog.createEventLog('Payment Sync failed', EventLog.STATUS_ERROR, EventLog.TYPE_XERO_SYNC, ex.getMessage());
        }
    }

    // Credit Notes
    @Future (Callout=true)
    public static void updateCreditNotesFromXero() {
        Map<String, XeroWrappers.XeroCreditNote> creditNoteForSalesforceCreditNote = getUpdatedCreditNotes();
        try {
            List<CreditNote__c> creditNotes = CreditNoteRepository.getUnpaidCreditNotes(creditNoteForSalesforceCreditNote.keySet());
            List<EventLog__c> logs = new List<EventLog__c>();
            List<CreditNote__c> creditNotesToUpdate = new List<CreditNote__c>();
            for (CreditNote__c cNote :creditNotes) {
                XeroWrappers.XeroCreditNote xeroCreditNote = creditNoteForSalesforceCreditNote.get(cNote.XeroId__c);

                if (xeroCreditNote.Status == XeroWrappers.XeroCreditNoteStatus.AUTHORISED && cNote.Status__c != CreditNote.STATUS_AUTHORISED) {
                    cNote.Status__c = CreditNote.STATUS_AUTHORISED;
                    logs.add(EventLog.createEventLog('Credit Note Approved in Xero', EventLog.STATUS_INFO, EventLog.TYPE_XERO_SYNC, cNote.Id));
                }

                if (xeroCreditNote.Status == XeroWrappers.XeroCreditNoteStatus.PAID && cNote.Status__c != CreditNote.STATUS_PAID) {
                    cNote.Status__c = CreditNote.STATUS_PAID;
                    if (!xeroCreditNote.LineItems.isEmpty()) {
                        cNote.XeroAmount__c = xeroCreditNote.LineItems[0].LineAmount;
                    }
                    logs.add(EventLog.createEventLog('Credit Note Paid', EventLog.STATUS_INFO, EventLog.TYPE_XERO_SYNC, cNote.Id));
                }
                creditNotesToUpdate.add(cNote);
            }
            update creditNotesToUpdate;
            insert logs;
        } catch (Exception ex) {
            insert EventLog.createEventLog('Credit Note Sync failed', EventLog.STATUS_ERROR, EventLog.TYPE_XERO_SYNC, ex.getMessage());
        }
    }

    public static Map<String, XeroWrappers.XeroCreditNote> getUpdatedCreditNotes() {
        Map<String, XeroWrappers.XeroCreditNote> creditNoteForSalesforceCreditNote = new Map<String, XeroWrappers.XeroCreditNote>();
        for (XeroSettings__c xeroSetting :xeroSettings) {
            creditNoteForSalesforceCreditNote.putAll(getUpdatedCreditNotes(xeroSetting));
        }
        return creditNoteForSalesforceCreditNote;
    }

    public static Map<String, XeroWrappers.XeroCreditNote> getUpdatedCreditNotes(XeroSettings__c service) {
        Map<String, XeroWrappers.XeroCreditNote> creditNoteForSalesforceCreditNote = new Map<String, XeroWrappers.XeroCreditNote>();
        XeroAPI.lastModifiedDate = System.today().addDays(-3);
        XeroWrappers.XeroCreditNoteResponse response = XeroAPI.getAllCreditNotes(service);
        if (response.StatusCode == 200) {
            for (XeroWrappers.XeroCreditNote creditNote : response.xeroCreditNotes) {
                creditNoteForSalesforceCreditNote.put(creditNote.CreditNoteId, creditNote);
            }
        } else {
            insert EventLog.createEventLog('Callout failed', EventLog.STATUS_ERROR, EventLog.TYPE_XERO_SYNC);
        }
        return creditNoteForSalesforceCreditNote;
    }

    global class InvoiceWrapper {
        @AuraEnabled public String Id;
        @AuraEnabled public String status;
        @AuraEnabled public String message;

        public InvoiceWrapper(String Id, String status, String message) {
            this.Id = Id;
            this.status = status;
            this.message = message;
        }
    }
}