public class CommissionProfileBonusesController {
    
    private final Commission_Profile__c profile;

    public CommissionProfileBonusesController(ApexPages.StandardController stdController) {
        profile = (Commission_Profile__c) stdController.getRecord();

    }

    public List<Sales_Rep_Quarterly_Bonus__c> getBonuses() {
        return [SELECT ID, quarter__c, CurrencyISOCode, year__r.Sales_Rep__c,Start_Date__c, End_Date__c,
                year__c, year__r.year__c, Gross_Profit__c, GP_Threshold__c
                FROM Sales_Rep_Quarterly_Bonus__c 
               WHERE year__r.Sales_Rep__c=:profile.Id AND Gross_Profit__c!=0
               ORDER BY year__r.year__c DESC, quarter__c DESC];
    }    
}