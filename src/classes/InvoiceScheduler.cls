/**
 * Created by pavel on 2020-10-26.
 */

public with sharing class InvoiceScheduler implements Schedulable {

    public static final String JOB_NAME = 'Strike Invoice Job';
    /*
    * // every hour at 45 minutes
    System.schedule('Strike Invoice Job', '0 45 * * * ?', new InvoiceScheduler());

    * String CRON_EXP = '0 ' + Datetime.now().addMinutes(1).minute() + ' ' +
        Datetime.now().hour() + ' ' +
        System.today().day() + ' ' +
        System.today().month() + ' ? ' + System.today().year();
    * */

    public void execute(SchedulableContext sc) {
        calloutInvoices();
    }

    private static HttpRequest getAccessTokenRequest() {
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('content-type', 'application/x-www-form-urlencoded');
        req.setEndpoint(InvoiceHelper.getAccessTokenEndpoint());
        req.setBody(String.format('grant_type=&username={0}&password={1}&scope=&client_id=&client_secret=', InvoiceHelper.getUserNameAndPassword()));
        return req;
    }

    @Future(Callout=true)
    public static void calloutInvoices() {
        List<EventLog__c> logs = new List<EventLog__c>();

        String accessToken = '';
        if (Test.isRunningTest()) {
            accessToken = 'TOKEN_TEST';
        } else {
            HttpRequest accessTokenRequest = getAccessTokenRequest();
            try {
                HttpResponse res = new Http().send(accessTokenRequest);
                if (res.getStatusCode() == 200) {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    accessToken = String.valueOf(responseMap.get('access_token'));
                } else {
                    logs.add(EventLog.createEventLog(
                        'CALLOUT ERROR. STATUS: ' + res.getStatus() + '\nSTATUS CODE: ' + res.getStatusCode() + '\nRESPONSE BODY: ' + res.getBody(),
                        EventLog.STATUS_ERROR,
                        EventLog.STRIKE_DATA_CALLOUT
                    ));
                }
            } catch (Exception ex) {
                logs.add(EventLog.createEventLog(
                    (ex.getTypeName()).toUpperCase() + ' EXCEPTION. MESSAGE: ' + ex.getMessage() + '\nLINE: ' + ex.getStackTraceString(),
                    EventLog.STATUS_ERROR,
                    EventLog.STRIKE_DATA_CALLOUT
                ));
            }
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(InvoiceHelper.getEndpointUrl());
        req.setTimeout(60000);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + accessToken/*InvoiceHelper.getAuthorizationHeader()*/);

        try {
            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() == 200) {
                List<InvoiceHelper.InvoiceData> response = (List<InvoiceHelper.InvoiceData>) JSON.deserializeStrict(res.getBody(), List<InvoiceHelper.InvoiceData>.class);
                Map<String, Invoice__c> strikeIDsToInvoice = new Map<String, Invoice__c>();

                List<Invoice__c> invoicesToUpsert = new List<Invoice__c>();
                for (InvoiceHelper.InvoiceData invoice :response) {
                    strikeIDsToInvoice.put(invoice.strike_id, InvoiceHelper.setInvoice(invoice));
                }

                System.debug('### StrikeIDs: ' + strikeIDsToInvoice.keySet());
                Map<String,Invoice__c> existingInvoices = getExistingInvoice(InvoiceHelper.getDate(), new List<String>(strikeIDsToInvoice.keySet()));
                System.debug('### existingInvoices: ' + existingInvoices);
                for (String strikeId :strikeIDsToInvoice.keySet()) {
                    Invoice__c externalInvoice = strikeIDsToInvoice.get(strikeId);
                    Invoice__c existingInvoice = existingInvoices.get(strikeId);
                    if (existingInvoice == null) {
                        System.debug('### existingInvoice is NULL: ' + externalInvoice);
                        // new invoice record should be inserted
                        invoicesToUpsert.add(externalInvoice);
                    } else {
                        Boolean doUpsert = isChanged(existingInvoice, externalInvoice);
                        System.debug('### doUpsert: ' + doUpsert);
                        if (doUpsert) {
                            externalInvoice.Id = existingInvoice.Id;
                            System.debug('### externalInvoice: ' + externalInvoice);
                            invoicesToUpsert.add(externalInvoice);
                        }
                    }
                }
                upsert invoicesToUpsert;
            } else {
                logs.add(EventLog.createEventLog(
                    'CALLOUT ERROR. STATUS: ' + res.getStatus() + '\nSTATUS CODE: ' + res.getStatusCode() + '\nRESPONSE BODY: ' + res.getBody(),
                    EventLog.STATUS_ERROR,
                    EventLog.STRIKE_DATA_CALLOUT
                ));
            }
        } catch (Exception ex) {
            logs.add(EventLog.createEventLog(
                (ex.getTypeName()).toUpperCase() + ' EXCEPTION. MESSAGE: ' + ex.getMessage() + '\nLINE: ' + ex.getStackTraceString(),
                EventLog.STATUS_ERROR,
                EventLog.STRIKE_DATA_CALLOUT
            ));
        }
        insert logs;
    }

    private static Map<String, Invoice__c> getExistingInvoice(List<String> monthYearList, List<String> strikeIDs) {
        Date invoiceDate = Date.newInstance(Integer.valueOf(monthYearList[1]), Integer.valueOf(monthYearList[0]), 01);
        Map<String, Invoice__c> strikeIdToInvoice = new Map<String, Invoice__c>();
        List<Invoice__c> existingInvoices = [
            SELECT Id, Start_Date__c, End_Date__c, Invoice_Amount__c, Due_Date__c, Strike_Id__c
            FROM Invoice__c
            WHERE Start_Date__c >= :invoiceDate AND End_Date__c < :invoiceDate.addMonths(1) AND Strike_Id__c IN :strikeIDs
        ];
        for (Invoice__c existingInvoice :existingInvoices) {
            strikeIdToInvoice.put(existingInvoice.Strike_Id__c, existingInvoice);
        }
        return strikeIdToInvoice;
    }

    private static Boolean isChanged(Invoice__c existingInvoice, Invoice__c updatedInvoice) {
        return existingInvoice.Start_Date__c != updatedInvoice.Start_Date__c ||
            existingInvoice.End_Date__c != updatedInvoice.End_Date__c ||
            existingInvoice.Invoice_Amount__c != updatedInvoice.Invoice_Amount__c ||
            existingInvoice.Due_Date__c != updatedInvoice.Due_Date__c;
    }
}