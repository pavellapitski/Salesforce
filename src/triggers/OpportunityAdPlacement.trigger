trigger OpportunityAdPlacement on OpportunityAdPlacement__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) 
{
    if(Label.TRIGGER_SWITCH_OpportunityAdPlacement==Utility.TRIGGER_ON) {
	    TriggerFactory.createHandler(OpportunityAdPlacement__c.sObjectType);        
    }
}