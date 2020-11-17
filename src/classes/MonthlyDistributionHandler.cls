public class MonthlyDistributionHandler implements ITrigger {

    public MonthlyDistributionHandler() {}

    public void bulkBefore() {}

    public void bulkAfter() {}

    public void beforeInsert(List<SObject> so) {
        List<Average_Monthly_Currency_History__c> avMonthCurrencyHistories = [SELECT Id, Start_Date__c, End_Date__c FROM Average_Monthly_Currency_History__c];

        for (Monthly_Distribution__c monthlyDistribution :(List<Monthly_Distribution__c>) so) {
            monthlyDistribution.Brand_Lookup__c = monthlyDistribution.Brand_formula__c;
            monthlyDistribution.Brand_Account_lookup__c = monthlyDistribution.Brand_Account_formula__c;

            if (!avMonthCurrencyHistories.isEmpty()){
                for (Average_Monthly_Currency_History__c rate: avMonthCurrencyHistories) {
                    if (monthlyDistribution.Date__c >= rate.Start_Date__c && monthlyDistribution.Date__c <= rate.End_Date__c){
                        monthlyDistribution.Average_Monthly_Currency_History__c = rate.Id;
                        break;
                    }
                }
                if (monthlyDistribution.Average_Monthly_Currency_History__c == null) {
                    monthlyDistribution.Average_Monthly_Currency_History__c = avMonthCurrencyHistories[0].Id;
                }
            }
        }
    }

    public void beforeUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) { }

    public void beforeDelete(List<SObject> so) {}

    public void afterInsert(List<SObject> so) {
        MonthlyDistribution.assignMonthlyDistributionToSalesRep((List<Monthly_Distribution__c>) so);
    }

    public void afterUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {}

    public void afterDelete(List<SObject> so) {}

    public void andFinally() {}

}