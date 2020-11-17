public with sharing class NotificationUtil {

    public static String DEFAULT_EMAIL = 'salesforce@strikesocial.com';

    public static Contact createContactForNotification(String contactEmail) {
        return new Contact(
            LastName = 'testContact',
            Email = contactEmail,
            MailingCity = 'Chicago',
            MailingState = 'Michigan',
            Phone = '123-456-789'
        );
    }

    public static Boolean isSandbox { get {
        if (isSandbox == null) {
            isSandbox = [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox;
        }
        return isSandbox;
    } set;}

    private static OrgWideEmailAddress orgWideEmailAddressDefault { get {
        if (orgWideEmailAddressDefault == null) {
            orgWideEmailAddressDefault = [SELECT Address, DisplayName, Id FROM OrgWideEmailAddress WHERE Address = :DEFAULT_EMAIL];
        }
        return orgWideEmailAddressDefault;
    } set; }

    public static OrgWideEmailAddress getDefaultNotificationSender() {
        return orgWideEmailAddressDefault;
    }

    public static Messaging.SingleEmailMessage prepareMessage(Id contactId, List<String> recipients, List<String> ccRecipients, String bccRecipients, String templateName, String whatId) {
        Messaging.SingleEmailMessage message = NotificationUtil.prepareMessage(contactId, recipients, ccRecipients, bccRecipients, templateName);
        message.setWhatId(whatId);
        message.setSaveAsActivity(false);

        return message;
    }

    public static List<Messaging.SingleEmailMessage> getClientServiceNotifications(Map<Id, User> clientServices,
                                                                                   Set<Id> clientServicesToNotify,
                                                                                   List<String> ccRecipients,
                                                                                   List<Contact> contacts,
                                                                                   String templateName,
                                                                                   Boolean notifyPodTeam)
    {
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        Map<Id, Contact> contactsForCSReps = new Map<Id, Contact>();

        if (!clientServicesToNotify.isEmpty()) {
            AppSettings__c appSettings = AppSettings__c.getInstance('Default');

            for (Id clientServiceId : clientServicesToNotify) {
                Contact c = createContactForNotification(clientServices.get(clientServiceId).Email);

                contactsForCSReps.put(clientServiceId, c);
                contacts.add(c);
            }
            insert contacts;

            for (Id clientServiceId : clientServicesToNotify) {
                List<String> additionalRecipients = new List<String>();
                User clientSerivce = clientServices.get(clientServiceId);

                if (notifyPodTeam && !string.isBlank(clientSerivce.PodEmail__c)) {
                    additionalRecipients.add(clientSerivce.PodEmail__c);
                }
                messages.add(NotificationUtil.prepareMessage(contactsForCSReps.get(clientServiceId).Id, additionalRecipients, ccRecipients, appSettings.PreLaunchNotificationBcc__c, templateName, clientServiceId));
            }
        }
        return messages;
    }

    public static Messaging.SingleEmailMessage prepareMessage(Id contactId, List<String> recipients, List<String> ccRecipients, String bccRecipients,String templateName) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        EmailTemplate template = [Select Id from EmailTemplate WHERE Name = :templateName];
        mail.setTargetObjectId(contactId);
        mail.setTemplateId(template.Id);
        mail.setOrgWideEmailAddressId(getDefaultNotificationSender().Id);

        if (!recipients.isEmpty()) {
            mail.setToAddresses(recipients);
        }

        if (!ccRecipients.isEmpty()) {
            mail.setCcAddresses(ccRecipients);
        }

        if (!string.isEmpty(bccRecipients)) {
            List<String> BccRecipientsList = bccRecipients.split(',');
            if (!BccRecipientsList.isEmpty()) {
                mail.setBccAddresses(BccRecipientsList);
            }
        }
        return mail;
    }

    public static List<NotificationResult> sendNotifications(List<Messaging.SingleEmailMessage> messages, List<Contact> contacts) {
        List<NotificationResult> retVal = new List<NotificationResult>();
        List<Messaging.SingleEmailMessage> messageList = new List<Messaging.SingleEmailMessage>();
        List<Messaging.SendEmailResult> results = new List<Messaging.SendEmailResult>();

        for (Messaging.SingleEmailMessage message : messages) {
            messageList.add(message);

            if (messageList.size() == 9) {
                results.addAll(Messaging.sendEmail(messageList));
                messageList = new List<Messaging.SingleEmailMessage>();
            }
        }

        if (!messageList.isEmpty()) {
            results.addAll(Messaging.sendEmail(messageList));
        }

        for (Messaging.SendEmailResult result : results) {
            NotificationResult notifResult = new NotificationResult();

            if (!result.isSuccess()) {
                notifResult.errors = result.getErrors();
            } else {
                notifResult.isSuccess = true;
            }
            retVal.add(notifResult);
        }
        delete contacts;
        return retVal;
    }

    public class NotificationResult {
        public List<Messaging.SendEmailError> errors {get; set;}
        public Boolean isSuccess {get; set;}

        public NotificationResult() {
            errors = new List<Messaging.SendEmailError>();
            isSuccess = false;
        }
    }
}