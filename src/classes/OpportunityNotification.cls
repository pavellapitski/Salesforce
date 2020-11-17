public class OpportunityNotification {

    public static List<NotificationUtil.NotificationResult> sendSalesRepNotifications(String templateName, Integer notificationAdvance) {
         List<Contact> contacts = new List<Contact>();
         List<Messaging.SingleEmailMessage> messages = getSalesRepNotifications(contacts, templateName, notificationAdvance);
         return NotificationUtil.sendNotifications(messages, contacts);
    }
     
    public static List<NotificationUtil.NotificationResult> sendCSRepNotifications(String templateName, Integer notificationAdvance) {
         List<Contact> contacts = new List<Contact>();
         List<Messaging.SingleEmailMessage> messages = getClientServiceNotifications(contacts, templateName, notificationAdvance);
         return NotificationUtil.sendNotifications(messages, contacts);
    }
     
    @TestVisible private static List<Messaging.SingleEmailMessage> getSalesRepNotifications(List<Contact> contacts, String templateName, Integer notificationAdvance) {
        Map<String, User> users = new Map<String, User>([SELECT Id, Email FROM User WHERE IsActive = TRUE]);
        Map<String, List<Opportunity>> closingOpportunities = OpportunityRepository.getSalesRepClosingOpportunities(users.keySet(), System.today().addDays(notificationAdvance));
        return prepareMessages(contacts, users, closingOpportunities, templateName, true);
    }

    @TestVisible private static List<Messaging.SingleEmailMessage> getClientServiceNotifications(List<Contact> contacts, String templateName, Integer notificationAdvance) {
        Map<String, User> users = new Map<String, User>([SELECT Id, Email FROM User WHERE IsActive = TRUE AND Client_Services_Rep__c = TRUE AND Email != NULL]);
        Map<String, List<Opportunity>> closingOpportunities = OpportunityRepository.getClientServiceClosingOpportunities(users.keySet(), System.today().addDays(notificationAdvance));
 
        return prepareMessages(contacts, users, closingOpportunities, templateName, false);
    }

    private static List<Messaging.SingleEmailMessage> prepareMessages(List<Contact> contacts, Map<String, User> users, Map<String, List<Opportunity>> closingOpportunities, String templateName, Boolean sendToCC) {
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        AppSettings__c appSettings = AppSettings__c.getInstance('Default');
        
        if (!closingOpportunities.isEmpty()) {
            Map<Id, Contact> contactsForUsers = new Map<Id, Contact>();
            List<String> ccRecipients = new List<String>();
        
            for (Id recipientId :closingOpportunities.keySet()) {
                Contact c = NotificationUtil.createContactForNotification(users.get(recipientId).Email);
                contactsForUsers.put(recipientId, c);
                contacts.add(c);
            }
            insert contacts;
            
            if (sendToCC && String.isNotBlank(appSettings.OpportunityNotificationCC__c)) {
                ccRecipients.add(appSettings.OpportunityNotificationCC__c);
            }
            
            for (Id userId :contactsForUsers.keySet()) {
                messages.add(NotificationUtil.prepareMessage(contactsForUsers.get(userId).Id, new List<String>(), ccRecipients, appSettings.PreLaunchNotificationBcc__c, templateName, userId));
            }   
        }
        return messages;
    }
}