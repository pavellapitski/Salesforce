@isTest
public class NotificatorTestUtils {

    public static final string StoragesPageRawData = '<th scope="row" class=" dataCell  ">File Storage</th><td class=" dataCell  numericalColumn">250.0&nbsp;MB</td><td class=" dataCell  numericalColumn">146.0&nbsp;MB</td><td class=" dataCell  numericalColumn">58%</td>'
            + '<th scope="row" class=" dataCell  ">Data Storage</th><td class=" dataCell  numericalColumn">250.0&nbsp;MB</td><td class=" dataCell  numericalColumn">112.0&nbsp;MB</td><td class=" dataCell  numericalColumn">45%</td>';

    public static NotificatorSetting__c prepareTestNotificator() {        
        NotificatorSetting__c notificator = new NotificatorSetting__c(recipient__c = 'test@notificator.com');
        insert notificator;

        List<NotificatorStorage__c> ns = new List<NotificatorStorage__c>{
            new NotificatorStorage__c(Name = 'File Storage', Setting__c = notificator.Id),
            new NotificatorStorage__c(Name = 'Data Storage', Setting__c = notificator.Id)
        };                    
        insert ns;

        return notificator;
    }

    public static StorageOCR prepareTestStorageOCR(Integer info, Integer warning) {
        return new StorageOCR(new NotificatorStorage__c(Name = 'File Storage', WarningPercentageThreshold__c = warning, InfoPercentageThreshold__c = info, Status__c = 'OK'));
    }

}