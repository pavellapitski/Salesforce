public class PlatformWrapper {
    public static final String CC_METRIC_SEPARATOR = ';';

    public Boolean isSelectedInitialValue { get; set; }
    public Boolean isSelected { get; set; }
    public Map<Id, AdPlacementWrapper> adPlacementsMap { get; set; }
    public OpportunityPlatform__c oppPlatform { get; set; }
    
    public String selectedCostStructures { get; set; }
    public Map<String,String> selectedMetrics { get; set; }
    public List<CostStructureWrapper> availableCostStructures { get; set; }

    private static List<Cost_Structure_Metric__mdt> metricsMDT = Platform.METRICS_MDT;

    public PlatformWrapper(Platform__c platform) {
        Set<String> initialCostStructures = new Set<String>();
        adPlacementsMap = new Map<Id, AdPlacementWrapper>();
        availableCostStructures = new List<CostStructureWrapper>();
        
        if (!platform.OpportunityPlatforms__r.isEmpty()) {
            oppPlatform = platform.OpportunityPlatforms__r[0];
            oppPlatform.Platform_Selected__c = platform.Name;
        } else {
            oppPlatform = new OpportunityPlatform__c(Platform__r = platform, Platform__c = platform.Id);
            oppPlatform.Platform_Selected__c = platform.Name;
        }
        
        if (String.isNotBlank(oppPlatform.CostStructure__c)) {
            initialCostStructures = new Set<String>(oppPlatform.CostStructure__c.split(';'));
        }
        
        for (AdPlacement__c adPlacement : platform.AdPlacements__r) {
            adPlacementsMap.put(adPlacement.Id, new AdPlacementWrapper(adPlacement));
        }
        
        if (String.isNotBlank(platform.CostStructures__c)) {
            for (String costStructure : platform.CostStructures__c.split(';')) {
                availableCostStructures.add(new CostStructureWrapper(costStructure, initialCostStructures.contains(costStructure) ? true : false));
            }
        }

        isSelected = false;
        isSelectedInitialValue = false;
        this.oppPlatform = oppPlatform;
        selectedCostStructures = '';

        selectedMetrics = new Map<String,String>();
        for (Schema.PicklistEntry costStructure :OpportunityPlatform__c.CostStructure__c.getDescribe().getPicklistValues()) {
            selectedMetrics.put(costStructure.getLabel(), '');
        }
        if (String.isNotBlank(oppPlatform.Cost_Structure_Metrics__c)) {
            Set<String> metrics = new Set<String>(oppPlatform.Cost_Structure_Metrics__c.split(CC_METRIC_SEPARATOR));
            for (Cost_Structure_Metric__mdt metric :metricsMDT) {
                if (selectedMetrics.containsKey(metric.Cost_Structure__c) && metrics.contains(metric.Label)) {
                    selectedMetrics.put(metric.Cost_Structure__c, metric.Label);
                }
            }
        }
    }
    
    public List<AdPlacementWrapper> getAdPlacements() {
        return adPlacementsMap.values();
    }

    public class CostStructureWrapper {
        public Boolean isSelected { get; set; }
        public String name {get; set;}
        
        public CostStructureWrapper(String name, Boolean isSelected) {
            this.name = name;
            this.isSelected = isSelected;
        }
    }
}