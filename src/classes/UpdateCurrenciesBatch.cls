global class UpdateCurrenciesBatch implements Database.Batchable <SObject>, Database.AllowsCallouts {

    global UpdateCurrenciesBatch() {}
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT id, ISOCode, DecimalPlaces, ConversionRate FROM CurrencyType ORDER BY ISOCode ASC');
    } 
    
    global void execute(Database.BatchableContext bc, List<CurrencyType> scope) {
        AppSettings__c appSettings = AppSettings__c.getInstance('Default');

        PartnerSoapSforceCom.Soap partner = new PartnerSoapSforceCom.Soap();
        PartnerSoapSforceCom.LoginResult lr = partner.login(appSettings.CurrencyUserLogin__c, appSettings.CurrencyUserPassword__c);
        String sessionID = lr.sessionId;

        CurrencyHistory__c currencyHistoryRecord = [
            SELECT Id, AUD__c, CAD__c, EUR__c, GBP__c, IDR__c, INR__c, MXN__c, MYR__c, NZD__c, PHP__c, PLN__c, SGD__c, HKD__c, JPY__c,
                    KRW__c, THB__c, RUB__c, AllCurrencies__c, Date__c
            FROM CurrencyHistory__c
            ORDER BY Date__c DESC, CreatedDate DESC
            LIMIT 1
        ];

        for (CurrencyType cType :scope) {
            if (cType.IsoCode.equals ('USD')) return;

            Double currentConversionRate = (Double) currencyHistoryRecord.get(cType.IsoCode + '__c');
            HttpRequest req = new HttpRequest();
            req.setEndpoint(Url.getSalesforceBaseUrl().toExternalForm() + '/services/data/v28.0/sobjects/CurrencyType/');
            req.setMethod('POST');
            req.setBody('{ "IsoCode" : "'+cType.IsoCode+'", "DecimalPlaces" : '+cType.DecimalPlaces+', "ConversionRate" : '+currentConversionRate+', "IsActive" : "true" }');
            req.setHeader('Authorization', 'OAuth ' + sessionID);
            req.setHeader('Content-Type', 'application/json');
            new Http().send(req);
        }
    }
    
    global void finish(Database.BatchableContext bc) {}
}