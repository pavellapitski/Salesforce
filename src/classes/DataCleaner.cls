global class DataCleaner implements Database.Batchable<sObject>, Schedulable  {

    public static final string DELETE_EVENT_LOG     = 'EventLog__c';
    public static final string DELETE_DLRS_JOB      = 'dlrs__LookupRollupCalculateJob__c';
    public static final string DELETE_DLRS_ITEMS    = 'dlrs__LookupRollupSummaryScheduleItems__c';

    public static final List<string> steps = new List<string>{
        DELETE_EVENT_LOG, DELETE_DLRS_JOB, DELETE_DLRS_ITEMS
    };

    global string currentStep;
    private string query;

    
   global void execute(SchedulableContext SC) {
		Database.executeBatch(new DataCleaner(),2000);
   }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global DataCleaner() {
        this(steps[0]);
    }

    global DataCleaner(string step) {
        currentStep=step;
        query = 'SELECT Id FROM ' + currentStep + ' WHERE overdue__c=true';
        query += ' LIMIT 40000';
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        delete scope;
    }

    global void finish(Database.BatchableContext BC) {
        Iterator<String> iter = steps.iterator();
        while (iter.hasNext()) {
            String step = iter.next();
            if (step == currentStep && iter.hasNext()) {
                String nextStep = iter.next();
                Database.executeBatch(new DataCleaner(nextStep), 2000);
            }
        }

    }
}