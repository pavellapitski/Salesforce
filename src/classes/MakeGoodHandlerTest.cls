@isTest
public class MakeGoodHandlerTest {

    private static MakeGood__c makeGood;
    private static Date today = System.today();
    private static Project__c contract;

    @isTest
    public static void testSetNames ()
    {
        Account acc = TestHelper.createAccount();
        contract = TestHelper.createContract(acc.Id);
        createGood();
    }
    
    private static void createGood() {
        
        makeGood = new MakeGood__c();
        makeGood.Contract__c = contract.Id;
        makeGood.StartDate__c = today.addDays(-1);
        makeGood.EndDate__c = today.addDays(1);
        insert makeGood;
    }
}