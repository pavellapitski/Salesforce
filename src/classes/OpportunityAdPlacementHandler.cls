public class OpportunityAdPlacementHandler implements ITrigger {
    public OpportunityAdPlacementHandler() {}
    
    public void bulkBefore() {}

    public void bulkAfter() {}

    public void beforeInsert(List<SObject> so) {
        updateContractOpportunityReference((List<OpportunityAdPlacement__c>) so);
    }

    public void beforeUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {}
    
    public void beforeDelete(List<SObject> so) {}

    public void afterInsert(List<SObject> so) {}
    
    public void afterUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {}
        
    public void afterDelete(List<SObject> so) {}

    public void andFinally() {} 
    
    private void updateContractOpportunityReference(List<OpportunityAdPlacement__c> opportunityAdPlacements) {
        Map<Id, List<OpportunityAdPlacement__c>> opportunityAdPlacementsForOpportunities = new Map<Id, List<OpportunityAdPlacement__c>>();
        Map<Id, List<OpportunityAdPlacement__c>> opportunityAdPlacementsForContracts = new Map<Id, List<OpportunityAdPlacement__c>>();
                
        for (OpportunityAdPlacement__c oppAdPlacement : opportunityAdPlacements) {
            if (String.isNotBlank(oppAdPlacement.Opportunity__c) && String.isBlank(oppAdPlacement.Contract__c)) {
            	if (!opportunityAdPlacementsForOpportunities.containsKey(oppAdPlacement.Opportunity__c)) {
                    opportunityAdPlacementsForOpportunities.put(oppAdPlacement.Opportunity__c, new List<OpportunityAdPlacement__c>{oppAdPlacement} );
                } else {
                    opportunityAdPlacementsForOpportunities.get(oppAdPlacement.Opportunity__c).add(oppAdPlacement);                     
                }
            } else if (String.isNotBlank(oppAdPlacement.Contract__c) && String.isBlank(oppAdPlacement.Opportunity__c)) {
            	if (!opportunityAdPlacementsForContracts.containsKey(oppAdPlacement.Contract__c)) {
                    opportunityAdPlacementsForContracts.put(oppAdPlacement.Contract__c, new List<OpportunityAdPlacement__c>{oppAdPlacement} );
                } else {
                    opportunityAdPlacementsForContracts.get(oppAdPlacement.Contract__c).add(oppAdPlacement);                     
                }
            }
        }
        
        if (!opportunityAdPlacementsForOpportunities.isEmpty()) {
        	for (Opportunity opp :OpportunityRepository.getOpportunityByIds(opportunityAdPlacementsForOpportunities.keySet())) {
            	if (!opp.Projects__r.isEmpty()) {
                	for (OpportunityAdPlacement__c oppAdPlacement :opportunityAdPlacementsForOpportunities.get(opp.Id)) {
                    	oppAdPlacement.Contract__c = opp.Projects__r[0].Id;                          
                    }
                }
            }                
        }
        
        if (!opportunityAdPlacementsForContracts.isEmpty()) {
        	for (Project__c contract :ContractRepository.getContractByIds(opportunityAdPlacementsForContracts.keySet())) {
            	if (String.isNotBlank(contract.Opportunity__c)) {
                	for (OpportunityAdPlacement__c oppAdPlacement : opportunityAdPlacementsForContracts.get(contract.Id)) {
                    	oppAdPlacement.Opportunity__c = contract.Opportunity__c;                          
                    }
                }
            }                
        }        
    }
}