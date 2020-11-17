trigger BrandAccount on Brand_Account__c (before insert, before update, before delete, after insert, after update, after delete) {
	    
	if(Label.TRIGGER_SWITCH_BrandAccount==Utility.TRIGGER_ON) {    
	    TriggerFactory.createHandler(Brand_Account__c.sObjectType);
    }
}