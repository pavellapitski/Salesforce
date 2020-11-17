@IsTest
private class CommMonitorTest {
	
	@IsTest static void testGetEventLogs() {
		EventLog__c log = EventLog.createMediaManagerLog('SUCCESS', EventLog.STATUS_INFO, 'Test', 'Some data');
		insert new List<EventLog__c>{log};

		RestRequest req = new RestRequest(); 
	    RestResponse res = new RestResponse();
	    Test.startTest();
		List<CommMonitor.EventWrapper> results = CommMonitor.getEventLogs();
	    Test.stopTest();

	    System.assertEquals(1, results.size());
	}
}