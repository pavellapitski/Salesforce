public class AdPlacementWrapper 
{
    public OpportunityAdPlacement__c oppAdPlacement {get; set;}
    public Boolean isSelectedInitialValue {get; set;}
    public Boolean isSelected {get; set;}
    
    public AdPlacementWrapper(AdPlacement__c adPlacement)
    {
        this.oppAdPlacement = new OpportunityAdPlacement__c(AdPlacement__c = adPlacement.Id, AdPlacement__r = adPlacement);
        isSelected = false;
        isSelectedInitialValue = false;
    }
}