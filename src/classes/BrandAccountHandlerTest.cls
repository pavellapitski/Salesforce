@isTest
public class BrandAccountHandlerTest {

    static testMethod void cannotCreateDuplicatedBrandAccount(){
        
        Account acc = TestHelper.createAccount();
        Brand__c brand = TestHelper.createBrand('testBrand');
        
		test.startTest();
        
        Boolean duplicateException = false;

        Brand_Account__c brandAcc1 = TestHelper.createBrandAccount(acc.Id, brand.Id);
        
        try {
            Brand_Account__c brandAcc2 = TestHelper.createBrandAccount(acc.Id, brand.Id);
        }
        catch (Exception ex) {
            duplicateException = true;            
        }
        
		test.stopTest();
		
        System.assert(duplicateException);
    }
}