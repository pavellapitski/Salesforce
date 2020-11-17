public with sharing class PlatformSectionCtrl {

    private static List<Cost_Structure_Metric__mdt> metricsMDT = Platform.METRICS_MDT;

    public Map<String, List<SelectOption>> costStructureToMetrics { get {
        if (costStructureToMetrics == null) {
            costStructureToMetrics = new Map<String, List<SelectOption>>();
            Schema.DescribeFieldResult costStructureFieldDescribe = OpportunityPlatform__c.CostStructure__c.getDescribe();
            List<Schema.PicklistEntry> costStructures = costStructureFieldDescribe.getPicklistValues();
            for (Schema.PicklistEntry costStructure :costStructures) {
                costStructureToMetrics.put(costStructure.getLabel(), new List<SelectOption>());
            }
            for (Cost_Structure_Metric__mdt metric :metricsMDT) {
                if (costStructureToMetrics.containsKey(metric.Cost_Structure__c)) {
                    costStructureToMetrics.get(metric.Cost_Structure__c).add(new SelectOption(metric.Label, metric.Label));
                }
                // otherwise a new Cost Structure should be added to OpportunityPlatform__c.CostStructure__c field
            }
        }
        return costStructureToMetrics;
    } set; }

    public List<String> selectedItems {get {
        if (selectedItems == null) {
            selectedItems = new List<String>();
        }
        return selectedItems;
    } set;}

    public PlatformWrapper platformInfo { get; set {
        platformInfo = value;
        if (selectedItems.isEmpty()) {
            if (platformInfo != null && platformInfo.oppPlatform != null && platformInfo.oppPlatform.CostStructure__c != null) {
                for (String item : platformInfo.oppPlatform.CostStructure__c.split(';')) {
                    selectedItems.add(item);
                }
            }
        }
    }}

    public void costStructureUpdated() {
        platformInfo.oppPlatform.CostStructure__c = '';
        // clean up selected metrics if needed
        Set<String> selectedItemsSet = new Set<String>(selectedItems);
        for (String ccName :platformInfo.selectedMetrics.keySet()) {
            if (!selectedItemsSet.contains(ccName)) {
                platformInfo.selectedMetrics.put(ccName, '');
            }
        }
        for (String ccName :selectedItems) {
            platformInfo.oppPlatform.CostStructure__c += ccName + ';';
        }
        platformInfo.oppPlatform.CostStructure__c.removeEnd(';');
    }

    public void noCostStructureUpdated() {}

    private List<SelectOption> options;
    public List<SelectOption> getItems() {
        options = new List<SelectOption>();
        for (PlatformWrapper.CostStructureWrapper csw :platformInfo.availableCostStructures) {
            options.add (new SelectOption (csw.name, csw.name));
        }
        return options;
    }

    public List<String> getStringItems() {
        List<String> options = new List<String>();
        for (PlatformWrapper.CostStructureWrapper csw :platformInfo.availableCostStructures) {
            for (String item: selectedItems) {
                if (item == csw.name) {
                    options.add (csw.name);
                }
            }
        }
        return options;
    }

}