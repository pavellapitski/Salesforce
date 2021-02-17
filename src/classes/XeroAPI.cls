/*************************************************
 * Class contains methods needed to
 * connecting to Private Application in Xero

 History
 -------------------------------------------------
 v 1.0  21/09/2015 mtomala@striketech.pl

 -------------------------------------------------

 *************************************************/

global with sharing class XeroAPI {

    public XeroAPI() {}

    public static Datetime lastModifiedDate = null;

    public static XeroWrappers.XeroContactResponse getAllContacts(String serviceName) {
        HttpResponse res = XeroAPI.connect(serviceName, 'GET', 'Contacts');
        if (res.getStatusCode() == 200) {
            return new XeroWrappers.XeroContactResponse(res.getBody());
        } else {
            return new XeroWrappers.XeroContactResponse(res.getStatus(), res.getStatusCode());
        }
    }

    public static XeroWrappers.XeroContactResponse getAllContacts(XeroSettings__c xeroEntity) {
        //Map<String,String> filters = new Map<String,String> {/*'IsCustomer' => 'true'*/};
        HttpResponse res = XeroAPI.connect(xeroEntity, 'GET', 'Contacts', new Map<String,String>());
        if (res.getStatusCode() == 200) {
            return new XeroWrappers.XeroContactResponse(res.getBody());
        } else {
            return new XeroWrappers.XeroContactResponse(res.getStatus(), res.getStatusCode());
        }
    }

    public static XeroWrappers.XeroContactResponse getContact(String serviceName, String contactId) {
        HttpResponse res = XeroAPI.connect(serviceName, 'GET', 'Contacts', contactId, null);
        if (res.getStatusCode() == 200) {
            return new XeroWrappers.XeroContactResponse(res.getBody());
        } else {
            return new XeroWrappers.XeroContactResponse(res.getStatus(), res.getStatusCode());
        }
    }

    public static XeroWrappers.XeroContactResponse getContact(XeroSettings__c service, String contactId) {
        HttpResponse res = XeroAPI.connect(service, 'GET', 'Contacts', contactId, null);
        if (res.getStatusCode() == 200) {
            return new XeroWrappers.XeroContactResponse(res.getBody());
        } else {
            return new XeroWrappers.XeroContactResponse(res.getStatus(), res.getStatusCode());
        }
    }

    private static List<XeroSettings__c> getXeroSettings(String serviceName) {
        List<XeroSettings__c> xeroList = [SELECT ConsumerKey__c,ConsumerSecret__c,PrivateKey__c, Name FROM XeroSettings__c WHERE Name =: serviceName];
        if (xeroList.isEmpty()) {
            throw new XeroException('Error: No service found with given name.');
        }
        return xeroList;
    }


    // post contact
    public static XeroWrappers.XeroContactResponse postContact(XeroWrappers.XeroContact contact, String serviceName) {
        return postContacts(new List<XeroWrappers.XeroContact>{contact}, serviceName);
    }

    public static XeroWrappers.XeroContactResponse postContact(XeroWrappers.XeroContact contact, XeroSettings__c serviceName) {
        return postContacts(new List<XeroWrappers.XeroContact>{contact}, serviceName);
    }

    public static XeroWrappers.XeroContactResponse postContacts(List<XeroWrappers.XeroContact> contacts, String serviceName) {
        return postContacts(contacts, getXeroSettings(serviceName)[0]);
    }

    public static XeroWrappers.XeroContactResponse postContacts(List<XeroWrappers.XeroContact> contacts, XeroSettings__c serviceName) {
        XmlStreamWriter xmlW = new XmlStreamWriter();
        xmlW.writeStartDocument('utf-8','1.0');
        xmlW.writeStartElement(null, 'Invoices', null);

        for (XeroWrappers.XeroContact xc :contacts) {
            XMLUtility.mapContactItemToXml(xc, xmlW);
        }

        xmlW.writeEndElement(); //Close
        xmlW.writeEndDocument(); //Close

        String body = xmlW.getXmlString();
        HttpResponse res = XeroAPI.connect(serviceName, 'POST', 'Contacts', body);
        if (res.getStatusCode() == 200) {
            String result = (res.getBody()).replaceAll('[/\\\\]', '');
            result        = result.replaceAll('\\bDate\\(\\b', '');
            return new XeroWrappers.XeroContactResponse(result);
        } else {
            return new XeroWrappers.XeroContactResponse(res.getStatus(), res.getStatusCode());
        }
    }

    // Credit Notes
    public static XeroWrappers.XeroCreditNoteResponse postCreditNotes(List<XeroWrappers.XeroCreditNote> creditNotes, XeroSettings__c xeroService) {
        XmlStreamWriter xmlW = new XmlStreamWriter();
        xmlW.writeStartDocument('utf-8','1.0');
        xmlW.writeStartElement(null, 'CreditNotes', null);
        for (XeroWrappers.XeroCreditNote xcn : creditNotes) {
            XMLUtility.mapCreditNoteToXML(xcn, xmlW);
        }
        xmlW.writeEndElement(); //Close
        xmlW.writeEndDocument(); //Close

        String body = xmlW.getXmlString();
        HttpResponse res = XeroAPI.connect(xeroService, 'POST', 'CreditNotes', body);
        if (res.getStatusCode() == 200) {
            return new XeroWrappers.XeroCreditNoteResponse(res.getBody());
        } else {
            return new XeroWrappers.XeroCreditNoteResponse(res.getStatus(), res.getStatusCode(), res.getBody());
        }
    }

    // Invoices
    public static XeroWrappers.XeroInvoiceResponse postInvoice(XeroWrappers.XeroInvoice invoice, String serviceName) {
        return postInvoices(new List<XeroWrappers.XeroInvoice>{invoice}, serviceName);
    }

    public static XeroWrappers.XeroInvoiceResponse postInvoice(XeroWrappers.XeroInvoice invoice, XeroSettings__c serviceName) {
        return postInvoices(new List<XeroWrappers.XeroInvoice>{invoice}, serviceName);
    }

    public static XeroWrappers.XeroInvoiceResponse postInvoices(List<XeroWrappers.XeroInvoice> invList, String serviceName) {
        return postInvoices(invList, getXeroSettings(serviceName)[0]);
    }

    public static XeroWrappers.XeroInvoiceResponse postInvoices(List<XeroWrappers.XeroInvoice> invList, XeroSettings__c serviceName) {
        XmlStreamWriter xmlW = new XmlStreamWriter();
        xmlW.writeStartDocument('utf-8','1.0');
        xmlW.writeStartElement(null, 'Invoices', null);
        for (XeroWrappers.XeroInvoice xi : invList) {
            XMLUtility.mapInvoiceItemToXML(xi, xmlW);
        }
        xmlW.writeEndElement(); //Close
        xmlW.writeEndDocument(); //Close

        String body = xmlW.getXmlString();
        HttpResponse res = XeroAPI.connect(serviceName, 'POST', 'Invoices', body);
        if (res.getStatusCode() == 200) {
            return new XeroWrappers.XeroInvoiceResponse(res.getBody());
        } else {
            return new XeroWrappers.XeroInvoiceResponse(res.getStatus(), res.getStatusCode(), res.getBody());
        }
    }

    // method returns Invoice by xero id or invoice number
    public static XeroWrappers.XeroInvoiceResponse getInvoiceById(String invoiceId, String serviceName) {
        HttpResponse res = XeroAPI.connect(serviceName, 'GET', 'Invoices', invoiceId, null);
        if (res.getStatusCode() == 200) {
            return new XeroWrappers.XeroInvoiceResponse(res.getBody());
        } else {
            return new XeroWrappers.XeroInvoiceResponse(res.getStatus(), res.getStatusCode());
        }
    }

    public static XeroWrappers.XeroInvoiceResponse getInvoiceById(String invoiceId, XeroSettings__c serviceName) {
        HttpResponse res = XeroAPI.connect(serviceName, 'GET', 'Invoices', invoiceId, null);
        if (res.getStatusCode() == 200) {
            return new XeroWrappers.XeroInvoiceResponse(res.getBody());
        } else {
            return new XeroWrappers.XeroInvoiceResponse(res.getStatus(), res.getStatusCode());
        }
    }

    public static XeroWrappers.XeroInvoiceResponse getInvoicesGreaterThanDate(XeroSettings__c serviceName, Date gtDate) {
        Map<String,String> filters = new Map<String,String>{
                'date' => 'DateTime(' + gtDate.year() + ', ' + gtDate.month() + ', ' + gtDate.day() + ')'
        };
        HttpResponse res = XeroAPI.connect(serviceName, 'GET', 'Invoices', filters);
        System.debug('### body:' + res.getBody());
        if (res.getStatusCode() == 200) {
            return new XeroWrappers.XeroInvoiceResponse(res.getBody());
        } else {
            return new XeroWrappers.XeroInvoiceResponse(res.getStatus(), res.getStatusCode());
        }
    }

    public static XeroWrappers.XeroInvoiceResponse getAllInvoices(XeroSettings__c serviceName) {
        HttpResponse res = XeroAPI.connect(serviceName, 'GET', 'Invoices');
        if (res.getStatusCode() == 200) {
            return new XeroWrappers.XeroInvoiceResponse(res.getBody());
        } else {
            return new XeroWrappers.XeroInvoiceResponse(res.getStatus(), res.getStatusCode());
        }
    }

    // Branding Theme
    public static XeroWrappers.XeroBrandingResponse getAllBrandingThemes(XeroSettings__c serviceName) {
        HttpResponse res = XeroAPI.connect(serviceName, 'GET', 'Branding');
        if (res.getStatusCode() == 200) {
            return new XeroWrappers.XeroBrandingResponse(res.getBody());
        } else {
            return new XeroWrappers.XeroBrandingResponse(res.getStatus(), res.getStatusCode());
        }
    }

    public static XeroWrappers.XeroBrandingResponse getBrandingTheme(XeroSettings__c serviceName, String brandingId) {
        HttpResponse res = XeroAPI.connect(serviceName, 'GET', 'Branding', brandingId, null);
        if (res.getStatusCode() == 200) {
            return new XeroWrappers.XeroBrandingResponse(res.getBody());
        } else {
            return new XeroWrappers.XeroBrandingResponse(res.getStatus(), res.getStatusCode());
        }
    }

    public static XeroWrappers.XeroBrandingResponse getAllBrandingThemes(String serviceName) {
        HttpResponse res = XeroAPI.connect(serviceName, 'GET', 'Branding');
        if (res.getStatusCode() == 200) {
            return new XeroWrappers.XeroBrandingResponse(res.getBody());
        } else {
            return new XeroWrappers.XeroBrandingResponse(res.getStatus(), res.getStatusCode());
        }
    }

     public static XeroWrappers.XeroCreditNoteResponse getAllCreditNotes(XeroSettings__c serviceName) {
        HttpResponse res = XeroAPI.connect(serviceName, 'GET', 'CreditNotes');
        if (res.getStatusCode() == 200) {
            return new XeroWrappers.XeroCreditNoteResponse(res.getBody());
        } else {
            return new XeroWrappers.XeroCreditNoteResponse(res.getStatus(), res.getStatusCode());
        }
    }

    // Connection
    public static HttpResponse connect(String serviceName, String method, String endpoint) {
        return connect(serviceName, method, endpoint, null, null);
    }

    public static HttpResponse connect(XeroSettings__c serviceName, String method, String endpoint) {
        return connect(serviceName, method, endpoint, null, null);
    }

    public static HttpResponse connect(String serviceName, String method, String endpoint, String body) {
        return connect(serviceName, method, endpoint, null, body);
    }

    public static HttpResponse connect(XeroSettings__c serviceName, String method, String endpoint, String body) {
        return connect(serviceName, method, endpoint, null, body);
    }

    public static HttpResponse connect(String serviceName, String method, String endpoint, String objId, String body) {
        return connect(getXeroSettings(serviceName)[0], method, endpoint, objId, body);
    }


    public static HttpResponse connect(XeroSettings__c xeroEntity, String method, String endpoint, Map<String,String> filters) {
        if (String.isBlank(method)) {
            throw new XeroException('Error: The request method is not specified.');
        }

        HttpRequest req = new HttpRequest();
        req.setMethod(method);
        String filterStr = '';
        if (!filters.isEmpty()) {
            for (String f :filters.keySet()) {
                if (!String.isBlank(filterStr)) {
                    filterStr += '&';
                }
                if (f == 'order') {
                    filterStr += f + '=' + filters.get(f);
                } else if (f == 'date') {
                    filterStr += f + '>=' + filters.get(f);
                }  else {
                    filterStr += f;
                    if (!String.isBlank(filters.get(f))) {
                        filterStr += '==' + filters.get(f);
                    }
                }
            }
        }
        req.setEndpoint(getUrlParam(endpoint) + (String.isBlank(filterStr) == true ? '' : '?where=' + EncodingUtil.urlEncode(filterStr, 'UTF-8')));
        signRequest(xeroEntity, req);

        return new Http().send(req);
    }

    public static HttpResponse connect(XeroSettings__c xeroEntity, String method, String endpoint, String objId, String body) {
        if (String.isBlank(method)) {
            throw new XeroException('Error: The request method is not specified.');
        }

        HttpRequest req = new HttpRequest();
        req.setMethod(method);
        String errorSummarize = '';
        if ((method == 'POST' || method == 'PUT') && String.isBlank(body) != null) {
            req.setBody(body);
            req.setHeader('Content-Type', 'application/xml');
            errorSummarize = '?summarizeErrors=false';
        }
        req.setEndpoint(
                getUrlParam(endpoint)
                + (String.isBlank(objId) == true ? '' : '/' + objId)
                + errorSummarize
        );
        signRequest(xeroEntity, req);

        return new Http().send(req);
    }


    private static String getUrlParam(String objName) {
        String baseUrl = 'https://api.xero.com/api.xro/2.0/';
        if (objName == 'Org') {
            return baseUrl + 'Organisation';
        } else if (objName == 'Accounts') {
            return baseUrl + 'Accounts';
        } else if (objName == 'Contacts') {
            return baseUrl + 'Contacts';
        } else if (objName == 'Invoices'){
            return baseUrl + 'Invoices';
        } else if (objName == 'CreditNotes') {
            return baseUrl + 'CreditNotes';
        } else if (objName == 'Branding') {
            return baseUrl + 'BrandingThemes';
        } else {
            return baseUrl + objName;
        }
    }

    private static void signRequest(XeroSettings__c service, HttpRequest req) {
        String nonce = String.valueOf(Crypto.getRandomLong());
        String timestamp = String.valueOf(Datetime.now().getTime()/1000);

        Map<String, String> parameters = new Map<String, String>();
        parameters.put('oauth_consumer_key', service.ConsumerKey__c);
        parameters.put('oauth_signature_method', 'RSA-SHA1');
        parameters.put('oauth_timestamp',timestamp);
        parameters.put('oauth_nonce', nonce);
        parameters.put('oauth_token', service.ConsumerKey__c);

        String s = createBaseString(parameters, req);

        Blob sig;
        if (String.isBlank(service.PrivateKey__c) == false) {
            sig = Crypto.sign('RSA-SHA1', Blob.valueOf(s), EncodingUtil.base64Decode(service.PrivateKey__c));
        } else {
            sig = Crypto.generateMac('HmacSHA1', Blob.valueOf(s), Blob.valueOf(service.ConsumerSecret__c + '&'));
        }
        String signature = EncodingUtil.urlEncode(EncodingUtil.base64Encode(sig), 'UTF-8');

        // OAuth header
        String header = 'OAuth ';
        for (String key : parameters.keySet()) {
            header += key + '="' + parameters.get(key) + '",';
        }
        header += 'oauth_signature="' + signature + '"';
        req.setHeader('Authorization',header);
        req.setHeader('Accept', 'application/json');

        if (lastModifiedDate != null) {
        	req.setHeader('If-Modified-Since', lastModifiedDate.formatGmt('EEE, d MMM yyyy HH:mm:ss'));
        }
    }

    private static String createBaseString(Map<String,String> parameters, HttpRequest req) {
        Map<String,String> params = parameters.clone();

        if(req.getMethod().equalsIgnoreCase('post') && req.getBody() != null && req.getHeader('Content-Type') == 'application/x-www-form-urlencoded') {
            params.putAll(getUrlParams(req.getBody()));
        }
        String host = req.getEndpoint();
        Integer n   = host.indexOf('?');
        if (n > -1) {
            params.putAll(getUrlParams(host.substring(n + 1)));
            host = host.substring(0,n);
        }
        List<String> keys = new List<String>();
        keys.addAll(params.keySet());
        keys.sort();

        String result = '';
        for (String s : keys) {
            result += (String.isBlank(result) == true ? '' : '&') + s + '=' + params.get(s);
        }
        return req.getMethod().toUpperCase()+ '&' + EncodingUtil.urlEncode(host, 'UTF-8') + '&' + EncodingUtil.urlEncode(result, 'UTF-8');
    }

    private static Map<String,String> getUrlParams(String value) {
        Map<String,String> res = new Map<String,String>();
        if (value == null || value == '') {
            return res;
        }

        String encName, encValue;
        for(String s :value.split('&')) {
            List<String> kv = s.split('=');
            if (kv.size() > 1) {
                // RFC 5849 section 3.4.1.3.1 and 3.4.1.3.2 specify that parameter names
                // and values are decoded then encoded before being sorted and concatenated
                // Section 3.6 specifies that space must be encoded as %20 and not +
                encName  = EncodingUtil.urlEncode(EncodingUtil.urlDecode(kv[0], 'UTF-8'), 'UTF-8').replace('+','%20');
                encValue = EncodingUtil.urlEncode(EncodingUtil.urlDecode(kv[1], 'UTF-8'), 'UTF-8').replace('+','%20');
                res.put(encName,encValue);
            }
        }
        return res;
    }

    public class XeroException extends Exception {}

    /* public static XeroWrappers.XeroCreditNoteAllocationResponse putCreditNoteAllocation(XeroWrappers.XeroCreditNoteAllocation creditNoteAllocation, XeroSettings__c xeroService, CreditNote__c creditNote) {
        XmlStreamWriter xmlW = new XmlStreamWriter();
        xmlW.writeStartDocument('utf-8','1.0');
        xmlW.writeStartElement(null, 'Allocations', null);

        XMLUtility.mapCreditNoteAllocationToXML(creditNoteAllocation, xmlW);

        xmlW.writeEndElement(); //Close
        xmlW.writeEndDocument(); //Close

        String body = xmlW.getXmlString();

        HttpResponse res = XeroAPI.connect(xeroService, 'PUT', 'CreditNotes/' + creditNote.XeroId__c + '/Allocations', body);

        if (res.getStatusCode() == 200) {
            return new XeroWrappers.XeroCreditNoteAllocationResponse(res.getBody());
        } else {
            return new XeroWrappers.XeroCreditNoteAllocationResponse(res.getStatus(), res.getStatusCode(), res.getBody());
        }
    }*/


    /*public static XeroWrappers.XeroInvoiceResponse getAllInvoicesForAccount(xeroSettings__c serviceName, String contactId) {
        Map<String,String> filters = new Map<String,String>{
            'Contact.ContactId' => 'Guid("' + contactId + '")'
        };
        HttpResponse res = XeroAPI.connect(serviceName, 'GET', 'Invoices', filters);

        if (res.getStatusCode() == 200) {
            return new XeroWrappers.XeroInvoiceResponse(res.getBody());
        } else {
            return new XeroWrappers.XeroInvoiceResponse(res.getStatus(), res.getStatusCode());
        }
    }*/

    /*public static XeroWrappers.XeroContactResponse getContactsByName(XeroSettings__c service, String contactName) {
        Map<String,String> filters = new Map<String,String> {'Name.Contains("' + contactName + '")' => '' };
        HttpResponse res = XeroAPI.connect(service, 'GET', 'Contacts', filters);
        if (res.getStatusCode() == 200) {
            return new XeroWrappers.XeroContactResponse(res.getBody());
        } else {
            return new XeroWrappers.XeroContactResponse(res.getStatus(), res.getStatusCode());
        }
    }*/

    /*public static XeroWrappers.XeroBrandingResponse getBrandingTheme(String serviceName, String brandingId) {
        HttpResponse res = XeroAPI.connect(serviceName, 'GET', 'Branding', brandingId, null);
        if (res.getStatusCode() == 200) {
            return new XeroWrappers.XeroBrandingResponse(res.getBody());
        } else {
            return new XeroWrappers.XeroBrandingResponse(res.getStatus(), res.getStatusCode());
        }
    }*/
}