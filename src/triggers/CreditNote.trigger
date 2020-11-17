trigger CreditNote on CreditNote__c (before insert, before update, before delete, after insert, after update, after delete) {
    
	if(Label.TRIGGER_SWITCH_CreditNote==Utility.TRIGGER_ON) {                
	    TriggerFactory.createHandler(CreditNote__c.sObjectType);
    }
}