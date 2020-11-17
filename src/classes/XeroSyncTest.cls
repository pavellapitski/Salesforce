@IsTest
public class XeroSyncTest {
    private static final String REGION = 'NA';
    private static Account acc;

    @TestSetup public static void initTestData() {
        TestHelper.createXeroEntityByRegion(REGION, true);
    }

    private static XeroSettings__c getXeroSettings() {
        return [SELECT AccountCode__c, ConsumerKey__c, ConsumerSecret__c, Name, Region__c, PrivateKey__c FROM XeroSettings__c WHERE Region__c = :REGION LIMIT 1];
    }

    @IsTest static void willCreateSyncRecords() {
        XeroSettings__c xs = getXeroSettings();

        System.assertEquals(0, [SELECT Id FROM XeroEntity__c].size());
        System.assertEquals(0, [SELECT Id FROM XeroSync__c].size());

        XeroSync.performSync = true;

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
            XeroSync.syncXeroObjects(xs, XeroSync.XERO_TYPE_CONTACT);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM XeroSync__c WHERE XeroSettings__c = :xs.Id AND ObjectType__c = :XeroSync.XERO_TYPE_CONTACT]);
        System.assertEquals(1, [SELECT COUNT() FROM XeroEntity__c WHERE XeroSettings__c = :xs.Id AND ObjectType__c = :XeroSync.XERO_TYPE_CONTACT]);
    }

    @IsTest static void willUpdateApprovedCreditNotesFromXero() {
        XeroSettings__c xs = getXeroSettings();

        Project__c contract = TestHelper.createContract(TestHelper.createAccount().Id);

        Sub_Project__c payment = [SELECT Id, Invoice_Amount__c FROM Sub_Project__c WHERE Invoice_Amount__c != NULL LIMIT 1];

        CreditNote__c creditNoteObj = TestHelper.createCreditNoteNoInsert(payment.Id);
        creditNoteObj.Amount__c = 100;
        creditNoteObj.XeroId__c = 'testCreditNoteXeroId';
        creditNoteObj.Status__c = CreditNote.STATUS_SUBMITTED;
        insert creditNoteObj;

        Test.startTest();
            XeroWrappers.XeroCreditNote xeroCreditNote = XeroTestHelper.createXeroCreditNote(CreditNoteRepository.getCreditNoteById(creditNoteObj.Id));
            xeroCreditNote.CreditNoteId = creditNoteObj.XeroId__c;
            xeroCreditNote.Status = XeroWrappers.XeroCreditNoteStatus.AUTHORISED;

            XeroTestHelper.xeroCreditNotes.add(xeroCreditNote);

            Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());

            XeroSync.updateCreditNotesFromXero();
        Test.stopTest();

        creditNoteObj = [SELECT Amount__c, Status__c, XeroAmount__c FROM CreditNote__c WHERE Id = :creditNoteObj.Id];

        System.assertEquals(CreditNote.STATUS_AUTHORISED, creditNoteObj.Status__c);
        System.assertEquals(payment.Invoice_Amount__c - creditNoteObj.Amount__c, [SELECT CreditNotesAmount__c FROM Sub_Project__c WHERE Id = :payment.Id].CreditNotesAmount__c);
    }

    @IsTest static void willUpdatePaidCreditNotesFromXero() {
        XeroSettings__c xs = getXeroSettings();

        Project__c contract = TestHelper.createContract(TestHelper.createAccount().Id);
        Sub_Project__c payment = [SELECT Id FROM Sub_Project__c WHERE Invoice_Amount__c != NULL LIMIT 1];

        CreditNote__c creditNoteObj = TestHelper.createCreditNoteNoInsert(payment.Id);
        creditNoteObj.XeroId__c = 'testCreditNoteXeroId';
        creditNoteObj.Status__c = CreditNote.STATUS_SUBMITTED;
        creditNoteObj.Amount__c = 200;
        insert creditNoteObj;

        Test.startTest();
            XeroWrappers.XeroCreditNote xeroCreditNote = XeroTestHelper.createXeroCreditNote(CreditNoteRepository.getCreditNoteById(creditNoteObj.Id));
            xeroCreditNote.CreditNoteId = creditNoteObj.XeroId__c;
            xeroCreditNote.Reference = 'SF-' + creditNoteObj.Id;
            xeroCreditNote.Status = XeroWrappers.XeroCreditNoteStatus.PAID;

            XeroTestHelper.xeroCreditNotes.add(xeroCreditNote);

            Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());

            XeroSync.updateCreditNotesFromXero();
        Test.stopTest();

        System.assertEquals(CreditNote.STATUS_PAID, [SELECT Status__c FROM CreditNote__c WHERE Id = :creditNoteObj.Id].Status__c);
    }

    /*@isTest static void willSetProperTaxWhenPostingInvoice() {
        XeroSettings__c xs = getXeroSettings();

        XeroTax__c xeroTax1 = new XeroTax__c();
        xeroTax1.Name = 'Singapore GST 7%';
        xeroTax1.NonZeroRate__c = true;
        xeroTax1.Currency__c = 'SGD';
        xeroTax1.XeroId__c = 'TAX001';
        xeroTax1.XeroSettings__c = xs.Id;

        XeroTax__c xeroTax2 = new XeroTax__c();
        xeroTax2.Name = 'Tax Exempt';
        xeroTax2.NonZeroRate__c = false;
        xeroTax2.Currency__c = 'SGD;USD';
        xeroTax2.XeroId__c = 'NONE';
        xeroTax2.XeroSettings__c = xs.Id;

        insert new List<XeroTax__c> {xeroTax1, xeroTax2};

        acc = TestHelper.createAccount();

        Project__c contract1 = TestHelper.createContractNoInsert(acc.Id, 'testContract', NULL);
        contract1.Xero_Id__c = 'testContract1XeroId';
        contract1.Xero_Entity__c = xs.Id;
        contract1.AddXeroTax__c = true;
        contract1.CurrencyIsoCode = 'SGD';

        Project__c contract2 = TestHelper.createContractNoInsert(acc.Id, 'testContract', NULL);
        contract2.Xero_Id__c = 'testContract2XeroId';
        contract2.Xero_Entity__c = xs.Id;
        contract2.AddXeroTax__c = false;
        contract2.CurrencyIsoCode = 'USD';

        insert new List<Project__c> {contract1, contract2};

        Sub_Project__c payment1 = [SELECT Id FROM Sub_Project__c WHERE Project__c = :contract1.Id LIMIT 1];
        Sub_Project__c payment2 = [SELECT Id FROM Sub_Project__c WHERE Project__c = :contract2.Id LIMIT 1];

        Test.startTest();
            XeroWrappers.XeroInvoice mappedInvoice1 = Utility.mapPaymentToInvoice(SubProjectRepository.getInvoiceForXeroSubmission(payment1.Id)[0], contract1.Xero_Id__c, xs.Id);
            XeroWrappers.XeroInvoice mappedInvoice2 = Utility.mapPaymentToInvoice(SubProjectRepository.getInvoiceForXeroSubmission(payment2.Id)[0], contract2.Xero_Id__c, xs.Id);

            Xmlstreamwriter xmlW = new Xmlstreamwriter();
            xmlW.writeStartDocument('utf-8','1.0');
            xmlW.writeStartElement(null, 'Invoices', null);

            XMLUtility.mapInvoiceItemToXML(mappedInvoice1, xmlW);

            xmlW.writeEndElement();
            xmlW.writeEndDocument();

        Test.stopTest();

        System.assertEquals(xeroTax1.XeroId__c, mappedInvoice1.LineItems[0].TaxType);
        System.assertEquals(xeroTax2.XeroId__c, mappedInvoice2.LineItems[0].TaxType);
    }*/

    @IsTest static void willSetProperItemCodeWhenPostingInvoice() {
        XeroSettings__c xs = getXeroSettings();

        XeroItem__c xeroItem1 = new XeroItem__c();
        xeroItem1.Name = 'Media Cost';
        xeroItem1.BillingProfile__c = 'Strike';
        xeroItem1.ItemCode__c = '1001';
        xeroItem1.XeroSettings__c = xs.Id;

        XeroItem__c xeroItem2 = new XeroItem__c();
        xeroItem2.Name = 'Service Fees';
        xeroItem2.BillingProfile__c = 'Client';
        xeroItem2.ItemCode__c = '1002';
        xeroItem2.XeroSettings__c = xs.Id;

        insert new List<XeroItem__c> {xeroItem1, xeroItem2};

        acc = TestHelper.createAccount();

        Project__c contract1 = TestHelper.createContractNoInsert(acc.Id, 'testContract', NULL);
        contract1.Xero_Id__c = 'testContract1XeroId';
        contract1.Xero_Entity__c = xs.Id;
        contract1.Account_Type__c = 'Strike';

        Project__c contract2 = TestHelper.createContractNoInsert(acc.Id, 'testContract', NULL);
        contract2.Xero_Id__c = 'testContract2XeroId';
        contract2.Xero_Entity__c = xs.Id;
        contract2.Account_Type__c = 'Client';

        insert new List<Project__c> {contract1, contract2};

        Sub_Project__c payment1 = [SELECT Id FROM Sub_Project__c WHERE Project__c = :contract1.Id LIMIT 1];
        Sub_Project__c payment2 = [SELECT Id FROM Sub_Project__c WHERE Project__c = :contract2.Id LIMIT 1];

        Test.startTest();
            XeroWrappers.XeroInvoice mappedInvoice1 = Utility.mapPaymentToInvoice(SubProjectRepository.getInvoiceForXeroSubmission(payment1.Id)[0], contract1.Xero_Id__c, xs.Id);
            XeroWrappers.XeroInvoice mappedInvoice2 = Utility.mapPaymentToInvoice(SubProjectRepository.getInvoiceForXeroSubmission(payment2.Id)[0], contract2.Xero_Id__c, xs.Id);

            XmlStreamWriter xmlW = new XmlStreamWriter();
            xmlW.writeStartDocument('utf-8','1.0');
            xmlW.writeStartElement(null, 'Invoices', null);

            XMLUtility.mapInvoiceItemToXML(mappedInvoice1, xmlW);

            xmlW.writeEndElement();
            xmlW.writeEndDocument();

        Test.stopTest();

        System.assertEquals(1, mappedInvoice1.LineItems.size());
        System.assertEquals(xeroItem1.ItemCode__c, mappedInvoice1.LineItems[0].ItemCode);
        System.assertEquals(1, mappedInvoice2.LineItems.size());
        System.assertEquals(xeroItem2.ItemCode__c, mappedInvoice2.LineItems[0].ItemCode);
    }

    @IsTest static void willSplitInvoiceMediaCostAndStrikeFee() {
        XeroSettings__c xs = getXeroSettings();
        User clientServicesRep = TestHelper.createClientServiceUser();
        Brand__c brand = TestHelper.createBrand('testBrand');

        Platform__c platformTV = TestHelper.createPlatform('TrueView', 'TV');
        upsert platformTV;

        acc = TestHelper.createAccount('TestAccountName', false);
        acc.InvoiceLayout__c = 'Media/Strike Fee';
        acc.Region__c = REGION;
        insert acc;

        //Create Opportunity
        Opportunity opp = TestHelper.createOpportunity(clientServicesRep, acc);
        opp.Amount = 100000;
        opp.Brand__c = brand.Id;
        insert opp;

        insert TestHelper.createOpportunityPlatform(opp.Id, platformTV.Id);

        opp.StageName = 'Closed Won';
        update opp;

        Project__c contract = [SELECT Id, End_Date__c FROM Project__c WHERE Opportunity__c = :opp.Id];
        contract.Xero_Id__c = 'testContractXeroId';
        contract.Xero_Entity__c = xs.Id;
        contract.Account_Type__c = 'Strike';
        update contract;

        //Assign media spends
        MM_Spendings__c spend = TestHelper.createMediaSpendings(contract.Id, contract.End_Date__c);
        spend.Media_Spend__c = 70000;
        insert spend;

        Test.startTest();
            Sub_Project__c payment = [SELECT Id, AdWordsSpend__c, Invoice_Amount__c FROM Sub_Project__c WHERE Project__c = :contract.Id LIMIT 1];
            payment.Checked__c = true;
            update payment;

            Payment__c project = [SELECT Id FROM Payment__c WHERE Payment__c = :payment.Id];
            project.InvoiceAmount__c = 95000;
            update project;

            XeroWrappers.XeroInvoice preparedInvoice = Utility.mapPaymentToInvoice(SubProjectRepository.getInvoiceForXeroSubmission(payment.Id)[0], contract.Xero_Id__c, xs.Id);

            XmlStreamWriter xmlW = new XmlStreamWriter();
            xmlW.writeStartDocument('utf-8','1.0');
            xmlW.writeStartElement(null, 'Invoices', null);

            XMLUtility.mapInvoiceItemToXML(preparedInvoice, xmlW);

            xmlW.writeEndElement();
            xmlW.writeEndDocument();

        Test.stopTest();

        System.assertEquals(2, preparedInvoice.LineItems.size());

        System.assertEquals('Media Cost', preparedInvoice.LineItems[0].ItemCode);
        System.assertEquals(payment.AdWordsSpend__c, 70000);
        System.assertEquals(payment.AdWordsSpend__c, preparedInvoice.LineItems[0].LineAmount);

        System.assertEquals('111', preparedInvoice.LineItems[1].ItemCode);
        System.assertEquals(95000 - payment.AdWordsSpend__c, preparedInvoice.LineItems[1].LineAmount);
    }

    @IsTest static void willSetProperAccountCodeWhenPostingInvoice() {
        XeroSettings__c xs = getXeroSettings();

        acc = TestHelper.createAccount();

        Project__c contract = TestHelper.createContractNoInsert(acc.Id, 'testContract', null);
        contract.Xero_Id__c = '87d5bfb8-359b-4273-8e0b-c08c64da2062';
        contract.Xero_Entity__c = xs.Id;
        insert contract;

        Sub_Project__c payment = [SELECT Id FROM Sub_Project__c WHERE Project__c = :contract.Id LIMIT 1];

        Test.startTest();
            XeroWrappers.XeroInvoice mappedInvoice = Utility.mapPaymentToInvoice(SubProjectRepository.getInvoiceForXeroSubmission(payment.Id)[0], contract.Xero_Id__c, xs.Id);
        Test.stopTest();

        System.assertEquals(xs.AccountCode__c, mappedInvoice.LineItems[0].AccountCode);
    }


    @IsTest static void willUpdatePaidPaymentsFromXero() {
        XeroSettings__c xs = getXeroSettings();

        Project__c contract = TestHelper.createContract(TestHelper.createAccount().Id);
        List<Sub_Project__c> payments = [SELECT Id, Paid__c, Xero_Id__c FROM Sub_Project__c WHERE Paid__c = false LIMIT 2];

        Sub_Project__c payment1 = payments[0];
        payment1.Xero_ID__c = 'AB123';
        update payment1;

        XeroWrappers.XeroInvoice xeroInvoice = XeroTestHelper.createXeroInvoice();
        xeroInvoice.InvoiceID = payment1.Xero_ID__c;
        xeroInvoice.Status = XeroWrappers.XeroInvoiceStatus.PAID;

        XeroTestHelper.xeroInvoices.add(xeroInvoice);

        Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
        Test.startTest();
            XeroSync.handleInvoicesFromXero();
        Test.stopTest();

        payment1 = [SELECT Paid__c, Payment_Date__c, XeroStatus__c  FROM Sub_Project__c WHERE Id = :payment1.Id];
        System.assertEquals(true, payment1.Paid__c);
        System.assertEquals(SubProject.XERO_STATUS_PAID, payment1.XeroStatus__c);
    }


    @IsTest static void willNotUpdateNonPaidPaymentsFromXero() {
        XeroSettings__c xs = getXeroSettings();

        Project__c contract2 = TestHelper.createContract(TestHelper.createAccount().Id);
        List<Sub_Project__c> payments = [SELECT Id, Paid__c, Xero_Id__c FROM Sub_Project__c WHERE Paid__c = false LIMIT 2];

        Sub_Project__c payment2 = payments[1];
        payment2.Xero_ID__c='AB234';
        update payment2;

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
            XeroSync.handleInvoicesFromXero();
        Test.stopTest();

        System.assertNotEquals(SubProject.XERO_STATUS_PAID, payment2.XeroStatus__c);
        System.assertEquals(false, [SELECT Paid__c FROM Sub_Project__c WHERE Id = :payment2.Id].Paid__c);
    }


    @IsTest static void willUpdateApprovedPaymentsFromXero() {
        XeroSettings__c xs = getXeroSettings();

        Project__c contract = TestHelper.createContract(TestHelper.createAccount().Id);
        contract.Xero_ID__c = 'TestXeroId1234567';
        contract.Gaps_Exist_Between_Projects__c = true;

        Test.startTest();
        update contract;

        delete [SELECT Id FROM Sub_Project__c WHERE Project__c = :contract.Id];

        Sub_Project__c payment = TestHelper.createPaymentNoInsert(contract);
        payment.XeroStatus__c = SubProject.XERO_STATUS_AUTHORISED;
        payment.Xero_ID__c = 'TestXeroId1234567Different';
        insert payment;

        XeroWrappers.XeroInvoice xeroInvoice = XeroTestHelper.createXeroInvoice();
        xeroInvoice.InvoiceID = payment.Xero_ID__c;
        xeroInvoice.Status = XeroWrappers.XeroInvoiceStatus.AUTHORISED;
        XeroTestHelper.xeroInvoices.add(xeroInvoice);
        Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
        XeroSync.handleInvoicesFromXero();
        Test.stopTest();

        payment = [SELECT XeroStatus__c  FROM Sub_Project__c WHERE Id = :payment.Id];
        System.assertEquals(SubProject.XERO_STATUS_AUTHORISED, payment.XeroStatus__c);
    }

    @IsTest static void handleInvoicesFromXeroTest_PAID_onlyPayments() {
        XeroSettings__c xs = getXeroSettings();

        acc = TestHelper.createAccount();

        Project__c contract = TestHelper.createContract(acc.Id);
        List<Sub_Project__c> payments = [SELECT Id, Paid__c, Xero_Id__c, XeroStatus__c FROM Sub_Project__c WHERE Paid__c = false];
        List<XeroWrappers.XeroInvoice> xeroInvoices = new List<XeroWrappers.XeroInvoice>();
        for (Integer i = 0; i < payments.size(); i++) {
            payments[i].Xero_ID__c = '87d5bfb8-359b-4273-8e0b-c08c64da20'+i;
            System.assertNotEquals(payments[i].XeroStatus__c , SubProject.XERO_STATUS_PAID);

            // set up Xero response data
            XeroWrappers.XeroInvoice xeroInvoice = XeroTestHelper.createXeroInvoice();
            xeroInvoice.InvoiceID = payments[i].Xero_ID__c;
            xeroInvoice.Status = XeroWrappers.XeroInvoiceStatus.PAID;
            xeroInvoices.add(xeroInvoice);
        }
        update payments;

        // set up CalloutMock class data
        XeroTestHelper.xeroInvoices.addAll(xeroInvoices);

        Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
        Test.startTest();
            XeroSync.handleInvoicesFromXero();
        Test.stopTest();

        Map<String, Date> xeroIdToPaymentDate = new Map<String, Date>();
        for (XeroWrappers.XeroInvoice xeroInvoice :xeroInvoices) {
            xeroIdToPaymentDate.put(xeroInvoice.InvoiceID, xeroInvoice.FullyPaidOnDate);
        }

        payments = [SELECT XeroStatus__c, Payment_Date__c, Paid__c, Xero_ID__c FROM Sub_Project__c WHERE Id IN :payments];
        for (Sub_Project__c payment :payments) {
            System.assertEquals(payment.XeroStatus__c, SubProject.XERO_STATUS_PAID);
            System.assertEquals(payment.Payment_Date__c, xeroIdToPaymentDate.get(payment.Xero_ID__c));
            System.assertEquals(payment.Paid__c, true);
        }
    }

    @IsTest static void handleInvoicesFromXeroTest_AUTHORISED_onlyPayments() {
        XeroSettings__c xs = getXeroSettings();

        acc = TestHelper.createAccount();

        Project__c contract = TestHelper.createContract(acc.Id);
        List<Sub_Project__c> payments = [SELECT Id, Paid__c, Xero_Id__c, XeroStatus__c FROM Sub_Project__c WHERE Paid__c = false];
        List<XeroWrappers.XeroInvoice> xeroInvoices = new List<XeroWrappers.XeroInvoice>();
        for (Integer i = 0; i < payments.size(); i++) {
            payments[i].Xero_ID__c = '87d5bfb8-359b-4273-8e0b-c08c64da20'+i;
            System.assertNotEquals(payments[i].XeroStatus__c , SubProject.XERO_STATUS_AUTHORISED);

            // set up Xero response data
            XeroWrappers.XeroInvoice xeroInvoice = XeroTestHelper.createXeroInvoice();
            xeroInvoice.InvoiceID = payments[i].Xero_ID__c;
            xeroInvoice.Status = XeroWrappers.XeroInvoiceStatus.AUTHORISED;
            xeroInvoices.add(xeroInvoice);
        }
        update payments;

        // set up CalloutMock class data
        XeroTestHelper.xeroInvoices.addAll(xeroInvoices);

        Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
        Test.startTest();
        XeroSync.handleInvoicesFromXero();
        Test.stopTest();

        payments = [SELECT XeroStatus__c  FROM Sub_Project__c WHERE Id IN :payments];
        for (Sub_Project__c payment :payments) {
            System.assertEquals(payment.XeroStatus__c, SubProject.XERO_STATUS_AUTHORISED);
        }
    }

    @IsTest static void sendInvoice() {
        XeroSettings__c xs = getXeroSettings();

        Account acc = TestHelper.createAccount();

        Project__c contract = TestHelper.createContractNoInsert(acc.Id, 'TestContract', null);
        contract.Gaps_Exist_Between_Projects__c = true;
        contract.Xero_Entity__c = xs.Id;
        contract.Xero_Id__c = 'TestContractXeroId';
        insert contract;

        PlanComponentCtrl ctrl = new PlanComponentCtrl();
        ctrl.objType = 'Sub_Project__c';
        ctrl.contractId = contract.Id;

        Test.startTest();
        Sub_Project__c payment = ctrl.getPaymentsList()[0].payment;
        ctrl.paymentToInvoice = payment.Id;
        ctrl.sendInvoice();
        Test.stopTest();

    }

    /*@isTest static void handleInvoicesFromXeroTest_AUTHORISED_kevInvoicesAndPaymens() {
        XeroSettings__c xs = getXeroSettings();

        acc = TestHelper.createAccount();

        Project__c contract = TestHelper.createContract(acc.Id);
        List<Sub_Project__c> payments = [SELECT Id, Paid__c, Xero_Id__c, XeroStatus__c FROM Sub_Project__c WHERE Paid__c = false];
        List<XeroWrappers.XeroInvoice> xeroInvoices = new List<XeroWrappers.XeroInvoice>();
        for (Integer i = 0; i < payments.size(); i++) {
            payments[i].Xero_ID__c = '87d5bfb8-359b-4273-8e0b-c08c64da20'+i;
            System.assertNotEquals(payments[i].XeroStatus__c , SubProject.XERO_STATUS_AUTHORISED);

            // set up Xero response data
            XeroWrappers.XeroInvoice xeroInvoice = XeroTestHelper.createXeroInvoice();
            xeroInvoice.InvoiceID = payments[i].Xero_ID__c;
            xeroInvoice.Status = XeroWrappers.XeroInvoiceStatus.AUTHORISED;
            xeroInvoices.add(xeroInvoice);
        }
        update payments;
        // set up CalloutMock class data for Payments
        XeroTestHelper.xeroInvoices.addAll(xeroInvoices);

        Kevin_Organization__c kevOrg = TestHelper.createKevinOrganization('KevinOrgName', acc.Id, false);
        kevOrg.Xero_Entity__c = xs.Id;
        kevOrg.Xero_Id__c = '17d5bfb8-359b-4273-8e0b-c08c64da2043';
        insert kevOrg;

        Kevin_Invoice__c kevinInvoice = TestHelper.createKevinInvoice(kevOrg.Id, false);
        kevinInvoice.Xero_ID__c = '18d5bfb8-359b-4273-8e0b-c08c64da2043';
        insert kevinInvoice;

        XeroWrappers.XeroInvoice xeroInvoiceKev = XeroTestHelper.createXeroInvoice();
        xeroInvoiceKev.InvoiceID = kevinInvoice.Xero_ID__c;
        xeroInvoiceKev.Status = XeroWrappers.XeroInvoiceStatus.AUTHORISED;

        // set up CalloutMock class data for Kevin Invoice
        XeroTestHelper.xeroInvoices.add(xeroInvoiceKev);

        Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
        Test.startTest();
        XeroSync.handleInvoicesFromXero();
        Test.stopTest();


        payments = [SELECT XeroStatus__c  FROM Sub_Project__c WHERE Id IN :payments];
        for (Sub_Project__c payment :payments) {
            System.assertEquals(payment.XeroStatus__c, SubProject.XERO_STATUS_AUTHORISED);
        }

        kevinInvoice = [SELECT Status__c FROM Kevin_Invoice__c WHERE Id = :kevinInvoice.Id];
        System.assertEquals(kevinInvoice.Status__c, 'Authorised');
    }

    @isTest static void handleInvoicesFromXeroTest_PAID_kevInvoicesAndPaymens() {
        XeroSettings__c xs = getXeroSettings();

        acc = TestHelper.createAccount();

        Project__c contract = TestHelper.createContract(acc.Id);
        List<Sub_Project__c> payments = [SELECT Id, Paid__c, Xero_Id__c, XeroStatus__c FROM Sub_Project__c WHERE Paid__c = false];
        List<XeroWrappers.XeroInvoice> xeroInvoices = new List<XeroWrappers.XeroInvoice>();
        for (Integer i = 0; i < payments.size(); i++) {
            payments[i].Xero_ID__c = '87d5bfb8-359b-4273-8e0b-c08c64da20'+i;
            System.assertNotEquals(payments[i].XeroStatus__c , SubProject.XERO_STATUS_PAID);

            // set up Xero response data
            XeroWrappers.XeroInvoice xeroInvoice = XeroTestHelper.createXeroInvoice();
            xeroInvoice.InvoiceID = payments[i].Xero_ID__c;
            xeroInvoice.Status = XeroWrappers.XeroInvoiceStatus.PAID;
            xeroInvoices.add(xeroInvoice);
        }
        update payments;
        // set up CalloutMock class data for Payments
        XeroTestHelper.xeroInvoices.addAll(xeroInvoices);

        Kevin_Organization__c kevOrg = TestHelper.createKevinOrganization('KevinOrgName', acc.Id, false);
        kevOrg.Xero_Entity__c = xs.Id;
        kevOrg.Xero_Id__c = '17d5bfb8-359b-4273-8e0b-c08c64da2043';
        insert kevOrg;

        Kevin_Invoice__c kevinInvoice = TestHelper.createKevinInvoice(kevOrg.Id, false);
        kevinInvoice.Xero_ID__c = '18d5bfb8-359b-4273-8e0b-c08c64da2043';
        insert kevinInvoice;

        XeroWrappers.XeroInvoice xeroInvoiceKev = XeroTestHelper.createXeroInvoice();
        xeroInvoiceKev.InvoiceID = kevinInvoice.Xero_ID__c;
        xeroInvoiceKev.Status = XeroWrappers.XeroInvoiceStatus.PAID;

        // set up CalloutMock class data for Kevin Invoice
        XeroTestHelper.xeroInvoices.add(xeroInvoiceKev);

        Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
        Test.startTest();
        XeroSync.handleInvoicesFromXero();
        Test.stopTest();

        Map<String, Date> xeroIdToPaymentDate = new Map<String, Date>();
        for (XeroWrappers.XeroInvoice xeroInvoice :xeroInvoices) {
            xeroIdToPaymentDate.put(xeroInvoice.InvoiceID, xeroInvoice.FullyPaidOnDate);
        }

        payments = [SELECT XeroStatus__c, Payment_Date__c, Paid__c, Xero_ID__c FROM Sub_Project__c WHERE Id IN :payments];
        for (Sub_Project__c payment :payments) {
            System.assertEquals(payment.XeroStatus__c, SubProject.XERO_STATUS_PAID);
            System.assertEquals(payment.Payment_Date__c, xeroIdToPaymentDate.get(payment.Xero_ID__c));
            System.assertEquals(payment.Paid__c, true);
        }

        kevinInvoice = [SELECT Status__c FROM Kevin_Invoice__c WHERE Id = :kevinInvoice.Id];
        System.assertEquals(kevinInvoice.Status__c, 'Paid');
    }*/

}