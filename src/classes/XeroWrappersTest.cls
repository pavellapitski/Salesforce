@IsTest
private class XeroWrappersTest {

	private static String xeroContractId = '7b4b45fb-a4b4-407e-8f45-0ffc93f96dee';
	
	@IsTest static void testXeroContact() {
		String contactStr = '{"ContactID": "7b4b45fb-a4b4-407e-8f45-0ffc93f96dee", "ContactNumber": "12343",' +
      		'"ContactStatus": "ACTIVE", "Name": "Test Contact", "FirstName": "Test", "LastName": "Test",' +
      		'"EmailAddress": "test@test.test", "SkypeUserName": "4444", "BankAccountDetails": "asd", "Addresses": [' +
	        '{"AddressType": "STREET", "AddressLine1": "asd", "City": "asd", "Region": "asd", "PostalCode": "1234",' +
          	'"Country": "us", "AttentionTo": "asd"}, { "AddressType": "POBOX", "AddressLine1": "asd", "City": "asd",'+
          	'"Region": "asd", "PostalCode": "1234", "Country": "us", "AttentionTo": "asd"}], "Discount": 1.09,' +
      		'"Phones": [{"PhoneType": "DDI", "PhoneNumber": "44", "PhoneAreaCode": "44", "PhoneCountryCode": "44"' +
        	'}, {"PhoneType": "DEFAULT", "PhoneNumber": "4444", "PhoneAreaCode": "444", "PhoneCountryCode": "44"},' +
        	'{"PhoneType": "FAX", "PhoneNumber": "444", "PhoneAreaCode": "44", "PhoneCountryCode": "44"}],' +
      		'"ContactGroups": [], "IsSupplier": false, "AccountNumber": "123123", "TaxNumber": "123",' +
      		'"IsCustomer": true, "DefaultCurrency": "PLN", "ContactPersons": [{"ContactPersonId": "123ass", "FirstName": "Fname",' +
      		'"LastName": "Lname", "EmailAddress": "test@test.com", "IncludeInEmails": false}], "HasAttachments": false,' +
      		'"HasValidationErrors": false, "AccountsReceivableTaxType": "asd", "AccountsPayableTaxType": "asd",' +
      		'"XeroNetworkKey": "123", "SalesDefaultAccountCode": "200", "PurchasesDefaultAccountCode": "200",' +
      		'"PaymentTerms":{"Bills": {"Day": 10, "Type": "OFFOLLOWINGMONTH"},"Sales": {"Day": 10, "Type": "OFFOLLOWINGMONTH"}},' + 
      		'"Website": "http://test.com", "BrandingTheme": {"BrandingThemeID": "123"},' +
      		'"ContactGroups": [{"ContactGroupID": "123", "Name": "CGroup", "Contacts":[]}], ' +
      		'"Balances" : {"AccountsReceivable" : {"Outstanding": 1.02, "Overdue": 1.9}, "AccountsPayable" : {"Outstanding": 1.02, "Overdue": 1.9}},' +
      		'"BatchPayments": {"BankAccountNumber": "123","BankAccountName":"Test", "Details": "Details", "Code": "200", "Reference": "Reference"}}';

      	Map<String,Object> objMap = (Map<String,Object>) JSON.deserializeUntyped(contactStr);

		Test.startTest();
		XeroWrappers.XeroContact xc = new XeroWrappers.XeroContact(objMap);
		XeroWrappers.XeroContact xc2 = new XeroWrappers.XeroContact(xeroContractId);
		Test.stopTest();

		System.assertEquals(xeroContractId, xc.ContactID);
		System.assertEquals('Test Contact', xc.Name);
		System.assertEquals(xeroContractId, xc2.ContactID);
		System.assertEquals(null, xc2.Name);
	}
	
	@IsTest static void testXeroAccount() {
		String accountId = 'e7d6af30-a3b8-477f-aebd-6644d937ce0f';
		String accountJSON = '{' + '' +
			'"AccountID": "' + accountId +'",' +
      		'"Code": "200",' +
      		'"Name": "Sales",' +
      		'"Status": "ACTIVE",' +
      		'"Type": "REVENUE",' +
      		'"TaxType": "OUTPUT",' +
      		'"Description": "Income from any normal business activity",' +
			'"Class": "REVENUE",' +
			'"SystemAccount": "",' +
			'"EnablePaymentsToAccount": false,' +
			'"ShowInExpenseClaims": false,' +
			'"BankAccountType": "NONE",' +
			'"ReportingCode": "",' +
			'"HasAttachments": false' +
		'}';
      	
      	Map<String,Object> deserializedAccount = (Map<String,Object>) JSON.deserializeUntyped(accountJSON);
		Test.startTest();
		XeroWrappers.XeroAccount xa = new XeroWrappers.XeroAccount(deserializedAccount);
		Test.stopTest();
		System.assertEquals(accountId, xa.AccountID);
	}

	@IsTest static void testCreditNote() {
        Date today = System.today();

        Project__c contract = TestHelper.createContractNoInsert(TestHelper.createAccount().Id, 'testContract', null);
        contract.Client_Spend__c = 10000;
        contract.Gaps_Exist_Between_Projects__c = true;
        contract.Start_Date__c = Date.newInstance(today.year(), today.month(), 1).addMonths(-2);
        contract.End_Date__c = Date.newInstance(today.year(), today.month(), 7).addMonths(-1);
		insert contract;

        delete [SELECT Id FROM Sub_Project__c WHERE Project__c = :contract.Id];

        Test.startTest();
		Sub_Project__c payment = TestHelper.createPaymentNoInsert(contract);
        payment.CurrencyIsoCode = 'SGD';
        payment.Checked__c = true;
        payment.Xero_Id__c = '871fd9e9-f7ca-4577-a57c-805838b14743';
        payment.Invoice__c = 'INV-999';
        insert payment;
        
        Payment__c project = [SELECT Id FROM Payment__c WHERE Payment__c = :payment.Id];
        project.InvoiceAmount__c = 90000;
        update project;

        CreditNote__c creditNote = TestHelper.createCreditNoteNoInsert(payment.Id);
        creditNote.Amount__c = 75000;
        insert creditNote;

        XeroWrappers.XeroCreditNote xNote = new XeroWrappers.XeroCreditNote(CreditNoteRepository.getCreditNoteById(creditNote.Id));
        Test.stopTest();

        payment = SubProjectRepository.getInvoiceForXeroSubmission(payment.Id)[0];
        System.assertEquals(15000, Math.round(xNote.lineItems[0].LineAmount));
        System.assertEquals(payment.CurrencyIsoCode, xNote.CurrencyCode);
        System.assert(xNote.lineItems[0].Description.contains(XeroUtils.LINE_ITEM_DESCRIPTION_CAMPAIGN_ID + payment.ProjectId__c));
        System.assertEquals(payment.Invoice__c + ' - ' + payment.Project__r.Name + ' - ' + payment.ProjectId__c, xNote.Reference);

        if (today.day() <= 14) {
            System.assertEquals(payment.End_Date__c, xNote.CreditNoteDate);
        } else {
            System.assertEquals(today, xNote.CreditNoteDate);
        }
    }
    
    @IsTest static void testXeroInvoice() {
      	Map<String, Object> objMap = (Map<String, Object>) JSON.deserializeUntyped('{"FullyPaidOnDate": "(1453633200000-1300)"}');
        
		Test.startTest();
		XeroWrappers.XeroInvoice xa = new XeroWrappers.XeroInvoice(objMap);
		Test.stopTest();
		System.assertEquals(Date.newInstance(2016, 01, 23), xa.FullyPaidOnDate);
	}
	
	@IsTest static void testXeroTrackingCategory() {
		Map<String,Object> objMap = (Map<String,Object>) JSON.deserializeUntyped('{"Name": "XTC name", "Status": "DELETED", "Options": [{"TrackingCategoryID": "11221", "Name": "Option1", "Status":"DELETED"}]}');

		Test.startTest();
		XeroWrappers.XeroTrackingCategory xa = new XeroWrappers.XeroTrackingCategory(objMap);
		Test.stopTest();
	}
}