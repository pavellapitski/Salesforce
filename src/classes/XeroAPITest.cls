@IsTest
private class XeroAPITest {
	
	@IsTest static void getAllContactsByConnectWithXeroSettings() {
		xeroSettings__c xs = TestHelper.createXeroEntity();

		Test.startTest();
			// Set mock callout class
	        Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
	        HttpResponse res = XeroAPI.connect(xs, 'GET', 'Contacts');
        Test.stopTest();

        // Verify response received contains fake values
		String contentType        = res.getHeader('Content-Type');
		System.assert(contentType == 'application/json');
		String actualValue        = res.getBody();
        //String expectedValue = '{"foo":"bar"}';
        //System.assertEquals(actualValue, expectedValue);
        System.assertEquals(200, res.getStatusCode());
	}
	
	@IsTest static void getAllContactsWithXeroSettings() {
		xeroSettings__c xs = TestHelper.createXeroEntity();

		Test.startTest();
			// Set mock callout class
	        Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());

	        XeroWrappers.XeroContactResponse res = XeroAPI.getAllContacts(xs);
        Test.stopTest();

        // Verify response received contains fake values
		List<XeroWrappers.XeroContact> contacts        = (List<XeroWrappers.XeroContact>)res.xeroObjects;
        System.assertEquals(1, contacts.size());
        System.assertEquals(200, res.StatusCode);
	}

	@IsTest static void getAllContactsWithXeroName() {
		xeroSettings__c xs = TestHelper.createXeroEntity();

		Test.startTest();
			// Set mock callout class
	        Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());

	        XeroWrappers.XeroContactResponse res = XeroAPI.getAllContacts('TestXero');
        Test.stopTest();

        // Verify response received contains fake values
		List<XeroWrappers.XeroContact> contacts        = (List<XeroWrappers.XeroContact>)res.xeroObjects;
        System.assertEquals(1, contacts.size());
        System.assertEquals(200, res.StatusCode);
	}
	
	@IsTest static void getContactWithXeroName() {
		xeroSettings__c xs = TestHelper.createXeroEntity();

		Test.startTest();
			// Set mock callout class
	        Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());

	        XeroWrappers.XeroContactResponse res = XeroAPI.getContact('TestXero', '87d5bfb8-359b-4273-8e0b-c08c64da2062');
        Test.stopTest();

        // Verify response received contains fake values
		List<XeroWrappers.XeroContact> contacts        = (List<XeroWrappers.XeroContact>)res.xeroObjects;
        System.assertEquals(1, contacts.size());
        System.assertEquals('87d5bfb8-359b-4273-8e0b-c08c64da2062', contacts[0].ContactId);
        System.assertEquals(200, res.StatusCode);
	}

	@IsTest static void getContactWithXeroSettings() {
		xeroSettings__c xs = TestHelper.createXeroEntity();

		Test.startTest();
			// Set mock callout class
	        Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());

	        XeroWrappers.XeroContactResponse res = XeroAPI.getContact(xs, '87d5bfb8-359b-4273-8e0b-c08c64da2062');
        Test.stopTest();

        // Verify response received contains fake values
		List<XeroWrappers.XeroContact> contacts        = (List<XeroWrappers.XeroContact>)res.xeroObjects;
        System.assertEquals(1, contacts.size());
        System.assertEquals('87d5bfb8-359b-4273-8e0b-c08c64da2062', contacts[0].ContactId);
        System.assertEquals(200, res.StatusCode);
	}

	@IsTest static void postContactWithXeroName() {
		xeroSettings__c xs = TestHelper.createXeroEntity();

		Test.startTest();
			// Set mock callout class
	        Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
	        XeroWrappers.XeroContact xc = XeroTestHelper.createXeroContact();
	        XeroWrappers.XeroContactResponse res = XeroAPI.postContact(xc, 'TestXero');
        Test.stopTest();

        // Verify response received contains fake values
		List<XeroWrappers.XeroContact> contacts        = (List<XeroWrappers.XeroContact>)res.xeroObjects;
        System.assertEquals(1, contacts.size());
        System.assertEquals('87d5bfb8-359b-4273-8e0b-c08c64da2062', contacts[0].ContactId);
        System.assertEquals(200, res.StatusCode);
	}

	@IsTest static void postContactWithXeroSettings() {
		xeroSettings__c xs = TestHelper.createXeroEntity();

		Test.startTest();
			// Set mock callout class
	        Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
	        XeroWrappers.XeroContact xc = XeroTestHelper.createXeroContact();
	        XeroWrappers.XeroContactResponse res = XeroAPI.postContact(xc, xs);
        Test.stopTest();

        // Verify response received contains fake values
		List<XeroWrappers.XeroContact> contacts        = (List<XeroWrappers.XeroContact>)res.xeroObjects;
        System.assertEquals(1, contacts.size());
        System.assertEquals('87d5bfb8-359b-4273-8e0b-c08c64da2062', contacts[0].ContactId);
        System.assertEquals(200, res.StatusCode);
	}

	@IsTest static void postInvoicetWithXeroName() {
		xeroSettings__c xs = TestHelper.createXeroEntity();

		Test.startTest();
			// Set mock callout class
	        Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
			XeroWrappers.XeroInvoice xi          = XeroTestHelper.createXeroInvoice();
			XeroWrappers.XeroInvoiceResponse res = XeroAPI.postInvoice(xi, 'TestXero');
        Test.stopTest();

        // Verify response received contains fake values
		List<XeroWrappers.XeroInvoice> invoices        = (List<XeroWrappers.XeroInvoice>)res.xeroObjects;
        System.assertEquals(1, invoices.size());
        System.assertEquals('c550782f-ce91-4261-a61c-387250909309', invoices[0].InvoiceID);
        System.assertEquals(200, res.StatusCode);
	}

	@IsTest static void postInvoiceWithXeroSettings() {
		xeroSettings__c xs = TestHelper.createXeroEntity();

		Test.startTest();
			// Set mock callout class
	        Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
	        XeroWrappers.XeroInvoice xc = XeroTestHelper.createXeroInvoice();
	        XeroWrappers.XeroInvoiceResponse res = XeroAPI.postInvoice(xc, xs);
        Test.stopTest();

        // Verify response received contains fake values
		List<XeroWrappers.XeroInvoice> invoices        = (List<XeroWrappers.XeroInvoice>)res.xeroObjects;
        System.assertEquals(1, invoices.size());
        System.assertEquals('c550782f-ce91-4261-a61c-387250909309', invoices[0].InvoiceID);
        System.assertEquals(200, res.StatusCode);
	}

	@IsTest static void getInvoicetWithXeroName() {
		xeroSettings__c xs = TestHelper.createXeroEntity();

		Test.startTest();
			// Set mock callout class
	        Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
			XeroWrappers.XeroInvoiceResponse res = XeroAPI.getInvoiceById('c550782f-ce91-4261-a61c-387250909309', 'TestXero');
        Test.stopTest();

        // Verify response received contains fake values
		List<XeroWrappers.XeroInvoice> invoices        = (List<XeroWrappers.XeroInvoice>)res.xeroObjects;
        System.assertEquals(1, invoices.size());
        System.assertEquals('c550782f-ce91-4261-a61c-387250909309', invoices[0].InvoiceID);
        System.assertEquals(200, res.StatusCode);
	}

	@IsTest static void getInvoiceWithXeroSettings() {
		xeroSettings__c xs = TestHelper.createXeroEntity();

		Test.startTest();
			// Set mock callout class
	        Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
	        XeroWrappers.XeroInvoiceResponse res = XeroAPI.getInvoiceById('c550782f-ce91-4261-a61c-387250909309', xs);
        Test.stopTest();

        // Verify response received contains fake values
		List<XeroWrappers.XeroInvoice> invoices        = (List<XeroWrappers.XeroInvoice>)res.xeroObjects;
        System.assertEquals(1, invoices.size());
        System.assertEquals('c550782f-ce91-4261-a61c-387250909309', invoices[0].InvoiceID);
        System.assertEquals(200, res.StatusCode);
	}

	@IsTest static void getAllInvoicesWithXeroSettings() {
		xeroSettings__c xs = TestHelper.createXeroEntity();

		Test.startTest();
			// Set mock callout class
	        Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
	        XeroWrappers.XeroInvoiceResponse res = XeroAPI.getAllInvoices(xs);
        Test.stopTest();

        // Verify response received contains fake values
		List<XeroWrappers.XeroInvoice> invoices        = (List<XeroWrappers.XeroInvoice>)res.xeroObjects;
        System.assertEquals(1, invoices.size());
        System.assertEquals('c550782f-ce91-4261-a61c-387250909309', invoices[0].InvoiceID);
        System.assertEquals(200, res.StatusCode);
	}

	@IsTest static void calloutErrorsTest() {
		xeroSettings__c xs = TestHelper.createXeroEntity();

		Test.startTest();
			// Set mock callout class
	        Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
	        XeroWrappers.XeroContact xc = XeroTestHelper.createXeroContact();
	        try {
	        	XeroWrappers.XeroContactResponse res = XeroAPI.postContact(xc, 'Xero Test');	
	        } catch (Exception e) {
	        	System.assert(e.getMessage().contains('Error: No service found with given name.'));
	        }

	        XeroWrappers.XeroInvoice xi = XeroTestHelper.createXeroInvoice();
	        try {
	        	XeroWrappers.XeroInvoiceResponse res = XeroAPI.postInvoice(xi, 'Xero Test');	
	        } catch (Exception e) {
	        	System.assert(e.getMessage().contains('Error: No service found with given name.'));
	        }
	        
        Test.stopTest();
	}

	@IsTest static void getAccountTest() {
		xeroSettings__c xs = TestHelper.createXeroEntity();

		Test.startTest();
			// Set mock callout class
	        Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
	        HttpResponse res = XeroAPI.connect(xs, 'GET', 'Accounts');
	        
        Test.stopTest();
        System.assertEquals(200, res.getStatusCode());
	}

	@IsTest static void getAllBrandingThemes() {
		xeroSettings__c xs = TestHelper.createXeroEntity();

		Test.startTest();
			// Set mock callout class
	        Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
	        XeroWrappers.XeroBrandingResponse res = XeroAPI.getAllBrandingThemes(xs);
	        
        Test.stopTest();
        System.assertEquals(200, res.StatusCode);
        System.assertEquals(2, res.xeroObjects.size());
	}

	@IsTest static void getBrandingThemeTest() {
		xeroSettings__c xs = TestHelper.createXeroEntity();

		Test.startTest();
			// Set mock callout class
	        Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
	        XeroWrappers.XeroBrandingResponse res = XeroAPI.getBrandingTheme(xs, 'a211225e-e7c3-4d18-bb4d-c70faa2be017');
	        
        Test.stopTest();
        System.assertEquals(200, res.StatusCode);
        System.assertEquals(1, res.xeroObjects.size());
	}
}