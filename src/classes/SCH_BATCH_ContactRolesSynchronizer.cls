public class SCH_BATCH_ContactRolesSynchronizer implements Database.Batchable <sObject>, Database.stateful, Schedulable {

    public void execute(SchedulableContext ctx) 
    {        
        Database.executeBatch(new SCH_BATCH_ContactRolesSynchronizer(), 200);
    }   
    
    public Database.Querylocator start(Database.BatchableContext bc)
    {      
        return Database.getQuerylocator([select id , 
                                         (select id, opportunityid, contactid, role from opportunitycontactroles), 
                                         (select id, unique_id__c, role__c, contact__c, opportunity__c from Contact_Opportunities__r) 
                                         from opportunity where id in (select opportunityid from opportunitycontactrole)]);
    } 
    
    public void execute(Database.BatchableContext bc, List<Opportunity> scope)
    {
		Map<String,Contact_Opportunity__c> cos = new Map<String,Contact_Opportunity__c>();
        for(Opportunity opp: scope){
            for(Contact_Opportunity__c co: opp.Contact_Opportunities__r){
                cos.put(co.unique_id__c, co);
            }
            
            for(OpportunityContactRole ocr: opp.opportunitycontactroles){
            	String uniqueKey = ocr.ContactId+'#'+ocr.OpportunityId;
                Contact_Opportunity__c co = cos.get(uniqueKey);
                if(co==null) {
                    co = new Contact_Opportunity__c(Contact__c=ocr.ContactId, Opportunity__c=ocr.OpportunityId,
                                                   Unique_Id__c=uniqueKey);
                }
                co.Role__c=ocr.Role;
                cos.put(co.Unique_Id__c,co);
            }
            
            
        }
        database.upsert(cos.values());
    }    
    
    public void finish(Database.BatchableContext bc)
    {
    }         
    
}