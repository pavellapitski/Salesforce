public class ContractSalesRepHandler implements ITrigger {
    private Boolean isInsert = false;
    
    public ContractSalesRepHandler() {}
    
    public void bulkBefore() {}
    
    public void bulkAfter() {}
    
    public void beforeInsert(List<SObject> so) {
        Set<String> newUniqueIds = new Set<String>();
        for (Contract_Sales_Rep__c salesRep :(List<Contract_Sales_Rep__c>) so) {
            salesRep.Unique_ID__c = salesRep.Commission_Profile__c + '#' + salesRep.Contract__c;
            newUniqueIds.add(salesRep.Unique_ID__c);
            
            if (salesRep.CurrencyIsoCode != salesRep.CommissionProfileCurrency__c) {
                salesRep.CurrencyIsoCode = salesRep.CommissionProfileCurrency__c;
            }
            
            if (salesRep.Commission_Profile_Commission_Type__c != null) {
                salesRep.Commission_Type__c = salesRep.Commission_Profile_Commission_Type__c;
            }
        }
    }
    
    public void beforeUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {
        for (Contract_Sales_Rep__c salesRep :((Map<Id, Contract_Sales_Rep__c>) so).values()) {
            if (salesRep.CurrencyIsoCode != salesRep.CommissionProfileCurrency__c) {
                salesRep.CurrencyIsoCode = salesRep.CommissionProfileCurrency__c;
            }
            if (salesRep.Commission_Profile_Commission_Type__c != null) {
                salesRep.Commission_Type__c = salesRep.Commission_Profile_Commission_Type__c;
            }
        }
    }
    
    public void beforeDelete(List<SObject> so) {}
    
    public void afterInsert(List<SObject> so) {
        MonthlyDistribution.assignSalesRepToMonthlyDistribution((List<Contract_Sales_Rep__c>)so);
        isInsert = true; 
        List<Contract_Sales_Rep__c> salesReps = (List<Contract_Sales_Rep__c>) so;
        recalculateCommissions(salesReps);
        
        Set<Id> contractsWithInsertedRepsSet = new Set <Id> ();
        for (Contract_Sales_Rep__c rep :salesReps) {
            contractsWithInsertedRepsSet.add (rep.Contract__c);
        }
        setDefaultPercentageOfGPAllocation(contractsWithInsertedRepsSet);
    }
    
    public void afterUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {
        List <Contract_Sales_Rep__c> salesReps = new List <Contract_Sales_Rep__c>();
        for (Contract_Sales_Rep__c newRep : (Contract_Sales_Rep__c []) so.values()) {
            salesReps.add (newRep);
        }
        recalculateCommissions(salesReps);
    }
    
    public void afterDelete(List<SObject> so) {
        Set <Id> contractsWithDeletedRepsSet = new Set<Id> ();
        for (Contract_Sales_Rep__c rep :(List<Contract_Sales_Rep__c>) so) {
            contractsWithDeletedRepsSet.add (rep.Contract__c);
        }
        
        List <Project__c> contractsWithDeletedReps = [SELECT Id FROM Project__c WHERE Id IN :contractsWithDeletedRepsSet];
        ConSalesRepExpCommissionCalculator.calculateExpectedCommission(contractsWithDeletedReps);
        setDefaultPercentageOfGPAllocation(contractsWithDeletedRepsSet);
    }
    
    public void andFinally() {}
    
    private void recalculateCommissions(List <Contract_Sales_Rep__c> salesReps) {
        List<Contract_Sales_Rep__c> fullList = new List<Contract_Sales_Rep__c>();
        List<Id> commissionProfileIds = new List<Id>();
        Set<Id> contractIds = new Set<Id>();
        for (Contract_Sales_Rep__c salesRep : salesReps) {
            if (salesRep.Commission_Profile_Commission_Type__c == Label.COMMISSION_TYPE_SHARED_INSIDE_SALES){
                commissionProfileIds.add(salesRep.Commission_Profile__c);
                contractIds.add(salesRep.Contract__c);
            }
        }
        
        if (commissionProfileIds.size() > 0 && isInsert) {
            List <Commission_Profile__c> missingSharedRepsProfiles = [
                SELECT Id
                FROM Commission_Profile__c
                WHERE CommissionType__c = :Label.COMMISSION_TYPE_SHARED_INSIDE_SALES
                    AND ActiveUser__c = TRUE
                    AND Id NOT IN :commissionProfileIds
                    AND Id NOT IN (SELECT Commission_Profile__c FROM Contract_Sales_Rep__c WHERE Contract__c IN :contractIds)
            ];
            if (missingSharedRepsProfiles.size() > 0) {
                List <Contract_Sales_Rep__c> missingSalesReps = new List<Contract_Sales_Rep__c>();
                for (Commission_Profile__c missingRep :missingSharedRepsProfiles) {
                    Contract_Sales_Rep__c rep = new Contract_Sales_Rep__c ();
                    rep.Commission_Profile__c = missingRep.Id;
                    rep.Contract__c = salesReps [0].Contract__c;
                    missingSalesReps.add (rep);
                }
                Database.insert(missingSalesReps,false);
                fullList.addAll(missingSalesReps);
            }
        }
        fullList.addAll(salesReps);
        ConSalesRepExpCommissionCalculator.calculateExpectedCommission(fullList);
        //ConSalesRepExpCommissionCalculator.SALES_REP_EXPECTED_COMMISSIONS_RECALCULATED = false;                    
    }
    
    private void setDefaultPercentageOfGPAllocation(Set<Id> contractIDs) {
        List<Contract_Sales_Rep__c> repsToUpdate = new List <Contract_Sales_Rep__c>();
        for (Project__c contract :[
            SELECT Id, (SELECT Id, Commission_Profile__r.GP_Bonus__c FROM Sales_Reps__r)
            FROM Project__c
            WHERE Id IN :contractIDs
        ]) {
            Integer repsWithBonus = 0;
            for (Contract_Sales_Rep__c rep : contract.Sales_Reps__r) {
                if (rep.Commission_Profile__r.GP_Bonus__c) {
                    repsWithBonus++;
                }
            }
            for (Contract_Sales_Rep__c rep :contract.Sales_Reps__r) {
                if (rep.Commission_Profile__r.GP_Bonus__c) {
                    rep.percentage_of_GP_allocation__c = 100.0 / repsWithBonus;
                } else {
                    rep.percentage_of_GP_allocation__c = null;
                }
                repsToUpdate.add(rep);
            }
        }    
        update repsToUpdate;
    }
}