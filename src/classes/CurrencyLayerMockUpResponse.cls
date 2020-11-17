global class CurrencyLayerMockUpResponse implements HttpCalloutMock {
    
    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');
        
        res.setBody(getCurrencyHistoryResponse());
        
        return res;
    }
    
    global String getCurrencyHistoryResponse() {
        String response = '{"terms":"http://www.xe.com/legal/dfs.php","privacy":"http://www.xe.com/privacy.php","from":"USD","amount":1.0,"timestamp":"2018-04-24T21:00:00Z","to":[{"quotecurrency":"HKD","mid":7.8459604339},{"quotecurrency":"MXN","mid":18.8184674959},{"quotecurrency":"MYR","mid":18.8184674959},{"quotecurrency":"EUR","mid":0.8174503494},{"quotecurrency":"CAD","mid":1.2832512116},{"quotecurrency":"INR","mid":66.440464824},{"quotecurrency":"THB","mid":31.453253609},{"quotecurrency":"AUD","mid":1.3152269136},{"quotecurrency":"SGD","mid":1.3222761799},{"quotecurrency":"KRW","mid":1076.702317357},{"quotecurrency":"JPY","mid":108.8141492423},{"quotecurrency":"PLN","mid":3.4391679757},{"quotecurrency":"GBP","mid":0.7153956902},{"quotecurrency":"IDR","mid":13887.2206443854},{"quotecurrency":"NZD","mid":1.4047712809},{"quotecurrency":"PHP","mid":52.2242579572},{"quotecurrency":"RUB","mid":61.5376362659}]}';        
        return response;
    }    
}