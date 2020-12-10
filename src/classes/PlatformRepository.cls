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
                     	Pixel_Tracking__c, PlatformAccount__c, Platform__c, Platform__r.CostStructures__c, Platform__r.Name, Provider__c, Cost_Structure_Metrics__c,
                        VariableCPAC__c, VariableCPA__c, VariableCPCO__c, VariableCPC__c, VariableCPDPV__c, VariableCPER__c, VariableCPE__c,
                        VariableCPF__c, VariableCPI__c, VariableCPLC__c, VariableCPLP__c, VariableCPL__c, VariableCPM__c, VariableCPPL__c,
                        VariableCPSU__c, VariableCPS__c, VariableCPVC__c, VariableCPV__c, VariableCPCV__c,
                        CPAC__c, CPA__c, CPCO__c, CPC__c, CPDPV__c, CPER__c, CPE__c, CPF__c, CPI__c, CPLC__c, CPLP__c, CPL__c,
                        CPM__c, CPPL__c, CPSU__c, CPS__c, CPVC__c, CPV__c, CPCV__c
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
                     	Facebook_page__c, Gender__c, KPI__c, NoCostStructure__c, Objectives__c, Opportunity_Ad_Placement__c, Opportunity__c, PlatformAccount__c,
                     	Pixel_Tracking__c, Platform__c, Platform__r.CostStructures__c, Platform__r.Name, Provider__c, Cost_Structure_Metrics__c,
                        VariableCPAC__c, VariableCPA__c, VariableCPCO__c, VariableCPC__c, VariableCPDPV__c, VariableCPER__c, VariableCPE__c,
                        VariableCPF__c, VariableCPI__c, VariableCPLC__c, VariableCPLP__c, VariableCPL__c, VariableCPM__c, VariableCPPL__c,
                        VariableCPSU__c, VariableCPS__c, VariableCPVC__c, VariableCPV__c, VariableCPCV__c,
                        CPAC__c, CPA__c, CPCO__c, CPC__c, CPDPV__c, CPER__c, CPE__c, CPF__c, CPI__c, CPLC__c, CPLP__c, CPL__c,
                        CPM__c, CPPL__c, CPSU__c, CPS__c, CPVC__c, CPV__c, CPCV__c
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
            SELECT Id, Contract__c, CostStructure__c, NoCostStructure__c, Opportunity__c, Platform__c, Platform__r.CostStructures__c, Platform__r.Name,
                CPAC__c, CPA__c, CPCO__c, CPC__c, CPDPV__c, CPER__c, CPE__c, CPF__c, CPI__c, CPLC__c, CPLP__c, CPL__c,
                CPM__c, CPPL__c, CPSU__c, CPS__c, CPVC__c, CPV__c, CPCV__c
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
            SELECT Id, Contract__c, CostStructure__c, Platform__c, Platform__r.CostStructures__c, Platform__r.Name,  NoCostStructure__c, Opportunity__c,
                CPAC__c, CPA__c, CPCO__c, CPC__c, CPDPV__c, CPER__c, CPE__c, CPF__c, CPI__c, CPLC__c, CPLP__c, CPL__c,
                CPM__c, CPPL__c, CPSU__c, CPS__c, CPVC__c, CPV__c, CPCV__c
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