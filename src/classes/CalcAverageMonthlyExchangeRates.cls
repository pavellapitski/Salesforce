global class CalcAverageMonthlyExchangeRates implements Database.Batchable <sObject>, Database.stateful, Schedulable
{
    public static final string CALCULATE_AVERAGE_EX_RATES     = 'Calculate average exchange rates';
    public static final string UPDATE_MONTHLY_DISTRIBUTION      = 'Update monthly distribution';
    public static final string UPDATE_MM_SPENDINGS    = 'Update media manager spendings';
    public static final string UPDATE_CONTRACT_MEDIA_SPEND    = 'Update contract media spends';
    
    Average_Monthly_Currency_History__c currentMonthAvgExchangeRates = new Average_Monthly_Currency_History__c();
    Date endMonthDate;
    Date startMonthDate;
    public static final List<string> steps = new List<string>{CALCULATE_AVERAGE_EX_RATES, UPDATE_MONTHLY_DISTRIBUTION,  UPDATE_MM_SPENDINGS, UPDATE_CONTRACT_MEDIA_SPEND};
        
        global string currentStep;
    private string query;
    
    global void execute(SchedulableContext ctx) 
    {        
        Database.executeBatch(new CalcAverageMonthlyExchangeRates(), 200);
    }   
    
    global CalcAverageMonthlyExchangeRates ()
    {
        this (steps [0], Date.today());
    }
    
    global CalcAverageMonthlyExchangeRates (Date eMD)
    {
        this (steps [0], eMD);
    }
    
    
    global CalcAverageMonthlyExchangeRates (String step,Date endDate)
    {
        endMonthDate=endDate;
        startMonthDate=Date.newInstance(endMonthDate.year(), endMonthDate.month(), 1);
        currentStep = step;
        
        if (currentStep == CALCULATE_AVERAGE_EX_RATES)
        {
            query = 'SELECT id, AUD__c, CAD__c, EUR__c,GBP__c, NZD__c, PLN__c, SGD__c, IDR__c, MXN__c, MYR__c, PHP__c,' +
                + 'HKD__c, JPY__c, KRW__c, INR__c, THB__c, RUB__c ' +
                ' FROM CurrencyHistory__c WHERE Date__c >=:startMonthDate AND Date__c<=:endMonthDate ORDER BY Date__c ASC';
        }
        else if (currentStep == UPDATE_MONTHLY_DISTRIBUTION)
        {
            query = 'SELECT ID, Actual_Gross_Profit__c, Actual_Revenue__c, Actual_Revenue_Rep__c, ' +
                + 'Client_Spend__c, Client_Spend_Rep__c, Expected_Gross_Profit__c, Expected_Revenue__c, ' +
                + 'Gross_Profit_Rep__c, Media_Order__c, CurrencyISOCode, Date__c  ' +
                + 'FROM Monthly_Distribution__c ORDER BY Date__c';
        }
        else if (currentStep == UPDATE_MM_SPENDINGS)
        {
            query = 'SELECT ID, Media_Spend__c, CurrencyISOCode, Date__c ' +
                + 'FROM MM_Spendings__c  ORDER BY Date__c';
        }      
        else if (currentStep == UPDATE_CONTRACT_MEDIA_SPEND)
        {
            query = 'SELECT ID, Amount__c, CurrencyISOCode, Date__c ' +
                + 'FROM Project_Media_Spend__c ORDER BY Date__c';
        }                          
    }
    
    
    global Database.Querylocator start(Database.BatchableContext bc)
    {
        return Database.getQuerylocator(query);
    } 
    
    global void execute(Database.BatchableContext bc, List<SObject> scope)
    {
        MMSpendingsHandler.skipProjectMediaSpendCreation=true;
        if (currentStep == CALCULATE_AVERAGE_EX_RATES)
        {
            calculateAverageExchangeRates ((List<CurrencyHistory__c>) scope);
        }
        else if (currentStep == UPDATE_MONTHLY_DISTRIBUTION || currentStep == UPDATE_MM_SPENDINGS || currentStep == UPDATE_CONTRACT_MEDIA_SPEND)
        {
            updateRecords(scope);
        } 
    }
    
    private void calculateAverageExchangeRates (List <CurrencyHistory__c> scope)
    {
        Map <String, Decimal> averageRates = new Map <String, Decimal> ();
        for (CurrencyHistory__c ch : scope)
        {
            averageRates.put ('AUD', averageRates.get ('AUD') == null ? ch.AUD__c : averageRates.get('AUD') + ch.AUD__c);
            averageRates.put ('CAD', averageRates.get ('CAD') == null ? ch.CAD__c : averageRates.get('CAD') + ch.CAD__c);
            averageRates.put ('EUR', averageRates.get ('EUR') == null ? ch.EUR__c : averageRates.get('EUR') + ch.EUR__c);
            averageRates.put ('GBP', averageRates.get ('GBP') == null ? ch.GBP__c : averageRates.get('GBP') + ch.GBP__c);
            averageRates.put ('NZD', averageRates.get ('NZD') == null ? ch.NZD__c : averageRates.get('NZD') + ch.NZD__c);
            averageRates.put ('PLN', averageRates.get ('PLN') == null ? ch.PLN__c : averageRates.get('PLN') + ch.PLN__c);
            averageRates.put ('SGD', averageRates.get ('SGD') == null ? ch.SGD__c : averageRates.get('SGD') + ch.SGD__c);
            averageRates.put ('IDR', averageRates.get ('IDR') == null ? ch.IDR__c : averageRates.get('IDR') + ch.IDR__c);
            averageRates.put ('MXN', averageRates.get ('MXN') == null ? ch.MXN__c : averageRates.get('MXN') + ch.MXN__c);
            averageRates.put ('MYR', averageRates.get ('MYR') == null ? ch.MYR__c : averageRates.get('MYR') + ch.MYR__c);
            averageRates.put ('PHP', averageRates.get ('PHP') == null ? ch.PHP__c : averageRates.get('PHP') + ch.PHP__c);
            averageRates.put ('HKD', averageRates.get ('HKD') == null ? ch.HKD__c : averageRates.get('HKD') + ch.HKD__c);
            averageRates.put ('JPY', averageRates.get ('JPY') == null ? ch.JPY__c : averageRates.get('JPY') + ch.JPY__c);
            averageRates.put ('KRW', averageRates.get ('KRW') == null ? ch.KRW__c : averageRates.get('KRW') + ch.KRW__c);
            averageRates.put ('INR', averageRates.get ('INR') == null ? ch.INR__c : averageRates.get('INR') + ch.INR__c);
            averageRates.put ('THB', averageRates.get ('THB') == null ? ch.THB__c : averageRates.get('THB') + ch.THB__c);
            averageRates.put ('RUB', averageRates.get ('RUB') == null ? ch.RUB__c : averageRates.get('RUB') + ch.RUB__c);            
        }
        
        for (String currencyName : averageRates.keySet())
        {
            averageRates.put (currencyName, averageRates.get(currencyName)/scope.size());
        }
        
        currentMonthAvgExchangeRates.Start_Date__c = startMonthDate;
        currentMonthAvgExchangeRates.End_Date__c = currentMonthAvgExchangeRates.Start_Date__c.addMonths(1).addDays(-1); 
        currentMonthAvgExchangeRates.Unique_ID__c=endMonthDate.year()+'-'+endMonthDate.month();
        currentMonthAvgExchangeRates.AUD__c = (Decimal)averageRates.get('AUD');
        currentMonthAvgExchangeRates.CAD__c  = (Decimal)averageRates.get('CAD');
        currentMonthAvgExchangeRates.EUR__c  = (Decimal)averageRates.get('EUR');
        currentMonthAvgExchangeRates.GBP__c  = (Decimal)averageRates.get('GBP');
        currentMonthAvgExchangeRates.NZD__c  = (Decimal)averageRates.get('NZD');
        currentMonthAvgExchangeRates.PLN__c  = (Decimal)averageRates.get('PLN');
        currentMonthAvgExchangeRates.SGD__c  = (Decimal)averageRates.get('SGD');
        currentMonthAvgExchangeRates.IDR__c  = (Decimal)averageRates.get('IDR');
        currentMonthAvgExchangeRates.MXN__c  = (Decimal)averageRates.get('MXN');
        currentMonthAvgExchangeRates.MYR__c  = (Decimal)averageRates.get('MYR');
        currentMonthAvgExchangeRates.PHP__c  = (Decimal)averageRates.get('PHP');
        currentMonthAvgExchangeRates.HKD__c  = (Decimal)averageRates.get('HKD');
        currentMonthAvgExchangeRates.JPY__c  = (Decimal)averageRates.get('JPY');
        currentMonthAvgExchangeRates.KRW__c  = (Decimal)averageRates.get('KRW');
        currentMonthAvgExchangeRates.INR__c  = (Decimal)averageRates.get('INR');
        currentMonthAvgExchangeRates.THB__c  = (Decimal)averageRates.get('THB');
        currentMonthAvgExchangeRates.RUB__c  = (Decimal)averageRates.get('RUB');
        
        upsert currentMonthAvgExchangeRates Unique_ID__c;
    }
    
    private void updateRecords(List <SObject> scope)
    {
        List<Average_Monthly_Currency_History__c> rates = [select id, start_date__c, End_date__c from Average_Monthly_Currency_History__c
                                                          ORDER BY Start_Date__c DESC];
        
        
        for (Sobject rec : scope)
        {
            Boolean found=false;
                for(Average_Monthly_Currency_History__c rate: rates){
                    if((Date)rec.get('Date__c')>= rate.Start_Date__c && (Date)rec.get('Date__c')<=rate.End_Date__c){
                        rec.put('Average_Monthly_Currency_History__c',rate.Id);
                        found=true;
                        break;
                    }
                }
            if(found==false) rec.put('Average_Monthly_Currency_History__c',rates[0].Id);
        }
        
        update scope;
    }
    
        
    global void finish(Database.BatchableContext bc)
    {
        Iterator<String> iter = steps.iterator();
        while (iter.hasNext()) {
            String step = iter.next();
            if (step == currentStep && iter.hasNext()) {
                String nextStep = iter.next();
                Database.executeBatch(new CalcAverageMonthlyExchangeRates(nextStep, endMonthDate), 200);
            }
        }
    }
}