public with sharing class PaymentRepository {

    public static final String API_NAME = Schema.Payment__c.SObjectType.getDescribe().getName();

    public static List<Payment__c> getProjectsByOppPlatformIds(Set<Id> oppPlatformIds) {
        return [
            SELECT Id, Action_Type__c, Age__c, Age_Max__c, Age_Min__c, Brand_Lift_Study__c, Companion_Banner__c, CTA_Overlay_Text__c,
                Facebook_Page__c, Gender__c, KPI__c, Objectives__c, OpportunityPlatform__c, Opportunity__c, CostStructure__c,
                Opportunity_Ad_Placement__c, Pixel_Tracking__c, PlatformPrefix__c, Project__c, UnitCost__c, VariableUnitCost__c,
                OpportunityPlatform__r.Platform__r.Name
            FROM Payment__c
            WHERE OpportunityPlatform__c IN :oppPlatformIds
        ];
    }

    public static List<Payment__c> getPaymentsByIDs(Set<Id> paymentIDs) {
        return [
            SELECT Name, Start_Date__c, End_Date__c, Client_Spend__c, Payment__c
            FROM Payment__c
            WHERE Id IN :paymentIDs
        ];
    }

    public static List<Payment__c> getPaymentsBySubProjectIDs(Set<Id> subProjectIDs) {
        return [
            SELECT Id, Payment__c, Name, Start_Date__c, End_Date__c, Client_Spend__c
            FROM Payment__c
            WHERE Payment__c IN :subProjectIDs
        ];
    }

    /*public static List<Payment__c> getPaymentsWithSubProjectsByContractID(Id contractID) {
        return [
            SELECT Id, Margin__c, Margin_Type__c, Name, Start_Date__c, End_Date__c, Project__c, Client_Spend__c, Media_Order__c, IsOverlapping__c,
                    Payment__c, ProjectID__c, StrikeId__c, StrikeIdFormula__c, UnitCost__c, VariableUnitCost__c
            FROM Payment__c
            WHERE Project__c = :contractID AND Payment__c != NULL
        ];
    }*/

    public static List<Payment__c> getPaymentsByIdsSortedByStartDateAndStrikeID(Set<Id> projectIds) {
        return [
            SELECT Id, Action_Type__c, AdWordsSpend__c, AmountDelivered__c, Brand_Lift_Study__c, Client_Spend__c, CostStructure__c,
                    End_Date__c, InvoiceAmount__c, IsOverlapping__c, Margin__c, Margin_Type__c, Media_Order__c, Name, Payment__c,
                    Objectives__c, OpportunityPlatform__r.Platform__r.Name, OpportunityPlatform__r.Platform__c,
                    OpportunityPlatform__r.CostStructure__c, OpportunityPlatform__r.Platform__r.CostStructures__c,
                    OpportunityPlatform__r.NoCostStructure__c, Payment__r.Project__r.Gaps_Exist_Between_Projects__c, Project__c, Media_Buyer__c,
                    ProjectID__c, Start_Date__c, Quantity__c, StrikeId__c, StrikeIdFormula__c, SuggestedSpend__c, UnitCost__c, VariableUnitCost__c,
                    PlatformPrefix__c, OpportunityPlatform__r.Objectives__c, OpportunityPlatform__r.Platform_Selected__c, Timezone__c,
                    OpportunityPlatform__r.VariableCPA__c, OpportunityPlatform__r.CPA__c,
                    OpportunityPlatform__r.VariableCPAC__c, OpportunityPlatform__r.CPAC__c,
                    OpportunityPlatform__r.VariableCPC__c, OpportunityPlatform__r.CPC__c,
                    OpportunityPlatform__r.VariableCPCO__c, OpportunityPlatform__r.CPCO__c,
                    OpportunityPlatform__r.VariableCPDPV__c, OpportunityPlatform__r.CPDPV__c,
                    OpportunityPlatform__r.VariableCPE__c, OpportunityPlatform__r.CPE__c,
                    OpportunityPlatform__r.VariableCPER__c, OpportunityPlatform__r.CPER__c,
                    OpportunityPlatform__r.VariableCPF__c, OpportunityPlatform__r.CPF__c,
                    OpportunityPlatform__r.VariableCPI__c, OpportunityPlatform__r.CPI__c,
                    OpportunityPlatform__r.VariableCPL__c, OpportunityPlatform__r.CPL__c,
                    OpportunityPlatform__r.VariableCPLC__c, OpportunityPlatform__r.CPLC__c,
                    OpportunityPlatform__r.VariableCPLP__c, OpportunityPlatform__r.CPLP__c,
                    OpportunityPlatform__r.VariableCPM__c, OpportunityPlatform__r.CPM__c,
                    OpportunityPlatform__r.VariableCPPL__c, OpportunityPlatform__r.CPPL__c,
                    OpportunityPlatform__r.VariableCPS__c, OpportunityPlatform__r.CPS__c,
                    OpportunityPlatform__r.VariableCPSU__c, OpportunityPlatform__r.CPSU__c,
                    OpportunityPlatform__r.VariableCPV__c, OpportunityPlatform__r.CPV__c,
                    OpportunityPlatform__r.VariableCPVC__c, OpportunityPlatform__r.CPVC__c
            FROM Payment__c
            WHERE Id IN :projectIds
            ORDER BY Start_Date__c, StrikeId__c
        ];
    }

    public static List<Payment__c> getPaymentsByStrikeOrProjectIDs(List<String> ids) {
        return [
            SELECT ProjectID__c, StrikeId__c, Payment__r.Project__c
            FROM Payment__c
            WHERE StrikeId__c IN :ids OR ProjectID__c IN :ids
        ];
    }

    public static List<Payment__c> getProjectsForPayment(String paymentId) {
        List<Payment__c> projects = new List<Payment__c>();
        Map<String, List<Payment__c>> projectsMap = getProjectsForPayments(new Set<String>{paymentId});
        if (projectsMap.containsKey(paymentId)) {
            projects = projectsMap.get(paymentId);
        }
        return projects;
    }

    public static Map<String, List<Payment__c>> getProjectsForPayments(Set<String> paymentIds) {
        Map<String, List<Payment__c>> retVal = new Map<String, List<Payment__c>>();
        List<Payment__c> projects = [
                SELECT Id, Action_Type__c, AdWordsSpend__c, AmountDelivered__c, Brand_Lift_Study__c, Client_Spend__c, CostStructure__c,
                        End_Date__c, InvoiceAmount__c, IsOverlapping__c, Margin__c, Margin_Type__c, Media_Order__c, Name, Payment__c,
                        Objectives__c, OpportunityPlatform__r.Platform__r.Name, OpportunityPlatform__r.Platform__c,
                        OpportunityPlatform__r.CostStructure__c, OpportunityPlatform__r.Platform__r.CostStructures__c,
                        OpportunityPlatform__r.NoCostStructure__c, Payment__r.Project__r.Gaps_Exist_Between_Projects__c, Project__c, Media_Buyer__c,
                        ProjectID__c, Start_Date__c, Quantity__c, StrikeId__c, StrikeIdFormula__c, SuggestedSpend__c, UnitCost__c, VariableUnitCost__c,
                        PlatformPrefix__c, OpportunityPlatform__r.Objectives__c, OpportunityPlatform__r.Platform_Selected__c, Timezone__c,
                        OpportunityPlatform__r.VariableCPA__c, OpportunityPlatform__r.CPA__c,
                        OpportunityPlatform__r.VariableCPAC__c, OpportunityPlatform__r.CPAC__c,
                        OpportunityPlatform__r.VariableCPC__c, OpportunityPlatform__r.CPC__c,
                        OpportunityPlatform__r.VariableCPCO__c, OpportunityPlatform__r.CPCO__c,
                        OpportunityPlatform__r.VariableCPDPV__c, OpportunityPlatform__r.CPDPV__c,
                        OpportunityPlatform__r.VariableCPE__c, OpportunityPlatform__r.CPE__c,
                        OpportunityPlatform__r.VariableCPER__c, OpportunityPlatform__r.CPER__c,
                        OpportunityPlatform__r.VariableCPF__c, OpportunityPlatform__r.CPF__c,
                        OpportunityPlatform__r.VariableCPI__c, OpportunityPlatform__r.CPI__c,
                        OpportunityPlatform__r.VariableCPL__c, OpportunityPlatform__r.CPL__c,
                        OpportunityPlatform__r.VariableCPLC__c, OpportunityPlatform__r.CPLC__c,
                        OpportunityPlatform__r.VariableCPLP__c, OpportunityPlatform__r.CPLP__c,
                        OpportunityPlatform__r.VariableCPM__c, OpportunityPlatform__r.CPM__c,
                        OpportunityPlatform__r.VariableCPPL__c, OpportunityPlatform__r.CPPL__c,
                        OpportunityPlatform__r.VariableCPS__c, OpportunityPlatform__r.CPS__c,
                        OpportunityPlatform__r.VariableCPSU__c, OpportunityPlatform__r.CPSU__c,
                        OpportunityPlatform__r.VariableCPV__c, OpportunityPlatform__r.CPV__c,
                        OpportunityPlatform__r.VariableCPVC__c, OpportunityPlatform__r.CPVC__c
                FROM Payment__c
                WHERE Payment__c IN :paymentIds
                ORDER BY Start_Date__c, StrikeId__c
        ];

        for (Payment__c project :projects) {
            if (!retVal.containsKey(project.Payment__c)) {
                retVal.put(project.Payment__c, new List<Payment__c>());
            }
            retVal.get(project.Payment__c).add(project);
        }
        return retVal;
    }

    public static List<Payment__c> getProjectsWithSpendsByContractId(Id contractId) {
        return [SELECT Id, Payment__c, Start_Date__c, End_Date__c, (SELECT Project__c, Is_Sync__c, Date__c FROM ContractMediaSpends__r) FROM Payment__c WHERE Project__c = :contractId];
    }
}