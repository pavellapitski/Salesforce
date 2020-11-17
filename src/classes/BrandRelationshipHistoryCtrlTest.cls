@IsTest
private class BrandRelationshipHistoryCtrlTest {

    static testMethod void getBrandRelationshipHistory() {
        String accAndBrandName = 'BrandAccountName';

        Account acc = TestHelper.createAccount(accAndBrandName, false);
        acc.Natural_Name__c = acc.Name;
        acc.RecordTypeId = BrandRelationshipHistoryCtrl.brandDirectRTId;

        Account acc1 = TestHelper.createAccount('DifferentAcc1', false);
        acc1.Natural_Name__c = acc1.Name;

        Account acc2 = TestHelper.createAccount('DifferentAcc2', false);
        acc2.Natural_Name__c = acc2.Name;

        Account acc3 = TestHelper.createAccount('DifferentAcc3', false);
        acc3.Natural_Name__c = acc3.Name;

        Account acc4 = TestHelper.createAccount('DifferentAcc4', false);
        acc4.Natural_Name__c = acc4.Name;

        insert new List<Account>{acc, acc1, acc2, acc3, acc4};

        Brand__c brand = TestHelper.createBrand(accAndBrandName, false);
        Brand__c brand1 = TestHelper.createBrand('DifferentBrand1', false);
        Brand__c brand2 = TestHelper.createBrand('DifferentBrand2', false);
        insert new List<Brand__c> {brand, brand1, brand2};

        Brand_Account__c brandAcc1 = TestHelper.createBrandAccount(acc1.Id, brand.Id, false);
        Brand_Account__c brandAcc2 = TestHelper.createBrandAccount(acc2.Id, brand.Id, false);
        Brand_Account__c brand1Acc3 = TestHelper.createBrandAccount(acc3.Id, brand1.Id, false);
        Brand_Account__c brand2Acc4 = TestHelper.createBrandAccount(acc4.Id, brand2.Id, false);
        insert new List<Brand_Account__c>{brandAcc1, brandAcc2, brand1Acc3, brand2Acc4};

        User salesRepUser = [SELECT Id FROM User WHERE IsActive = true AND ProfileId IN (SELECT Id FROM Profile WHERE Name IN ('Sales User','Sales Manager')) LIMIT 1];
        Test.startTest();
        System.runAs(salesRepUser) {
            Test.setCurrentPage(Page.BrandRelationshipHistory);
            BrandRelationshipHistoryCtrl ctrl = new BrandRelationshipHistoryCtrl(new ApexPages.StandardController(acc));
            System.assertEquals(ctrl.retUrl, '/' + String.valueOf(acc.Id).substring(0, 15));

            List<Brand_Account__c> brandAccounts = ctrl.brandAccounts;
            System.assertEquals(brandAccounts.size(), new List<Brand_Account__c>{brandAcc1, brandAcc2}.size());
        }
        Test.stopTest();
    }
}