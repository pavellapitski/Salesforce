public class SCH_BATCH_SalesRepBonusCalc implements Database.Batchable <sObject>, Database.stateful, Schedulable
{
    public static final string CREATE_BONUSES     = 'Create Annual and Quarter Bonuses records';
    public static final string CALCULATE_BONUSES    = 'Nightly recalculate bonuses';
    
    
    public static final List<string> steps = new List<string>{CREATE_BONUSES,CALCULATE_BONUSES};
        
    public string currentStep;
    private string query;    
    public Date proceedingDate {get; set;}
    
    
    public void execute(SchedulableContext ctx) 
    {        
        if(Date.today().day()==1 && Date.today().month()==1)
            Database.executeBatch(new SCH_BATCH_SalesRepBonusCalc(), 200);
        else 
            Database.executeBatch(new SCH_BATCH_SalesRepBonusCalc(steps[1], Date.today()), 10);
    }   
    
    public SCH_BATCH_SalesRepBonusCalc()
    {
        this (steps [0], Date.today());
    }
    
    public SCH_BATCH_SalesRepBonusCalc(Date eMD)
    {
        this (steps [0], eMD);
    }
    
    public SCH_BATCH_SalesRepBonusCalc(String step,Date pD)
    {
        proceedingDate=pD;
        currentStep = step;
        Integer year = pd.year();
        Integer quarter = getQuarterFromDate(pd);
        
        if (currentStep == CREATE_BONUSES)
        {
            query = 'SELECT ID, CurrencyISOCode FROM Commission_Profile__c WHERE GP_Bonus__c=true';
        }
        if (currentStep == CALCULATE_BONUSES)
        {
            query = 'SELECT ID, quarter__c, CurrencyISOCode, year__r.Sales_Rep__c,Start_Date__c, End_Date__c FROM Sales_Rep_Quarterly_Bonus__c';
        }      
        
    }        
    
    private Integer getQuarterFromDate(Date pD){
        if(pd.month()==1 || pd.month()==2 || pd.month()==3) return 1;
        if(pd.month()==4 || pd.month()==5 || pd.month()==6) return 2;
        if(pd.month()==7 || pd.month()==8 || pd.month()==9) return 3;
        if(pd.month()==10 || pd.month()==11 || pd.month()==12) return 4;
        return -1;
    }
    
    public Database.Querylocator start(Database.BatchableContext bc)
    {
        Integer year = proceedingDate.year();
        Integer quarter = getQuarterFromDate(proceedingDate);        
        return Database.getQuerylocator(query);
    } 
    
    public void execute(Database.BatchableContext bc, List<SObject> scope)
    {
        if (currentStep == CREATE_BONUSES && proceedingDate.day()==1 && proceedingDate.month()==1) {
            createAnnualBonuses((List<Commission_Profile__c>) scope);
        }  else if(currentStep == CALCULATE_BONUSES) {
                       calculateBonuses((List<Sales_Rep_Quarterly_Bonus__c>)scope);
                   }
    }    
    
    private void createAnnualBonuses(List<Commission_Profile__c> salesReps) {
        Integer year = proceedingDate.year();
        List<Sales_Rep_Annual_Bonus__c> years = new List<Sales_Rep_Annual_Bonus__c>();
        for(Commission_Profile__c rep: salesReps){
            years.add(new Sales_Rep_Annual_Bonus__c(Sales_Rep__c=rep.Id, year__c=year,
                                                    Unique_Id__c=year+'#'+rep.Id,
                                                    CurrencyISOCode=rep.CurrencyISOCode));
            Integer nextYear = year +1;
            years.add(new Sales_Rep_Annual_Bonus__c(Sales_Rep__c=rep.Id, year__c=nextYear,
                                                    Unique_Id__c=nextYear+'#'+rep.Id,
                                                    CurrencyISOCode=rep.CurrencyISOCode));
        }
        upsert years Unique_Id__c;
        createQuarterlyBonuses(years);
    }
    
    private void createQuarterlyBonuses(List<Sales_Rep_Annual_Bonus__c> years){        
        List<Sales_Rep_Quarterly_Bonus__c> quarters = new List<Sales_Rep_Quarterly_Bonus__c>();
        for(Sales_Rep_Annual_Bonus__c year: years) {
            quarters.add(new Sales_Rep_Quarterly_Bonus__c(quarter__c=1, year__c=year.Id,
                                                          Start_Date__c=Date.newInstance((integer)year.year__c,1,1),
                                                          End_date__c=Date.newInstance((integer)year.year__c,3,31),
                                                          Unique_Id__c='1#'+year.Id,
                                                          CurrencyISOCode=year.CurrencyISOCode));
            quarters.add(new Sales_Rep_Quarterly_Bonus__c(quarter__c=2, year__c=year.Id,
                                                          Start_Date__c=Date.newInstance((integer)year.year__c,4,1),
                                                          End_date__c=Date.newInstance((integer)year.year__c,6,30),
                                                          Unique_Id__c='2#'+year.Id,
                                                          CurrencyISOCode=year.CurrencyISOCode));
            quarters.add(new Sales_Rep_Quarterly_Bonus__c(quarter__c=3, year__c=year.Id,
                                                          Start_Date__c=Date.newInstance((integer)year.year__c,7,1),
                                                          End_date__c=Date.newInstance((integer)year.year__c,9,30),
                                                          Unique_Id__c='3#'+year.Id,
                                                          CurrencyISOCode=year.CurrencyISOCode));
            quarters.add(new Sales_Rep_Quarterly_Bonus__c(quarter__c=4, year__c=year.Id,
                                                          Start_Date__c=Date.newInstance((integer)year.year__c,10,1),
                                                          End_date__c=Date.newInstance((integer)year.year__c,12,31),
                                                          Unique_Id__c='4#'+year.Id,
                                                          CurrencyISOCode=year.CurrencyISOCode));            
        }
        upsert quarters Unique_ID__c;
    }
    
    private void calculateBonuses(List<Sales_Rep_Quarterly_Bonus__c> bonuses) {
            Map<Id,Average_Monthly_Currency_History__c> rates = new Map<Id,Average_Monthly_Currency_History__c>(
                [SELECT id, AUD__c, CAD__c, EUR__c,GBP__c, NZD__c, PLN__c, SGD__c, IDR__c, MXN__c, MYR__c, PHP__c,
                                               HKD__c, JPY__c, KRW__c, INR__c, THB__c, RUB__c 
                                               FROM Average_Monthly_Currency_History__c ]);

        for(Sales_Rep_Quarterly_Bonus__c bonus: bonuses){
            
            bonus.Gross_profit__c=0;
            for(Sales_Rep_MD__c md: [SELECT Id, Monthly_Distribution__r.Date__c, Monthly_Distribution__r.Actual_Gross_Profit__c,
                                     Monthly_Distribution__r.Average_Monthly_Currency_History__c,
                                     Sales_Rep__c, Sales_Rep__r.Bonus_GP__c, Monthly_Distribution__r.CurrencyISOCode,
                                     Sales_Rep__r.percentage_of_GP_allocation__c, Sales_Rep__r.CurrencyISOCode 
                                     FROM Sales_Rep_MD__c 
                                     WHERE Sales_Rep__r.Commission_Profile__c = : bonus.year__r.Sales_Rep__c
                                     AND Monthly_Distribution__r.Date__c>=:bonus.Start_Date__c
                                     AND Monthly_Distribution__r.Date__c<=:bonus.End_Date__c
                                     AND Sales_Rep__r.Bonus_GP__c!=null
                                     AND Monthly_Distribution__r.Actual_Gross_Profit__c!=null
                                     AND Sales_Rep__r.percentage_of_GP_allocation__c!=null]){
                                         
           		Decimal ratio = 1.0;
                if(bonus.CurrencyISOCode != md.Monthly_Distribution__r.CurrencyISOCode) {
                    Average_Monthly_Currency_History__c rate = rates.get(md.Monthly_Distribution__r.Average_Monthly_Currency_History__c);
                    Decimal ratioBonus = 1.0;
                    if(bonus.CurrencyISOCode!='USD') ratioBonus = (Decimal)rate.get(bonus.CurrencyISOCode+'__c');                    
                    Decimal ratioMD = 1.0;
                    if(md.Monthly_Distribution__r.CurrencyISOCode!='USD') ratioMD = (Decimal)rate.get(md.Monthly_Distribution__r.CurrencyISOCode+'__c');
	       	        ratio = 1.0 * ratioBonus/ratioMD;
                }
				bonus.Gross_profit__c+=md.Monthly_Distribution__r.Actual_Gross_Profit__c * md.Sales_Rep__r.percentage_of_GP_allocation__c / 100.0 * ratio;
        	}
            
            bonus.Gross_profit__c = bonus.Gross_profit__c.setScale(2);
        }
        update bonuses;
    }
    
    public void finish(Database.BatchableContext bc)
    {
        Iterator<String> iter = steps.iterator();
        while (iter.hasNext()) {
            String step = iter.next();
            if (step == currentStep && iter.hasNext()) {
                String nextStep = iter.next();
                Database.executeBatch(new SCH_BATCH_SalesRepBonusCalc(nextstep,proceedingDate), 10);
            }
        }
    }  
    
}