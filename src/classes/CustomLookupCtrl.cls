public with sharing class CustomLookupCtrl {
    @AuraEnabled
    public static List<SObject> fetchLookUpValues(String searchKeyWord, String objectAPIName, String fieldToSearch, List<String> fieldsToSOQL) {
        String fieldsToSelect = '';
        if (fieldsToSOQL != null && fieldsToSOQL.size() > 0) {
            fieldsToSelect = ',' + String.join(fieldsToSOQL, ',');
        }

        String searchKey = searchKeyWord + '%';
        List<SObject> returnList = new List<SObject>();
        String sQuery =  'SELECT Id, ' + fieldToSearch + fieldsToSelect + ' FROM ' + objectAPIName + ' WHERE ' + fieldToSearch + ' LIKE :searchKey ORDER BY createdDate DESC LIMIT 5';
        List<SObject> records = Database.query(sQuery);

        for (sObject record: records) {
            returnList.add(record);
        }
        return returnList;
    }
}