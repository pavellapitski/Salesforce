trigger Brand on Brand__c(before insert, before update, before delete, after insert, after update, after delete, after undelete) 
{    
	if(Label.TRIGGER_SWITCH_Brand==Utility.TRIGGER_ON) {                 	   
    	TriggerFactory.createHandler(Brand__c.sObjectType);
    }
}