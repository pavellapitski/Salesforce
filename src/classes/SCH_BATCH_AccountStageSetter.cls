public class SCH_BATCH_AccountStageSetter implements Database.Batchable <sObject>, Database.stateful, Schedulable {

    private static final String STATUS_OPEN = 'Open';
    private static final String STATUS_WORKING = 'Working';
    private static final String STATUS_MEETING = 'Meeting';
    private static final String STATUS_CLIENT = 'Client';
    private static final String STATUS_DO_NOT_CONTACT = 'Do Not Contact';
    
    public void execute(SchedulableContext ctx) 
    {        
        Database.executeBatch(new SCH_BATCH_AccountStageSetter(), 200);
    }   
    
    public Database.Querylocator start(Database.BatchableContext bc)
    {      
        return Database.getQuerylocator([SELECT Id, Account_Stage__c, LastActivityDate,
            (SELECT Id, ActivityDate FROM Tasks WHERE ActivityDate!=null ORDER BY ActivityDate DESC LIMIT 1), 
            (SELECT Id, ActivityDateTime FROM Events WHERE ActivityDateTime!=null ORDER BY ActivityDateTime DESC LIMIT 1), 
            (SELECT id, end_Date__c from projects__r order by end_date__c desc LIMIT 1),                             
            (SELECT ID, CloseDate From Opportunities WHERE isClosed=false ORDER BY CloseDate DESC LIMIT 1) 
            FROM Account WHERE Account_Stage__c!=:STATUS_DO_NOT_CONTACT]);
    } 
    
    public void execute(Database.BatchableContext bc, List<Account> scope)
    {
        for(Account acc: scope) {
            if(acc.projects__r.size()>0 && acc.projects__r[0].End_Date__c>= Date.today().addDays(-365)) acc.Account_Stage__c=STATUS_CLIENT;
			else if(acc.Opportunities.size()>0 || (acc.Events.size()>0 && acc.Events[0].ActivityDateTime > Date.today().addDays(-120))) acc.Account_Stage__c=STATUS_MEETING;
            else if((acc.Tasks.size()>0 && acc.Tasks[0].ActivityDate >= Date.today().addDays(-60))
                    || (acc.LastActivityDate!=null && acc.LastActivityDate>= Date.today().addDays(-60))) acc.Account_Stage__c=STATUS_WORKING;
            else acc.Account_Stage__c=STATUS_OPEN;
        }
        database.update(scope,false);
    }    
    
    public void finish(Database.BatchableContext bc)
    {
    }         
}