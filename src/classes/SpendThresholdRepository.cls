public class SpendThresholdRepository {
    public static List<Spend_Threshold__c> getSpendThresholdsForOpportunity(Id opportunityId)
    {
        List<Spend_Threshold__c> retVal = new List<Spend_Threshold__c>();
        
        Map<Id, List<Spend_Threshold__c>> opportunitySpendThresholds = getSpendThresholdsForOpportunities(new Set<Id> {opportunityId}); 
        
        if (opportunitySpendThresholds.containsKey(opportunityId))
        {
            retVal = opportunitySpendThresholds.get(opportunityId);                
        }
        
        return retVal;
    }
    
    public static Map<Id, List<Spend_Threshold__c>> getSpendThresholdsForOpportunities(Set<Id> opportunityIds)
    {
        Map<Id, List<Spend_Threshold__c>> retVal = new Map<Id, List<Spend_Threshold__c>>();
        
        for (Spend_Threshold__c spendThreshold : [SELECT Name, Fee__c, Opportunity__c, Spend_From__c, Spend_To__c
                                                  FROM Spend_Threshold__c
                                                  WHERE Opportunity__c IN :opportunityIds
                                                  ORDER BY Spend_From__c ASC])
        {
            if (!retVal.containsKey(spendThreshold.Opportunity__c))
            {
                retVal.put(spendThreshold.Opportunity__c, new List<Spend_Threshold__c> { spendThreshold });                   
            }                
            else
            {
                retVal.get(spendThreshold.Opportunity__c).add(spendThreshold);                
            }
        }
        return retVal;
    }
}