trigger OpportunityPlatform on OpportunityPlatform__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) 
{
    if(Label.TRIGGER_SWITCH_OpportunityPlatform==Utility.TRIGGER_ON) {
    	TriggerFactory.createHandler(OpportunityPlatform__c.sObjectType);
    }
}