public with sharing class SpendRetrieveNotification {

    private static SpendRetrieveNotification sInstance = null;
    private static List<String> errorMessages = new List<String>();

    private SpendRetrieveNotification() {}

    public static SpendRetrieveNotification getInstance() {
        if (sInstance == null) {
            sInstance = new SpendRetrieveNotification();
        }
        return sInstance;
    }

    public static Map<String, List<String>> errorsMap = new Map<String, List<String>>();

    // methods for a JOB callouts by platform name
    public static void addErrors(Map<String, String> projectNameToErrorMap) {
        for (String projectName :projectNameToErrorMap.keySet()) {
            String errorMsg = projectNameToErrorMap.get(projectName);
            if (!errorsMap.containsKey(errorMsg)) {
                errorsMap.put(errorMsg, new List<String>());
            }
            errorsMap.get(errorMsg).add(projectName);
        }
    }

    public static void sendErrorNotification(String packageType) {
        if (!errorsMap.isEmpty()) {
            Messaging.sendEmail(new List<Messaging.Email>{createEmailMsg(packageType)});
        }
    }

    private static Messaging.SingleEmailMessage createEmailMsg(String packageType) {
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setSaveAsActivity(false);
        message.setSubject(packageType + ' Job Run Report ' + Date.today().format());
        message.setPlainTextBody(prepareEmailBody());
        message.setOrgWideEmailAddressId(NotificationUtil.getDefaultNotificationSender().Id);

        if (!String.isBlank(Strike_Settings__c.getInstance().Admin_Emails__c)) {
            message.setToAddresses((Strike_Settings__c.getInstance().Admin_Emails__c).split(';'));
        } else {
            message.setToAddresses(new List<String>{'salesforce@strikesocial.com'});
        }
        return message;
    }

    private static String prepareEmailBody() {
        String messageBody   = 'Hello,\n\n' +
                'The following errors occurred during batch run on ' + Date.today().format() + ':\n';
        String messageEnding = '\n\nKind regards,\nAdministration';
        String errorMessageBody = '';

        Integer counter = 1;
        for (String errorKey :errorsMap.keySet()) {
            errorMessageBody += '\n\n' + counter + '. ' + errorKey;
            errorMessageBody += '\t' + String.join(errorsMap.get(errorKey), ', ');
            counter++;
        }
        return messageBody + errorMessageBody + '.' + messageEnding;
    }
}