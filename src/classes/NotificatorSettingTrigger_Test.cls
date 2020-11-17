@isTest
private class NotificatorSettingTrigger_Test {

    static testMethod void tryInsertMoreThanOneNotificator_addError() {
        NotificatorSetting__c notificator = new NotificatorSetting__c(recipient__c = 'test@notificator.com');
        insert notificator;

        try {
            NotificatorSetting__c notificator2 = new NotificatorSetting__c(recipient__c = 'test2@notificator.com');
            insert notificator2;
            system.assert(false);
        } catch (Exception ex) {
            system.assert(ex.getMessage().contains(Label.Notificator_TriggerError));
        }
    }
}