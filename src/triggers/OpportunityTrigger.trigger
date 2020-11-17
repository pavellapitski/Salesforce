trigger OpportunityTrigger on Opportunity (before insert, before update, before delete, after insert, after update, after delete) {

    if(Label.TRIGGER_SWITCH_Opportunity==Utility.TRIGGER_ON) {
		TriggerFactory.createHandler(Opportunity.sObjectType);
    }
}