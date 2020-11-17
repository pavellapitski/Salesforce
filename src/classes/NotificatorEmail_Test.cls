@isTest 
private class NotificatorEmail_Test {

    static testMethod void addStorage_WhenNotificationRequired_AddIt() {
       NotificatorEmail mail = new NotificatorEmail();
       StorageOCR ocr = NotificatorTestUtils.prepareTestStorageOCR(40,95);
        
       mail.addStorage(ocr);

       System.assertEquals(1, mail.storageNotifications.size());   
    }
    
    static testMethod void addStorage_WhenNotificationNotRequired_IgnoreIt() {
       NotificatorEmail mail = new NotificatorEmail();
       StorageOCR ocr = NotificatorTestUtils.prepareTestStorageOCR(75,95);
        
       mail.addStorage(ocr);

       System.assertEquals(0, mail.storageNotifications.size());   
    }  
    
    static testMethod void sendNotification_WhenNoRows_DoNothing() {
       NotificatorEmail mail = new NotificatorEmail();
       
       mail.sendNotification();

       System.assertEquals('', mail.htmlBody);
       System.assertEquals('', mail.plainTextBody); 
    }     
    
    static testMethod void sendNotification_WhenRows_PrepareBodyAndSend() {
	   NotificatorTestUtils.prepareTestNotificator();        
       NotificatorEmail mail = new NotificatorEmail();
       StorageOCR socr = NotificatorTestUtils.prepareTestStorageOCR(40,95);        
       mail.addStorage(socr);
        
       mail.sendNotification();

       String expectedHTML = '<html><body>Salesforce Notificator detected potential problems with your organization!<br/><br/>'
           +'<h1>Storage Usage Alerts</h1><table width="300px">'
           +'<tr><th style="width:50%">Name</th><th style="width:25%">Status</th><th style="width:25%">Percent Usage</th></tr>'
           +'<tr align="center"><td style="width:50%">File Storage</td><td style="width:30%">Info</td><td style="width:20%">58%</td></tr></table>'
           +'<br/><br/>More info: '+URL.getSalesforceBaseUrl().toExternalForm() + Page.NotificatorAdminPanel.getUrl()+'</body></html>';
       String expectedText = 'Salesforce Notificator detected potential problems with your organization!\n\n'
		   +'File Storage\'s usage has overstepped Info threshold! Actual Percent Usage: 58%.\n\n'
           +'More info: '+URL.getSalesforceBaseUrl().toExternalForm() + Page.NotificatorAdminPanel.getUrl();
        
       System.assertEquals(expectedHTML, mail.htmlBody);
       System.assertEquals(expectedText, mail.plainTextBody); 
    }          
    
}