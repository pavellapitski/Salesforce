@isTest
private class NewContactOpportunityController_Test {

    testmethod static void addNewContactRole_increaseContactRolesListSize() {
        Account acc = TestHelper.createAccount();
        User usr = TestHelper.createUser();
        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        insert opp;
        Test.setCurrentPage(Page.NewContactOpportunity);
        System.currentPageReference().getParameters().put('id', opp.Id);
        NewContactOpportunityController controller = new
                NewContactOpportunityController(new ApexPages.StandardSetController(new List<Contact_Opportunity__c>()));
        System.assertEquals(1, controller.contactRoles.size());

        Test.startTest();
        controller.addNewContactRole();
        Test.stopTest();

        System.assertEquals(2, controller.contactRoles.size());
    }

    testmethod static void deleteContactRole_decreaseContactRolesListSize() {
        Account acc = TestHelper.createAccount();
        User usr = TestHelper.createUser();
        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        insert opp;
        Test.setCurrentPage(Page.NewContactOpportunity);
        System.currentPageReference().getParameters().put('id', opp.Id);
        NewContactOpportunityController controller = new
                NewContactOpportunityController(new ApexPages.StandardSetController(new List<Contact_Opportunity__c>()));
        controller.contactRoleRow = 0;

        Test.startTest();
        controller.deleteContactRole();
        Test.stopTest();

        System.assertEquals(0, controller.contactRoles.size());
    }

    testmethod static void save_insertContactRole() {
        Account acc = TestHelper.createAccount();
        User usr = TestHelper.createUser();
        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        insert opp;
        Test.setCurrentPage(Page.NewContactOpportunity);
        System.currentPageReference().getParameters().put('id', opp.Id);
        NewContactOpportunityController controller = new
                NewContactOpportunityController(new ApexPages.StandardSetController(new List<Contact_Opportunity__c>()));
        Contact con = new Contact(LastName = 'TestCon', Status__c = 'Open', MailingCity = 'Test', MailingState = 'Test', MailingCountry = 'Test');
        insert con;

        Test.startTest();
        controller.contactRoles[0].Contact__c = con.Id;
        controller.contactRoles[0].Role__c = 'Decision Maker';
        controller.save();
        Test.stopTest();

        System.assertEquals(1, [
                SELECT count()
                FROM Contact_Opportunity__c
                WHERE Contact__c = :con.Id AND
                Opportunity__c = :opp.Id AND Role__c = 'Decision Maker'
        ]);
    }

    testmethod static void save_returnToOpportunity() {
        Account acc = TestHelper.createAccount();
        User usr = TestHelper.createUser();
        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        insert opp;
        Test.setCurrentPage(Page.NewContactOpportunity);
        System.currentPageReference().getParameters().put('id', opp.Id);
        NewContactOpportunityController controller = new
                NewContactOpportunityController(new ApexPages.StandardSetController(new List<Contact_Opportunity__c>()));
        Contact con = new Contact(LastName = 'TestCon', Status__c = 'Open', MailingCity = 'Test', MailingState = 'Test', MailingCountry = 'Test');
        insert con;

        Test.startTest();
        PageReference result = controller.save();
        Test.stopTest();

        PageReference expected = new PageReference('/' + opp.Id);
        System.assertEquals(expected.getUrl(), result.getUrl());
    }
}