trigger PaymentTrigger on Payment__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    if(Label.TRIGGER_SWITCH_Payment==Utility.TRIGGER_ON) {
    	TriggerFactory.createHandler(Payment__c.sObjectType);
    }
}