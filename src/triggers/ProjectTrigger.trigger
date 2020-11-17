trigger ProjectTrigger on Project__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    if(Label.TRIGGER_SWITCH_Project==Utility.TRIGGER_ON) {
    	TriggerFactory.createHandler(Project__c.sObjectType);
    }
}