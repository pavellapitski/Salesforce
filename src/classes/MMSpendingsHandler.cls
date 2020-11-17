public with sharing class MMSpendingsHandler implements ITrigger {

    public static Boolean skipProjectMediaSpendCreation = false;

    private Set<String> strikeIds = new Set<String>();
    private static Set<Id> problematicSpendIds = new Set<Id>(); // Ids of spends that were not assigned

    public MMSpendingsHandler() {}

    public void bulkBefore() {}

    public void bulkAfter() {}

    public void beforeInsert(List<SObject> so) {}

    public void beforeUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {}

    public void afterDelete(List<SObject> so) {}

    public void afterInsert(List<SObject> so) {
        if (skipProjectMediaSpendCreation) return;

        List<MM_Spendings__c> spends = new List<MM_Spendings__c>();
        for (SObject record :so) {
            MM_Spendings__c spend = (MM_Spendings__c) record;
            String strikeId = String.isNotBlank(spend.StrikeId__c) ? spend.StrikeId__c : spend.Strike_ID__c;

            spends.add(spend);
            strikeIds.add(strikeId);
        }
        
        // remove records from List to avoid duplicates of Contract Media Spends on Insert
        checkDuplicates(spends);
        // create Contract Media Spend records
        createContractSpend(spends);
        removeDuplicates(spends);
    }

    public void afterUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {
        if (skipProjectMediaSpendCreation) return;

        List<MM_Spendings__c> spends = new List<MM_Spendings__c>();
        for (SObject record  :so.values()) {
            MM_Spendings__c spend = (MM_Spendings__c) record;
            String strikeId = String.isNotBlank(spend.StrikeId__c) ? spend.StrikeId__c : spend.Strike_ID__c;

            spends.add(spend);
            strikeIds.add(strikeId);
        }
        updateExistingMediaSpendings(spends);
    }

    public void beforeDelete(List<SObject> so) {}

    public void andFinally() {}

    private void checkDuplicates(List<MM_Spendings__c> spends) {
        Set<String> uniqueKeys = new Set<String>();
        for (Integer i = spends.size()-1; i >= 0; i--) {
            String uniqueKey = spends[i].StrikeId__c + '_' + spends[i].Date__c;
            if (uniqueKeys.contains(uniqueKey)) {
                // Only one record should be assign on project per day
                spends.remove(i);
            } else {
                uniqueKeys.add(uniqueKey);
            }
        }
    }

    private void createContractSpend(List<MM_Spendings__c> spends) {
        Map<String, List<Payment__c>> strikeIdToProjectMap = getStrikeIdToProjectsMap();
        if (spends.isEmpty() || strikeIdToProjectMap.isEmpty())  return;

        List<Project_Media_Spend__c> contractSpends = new List<Project_Media_Spend__c>();
        List<MM_Spendings__c> notAssignedSpends = new List<MM_Spendings__c>();

        for (MM_Spendings__c spend :spends)  {
            List<Payment__c> relatedProjects = new List<Payment__c>();
            if (String.isNotBlank(spend.StrikeId__c) && strikeIdToProjectMap.containsKey(spend.StrikeId__c)) {
                relatedProjects = strikeIdToProjectMap.get(spend.StrikeId__c);
            } else if (String.isBlank(spend.StrikeId__c) && strikeIdToProjectMap.containsKey(spend.Strike_ID__c)){
                relatedProjects = strikeIdToProjectMap.get(spend.Strike_ID__c);
            }

            Boolean spendAssigned = false;
            for (Payment__c project :relatedProjects) {
                if (spend.Date__c >= project.Start_Date__c && spend.Date__c <= project.End_Date__c) {
                    contractSpends.add(newContractSpendRecord(spend, project));
                    spendAssigned = true;
                }
            }
            if (!spendAssigned) {
                notAssignedSpends.add(spend);
            }
        }

        try {
            insert contractSpends;
        } catch (Exception ex) {
            System.debug('### MMSpendingsHandler.createContractSpend: ' + ex.getMessage());
            throw new SpendManager.SpendManagerException(ex.getMessage());
        }

        createLog(notAssignedSpends);
    }

    private void createLog(List<MM_Spendings__c> notAssignedSpends) {
        List<EventLog__c> logs = new List<EventLog__c>();
        for (MM_Spendings__c spend :notAssignedSpends) {
            if (problematicSpendIds.contains(spend.Id)) continue;

            problematicSpendIds.add(spend.Id);
            EventLog__c log = EventLog.createMediaManagerLog('Unable to assign spend to project.', EventLog.STATUS_ERROR, EventLog.TYPE_INVOICE_API_SYNC, 'Spend Id: ' + spend.Id);
            log.MMSpending__c = spend.Id;
            log.Contract__c = spend.Contract__c;
            logs.add(log);
        }
        insert logs;
    }

    private void removeDuplicates(List<MM_Spendings__c> spends) {
        Map<Id, List<MM_Spendings__c>> contractSpendings = new Map<Id, List<MM_Spendings__c>>();

        Set<Id> newSpendIds = new Set<Id>();
        for (MM_Spendings__c spending :spends) {
            newSpendIds.add(spending.Id);

            if (!contractSpendings.containsKey(spending.Contract__c)) {
                contractSpendings.put(spending.Contract__c, new List<MM_Spendings__c>());
            }
            contractSpendings.get(spending.Contract__c).add(spending);
        }

        List<MM_Spendings__c> existingSpends = [
            SELECT Contract__c, Date__c, StrikeId__c, Strike_ID__c
            FROM MM_Spendings__c
            WHERE Contract__c IN :contractSpendings.keySet() AND Id NOT IN :newSpendIds
        ];

        Map<Id, MM_Spendings__c> spendingsToRemove = new Map<Id, MM_Spendings__c>();
        for (MM_Spendings__c existingSpend :existingSpends) {
            for (MM_Spendings__c newSpending :contractSpendings.get(existingSpend.Contract__c)) {
                if (newSpending.Date__c == existingSpend.Date__c && (String.isBlank(existingSpend.StrikeId__c) || existingSpend.StrikeId__c.equals(newSpending.StrikeId__c))) {
                    if (!spendingsToRemove.containsKey(existingSpend.Id)) {
                        spendingsToRemove.put(existingSpend.Id, existingSpend);
                    }
                }
            }
        }
        delete spendingsToRemove.values();
    }

    private Map<String, List<Payment__c>> getStrikeIdToProjectsMap() {
        List<Payment__c> projects = getProjectsByStrikeId();
        Map<String, List<Payment__c>> strikeIdToProjectMap = new Map<String,List<Payment__c>>();
        for (Payment__c project :projects) {
            if (!strikeIdToProjectMap.containsKey(project.StrikeId__c)) {
                strikeIdToProjectMap.put(project.StrikeId__c, new List<Payment__c>());
            }
            strikeIdToProjectMap.get(project.StrikeId__c).add(project);

            if (!strikeIdToProjectMap.containsKey(project.ProjectID__c)) {
                strikeIdToProjectMap.put(project.ProjectID__c, new List<Payment__c>());
            }
            strikeIdToProjectMap.get(project.ProjectID__c).add(project);
        }
        return strikeIdToProjectMap;
    }

    private void updateExistingMediaSpendings(List<MM_Spendings__c> spends) {
        Map<String, List<Project_Media_Spend__c>> strikeId2ContractMediaSpends = getContractMediaSpends();
        Map<String, List<Payment__c>> strikeIdToProjectMap = getStrikeIdToProjectsMap();

        Map<Id, Project_Media_Spend__c> contractMediaSpendsToUpdate = new Map<Id, Project_Media_Spend__c>();
        List<Project_Media_Spend__c> projectMediaSpendsToInsert = new List<Project_Media_Spend__c>();
        List<MM_Spendings__c> notAssignedSpends = new List<MM_Spendings__c>();
        for (MM_Spendings__c spend :spends)  {
            List<Payment__c> relatedProjects = new List<Payment__c>();
            if (String.isNotBlank(spend.StrikeId__c) && strikeIdToProjectMap.containsKey(spend.StrikeId__c)) {
                relatedProjects = strikeIdToProjectMap.get(spend.StrikeId__c);
            } else if (String.isBlank(spend.StrikeId__c) && strikeIdToProjectMap.containsKey(spend.Strike_ID__c)){
                relatedProjects = strikeIdToProjectMap.get(spend.Strike_ID__c);
            }

            List<Project_Media_Spend__c> contractMediaSpends = new List<Project_Media_Spend__c>();
            if (String.isNotBlank(spend.StrikeId__c) && strikeId2ContractMediaSpends.containsKey(spend.StrikeId__c)) {
                contractMediaSpends = strikeId2ContractMediaSpends.get(spend.StrikeId__c);
            } else if (strikeId2ContractMediaSpends.containsKey(spend.Strike_ID__c)) {
                contractMediaSpends = strikeId2ContractMediaSpends.get(spend.Strike_ID__c);
            }

            Boolean contractMediaSpendFound = false;
            for (Project_Media_Spend__c contractMediaSpend :contractMediaSpends) {
                if (contractMediaSpend.Date__c == spend.Date__c /*&& !contractMediaSpendsToUpdate.containsKey(contractMediaSpend.Id)*/) {
                    contractMediaSpendsToUpdate.put(contractMediaSpend.Id, contractMediaSpend);
                    contractMediaSpend.Amount__c = spend.Media_Spend__c;
                    contractMediaSpend.Delivered__c = spend.Delivered__c;
                    contractMediaSpend.CurrencyIsoCode = spend.CurrencyIsoCode;
                    contractMediaSpend.MMSpending__c = spend.Id;

                    contractMediaSpendFound = true;
                }
            }

            if (!contractMediaSpendFound) {
                for (Payment__c project :relatedProjects) {
                    if (spend.Date__c >= project.Start_Date__c && spend.Date__c <= project.End_Date__c) {
                        // spend can be assigned
                        projectMediaSpendsToInsert.add(newContractSpendRecord(spend, project));
                    } else {
                        // mark as not assigned spend and create a log
                        notAssignedSpends.add(spend);
                    }
                }
            }
        }
        update contractMediaSpendsToUpdate.values();
        insert  projectMediaSpendsToInsert;
        createLog(notAssignedSpends);
    }

    private Project_Media_Spend__c newContractSpendRecord(MM_Spendings__c spend, Payment__c project) {
        return new Project_Media_Spend__c(
            Delivered__c = spend.Delivered__c,
            Amount__c = spend.Media_Spend__c,
            CurrencyIsoCode = spend.CurrencyIsoCode,
            MMSpending__c = spend.Id,
            Date__c = spend.Date__c,
            Project__c = project.Id
        );
    }

    private Map<String, List<Project_Media_Spend__c>> getContractMediaSpends() {
        Map<String, List<Project_Media_Spend__c>> retVal = new Map<String, List<Project_Media_Spend__c>>();
        for (Payment__c project : getProjectsByStrikeId()) {
            if (String.isNotBlank(project.StrikeId__c)) {
                if (!retVal.containsKey(project.StrikeId__c)) {
                    retVal.put(project.StrikeId__c, new List<Project_Media_Spend__c>());
                }
                retVal.get(project.StrikeId__c).addAll(project.ContractMediaSpends__r);
            }
            if (!retVal.containsKey(project.ProjectID__c)) {
                retVal.put(project.ProjectID__c, new List<Project_Media_Spend__c>());
            }
            retVal.get(project.ProjectID__c).addAll(project.ContractMediaSpends__r);
        }
        return retVal;
    }

    private List<Payment__c> getProjectsByStrikeId() {
        return [
            SELECT Id, Start_Date__c, End_Date__c, ProjectID__c, StrikeId__c, (SELECT Date__c FROM ContractMediaSpends__r)
            FROM Payment__c
            WHERE StrikeId__c IN :strikeIds OR ProjectID__c IN :strikeIds
        ];
    }

}