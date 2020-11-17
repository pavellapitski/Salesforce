trigger MakeGood on MakeGood__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

	if(Label.TRIGGER_SWITCH_MakeGood==Utility.TRIGGER_ON) {                
	    TriggerFactory.createHandler(MakeGood__c.sObjectType);
    }
}