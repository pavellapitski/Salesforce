trigger SubProjectTrigger on Sub_Project__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    if(Label.TRIGGER_SWITCH_SubProject==Utility.TRIGGER_ON) {
		TriggerFactory.createHandler(Sub_Project__c.sObjectType);
    }
}