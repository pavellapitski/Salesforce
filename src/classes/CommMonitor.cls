// This web service is used for monitoring of incoming reports from Media Manager
@RestResource(UrlMapping='/commManager/*')
global with sharing class CommMonitor {

	global class EventWrapper {
		public String type;
		public String error;
		public String description;
		public String error_description { get;set; }
		public Long timestamp;
		public String extramessage;
		public String event_id;
        public String request_token_id;

		public EventWrapper(EventLog__c ev) {
			this.event_id = ev.Id;
			this.type = ev.Type__c;
            this.request_token_id = ev.RequestId__c;
			this.timestamp = ev.CreatedDate.getTime();

			if (ev.Status__c == EventLog.STATUS_ERROR) {
				this.error = ev.Status__c;
				this.error_description = ev.Info__c;
			} else {
				this.description = ev.Info__c;
			}
			if (String.isNotBlank(ev.Description__c)){
				this.extramessage = ev.Description__c;
			}
		}
	}

    @HttpGet
    global static List<EventWrapper> getEventLogs() {
        List<EventLog__c> events = [SELECT Id, CreatedDate, Status__c, Description__c, Type__c, Info__c, Name, RequestId__c
			FROM EventLog__c
			WHERE CreatedDate >= :System.now().addMinutes(-30)
			ORDER BY CreatedDate DESC
		];

		List<EventWrapper> result = new List<EventWrapper>();
		for (EventLog__c ev :events) {
			result.add(new EventWrapper(ev));
		}
		return result;
    }
}