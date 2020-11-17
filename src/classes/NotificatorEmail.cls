public class NotificatorEmail {

    @testVisible List<SObjectNotification> storageNotifications;
    @testVisible String htmlBody;
    @testVisible String plainTextBody;

    public NotificatorEmail() {
        storageNotifications = new List<SObjectNotification>();
        htmlBody='';
        plainTextBody='';
    }

    public void addStorage(StorageOCR storage) {
        if (storage.isNotificationRequired()) {
            SOBjectNotification notification = new SObjectNotification(storage.getSettings().Name, storage.newStatus, storage.sPercent, Label.Notificator_StorageAlert);
            storageNotifications.add(notification);
        }
    }

    public void sendNotification() {
        if (storageNotifications.size() == 0) return;
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAdd = new String[]{
                NotificatorSingleton.getNotificator().recipient__c
        };

        mail.setToAddresses(toAdd);
        mail.setReplyTo(Label.Notificator_ReplyTo);
        mail.setSenderDisplayName(Label.Notificator_Sender_Name);
        mail.setSubject(Label.Notificator_Subject);
        mail.setBccSender(false);
        mail.setUseSignature(false);        
        prepareEmailBody();
        mail.setHtmlBody(htmlBody);
        mail.setPlainTextBody(plainTextBody);
        
        if(Test.isRunningTest()==false)  List<Messaging.SendEmailResult> results = Messaging.sendEmail(new Messaging.Email[]{
                mail
        });
    }

    private void prepareEmailBody() {
        String footer = String.format(Label.Notificator_AlertFooter, new String[]{
                URL.getSalesforceBaseUrl().toExternalForm() + Page.NotificatorAdminPanel.getUrl()
        });

        htmlBody = '<html><body>' + Label.Notificator_AlertHeader + '<br/><br/>';
        plainTextBody = Label.Notificator_AlertHeader + '\n';

        addStorageRows();
        
        htmlBody += '<br/><br/>' + footer + '</body></html>';
        plainTextBody += '\n\n' + footer;
    }
    
    private void addStorageRows() {
        if (storageNotifications.size() > 0) {
            htmlBody += '<h1>'+Label.Notificator_EmailStorageHeader+'</h1>';
            htmlBody += '<table width="300px"><tr><th style="width:50%">'+Label.Notificator_Name+'</th><th style="width:25%">'
                +Label.Notificator_Status+'</th><th style="width:25%">'+Label.Notificator_PercentUsage+'</th></tr>';
            for (SObjectNotification notification: storageNotifications) {
                plainTextBody += notification.getTextNotification();
                htmlBody += notification.getHTMLNotification();
            }
            htmlBody += '</table>';
        } 
    }
    
}