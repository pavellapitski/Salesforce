trigger MMSpendings on MM_Spendings__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    if(Label.TRIGGER_SWITCH_MMSpendings==Utility.TRIGGER_ON) {    
		TriggerFactory.createHandler(MM_Spendings__c.sObjectType);
    }
}