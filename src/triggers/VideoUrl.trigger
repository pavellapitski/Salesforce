trigger VideoUrl on VideoUrl__c (before insert, before update, before delete, after insert, after update, after delete) {
	if (Label.TRIGGER_SWITCH_VideoUrl == Utility.TRIGGER_ON) {
		TriggerFactory.createHandler(VideoUrl__c.sObjectType);
    }
}