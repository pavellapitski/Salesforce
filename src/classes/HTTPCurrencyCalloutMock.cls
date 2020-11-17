@isTest
global with sharing class HTTPCurrencyCalloutMock implements HttpCalloutMock
{
		global HTTPResponse respond(HTTPRequest req)
        {
            HttpResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/JSON');
            res.setBody('TestResponse OK');
            res.setStatusCode(201);
            return res;
    	}
}