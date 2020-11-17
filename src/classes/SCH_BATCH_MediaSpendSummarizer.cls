public class SCH_BATCH_MediaSpendSummarizer implements Database.Batchable <sObject>, Database.stateful, Schedulable {

    public static final string SUMMARIZE_PMS    = 'Summarize Project Media Spends';
    public static final string SUMMARIZE_MM_SPENDINGS    = 'Summarize MM Spendings';
    public static final string SET_PMS_LOOKUPS = 'Set Lookups between new PMS and MM Spendings';
    
    public static final List<string> steps = new List<string>{SUMMARIZE_PMS,SUMMARIZE_MM_SPENDINGS,SET_PMS_LOOKUPS};
        
    public string currentStep;
    private string query;    
    
    public void execute(SchedulableContext ctx) 
    {        
        Database.executeBatch(new SCH_BATCH_MediaSpendSummarizer(steps[0]), 1);
    }   
  
    public SCH_BATCH_MediaSpendSummarizer()
    {   
        this(steps[0]);
    }
    public SCH_BATCH_MediaSpendSummarizer(String step)
    {        
        currentStep = step;
        if (currentStep == SUMMARIZE_PMS)
        {
            query = 'SELECT id, CurrencyIsoCode, Media_Spend_Counter__c, project__r.strike_id__c FROM Payment__c WHERE Media_Spend_Counter__c>0';
            query +=' AND id not in (select project__c from Project_Media_Spend__c WHERE summarized__c=true) ';
            if(Test.isRunningTest()==false) query +=' AND project__r.InvoicesPaid__c=true';
        }          
        if (currentStep == SUMMARIZE_MM_SPENDINGS)
        {
            query = 'SELECT ID, CurrencyIsoCode, MM_Spendings_Counter__c, strike_id__c, Start_Date__c FROM Project__c WHERE  MM_Spendings_Counter__c>0 ';
            query +=' AND id not in (select contract__c from MM_Spendings__c WHERE summarized__c=true) ';
            if(Test.isRunningTest()==false) query +=' AND  InvoicesPaid__c=true';
        }            
        if (currentStep == SET_PMS_LOOKUPS)
        {
            query = 'SELECT id, Project__c, Project__r.Project__c FROM Project_Media_Spend__c WHERE MMSpending__c=null AND summarized__c=true';
        }    
    }     
    
    public Database.Querylocator start(Database.BatchableContext bc)
    {      
        return Database.getQuerylocator(query);
    } 
    
    public void execute(Database.BatchableContext bc, List<SObject> scope)
    {
        MMSpendingsHandler.skipProjectMediaSpendCreation = true;
        
        if (currentStep == SUMMARIZE_MM_SPENDINGS) {
            summarizeMMSpendings((List<Project__c>) scope);
        }  else if(currentStep == SUMMARIZE_PMS) {
            summarizePMS((List<Payment__c>) scope);
        }  else if(currentStep == SET_PMS_LOOKUPS) {
            setLookups((List<Project_Media_Spend__c>) scope);
        }
        
    }    
    
    public void setLookups(List<Project_Media_Spend__c> scope) {
        Set<ID> contractIDs = new Set<ID>();
        for(Project_Media_Spend__c spend: scope) contractIDs.add(spend.Project__r.Project__c);

        Map<Id,Id> MMspendByContract = new Map<Id,Id>();
        for(MM_Spendings__c MMspend: [SELECT Id,Contract__c FROM MM_Spendings__c WHERE Contract__c IN : contractIDs]){
            MMspendByContract.put(MMSpend.Contract__c, MMSpend.Id);
        }
        
        for(Project_Media_Spend__c spend: scope){
            spend.MMSpending__c = MMspendByContract.get(spend.Project__r.Project__c);
        }
        
        update scope;
    }
    
    public void summarizeMMSpendings(List<Project__c> scope){
		List<MM_Spendings__c> summarizedSpends = new List<MM_Spendings__c>(); 
        List<MM_Spendings__c> spendToDelete = new List<MM_Spendings__c>();           
        for(Project__c contract: scope) {
            MM_Spendings__c newSpend = new MM_Spendings__c(Media_Spend__c=0, summarized__c=true);
            newSpend.Date__c=contract.Start_Date__c;
            newSpend.Contract__c=contract.Id;
            newSpend.CurrencyIsoCode=contract.CurrencyIsoCode;
            newSpend.BypassValidationRule__c=true;
            List<MM_Spendings__c> spends  =
                [select id, Media_Spend__c,  (SELECT Id FROM ContractMediaSpend__r) 
                 from MM_Spendings__c WHERE Contract__c=:contract.Id AND summarized__c=false 
                 ORDER By Date__c DESC];  
            Boolean errorDetected = false;
            for(MM_Spendings__c spend: spends) {
                newSpend.Media_Spend__c+=spend.Media_Spend__c;
                if(spend.ContractMediaSpend__r.size()>0) errorDetected=true;
            }
            if(errorDetected==false) {
                summarizedSpends.add(newSpend);            
                spendToDelete.addAll(spends);  
            }
        }
        
        insert summarizedSpends;
        delete spendToDelete;                  
    }
    
    public void summarizePMS(List<Payment__c> scope){
		List<Project_Media_Spend__c> summarizedSpends = new List<Project_Media_Spend__c>(); 
        List<Project_Media_Spend__c> spendToDelete = new List<Project_Media_Spend__c>();         
        for(Payment__c proj: scope) {
            Project_Media_Spend__c newSpend = new Project_Media_Spend__c(delivered__c=0,Amount__c=0, summarized__c=true);
            newSpend.CurrencyIsoCode=proj.CurrencyIsoCode;
            List<Project_Media_Spend__c> spends  =
                [select id, amount__c, delivered__c, Average_Monthly_Currency_History__c, Date__c, MMSpending__c, Project__c 
                 from Project_Media_Spend__c WHERE Project__c=:proj.Id AND summarized__c=false ORDER By Date__c DESC];
            newSpend.Date__c=spends[0].Date__c;
            newSpend.Average_Monthly_Currency_History__c=spends[0].Average_Monthly_Currency_History__c;
            newSpend.MMSpending__c=null;
            newSpend.Project__c =spends[0].Project__c ;
            
            
            for(Project_Media_Spend__c oldSpend: spends){
                if(oldSpend.Amount__c!=null) newSpend.Amount__c+=oldSpend.Amount__c;
                if(oldSpend.delivered__c!=null) newSpend.delivered__c+=oldSpend.delivered__c;
            }
			summarizedSpends.add(newSpend);            
            spendToDelete.addAll(spends);
            
        }
        insert summarizedSpends;
        delete spendToDelete;        
    }
    
    public void finish(Database.BatchableContext bc)
    {
        Iterator<String> iter = steps.iterator();
        while (iter.hasNext()) {
            String step = iter.next();
            if (step == currentStep && iter.hasNext()) {
                String nextStep = iter.next();
                Database.executeBatch(new SCH_BATCH_MediaSpendSummarizer(nextstep), 1);
            }
        }        
    }         
    
}