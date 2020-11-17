public class SubProjectNotification {

    private static AppSettings__c appSettings = AppSettings__c.getInstance('Default');
    
    private static AppSettings__c getAppSettings() {
        return appSettings;
    }
    
    public static List<NotificationUtil.NotificationResult> sendPaymentsNotification() {
        List<Contact> contacts = new List<Contact>();
        List<Messaging.SingleEmailMessage> messages = getPaymentNotifications(contacts);
        
        Map<Id, User> clientServices = new Map<Id, User>([SELECT Id, Email, PodEmail__c FROM User WHERE Client_Services_Rep__c = TRUE AND Email != NULL]);
        Map<Id, List<Sub_Project__c>> paymentsToApprove = SubProjectRepository.getPaymentsForNotification(clientServices.keySet());
        
        List<Sub_Project__c> paymentsToUpdate = new List<Sub_Project__c>();
        for (List<Sub_Project__c> payments : paymentsToApprove.values()) {
            paymentsToUpdate.addAll(payments);
        }
        
        for (Sub_Project__c payment :paymentsToUpdate) {
            payment.InvoiceNotificationSent__c = true;
        }
        
        List<NotificationUtil.NotificationResult> notificationResult = NotificationUtil.sendNotifications(messages, contacts);
        try {
            update paymentsToUpdate;
        } catch (Exception ex) {
            EventLog__c log = EventLog.createEventLog('Invoice approval notification. Error updating payments', EventLog.STATUS_ERROR, EventLog.TYPE_CONTRACT);
            log.Description__c = ex.getMessage();
            insert log;
        }
         
        return notificationResult;
    }
    
    public static void sendCreditNotesNotification() {
        getAppSettings();
        
        if (String.isNotBlank(appSettings.CreditNotesNotificationRecipients__c)) {
            List<String> recipients = appSettings.CreditNotesNotificationRecipients__c.split(',');
            if (!recipients.isEmpty()) {
                List<CreditNote__c> creditNotes = CreditNoteRepository.getPendingCreditNotes(null, null, 'CreatedDate', 'ASC');
                List<Sub_Project__c> payments = SubProjectRepository.getPaymentsSubmittedToXero();
                
                if (!creditNotes.isEmpty() || !payments.isEmpty()) {
                    Contact testContact = NotificationUtil.createContactForNotification(recipients.remove(0));
                    insert testContact;
                    
                    Messaging.SingleEmailMessage mail = NotificationUtil.prepareMessage(testContact.Id, recipients, new List<String>(), appSettings.CreditNotesNotificationBcc__c, 'CreditNotesNotification');
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
                    delete testContact;
                }
            }
        }
    }
 
    public static List<Messaging.SingleEmailMessage> getPaymentNotifications(List<Contact> contacts) {
        Map<Id, User> clientServices = new Map<Id, User>([SELECT Id, Email, PodEmail__c FROM User WHERE Client_Services_Rep__c = TRUE AND Email != NULL]);
        Map<Id, List<Sub_Project__c>> paymentsToApprove = SubProjectRepository.getPaymentsForNotification(clientServices.keySet());
        List<String> notificationCC = new List<String>();
        
        if (String.isNotBlank(getAppSettings().InvoiceNotificationCC__c)) {
            notificationCC.add(getAppSettings().InvoiceNotificationCC__c);
        }
        return NotificationUtil.getClientServiceNotifications(clientServices, paymentsToApprove.keySet(), notificationCC, contacts, 'InvoiceNotification', false);
    }  
}