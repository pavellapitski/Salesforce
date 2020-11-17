trigger AccountTrigger on Account (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    if (Label.TRIGGER_SWITCH_Account == Utility.TRIGGER_ON) {
    	TriggerFactory.createHandler(Account.SObjectType);
    }
}