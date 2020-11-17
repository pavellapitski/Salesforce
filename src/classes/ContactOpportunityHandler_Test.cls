@IsTest
private class ContactOpportunityHandler_Test {

    @IsTest static void whenClientDoNotDegrade() {
        User owner = TestHelper.createUser('testopportunitycontacthandler@test.com');

        Account acc = TestHelper.createAccount();

        Opportunity opp = TestHelper.createOpportunity(owner, acc);
        opp.MeetingStatus__c = 'Short-Term Follow Up';
        insert opp;

        Contact contactRec = TestHelper.createContact('ContactLastName', true);

        Test.startTest();
        Contact_Opportunity__c co = new Contact_Opportunity__c(Opportunity__c = opp.Id, Contact__c = contactRec.Id, Role__c = 'Decision Maker');
        insert co;
        Test.stopTest();

        Contact updatedCon = [SELECT Status__c FROM Contact WHERE Id = :contactRec.Id];
        System.assertEquals(contactRec.Status__c, updatedCon.Status__c, 'Contact.Status__c shouldn\'t be changed.');
    }

    @IsTest static void willSetMediaProcessTypeOnContact() {
        User owner = TestHelper.createUser('testopportunitycontacthandler@test.com');
        String mediaProcessType = 'Managed Service Social';

        Account acc = TestHelper.createAccount();
        Contact con = TestHelper.createContact('ContactLastName', true);

        Opportunity opp = TestHelper.createOpportunity(owner, acc);
        opp.Media_Process_Type__c = mediaProcessType;
        insert opp;

        Test.startTest();
        Contact_Opportunity__c co = new Contact_Opportunity__c(Opportunity__c = opp.Id, Contact__c = con.Id, Role__c = 'Decision Maker');
        insert co;
        Test.stopTest();

        Contact updatedCon = [SELECT Media_Process_Type__c FROM Contact WHERE Id = :con.Id];
        System.assertEquals(mediaProcessType, updatedCon.Media_Process_Type__c);
    }

    @IsTest static void whenContractOppDeletedDeleteContactRole() {
        Account acc = TestHelper.createAccount();
        User owner = TestHelper.createUser('testopportunitycontacthandler@test.com');
        Opportunity opp = TestHelper.createOpportunity(owner, acc);
        opp.MeetingStatus__c='Short-Term Follow Up';
        insert opp;
        Contact con = TestHelper.createContact('ContactLastName', true);

        Contact_Opportunity__c co = new Contact_Opportunity__c(Opportunity__c=opp.Id, Contact__c=con.Id, Role__c='Decision Maker');
        insert co;
        System.assertEquals(1, [SELECT Id FROM OpportunityContactRole].size());

        Test.startTest();
        delete co;
        Test.stopTest();

        System.assertEquals(0, [SELECT Id FROM OpportunityContactRole].size());
    }

    @IsTest static void whenOppClosedWonSetContactOutreachStage() {
        Account acc = TestHelper.createAccountByRecType(AccountHandler.RT_ID_BRAND_DIRECT, true);

        User owner = TestHelper.createUser('testopportunitycontacthandler@test.com');

        Opportunity opp = TestHelper.createOpportunity(owner, acc);
        opp.Brand__c = TestHelper.createBrand('TestBrand').Id;
        insert opp;

        Contact con = TestHelper.createContact('ContactLastName', true);
        Contact_Opportunity__c co = new Contact_Opportunity__c(Opportunity__c = opp.Id, Contact__c = con.Id, Role__c = 'Decision Maker');
        insert co;

        Platform__c platform = TestHelper.createPlatform('TrueView', 'TV');
        insert platform;

        OpportunityPlatform__c oppPlatform = TestHelper.createOpportunityPlatform(opp.Id, platform.Id);
        insert oppPlatform;

        Test.startTest();
        opp.StageName = ContactOpportunityHandler.CLOSED_WON;
        opp.BypassValidationRule__c = true;
        update opp;
        Test.stopTest();

        Contact updatedCon = [SELECT Outreach_Stage__c FROM Contact WHERE Id=:con.Id];
        System.assertEquals('Active Client', updatedCon.Outreach_Stage__c);
    }

    @IsTest static void setContactsOutreachStatusWhenBrandDirectOpportunityIsClosedWon() {
        User owner = TestHelper.createUser('testopportunitycontacthandler@test.com');

        Account acc = TestHelper.createAccount('TestAccountName', false);
        acc.RecordTypeId = AccountHandler.RT_ID_BRAND_DIRECT;
        insert acc;

        Opportunity opp = TestHelper.createOpportunity(owner, acc);
        opp.Brand__c = TestHelper.createBrand('TestBrand').Id;
        opp.RecordTypeId = OpportunityRepository.RT_ID_BRAND_DIRECT;
        insert opp;

        Integer amountOfContacts = 5;
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < amountOfContacts; i++) {
            // the following contact needs to be linked to Account
            contacts.add(TestHelper.createSimpleContactWithAccount(i,acc.Id));
        }
        insert contacts;

        Test.startTest();
        opp.StageName = ContactOpportunityHandler.CLOSED_WON;
        opp.BypassValidationRule__c = true;
        update opp;
        Test.stopTest();

        for (Contact updatedContact :[SELECT Outreach_Stage__c FROM Contact WHERE Id IN :contacts]) {
            System.assertEquals(ContactOpportunityHandler.ACTIVE_CLIENT, updatedContact.Outreach_Stage__c);
        }
    }

    @IsTest static void doNotSetContactsOutreachStatusWhenBrandDirectOpportunityIsNotClosedWon() {
        User owner = TestHelper.createUser('testopportunitycontacthandler@test.com');

        Account acc = TestHelper.createAccountByRecType(AccountHandler.RT_ID_BRAND_DIRECT, true);

        Opportunity opp = TestHelper.createOpportunity(owner, acc);
        opp.Brand__c = TestHelper.createBrand('TestBrand').Id;
        opp.RecordTypeId = OpportunityRepository.RT_ID_BRAND_DIRECT;
        insert opp;

        Integer amountOfContacts = 1;
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < amountOfContacts; i++) {
            // the following contact needs to be linked to Account
            contacts.add(TestHelper.createSimpleContactWithAccount(i,acc.Id));
        }
        insert contacts;

        Test.startTest();
        opp.StageName = ContactOpportunityHandler.EVALUATION;
        opp.BypassValidationRule__c = true;
        update opp;
        Test.stopTest();

        for (Contact updatedContact :[SELECT Outreach_Stage__c FROM Contact WHERE Id IN :contacts]) {
            System.assertNotEquals(ContactOpportunityHandler.ACTIVE_CLIENT, updatedContact.Outreach_Stage__c);
        }
    }

    @IsTest static void setContactsOutreachStatusWhenNoNBrandDirectOpportunityIsClosedWon() {
        User owner = TestHelper.createUser('testopportunitycontacthandler@test.com');

        Account acc = TestHelper.createAccountByRecType(AccountHandler.RT_ID_BRAND_DIRECT, true);

        Opportunity opp = TestHelper.createOpportunity(owner, acc);
        opp.Brand__c = TestHelper.createBrand('TestBrand').Id;
        opp.RecordTypeId = OpportunityRepository.RT_ID_AGENCY;
        insert opp;

        Integer amountOfContacts = 5;
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < amountOfContacts; i++) {
            // the following contact needs to be linked to Account
            contacts.add(TestHelper.createSimpleContactWithAccount(i,acc.Id));
        }
        insert contacts;

        Test.startTest();
        opp.StageName = ContactOpportunityHandler.CLOSED_WON;
        opp.BypassValidationRule__c = true;
        update opp;
        Test.stopTest();

        Map<Id,Contact> contactsMap = new Map<Id,Contact>(contacts);
        for (Contact updatedContact :[SELECT Outreach_Stage__c FROM Contact WHERE Id IN :contacts]) {
            System.assertEquals(ContactOpportunityHandler.ACTIVE_CLIENT, updatedContact.Outreach_Stage__c, 'Outreach_Stage__c shall be changed to Active Client.');
        }
    }

    @IsTest static void setContactsOutreachStatusIfBrandDirectOpportunityChangedTo_EVALUATION() {
        User owner = TestHelper.createUser('testopportunitycontacthandler@test.com');

        Account acc = TestHelper.createAccountByRecType(AccountHandler.RT_ID_BRAND_DIRECT, true);

        Opportunity opp = TestHelper.createOpportunity(owner, acc);
        opp.Brand__c = TestHelper.createBrand('TestBrand').Id;
        opp.RecordTypeId = OpportunityRepository.RT_ID_BRAND_DIRECT;
        insert opp;

        // add Contacts, one contact is going to be related through Contact_Opportunity__c object
        Integer amountOfContacts = 5;
        List<Contact> contactsUnchanged = new List<Contact>();
        for (Integer i = 0; i < amountOfContacts; i++) {
            // the following contact needs to be linked to Account
            contactsUnchanged.add(TestHelper.createSimpleContactWithAccount(i,acc.Id));
        }
        Contact contactToChange = TestHelper.createSimpleContact(amountOfContacts);

        List<Contact> allContactsToInsert = new List<Contact>(contactsUnchanged);
        allContactsToInsert.add(contactToChange);
        insert allContactsToInsert;

        Contact_Opportunity__c co = new Contact_Opportunity__c(Opportunity__c = opp.Id, Contact__c = contactToChange.Id, Role__c = 'Decision Maker');
        insert co;

        Test.startTest();
        opp.StageName = ContactOpportunityHandler.EVALUATION;
        opp.BypassValidationRule__c = true;
        update opp;
        Test.stopTest();

        Map<Id,Contact> contactsMap = new Map<Id,Contact>(allContactsToInsert);
        for (Contact updatedContact :[SELECT Outreach_Stage__c, Id FROM Contact WHERE Id IN :allContactsToInsert]) {
            if (updatedContact.Id == contactToChange.Id) {
                System.assertEquals(updatedContact.Outreach_Stage__c, ContactOpportunityHandler.EVALUATION);
            } else {
                System.assertEquals(contactsMap.get(updatedContact.Id).Outreach_Stage__c, updatedContact.Outreach_Stage__c, 'No changes in Outreach_Stage__c shall be for NOT CLOSED WON BrandDirect Opportunity/');
            }
        }
    }

    @IsTest static void setContactsOutreachStatusIfBrandDirectOpportunityChangedTo_DISCOVERY_CALL() {
        User owner = TestHelper.createUser('testopportunitycontacthandler@test.com');

        Account acc = TestHelper.createAccountByRecType(AccountHandler.RT_ID_BRAND_DIRECT, true);

        Opportunity opp = TestHelper.createOpportunity(owner, acc);
        opp.Brand__c = TestHelper.createBrand('TestBrand').Id;
        opp.RecordTypeId = OpportunityRepository.RT_ID_BRAND_DIRECT;
        insert opp;

        // add Contacts, one contact is going to be related through Contact_Opportunity__c object
        Integer amountOfContacts = 5;
        List<Contact> contactsUnchanged = new List<Contact>();
        for (Integer i = 0; i < amountOfContacts; i++) {
            // the following contact needs to be linked to Account
            contactsUnchanged.add(TestHelper.createSimpleContactWithAccount(i,acc.Id));
        }
        Contact contactToChange = TestHelper.createSimpleContact(amountOfContacts);

        List<Contact> allContactsToInsert = new List<Contact>(contactsUnchanged);
        allContactsToInsert.add(contactToChange);
        insert allContactsToInsert;

        Contact_Opportunity__c co = new Contact_Opportunity__c(Opportunity__c = opp.Id, Contact__c = contactToChange.Id, Role__c = 'Decision Maker');
        insert co;

        Test.startTest();
        opp.StageName = ContactOpportunityHandler.DISCOVERY_CALL;
        opp.BypassValidationRule__c = true;
        update opp;
        Test.stopTest();

        Map<Id,Contact> contactsMap = new Map<Id,Contact>(allContactsToInsert);
        for (Contact updatedContact :[SELECT Outreach_Stage__c, Id FROM Contact WHERE Id IN :allContactsToInsert]) {
            if (updatedContact.Id == contactToChange.Id) {
                System.assertEquals(updatedContact.Outreach_Stage__c, ContactOpportunityHandler.DISCOVERY_MEETING);
            } else {
                System.assertEquals(contactsMap.get(updatedContact.Id).Outreach_Stage__c, updatedContact.Outreach_Stage__c, 'No changes in Outreach_Stage__c shall be for NOT CLOSED WON BrandDirect Opportunity/');
            }
        }
    }

    @IsTest static void setContactsOutreachStatusIfBrandDirectOpportunityChangedTo_VALIDATING_BENEFITS() {
        User owner = TestHelper.createUser('testopportunitycontacthandler@test.com');

        Account acc = TestHelper.createAccountByRecType(AccountHandler.RT_ID_BRAND_DIRECT, true);

        Opportunity opp = TestHelper.createOpportunity(owner, acc);
        opp.Brand__c = TestHelper.createBrand('TestBrand').Id;
        opp.RecordTypeId = OpportunityRepository.RT_ID_BRAND_DIRECT;
        insert opp;

        // add Contacts, one contact is going to be related through Contact_Opportunity__c object
        Integer amountOfContacts = 5;
        List<Contact> contactsUnchanged = new List<Contact>();
        for (Integer i = 0; i < amountOfContacts; i++) {
            // the following contact needs to be linked to Account
            contactsUnchanged.add(TestHelper.createSimpleContactWithAccount(i,acc.Id));
        }
        Contact contactToChange = TestHelper.createSimpleContact(amountOfContacts);

        List<Contact> allContactsToInsert = new List<Contact>(contactsUnchanged);
        allContactsToInsert.add(contactToChange);
        insert allContactsToInsert;

        Contact_Opportunity__c co = new Contact_Opportunity__c(Opportunity__c = opp.Id, Contact__c = contactToChange.Id, Role__c = 'Decision Maker');
        insert co;

        Test.startTest();
        opp.StageName = ContactOpportunityHandler.VALIDATING_BENEFITS;
        opp.BypassValidationRule__c = true;
        update opp;
        Test.stopTest();

        Map<Id,Contact> contactsMap = new Map<Id,Contact>(allContactsToInsert);
        for (Contact updatedContact :[SELECT Outreach_Stage__c, Id FROM Contact WHERE Id IN :allContactsToInsert]) {
            if (updatedContact.Id == contactToChange.Id) {
                System.assertEquals(updatedContact.Outreach_Stage__c, ContactOpportunityHandler.VALIDATING_BENEFITS);
            } else {
                System.assertEquals(contactsMap.get(updatedContact.Id).Outreach_Stage__c, updatedContact.Outreach_Stage__c, 'No changes in Outreach_Stage__c shall be for NOT CLOSED WON BrandDirect Opportunity/');
            }
        }
    }

    @IsTest static void setContactsOutreachStatusIfBrandDirectOpportunityChangedTo_CLOSED_WON() {
        User owner = TestHelper.createUser('testopportunitycontacthandler@test.com');

        Account acc = TestHelper.createAccountByRecType(AccountHandler.RT_ID_BRAND_DIRECT, true);

        Opportunity opp = TestHelper.createOpportunity(owner, acc);
        opp.Brand__c = TestHelper.createBrand('TestBrand').Id;
        opp.RecordTypeId = OpportunityRepository.RT_ID_BRAND_DIRECT;
        insert opp;

        // add Contacts
        Integer amountOfContacts = 5;
        List<Contact> contactsToBeChanged = new List<Contact>();
        for (Integer i = 0; i < amountOfContacts; i++) {
            // the following contact needs to be linked to Account
            contactsToBeChanged.add(TestHelper.createSimpleContactWithAccount(i,acc.Id));
        }
        // one contact is going to be related through Contact_Opportunity__c object
        Contact contactNoChange = TestHelper.createSimpleContact(amountOfContacts);

        List<Contact> allContactsToInsert = new List<Contact>(contactsToBeChanged);
        allContactsToInsert.add(contactNoChange);
        insert allContactsToInsert;

        Contact_Opportunity__c co = new Contact_Opportunity__c(Opportunity__c = opp.Id, Contact__c = contactNoChange.Id, Role__c = 'Decision Maker');
        insert co;

        Test.startTest();
        opp.StageName = ContactOpportunityHandler.CLOSED_WON;
        opp.BypassValidationRule__c = true;
        update opp;
        Test.stopTest();

        for (Contact updatedContact :[SELECT Outreach_Stage__c, Id FROM Contact WHERE Id IN :allContactsToInsert]) {
            System.assertEquals(ContactOpportunityHandler.ACTIVE_CLIENT, updatedContact.Outreach_Stage__c);
        }
    }
}