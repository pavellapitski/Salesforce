trigger InvoiceTrigger on Invoice__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if (Label.TRIGGER_SWITCH_Account == Utility.TRIGGER_ON) {
        TriggerFactory.createHandler(Invoice__c.SObjectType);
    }
}