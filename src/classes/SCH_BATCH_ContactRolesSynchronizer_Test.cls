@isTest
public class SCH_BATCH_ContactRolesSynchronizer_Test {

	testmethod static void synchronize() {
        Account acc = TestHelper.createAccount();
        User owner = TestHelper.createUser('TestOpportunityContactHandler@test.com');
        Opportunity opp = TestHelper.createOpportunity(owner, acc);
        opp.MeetingStatus__c='Short-Term Follow Up';
        insert opp;
        Contact con = new Contact(LastName='TestCon', Status__c='Open',MailingCity='Test',MailingState='Test',MailingCountry='Test');
        insert con;
        OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId=opp.Id,
                                                               ContactId=con.Id,
                                                               Role='Decision Maker');
        insert ocr;
        
        Test.startTest();
        Database.executeBatch(new SCH_BATCH_ContactRolesSynchronizer(), 200);
        Test.stopTest();
        
        
        System.assertEquals(1,  [SELECT count () FROM Contact_Opportunity__c WHERE Opportunity__c=:opp.Id AND Contact__c=:con.Id
                                                             AND Role__c='Decision Maker']);      
    }    
}