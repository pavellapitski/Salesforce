@isTest
private class AutoCompleteControllerTest {
    static testMethod void testAutocomplete(){
        List<Account> accountList = new List<Account>();
        for (Integer i = 0 ; i < 10 ; i++) {
            Account acc = TestHelper.createAccount('Test' + i, false);
            accountList.add(acc);
        }
        insert accountList;
        
        Test.startTest();
        System.assertEquals(accountList.size(), AutoCompleteController.getData('Account','Name','Id','','T').size());
        System.assertEquals(1, AutoCompleteController.getData('Account','Name','Id','','Test9').size());
        System.assertEquals(0, AutoCompleteController.getData('Account','Name','Id','','xxxxxxx').size());
        AutoCompleteController controller = new AutoCompleteController();
        controller.setTargetFieldVar(accountList[0].Id);
        System.assertEquals(accountList[0].Id,controller.getTargetFieldVar());
        controller.setCacheField(null);
            
        Test.stopTest();
    }
}