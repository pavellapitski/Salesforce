trigger SalesRepMD on Sales_Rep_MD__c(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if (Label.TRIGGER_SWITCH_Brand == Utility.TRIGGER_ON) {
        TriggerFactory.createHandler(Sales_Rep_MD__c.sObjectType);
    }
}