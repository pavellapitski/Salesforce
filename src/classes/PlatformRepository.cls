public with sharing class PlatformRepository {
    public static List<Platform__c> getAvailablePlatforms() {
        return [
            SELECT Id, Name, Prefix__c, CostStructures__c, (SELECT Id, Name, Platform__c FROM AdPlacements__r ORDER BY Name)
            FROM Platform__c
            ORDER BY Name
        ];
    }

    public static List<Platform__c> getAvailablePlatformsForContract(String contractId) {
        return [
            SELECT Id, Name, Prefix__c, CostStructures__c,
                    (SELECT Id, Name, Platform__c FROM AdPlacements__r ORDER BY Name),
                    (SELECT Id, Account_Entity__c, Age__c, Age_min__c, Age_max__c, Brand_Lift_Study__c, Companion_Banner__c, Contract__c, CostStructure__c, 
                     	CTA_Overlay_Text__c, Facebook_page__c, Gender__c, KPI__c, NoCostStructure__c, Objectives__c, Opportunity_Ad_Placement__c, Opportunity__c, 
                     	Pixel_Tracking__c, PlatformAccount__c, Platform__c, Platform__r.CostStructures__c, Platform__r.Name, Provider__c, VariableCPA__c, CPA__c,
                        VariableCPAC__c, CPAC__c, VariableCPC__c, CPC__c, VariableCPE__c, CPE__c, VariableCPER__c, CPER__c, VariableCPF__c, CPF__c,
                        VariableCPI__c, CPI__c, VariableCPL__c, CPL__c, VariableCPLC__c, CPLC__c, VariableCPM__c, CPM__c, VariableCPPL__c, CPPL__c,
                        VariableCPS__c, CPS__c, VariableCPSU__c, CPSU__c, VariableCPV__c, CPV__c, CPLP__c, VariableCPLP__c, CPCO__c, VariableCPCO__c, Cost_Structure_Metrics__c,
                        CPDPV__c, VariableCPDPV__c, CPVC__c, VariableCPVC__c
                    FROM OpportunityPlatforms__r WHERE Contract__c = :contractId)
            FROM Platform__c
            ORDER BY Name
        ];
    }

    public static List<Platform__c> getAvailablePlatformsForOpportunity(String oppId) {
        return [
            SELECT Id, Name, Prefix__c, CostStructures__c,
                    (SELECT Id, Name, Platform__c FROM AdPlacements__r ORDER BY Name),
                    (SELECT Id, Account_Entity__c, Age__c, Age_min__c, Age_max__c, Companion_Banner__c, Contract__c, CostStructure__c, CTA_Overlay_Text__c, 
                     	Facebook_page__c, Gender__c, KPI__c, NoCostStructure__c, Objectives__c, Opportunity_Ad_Placement__c, Opportunity__c, 
                     	Pixel_Tracking__c, Platform__c, Platform__r.CostStructures__c, Platform__r.Name, Provider__c, VariableCPA__c, CPA__c,
                        VariableCPAC__c, CPAC__c, VariableCPC__c, CPC__c, VariableCPE__c, CPE__c, VariableCPER__c, CPER__c, VariableCPF__c, CPF__c,
                        VariableCPI__c, CPI__c, VariableCPL__c, CPL__c, VariableCPLC__c, CPLC__c, VariableCPM__c, CPM__c, VariableCPPL__c, CPPL__c,
                        VariableCPS__c, CPS__c, VariableCPSU__c, CPSU__c, VariableCPV__c, CPV__c, VariableCPCO__c, CPCO__c, PlatformAccount__c, Cost_Structure_Metrics__c,
                        CPDPV__c, VariableCPDPV__c, CPVC__c, VariableCPVC__c
                    FROM OpportunityPlatforms__r WHERE Opportunity__c = :oppId)
            FROM Platform__c
            ORDER BY Name
        ];
    }

    public static Map<Id, List<OpportunityAdPlacement__c>> getOpportunityAdPlacementsForOpportunities(Set<Id> opportunityIds) {
        Map<Id, List<OpportunityAdPlacement__c>> retVal = new Map<Id, List<OpportunityAdPlacement__c>>();
        List<OpportunityAdPlacement__c> oppAdPlacements = [
            SELECT AdPlacement__c, Contract__c, Opportunity__c
            FROM OpportunityAdPlacement__c
            WHERE Opportunity__c IN :opportunityIds
            ORDER BY Name ASC
        ];

        for (OpportunityAdPlacement__c oppAdPlacement :oppAdPlacements) {
            if (!retVal.containsKey(oppAdPlacement.Opportunity__c)) {
                retVal.put(oppAdPlacement.Opportunity__c, new List<OpportunityAdPlacement__c>{oppAdPlacement});
            } else {
                retVal.get(oppAdPlacement.Opportunity__c).add(oppAdPlacement);
            }
        }
        return retVal;
    }

    public static Map<Id, List<OpportunityPlatform__c>> getPlatformsForContracts(Set<Id> contractIds) {
        Map<Id, List<OpportunityPlatform__c>> retVal = new Map<Id, List<OpportunityPlatform__c>>();
        List<OpportunityPlatform__c> contractPlatforms = [
            SELECT Id, Contract__c, CostStructure__c, CPA__c, CPAC__c, CPC__c, CPE__c, CPER__c, CPF__c, CPI__c, CPCO__c,
                CPL__c, CPLC__c, CPM__c, CPPL__c, CPS__c, CPSU__c, CPV__c, NoCostStructure__c, Opportunity__c,
                Platform__c, Platform__r.CostStructures__c, Platform__r.Name
            FROM OpportunityPlatform__c
            WHERE Contract__c IN :contractIds
            ORDER BY Name ASC
        ];

        for (OpportunityPlatform__c contractPlatform :contractPlatforms) {
            if (!retVal.containsKey(contractPlatform.Contract__c)) {
                retVal.put(contractPlatform.Contract__c, new List<OpportunityPlatform__c>{contractPlatform});
            } else {
                retVal.get(contractPlatform.Contract__c).add(contractPlatform);
            }
        }
        return retVal;
    }

    public static Map<Id, List<OpportunityPlatform__c>> getPlatformsForOpportunities(Set<Id> opportunityIds) {
        Map<Id, List<OpportunityPlatform__c>> retVal = new Map<Id, List<OpportunityPlatform__c>>();
        List<OpportunityPlatform__c> oppPlatforms = [
            SELECT Id, Contract__c, CostStructure__c, CPA__c, CPAC__c, CPC__c, CPE__c, CPER__c, CPF__c, CPI__c, CPCO__c,
                CPL__c, CPLC__c, CPM__c, CPPL__c, CPS__c, CPSU__c, CPV__c, NoCostStructure__c, Opportunity__c,
                Platform__c, Platform__r.CostStructures__c, Platform__r.Name
            FROM OpportunityPlatform__c
            WHERE Opportunity__c IN :opportunityIds
            ORDER BY Name ASC
        ];

        for (OpportunityPlatform__c oppPlatform :oppPlatforms) {
            if (!retVal.containsKey(oppPlatform.Opportunity__c)) {
                retVal.put(oppPlatform.Opportunity__c, new List<OpportunityPlatform__c> { oppPlatform });
            } else {
                retVal.get(oppPlatform.Opportunity__c).add(oppPlatform);
            }
        }
        return retVal;
    }
}