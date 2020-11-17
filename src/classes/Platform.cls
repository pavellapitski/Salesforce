public with sharing class Platform {

    public static final List<Cost_Structure_Metric__mdt> METRICS_MDT = [SELECT Id, Label, Cost_Structure__c FROM Cost_Structure_Metric__mdt];

    public static Map<String, String> metricsToCCNames { get {
        if (metricsToCCNames == null) {
            metricsToCCNames = new Map<String,String>();
            for (Cost_Structure_Metric__mdt metric :Platform.METRICS_MDT) {
                metricsToCCNames.put(metric.Label, metric.Cost_Structure__c);
            }
        }
        return metricsToCCNames;
    } set; }

    public static String initPlatformsInfo(Map<Id, PlatformWrapper> platformsMap, List<OpportunityPlatform__c> oppPlatforms, List<OpportunityAdPlacement__c> oppAdPlacements, String platformString) {
        List<String> platformNames = new List<String>();
        for (OpportunityPlatform__c oppPlatform : oppPlatforms) {
            PlatformWrapper currentPlatform = platformsMap.get(oppPlatform.Platform__c);
            currentPlatform.isSelectedInitialValue = true;
            currentPlatform.isSelected = true;
            platformNames.add(oppPlatform.Platform__r.Name);
        }

        platformString = String.join(platformNames, ', ');
        for (OpportunityAdPlacement__c oppAdPlacement : oppAdPlacements) {
            AdPlacementWrapper currentAdPlacement = platformsMap.get(oppAdPlacement.AdPlacement__r.Platform__c).adPlacementsMap.get(oppAdPlacement.AdPlacement__c);
            currentAdPlacement.oppAdPlacement.Id = oppAdPlacement.Id;
            currentAdPlacement.isSelectedInitialValue = true;
            currentAdPlacement.isSelected = true;
        }
        return platformString;
    }

    public static void savePlatformInfo(Id oppId, Id contractId, Map<Id, PlatformWrapper> platformsMap) {
        List<OpportunityPlatform__c> opportunityPlatformsToUpsert = new List<OpportunityPlatform__c>();
        List<OpportunityPlatform__c> opportunityPlatformsToDelete = new List<OpportunityPlatform__c>();
        List<OpportunityAdPlacement__c> opportunityAdPlacementsToDelete = new List<OpportunityAdPlacement__c>();
        List<OpportunityAdPlacement__c> opportunityAdPlacementsToUpsert = new List<OpportunityAdPlacement__c>();

        for (PlatformWrapper platform :platformsMap.values()) {
            OpportunityPlatform__c oppPlatform = platform.oppPlatform;
            System.debug('### platform: ' + platform.oppPlatform);
            if (String.isBlank(oppPlatform.Opportunity__c)) {
                if (String.isNotBlank(oppId)) {
                    oppPlatform.Opportunity__c = oppId;
                }
                if (String.isNotBlank(contractId)) {
                    oppPlatform.Contract__c = contractId;
                }
            }

            // remove empty values
            List<String> metrics = platform.selectedMetrics.values();
            Integer j = 0;
            while (j < metrics.size()) {
                if (metrics.get(j) == null || metrics.get(j) == '') {
                    metrics.remove(j);
                } else {
                    j++;
                }
            }
            oppPlatform.Cost_Structure_Metrics__c = String.join(metrics, PlatformWrapper.CC_METRIC_SEPARATOR);

            if (platform.isSelected) {
                opportunityPlatformsToUpsert.add(oppPlatform);
            } else if (!platform.isSelected && platform.isSelectedInitialValue &&  oppPlatform.Id != null) {
                opportunityPlatformsToDelete.add(oppPlatform);
            }

            for (AdPlacementWrapper oppAdPlacement : platform.adPlacementsMap.values()) {
                OpportunityAdPlacement__c adPlacement = oppAdPlacement.oppAdPlacement;

                if (String.isBlank(adPlacement.Opportunity__c) && String.isNotBlank(oppId)) {
                    adPlacement.Opportunity__c = oppId;
                }
                if (String.isBlank(adPlacement.Contract__c) && String.isNotBlank(contractId)) {
                    adPlacement.Contract__c = contractId;
                }

                if (oppAdPlacement.isSelected && platform.isSelected) {
                    opportunityAdPlacementsToUpsert.add(adPlacement);
                } else if ((!oppAdPlacement.isSelected || !platform.isSelected) && oppAdPlacement.isSelectedInitialValue && adPlacement.Id != null) {
                    opportunityAdPlacementsToDelete.add(adPlacement);
                }
            }
        }
        upsert opportunityPlatformsToUpsert;

        for (OpportunityAdPlacement__c oppAdPlacement : opportunityAdPlacementsToUpsert) {
            if (String.isBlank(oppAdPlacement.OpportunityPlatform__c)) {
                oppAdPlacement.OpportunityPlatform__c = platformsMap.get(oppAdPlacement.AdPlacement__r.Platform__c).oppPlatform.Id;
            }
        }
        for (OpportunityPlatform__c oppPlatform : opportunityPlatformsToDelete) {
            platformsMap.get(oppPlatform.Platform__c).isSelectedInitialValue = false;
            platformsMap.get(oppPlatform.Platform__c).isSelected = false;
        }
        upsert opportunityAdPlacementsToUpsert;
        delete opportunityAdPlacementsToDelete;

        for (OpportunityAdPlacement__c oppAdPlacement : opportunityAdPlacementsToDelete) {
            Id platformId = oppAdPlacement.AdPlacement__r.Platform__c;
            platformsMap.get(platformId).adPlacementsMap.get(oppAdPlacement.AdPlacement__c).isSelectedInitialValue = false;
            platformsMap.get(platformId).adPlacementsMap.get(oppAdPlacement.AdPlacement__c).isSelected = false;
        }
        delete opportunityPlatformsToDelete;
    }
}