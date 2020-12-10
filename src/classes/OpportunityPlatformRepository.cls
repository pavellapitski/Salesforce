public with sharing class OpportunityPlatformRepository {
    //public static final String API_NAME = Schema.OpportunityPlatform__c().SObjectType.getDescribe().getName();

    public static List<OpportunityPlatform__c> getByIDs(Set<Id> Ids) {
        return [
            SELECT Account_Entity__c, Age__c, Age_max__c, Age_min__c, Brand_Lift_Study__c, CTA_Overlay_Text__c, Companion_Banner__c, CostStructure__c,
                Cost_Structure_Metrics__c, Facebook_page__c, Gender__c, Id, KPI__c, NoCostStructure__c, Objectives__c, Opportunity_Ad_Placement__c,
                Opportunity__c, Pixel_Tracking__c, PlatformAccount__c, Platform__c, Platform__r.CostStructures__c, Platform__r.Name, Provider__c,
                VariableCPAC__c, VariableCPA__c, VariableCPCO__c, VariableCPC__c, VariableCPDPV__c, VariableCPER__c, VariableCPE__c,
                VariableCPF__c, VariableCPI__c, VariableCPLC__c, VariableCPLP__c, VariableCPL__c, VariableCPM__c, VariableCPPL__c,
                VariableCPSU__c, VariableCPS__c, VariableCPVC__c, VariableCPV__c, VariableCPCV__c,
                CPAC__c, CPA__c, CPCO__c, CPC__c, CPDPV__c, CPER__c, CPE__c, CPF__c, CPI__c, CPLC__c, CPLP__c, CPL__c,
                CPM__c, CPPL__c, CPSU__c, CPS__c, CPVC__c, CPV__c, CPCV__c
            FROM OpportunityPlatform__c
            WHERE Id IN :Ids
        ];
    }

    public static List<OpportunityPlatform__c> getByOpportunityId(Id oppId) {
        return [
            SELECT Account_Entity__c, Age__c, Age_max__c, Age_min__c, Brand_Lift_Study__c, CTA_Overlay_Text__c, Companion_Banner__c, CostStructure__c,
                Cost_Structure_Metrics__c, Facebook_page__c, Gender__c, Id, KPI__c, NoCostStructure__c, Objectives__c, Opportunity_Ad_Placement__c,
                Opportunity__c, Pixel_Tracking__c, PlatformAccount__c, Platform__c, Platform__r.CostStructures__c, Platform__r.Name, Provider__c,
                VariableCPAC__c, VariableCPA__c, VariableCPCO__c, VariableCPC__c, VariableCPDPV__c, VariableCPER__c, VariableCPE__c,
                VariableCPF__c, VariableCPI__c, VariableCPLC__c, VariableCPLP__c, VariableCPL__c, VariableCPM__c, VariableCPPL__c,
                VariableCPSU__c, VariableCPS__c, VariableCPVC__c, VariableCPV__c, VariableCPCV__c,
                CPAC__c, CPA__c, CPCO__c, CPC__c, CPDPV__c, CPER__c, CPE__c, CPF__c, CPI__c, CPLC__c, CPLP__c, CPL__c,
                CPM__c, CPPL__c, CPSU__c, CPS__c, CPVC__c, CPV__c, CPCV__c
            FROM OpportunityPlatform__c
            WHERE Opportunity__c = :oppId
        ];
    }
}