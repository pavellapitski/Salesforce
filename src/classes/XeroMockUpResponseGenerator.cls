@isTest
global class XeroMockUpResponseGenerator implements HttpCalloutMock {
	
	global HttpResponse respond(HttpRequest req) {
		HttpResponse res = new HttpResponse();
		res.setStatusCode(200);
		res.setHeader('Content-Type', 'application/json');

		if (req.getEndpoint().contains('https://api.xero.com/api.xro/2.0/Contacts/87d5bfb8-359b-4273-8e0b-c08c64da1234')) {
			res.setBody(getContactsErrorResponse());
		} else if (req.getEndpoint().contains('https://api.xero.com/api.xro/2.0/Contacts') == true) {
			res.setBody(getContactsResponse());
		} else if (req.getEndpoint() == 'https://api.xero.com/api.xro/2.0/Contacts/87d5bfb8-359b-4273-8e0b-c08c64da2062') {
			res.setBody(getContactsResponse());
        } else if (req.getEndpoint().contains('https://api.xero.com/api.xro/2.0/Invoices') == true ) {
			res.setBody(getInvoicesResponse());
		} else if (req.getEndpoint() == 'https://api.xero.com/api.xro/2.0/Invoices/c550782f-ce91-4261-a61c-387250909309') {
			res.setBody(getInvoicesResponse());
		} else if (req.getEndpoint() == 'https://api.xero.com/api.xro/2.0/Accounts') {
			res.setBody(getAccountsResponse());
		} else if (req.getEndpoint() == 'https://api.xero.com/api.xro/2.0/BrandingThemes') {
			res.setBody(getBrandingsResponse());
		} else if (req.getEndpoint().contains('https://api.xero.com/api.xro/2.0/BrandingThemes') == true) {
			res.setBody(getBrandingResponse());
		} else if (req.getEndpoint().contains('https://api.xero.com/api.xro/2.0/CreditNotes') == true) {
			res.setBody(getCreditNotesResponse());
		}else {
		}
		return res;
	}

	global String getContactsResponse() {
		XeroWrappers.XeroContact xc = XeroTestHelper.createXeroContact();

      List<XeroWrappers.XeroContact> xcList 	= new List<XeroWrappers.XeroContact>{xc};
      String result = '{"Id": "e2b6e6f5-124f-48ff-9525-a1a456d7ca59","Status": "OK", "Contacts": ' + JSON.serialize(xcList) 
      	+', "ProviderName": "TestM", "StatusCode": "200"}';
      
      return result;
	}

	global String getContactsErrorResponse() {
		String result = '{"Id": "e2b6e6f5-124f-48ff-9525-a1a456d7ca59","Status": "Invalid Id", "Contacts": []' + 
      	', "ProviderName": "TestM", "StatusCode": "400"}';
      
      return result;
	}

	global String getInvoicesResponse() {
		XeroWrappers.XeroInvoice xi = XeroTestHelper.createXeroInvoice();

		List<XeroWrappers.XeroInvoice> xiList 	= new List<XeroWrappers.XeroInvoice>{xi};
        xiList.addAll(XeroTestHelper.xeroInvoices);    
            
      	String result = '{"Id": "e2b6e6f5-124f-48ff-9525-a1a456d7ca59","Status": "OK", "Invoices": ' + JSON.serialize(xiList) 
      	+', "ProviderName": "TestM", "StatusCode": "200"}';
      	return result;
	}

	global String getAccountsResponse() {
		XeroWrappers.XeroAccount xa = XeroTestHelper.createXeroAccount();

		List<XeroWrappers.XeroAccount> xaList 	= new List<XeroWrappers.XeroAccount>{xa};
      String result = '{"Id": "e2b6e6f5-124f-48ff-9525-a1a456d7ca59","Status": "OK", "Accounts": ' + JSON.serialize(xaList) 
      	+', "ProviderName": "TestM", "StatusCode": "200"}';
      return result;
	}

	global String getBrandingsResponse() {
		String result = '{"Id": "7e94fe23-119f-437a-a6ff-c6e1a2a94cbd","Status": "OK","ProviderName": "TestM","BrandingThemes": [{' + 
      	'"BrandingThemeID": "a211225e-e7c3-4d18-bb4d-c70faa2be017", "Name": "Standard", "SortOrder": 0},' + 
    	'{"BrandingThemeID": "d9ea7550-8a3c-4ba9-87fd-7dec06cff19e","Name": "Test","SortOrder": 1}],' +
    	'"StatusCode": "200"}';

    	return result;
	}

	global String getBrandingResponse() {
		String result = '{"Id": "7e94fe23-119f-437a-a6ff-c6e1a2a94cbd","Status": "OK","ProviderName": "TestM","BrandingThemes": [{' + 
      	'"BrandingThemeID": "a211225e-e7c3-4d18-bb4d-c70faa2be017", "Name": "Standard", "SortOrder": 0}],' + 
    	'"StatusCode": "200"}';

    	return result;
	}

	global String getCreditNotesResponse() {  
            
      	String result = '{"Id": "e2b6e6f5-124f-48ff-9525-a1a456d7ca59","Status": "OK", "CreditNotes": ' + JSON.serialize(XeroTestHelper.xeroCreditNotes) 
      	+', "ProviderName": "TestM", "StatusCode": "200"}';
    
        return result;
	}
}