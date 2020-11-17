trigger MonthlyDistributionTrigger on Monthly_Distribution__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

	if(Label.TRIGGER_SWITCH_MonthlyDistribution==Utility.TRIGGER_ON) {            
    	TriggerFactory.createHandler(Monthly_Distribution__c.sObjectType);
    }
}