public class MMSpendingsRepository {

    public static String DATA_ERR    = 'Incorrect data has been delivered.';
    public static String NO_CONTRACT = 'Following Contracts included in report have not been found: \n';
    public static String CURR_ERR    = 'Received Media Spend information has a different currency than the one on the following Contracts: \n';
    public static String INSERT_OK   = 'Media Manager Spendings have been inserted successfuly.';
    public static String INSERT_ERR  = 'Error occured while inserting Media Manager spendings: ';
    public static String AD_WORDS_ACCOUNT_ERR = 'Received Media Spend information has a different AdWords Account than following Contracts: \n';
    public static String DBM_ACCOUNT_ERR = 'Received Media Spend information has a different DBM Account than following Contracts: \n';

    public static final String UNIQUE_ID_PATTERN = '{0}_{1}_{2}_{3}_{4}_1';// "1" at the end means that record is Sync with StrikeDataWarehouse

    public static Map<Id, Set<String>> getUniqueIdsForAWSpends(Set<Id> contractIds) {
        Map<Id, Set<String>> contractIdToUniqueID = new Map<Id, Set<String>>();
        for (MM_Spendings__c spend :[SELECT Unique_Id__c, Contract__c FROM MM_Spendings__c WHERE Contract__c IN :contractIds AND Type__c = 'AdWords']) {
            if (!contractIdToUniqueID.containsKey(spend.Contract__c)) {
                contractIdToUniqueID.put(spend.Contract__c, new Set<String>());
            }
            contractIdToUniqueID.get(spend.Contract__c).add(spend.Unique_Id__c);
        }
        return contractIdToUniqueID;
    }

    public static Map<String, Set<String>> getUniqueIdsByProjectNames(Set<String> projectNames, StrikeDataAPI.PackageType packageType) {
        Map<String, Set<String>> projectNameToUniqueIds = new Map<String, Set<String>>();
        List<MM_Spendings__c> spends;
        if (packageType == null) {
            spends = [SELECT Unique_Id__c, StrikeId__c FROM MM_Spendings__c WHERE StrikeId__c IN :projectNames];
        } else {
            spends = [SELECT Unique_Id__c, StrikeId__c FROM MM_Spendings__c WHERE StrikeId__c IN :projectNames AND Type__c = :packageType.name()];
        }

        for (MM_Spendings__c spend :spends) {
            if (!projectNameToUniqueIds.containsKey(spend.StrikeId__c)) {
                projectNameToUniqueIds.put(spend.StrikeId__c, new Set<String>());
            }
            projectNameToUniqueIds.get(spend.StrikeId__c).add(spend.Unique_Id__c);
        }
        // some projects might not have related MM_Spendings records
        // fill the collection by keys with empty Sets. Need for a Job call based on platform name
        for (String projectName :projectNames) {
            if (!projectNameToUniqueIds.containsKey(projectName)) {
                projectNameToUniqueIds.put(projectName, new Set<String>());
            }
        }
        return projectNameToUniqueIds;
    }
}