trigger NotificatorSettingTrigger on NotificatorSetting__c (before insert) {
    static Boolean isFirstTime = true;

    Integer count = [SELECT count() FROM NotificatorSetting__c LIMIT 2];
    if (count > 0) isFirstTime = false;

    for (NotificatorSetting__c setting : Trigger.new) {
        if (isFirstTime == false) {
            setting.AddError(Label.Notificator_TriggerError);
        } else {
            isFirstTime = false;
        }
    }
}