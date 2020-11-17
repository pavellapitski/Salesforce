trigger ContactOpportunity on Contact_Opportunity__c (after insert, before insert, before delete) {
    if (Label.TRIGGER_SWITCH_ContactOpportunity == Utility.TRIGGER_ON) {
        if (Trigger.isBefore && Trigger.isInsert) {
            ContactOpportunityHandler.setUniqueID(Trigger.new);
        }

        if (Trigger.isAfter && Trigger.isInsert) {
            ContactOpportunityHandler.setContactStatus(Trigger.new);
            ContactOpportunityHandler.createOpportunityContactRoles(Trigger.new);
        }
        
        if (Trigger.isBefore && Trigger.isDelete) {
            ContactOpportunityHandler.deleteOpportunityContactRoles(Trigger.old);
        }
    }
}