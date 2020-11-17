public class CurrencyHistory {

    @Future (Callout=true)
    public static void updateCurrencyRates(Date dt) {
        Map<String, Object> currencyRates = getCurrencyRates(String.valueOf (dt));
        
        CurrencyHistory__c currencyHistory = new CurrencyHistory__c();
        currencyHistory.Date__c = dt;
        currencyHistory.AUD__c = (Decimal) currencyRates.get('USDAUD');
        currencyHistory.CAD__c = (Decimal) currencyRates.get('USDCAD');
        currencyHistory.EUR__c = (Decimal) currencyRates.get('USDEUR');
        currencyHistory.GBP__c = (Decimal) currencyRates.get('USDGBP');
        currencyHistory.NZD__c = (Decimal) currencyRates.get('USDNZD');
        currencyHistory.PLN__c = (Decimal) currencyRates.get('USDPLN');
        currencyHistory.SGD__c = (Decimal) currencyRates.get('USDSGD');
        currencyHistory.IDR__c = (Decimal) currencyRates.get('USDIDR');
        currencyHistory.MXN__c = (Decimal) currencyRates.get('USDMXN');
        currencyHistory.MYR__c = (Decimal) currencyRates.get('USDMYR');
        currencyHistory.PHP__c = (Decimal) currencyRates.get('USDPHP');
        currencyHistory.HKD__c = (Decimal) currencyRates.get('USDHKD');
        currencyHistory.JPY__c = (Decimal) currencyRates.get('USDJPY');
        currencyHistory.KRW__c = (Decimal) currencyRates.get('USDKRW');
        currencyHistory.INR__c = (Decimal) currencyRates.get('USDINR');
        currencyHistory.THB__c = (Decimal) currencyRates.get('USDTHB');
        currencyHistory.RUB__c = (Decimal) currencyRates.get('USDRUB');
        currencyHistory.AllCurrencies__c = JSON.serializePretty(currencyRates);
        
        insert currencyHistory;        
    }
    
    public static Map<String, Object> getCurrencyRates(String dateParam) {
        AppSettings__c appSettings = AppSettings__c.getInstance('Default');
        
        String urlStart = appSettings.CurrencyAPIEndpoint__c;
        String fromParam = 'from=USD';
        String toParams = 'to=AUD,CAD,EUR,GBP,NZD,PLN,SGD,IDR,MXN,MYR,PHP,INR,HKD,JPY,KRW,THB,RUB';
        String amountParam = 'amount=1.00';
        String dateParamString = 'date=' + dateParam;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(urlStart + fromParam + '&' + toParams + '&' + amountParam + '&' + dateParamString);
        req.setMethod('GET');
        Blob headerValue = Blob.valueOf(appSettings.CurrencyAPIAccountID__c + ':' + appSettings.CurrencyAPIKey__c);        
        req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(headerValue));
        
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) return null;

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        List<Object> resultsArray = (List<Object>) responseMap.get('to');

        Map<String, Object> currencyRatesMap = new Map<String, Decimal>();
        for (Object result :resultsArray) {
            Map<String, Object> resultsMap = (Map <String, Object>) result;
            String quoteCurrency = (String) resultsMap.get('quotecurrency');
            Object mid = resultsMap.get('mid');
            
            if (quoteCurrency != null &&  mid != null) {
                currencyRatesMap.put('USD' + quoteCurrency, mid);
            }
        }
        return currencyRatesMap;
    }
}