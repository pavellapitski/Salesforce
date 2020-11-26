public class OpportunityPlatformHandler implements ITrigger {
    @TestVisible private static Boolean run = true;
    @TestVisible private static final String EX_PLATFORM_USED_PATTERN = '{0} is used in {1} and cannot be deleted.';

    public void bulkBefore() {}

    public void bulkAfter() {}

    public void beforeInsert(List<SObject> so) {
        List<OpportunityPlatform__c> opportunityPlatforms = (List<OpportunityPlatform__c>) so;
        validatePlatformAccount(opportunityPlatforms);
        updateContractOpportunityReference(opportunityPlatforms);
    }

    public void beforeUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {
        Map<Id, OpportunityPlatform__c> newMap = (Map<Id, OpportunityPlatform__c>) so;
		
        validatePlatformAccount(newMap.values());
        
        for (OpportunityPlatform__c oppPlatform : newMap.values()) {
            if (oppPlatform.NoCostStructure__c) {
                oppPlatform.CostStructure__c = '';
                oppPlatform.CPA__c = null;
                oppPlatform.CPAC__c = null;
                oppPlatform.CPC__c = null;
                oppPlatform.CPE__c = null;
                oppPlatform.CPER__c = null;
                oppPlatform.CPF__c = null;
                oppPlatform.CPI__c = null;
                oppPlatform.CPL__c = null;
                oppPlatform.CPLC__c = null;
                oppPlatform.CPM__c = null;
                oppPlatform.CPPL__c = null;
                oppPlatform.CPSU__c = null;
                oppPlatform.CPS__c = null;
                oppPlatform.CPV__c = null;
                oppPlatform.CPVC__c = null;
                oppPlatform.CPDPV__c = null;
                oppPlatform.VariableCPA__c = false;
                oppPlatform.VariableCPAC__c = false;
                oppPlatform.VariableCPC__c = false;
                oppPlatform.VariableCPE__c = false;
                oppPlatform.VariableCPER__c = false;
                oppPlatform.VariableCPF__c = false;
                oppPlatform.VariableCPI__c = false;
                oppPlatform.VariableCPL__c = false;
                oppPlatform.VariableCPLC__c = false;
                oppPlatform.VariableCPM__c = false;
                oppPlatform.VariableCPPL__c = false;
                oppPlatform.VariableCPS__c = false;
                oppPlatform.VariableCPSU__c = false;
                oppPlatform.VariableCPV__c = false;
                oppPlatform.VariableCPDPV__c = false;
                oppPlatform.VariableCPVC__c = false;
                oppPlatform.Cost_Structure_Metrics__c = '';
            }
        }
    }

    public void beforeDelete(List<SObject> so) {
        Set<Id> parentContractsIDs = new Set<Id>();
        for (OpportunityPlatform__c oppPlatform :(List<OpportunityPlatform__c>) so) {
            if (String.isNotBlank(oppPlatform.Contract__c)) {
                parentContractsIDs.add(oppPlatform.Contract__c);
            }
        }

        for (Project__c contract :[SELECT Id, Name, (SELECT Id, OpportunityPlatform__c, Name FROM Payments__r) FROM Project__c WHERE Id IN :parentContractsIDs]) {
            for (Payment__c project :contract.Payments__r) {
                for (OpportunityPlatform__c oppPlatform :(List<OpportunityPlatform__c>) so) {
                    if (oppPlatform.Id == project.OpportunityPlatform__c) {
                        oppPlatform.addError(String.format(EX_PLATFORM_USED_PATTERN, new List<String>{oppPlatform.Name, project.Name}));
                    }
                }
            }
        }
    }

    public void afterInsert(List<SObject> so) {
        List<Id> oppPlatformsIDs = new List<Id>();
        List<OpportunityPlatform__c> toModify = new List <OpportunityPlatform__c> ();
        for (OpportunityPlatform__c oppPlatform :(List<OpportunityPlatform__c>) so) {
            oppPlatformsIDs.add (oppPlatform.Id);
            if (!Test.isRunningTest() && null == oppPlatform.Salesforce_ID__c || String.isBlank(oppPlatform.Salesforce_ID__c)) {
                toModify.add(new OpportunityPlatform__c(Id = oppPlatform.Id, Salesforce_ID__c = oppPlatform.Id));
            }
        }
        update toModify;

        if (run) {
            updatePlatforms(oppPlatformsIDs);
            run = false;
        }
    }

    public void afterUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {
        Map<Id, OpportunityPlatform__c> oldMap = (Map<Id, OpportunityPlatform__c>) oldSo;
        Map<Id, OpportunityPlatform__c> newMap = (Map<Id, OpportunityPlatform__c>) so;

        updateProjects(oldMap, newMap);
        if (run) {
            updatePlatforms(new List<Id>(so.keySet()));
            run = false;
        }
    }

    public void afterDelete(List<SObject> so) {
        List<Payment__c> projects = PaymentRepository.getProjectsByOppPlatformIds((new Map<Id,SObject>(so)).keySet());
        updateProjectsMetrics(projects);
        update projects;
    }

    private void updateProjectsMetrics(List<Payment__c> projects) {
        for (Payment__c project :projects) {
            project.Metric__c = '';
        }
    }

    public void andFinally() {}

    public static void updatePlatforms(List<Id> oppPlatforms) {
        Map<Id, Opportunity> oppsToUpdateMap = new Map<Id, Opportunity> ();
        Map<Id, Project__c> contractsToUpdateMap = new Map<Id, Project__c> ();
        Map<Id, OpportunityPlatform__c> oppPlatformMap = new Map<Id, OpportunityPlatform__c>([
            SELECT Id, Platform__r.Name, Opportunity__r.Platforms__c, Contract__r.Platforms__c
            FROM OpportunityPlatform__c
            WHERE Id IN :oppPlatforms
        ]);

        for (Id oppPlatformId : oppPlatformMap.keySet()) {
            if (oppPlatformMap.get(oppPlatformId).Opportunity__r.Platforms__c == null) {
                oppPlatformMap.get(oppPlatformId).Opportunity__r.Platforms__c = '';
            }
            if (oppPlatformMap.get(oppPlatformId).Opportunity__r.Platforms__c != '') {
                oppPlatformMap.get(oppPlatformId).Opportunity__r.Platforms__c += '; ';
            }
            if (!oppPlatformMap.get(oppPlatformId).Opportunity__r.Platforms__c.contains (oppPlatformMap.get(oppPlatformId).Platform__r.Name)) {
                oppPlatformMap.get(oppPlatformId).Opportunity__r.Platforms__c += oppPlatformMap.get(oppPlatformId).Platform__r.Name;

                List <String> oppsPlatformsString = oppPlatformMap.get(oppPlatformId).Opportunity__r.Platforms__c.split ('; ');
                oppsPlatformsString.sort();
                oppPlatformMap.get(oppPlatformId).Opportunity__r.Platforms__c = String.join(oppsPlatformsString, '; ');
                oppsToUpdateMap.put (oppPlatformMap.get (oppPlatformId).Opportunity__c, oppPlatformMap.get(oppPlatformId).Opportunity__r);
            }
            if (oppPlatformMap.get(oppPlatformId).Contract__r != null) {
                if (oppPlatformMap.get(oppPlatformId).Contract__r.Platforms__c == null) {
                    oppPlatformMap.get(oppPlatformId).Contract__r.Platforms__c = '';
                }
                if (oppPlatformMap.get(oppPlatformId).Contract__r.Platforms__c == '') {
                    oppPlatformMap.get(oppPlatformId).Contract__r.Platforms__c = oppPlatformMap.get(oppPlatformId).Opportunity__r.Platforms__c;
                    contractsToUpdateMap.put(oppPlatformMap.get(oppPlatformId).Contract__c, oppPlatformMap.get(oppPlatformId).Contract__r);
                }
            }
        }
        update oppsToUpdateMap.values();
        update contractsToUpdateMap.values();
    }

    public static void updateContractOpportunityReference(List<OpportunityPlatform__c> opportunityPlatforms) {
        Map<Id, List<OpportunityPlatform__c>> opportunityPlatformsForOpportunities = new Map<Id, List<OpportunityPlatform__c>>();
        Map<Id, List<OpportunityPlatform__c>> opportunityPlatformsForContracts = new Map<Id, List<OpportunityPlatform__c>>();

        for (OpportunityPlatform__c oppPlatform : opportunityPlatforms) {
            if (!String.isBlank(oppPlatform.Opportunity__c) && String.isBlank(oppPlatform.Contract__c)) {
                if (!opportunityPlatformsForOpportunities.containsKey(oppPlatform.Opportunity__c)) {
                    opportunityPlatformsForOpportunities.put(oppPlatform.Opportunity__c, new List<OpportunityPlatform__c> { oppPlatform } );
                } else {
                    opportunityPlatformsForOpportunities.get(oppPlatform.Opportunity__c).add(oppPlatform);
                }
            } else if (!String.isBlank(oppPlatform.Contract__c) && String.isBlank(oppPlatform.Opportunity__c)) {
                if (!opportunityPlatformsForContracts.containsKey(oppPlatform.Contract__c)) {
                    opportunityPlatformsForContracts.put(oppPlatform.Contract__c, new List<OpportunityPlatform__c> { oppPlatform } );
                } else {
                    opportunityPlatformsForContracts.get(oppPlatform.Contract__c).add(oppPlatform);
                }
            }
        }

        if (!opportunityPlatformsForOpportunities.isEmpty()) {
            for (Opportunity opp : [SELECT Id, (SELECT Id FROM Projects__r) FROM Opportunity WHERE Id IN :opportunityPlatformsForOpportunities.keySet()]) {
                if (!opp.Projects__r.isEmpty()) {
                    for (OpportunityPlatform__c oppPlatform : opportunityPlatformsForOpportunities.get(opp.Id)) {
                        oppPlatform.Contract__c = opp.Projects__r[0].Id;
                    }
                }
            }
        }

        if (!opportunityPlatformsForContracts.isEmpty()) {
            for (Project__c contract : [SELECT Id, Opportunity__c FROM Project__c WHERE Id IN :opportunityPlatformsForContracts.keySet()]) {
                if (!String.isBlank(contract.Opportunity__c)) {
                    for (OpportunityPlatform__c oppPlatform : opportunityPlatformsForContracts.get(contract.Id)) {
                        oppPlatform.Opportunity__c = contract.Opportunity__c;
                    }
                }
            }
        }
    }

    private static void updateProjects(Map<Id, OpportunityPlatform__c> oldMap, Map<Id, OpportunityPlatform__c> newMap) {
        List<Payment__c> projectsToUpdate = new List<Payment__c>();

        for (Payment__c project :PaymentRepository.getProjectsByOppPlatformIds(newMap.keySet())) {
            OpportunityPlatform__c oppPlatform = newMap.get(project.OpportunityPlatform__c);
            if (oppPlatform == null) continue;


            project.KPI__c = oppPlatform.KPI__c;
            project.CTA_Overlay_Text__c = oppPlatform.CTA_Overlay_Text__c;
            project.Pixel_Tracking__c = oppPlatform.Pixel_Tracking__c;
            project.Companion_Banner__c = oppPlatform.Companion_Banner__c;
            project.Opportunity__c = oppPlatform.Opportunity__c;
            project.Age__c = oppPlatform.Age__c;
            project.Age_Max__c = oppPlatform.Age_Max__c;
            project.Age_Min__c = oppPlatform.Age_Min__c;
            project.Gender__c = oppPlatform.Gender__c;
            project.Facebook_Page__c = oppPlatform.Facebook_page__c;
            project.Objectives__c = oppPlatform.Objectives__c;
            project.Opportunity_Ad_Placement__c = oppPlatform.Opportunity_Ad_Placement__c;

            if (oppPlatform.NoCostStructure__c) {
                project.UnitCost__c = null;
            } else {
                Boolean isPlatformChanged = oppPlatform.Platform__c != oldMap.get(project.OpportunityPlatform__c).Platform__c;
                String costStructureOnProject = project.CostStructure__c;

                List<String> platformCostStructures = oppPlatform.CostStructure__c.split(';'); // split values in multipicklist field
                System.debug('### isPlatformChanged: ' + isPlatformChanged);
                System.debug('### costStructureOnProject: ' + costStructureOnProject);
                for (String costStructure :platformCostStructures) {
                    // if Platform was not changed but CCs were changed and they contain previous value
                    if (String.isNotBlank(costStructureOnProject) && !isPlatformChanged) {
                        if (costStructure == costStructureOnProject) {
                            assignCostStructureData(project, costStructure, oppPlatform);
                            // value is assigned, exit  the loop
                            break;
                        } else {
                            // reset CC to update it below
                            project.CostStructure__c = null;
                        }
                    }
                }

                if (isPlatformChanged || project.CostStructure__c == null) {
                    // Assign the first Cost Structure for a new Platform in a list of values
                    assignCostStructureData(project, platformCostStructures[0], oppPlatform);
                }
            }

            // update Metrics field in accordance with Cost Structure(CostStructure__c) and Platform(OpportunityPlatform__r.Platform__r.Name) selected
            if (String.isNotBlank(oppPlatform.Cost_Structure_Metrics__c) && String.isNotBlank(project.CostStructure__c)) {
                List<String> allMetrics = oppPlatform.Cost_Structure_Metrics__c.split(PlatformWrapper.CC_METRIC_SEPARATOR);
                for (String selectedMetric :allMetrics) {
                    String ccName = Platform.metricsToCCNames.containsKey(selectedMetric) ? Platform.metricsToCCNames.get(selectedMetric) : '';
                    if (project.CostStructure__c == ccName) {
                        project.Metric__c = selectedMetric;
                    }
                }
            }
            projectsToUpdate.add(project);
        }
        System.debug('### projects to update:' + projectsToUpdate);
        update projectsToUpdate;
    }

    private static void assignCostStructureData(Payment__c project, String costStructure, OpportunityPlatform__c oppPlatform) {
        Decimal unitCost = (Decimal) oppPlatform.get(costStructure + '__c');
        Boolean variable = (Boolean) oppPlatform.get('Variable' + costStructure + '__c');
        project.CostStructure__c = costStructure;
        project.UnitCost__c = (unitCost != project.UnitCost__c) ? unitCost : project.UnitCost__c;
        project.VariableUnitCost__c = (variable != project.VariableUnitCost__c) ? variable : project.VariableUnitCost__c;
    }
    
    private static void validatePlatformAccount(List<OpportunityPlatform__c> oppPlatforms) {
        for (OpportunityPlatform__c oppPlatform :oppPlatforms) {
            if (oppPlatform.Provider__c.toLowerCase() == 'dbm' && !containsOnlyNumbersOrEmpty(oppPlatform.PlatformAccount__c)) {
                oppPlatform.PlatformAccount__c.addError('A numeric value is required');
            }
        }
    }

    private static Boolean containsOnlyNumbersOrEmpty(String valueToCheck) {
        return (String.isBlank(valueToCheck)) ? true : valueToCheck.containsOnly('1234567890');
    }
}