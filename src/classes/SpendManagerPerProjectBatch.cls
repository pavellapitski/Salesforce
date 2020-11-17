/**
 * Created by Pavel Lapitski on 2020-04-07.
 *
 * Created for Contracts for which clicking Refresh Spend causes "Apex CPU time limit exceeded" exception
 */

public class SpendManagerPerProjectBatch implements Database.Batchable<AggregateResult>, Database.AllowsCallouts {

    private final Id contractId { get; set; }

    public SpendManagerPerProjectBatch(Id contractId) {
        this.contractId = contractId;
    }

    public Iterable<AggregateResult> start(Database.BatchableContext bc) {
        return new AggregateResultIterable('SELECT StrikeId__c, Project__c FROM Payment__c WHERE Project__c = \'' + contractId + '\' GROUP BY StrikeId__c, Project__c');
    }

    public void execute(Database.BatchableContext bc, List<AggregateResult> aggregateResults) {
        Map<String,Id> projectNamesToContractIds = new Map<String,Id>();
        for (AggregateResult ar :aggregateResults) {
            projectNamesToContractIds.put(String.valueOf(ar.get('StrikeId__c')), (Id) ar.get('Project__c'));
        }

        Project__c parentContract = ContractRepository.getContractsByIdsForSpends(new Set<Id>{contractId})[0];

        Map<String, StrikeDataAPI.SpendCalloutResult> spendsResponseByProjectNames = StrikeDataAPI.getSpendsByProjectNames(projectNamesToContractIds);
        System.debug('### BATCH spendsResponseByProjectNames: ' + spendsResponseByProjectNames);
        Map<String, Set<String>> existingUniqueIdsByProjectNames = MMSpendingsRepository.getUniqueIdsByProjectNames(spendsResponseByProjectNames.keySet(), null);
        System.debug('### BATCH existingUniqueIdsByProjectNames: ' + existingUniqueIdsByProjectNames);

        Map<String, Utility.SpendAssignResult> result = new Map<String, Utility.SpendAssignResult>();

        List<MM_Spendings__c> allSpendsToInsert = new List<MM_Spendings__c>();
        for (String projectName :spendsResponseByProjectNames.keySet()) {
            StrikeDataAPI.SpendCalloutResult spendResponse = spendsResponseByProjectNames.get(projectName);
            Utility.SpendAssignResult assignResult = new Utility.SpendAssignResult();

            List<MM_Spendings__c> spendsToInsert = new List<MM_Spendings__c>();
            if (spendResponse.isValid) {
                if (!spendResponse.spends.isEmpty()) {
                    StrikeDataAPI.PackageType packageType = StrikeDataAPI.getPackageTypeByProjectName(projectName);
                    System.debug('### BATCH spendResponse.spends: ' + spendResponse.spends);
                    SpendManager.SpendMappingResult mappingResult = SpendManager.mapSpends(spendResponse.spends, spendsToInsert, existingUniqueIdsByProjectNames.get(projectName), parentContract, packageType);
                    System.debug('### BATCH mappingResult: ' + mappingResult);
                    if (mappingResult.getHasErrors()) {
                        assignResult.setFailure(mappingResult.getErrors());
                    } else {
                        allSpendsToInsert.addAll(spendsToInsert);
                        assignResult = null;
                    }
                } else {
                    assignResult.setFailure(SpendManager.ERROR_NO_SPENDS_RECEIVED);
                }
            } else {
                assignResult.setFailure(spendResponse.message);
            }
            result.put(projectName, assignResult);
        }

        List<Database.SaveResult> insertResults = Database.insert(allSpendsToInsert, false);
        Map<String, List<String>> projectNameToErrorsOnInsert = new Map<String, List<String>>();
        for (Integer i = 0; i < insertResults.size(); i++) {
            // assuming that order is the same in both Lists
            // MM_Spendings__c spend = allSpendsToInsert[i];
            Database.SaveResult insertResult = insertResults[i];
            String projectName = allSpendsToInsert[i].StrikeId__c;
            if (!insertResult.isSuccess()) {
                projectNameToErrorsOnInsert.put(projectName, new List<String>());
                for (Database.Error err :insertResult.getErrors()) {
                    projectNameToErrorsOnInsert.get(projectName).add(err.getMessage());
                }
            }
        }
        System.debug('### BATCH projectNameToErrorsOnInsert: ' + projectNameToErrorsOnInsert);
        for (String projectName :result.keySet()) {
            if (result.get(projectName) == null) {
                Utility.SpendAssignResult assignResult = new Utility.SpendAssignResult();
                if (projectNameToErrorsOnInsert.containsKey(projectName)) {
                    String errorString = String.join(projectNameToErrorsOnInsert.get(projectName), ';\n');
                    assignResult.setFailure(errorString);
                } else {
                    assignResult.setSuccess();
                }
                result.put(projectName, assignResult);
            } else {
                // leave the first error as main error
            }
            System.debug('### BATCH RESULT: ' + projectName + ' >>> ' + result.get(projectName));
        }
    }

    public void finish(Database.BatchableContext bc) {}


    public class AggregateResultIterable implements Iterable<AggregateResult> {
        private String query;

        public AggregateResultIterable(String soql) {
            query = soql;
        }

        public Iterator<AggregateResult> iterator() {
            return new AggregateResultIterator(query);
        }
    }

    public class AggregateResultIterator implements Iterator<AggregateResult> {
        List<AggregateResult> results {get;set;}
        Integer index {get; set;}

        public AggregateResultIterator(String query) {
            index = 0;
            results = Database.query(query);
        }

        public Boolean hasNext() {
            return results != null && !results.isEmpty() && index < results.size();
        }

        public AggregateResult next() {
            return results[index++];
        }
    }
}