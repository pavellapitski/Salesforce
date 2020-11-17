@IsTest
private class CustomLookupCtrlTest {
    @isTest static void fetchLookUpValuesTest_fieldsToSOQLEmpty() {
        String searchKeyWord = 'Acc';
        String fieldToSearch = 'Name';
        List<String> fieldsToSOQL = new List<String>();

        Account acc1 = TestHelper.createAccount(searchKeyWord + '1',false);
        Account acc2 = TestHelper.createAccount(searchKeyWord + '2',false);
        List<Account> accsToInsert = new List<Account>{acc1,acc2};
        insert accsToInsert;

        User standardUser = TestHelper.createUser(TestHelper.generateUniqueEmail());
        System.runAs(standardUser) {
            List<SObject> accounts = CustomLookupCtrl.fetchLookUpValues(searchKeyWord, String.valueOf(acc1.getSObjectType()), fieldToSearch, fieldsToSOQL);

            System.assertEquals(accsToInsert.size(), accounts.size());
            for (SObject acc :accounts) {
                System.assert(acc.get(fieldToSearch) != null, 'The field should be in SOQL');
            }
        }
    }

    @isTest static void fetchLookUpValuesTest_fieldsToSOQL() {
        String searchKeyWord = 'Acc';
        String fieldToSearch = 'Name';
        List<String> fieldsToSOQL = new List<String>{'BillingCountry', 'Region__c'};

        Account acc1 = TestHelper.createAccount(searchKeyWord + '1',false);
        Account acc2 = TestHelper.createAccount(searchKeyWord + '2',false);

        acc1.put(fieldsToSOQL[0], 'USA');
        acc2.put(fieldsToSOQL[0], 'USA');
        acc1.put(fieldsToSOQL[1], 'NA');
        acc2.put(fieldsToSOQL[1], 'NA');

        List<Account> accsToInsert = new List<Account>{acc1,acc2};
        insert accsToInsert;

        User standardUser = TestHelper.createUser(TestHelper.generateUniqueEmail());
        System.runAs(standardUser) {
            List<SObject> accounts = CustomLookupCtrl.fetchLookUpValues(searchKeyWord, String.valueOf(acc1.getSObjectType()), fieldToSearch, fieldsToSOQL);

            System.assertEquals(accsToInsert.size(), accounts.size());
            for (SObject acc :accounts) {
                System.assert(acc.get(fieldToSearch) != null, 'The field should be in SOQL');
                System.assert(acc.get(fieldsToSOQL[0]) != null, 'The field should be in SOQL');
                System.assert(acc.get(fieldsToSOQL[1]) != null, 'The field should be in SOQL');
            }
        }
    }
}