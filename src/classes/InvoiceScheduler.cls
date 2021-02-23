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

    private Integer year  { get; set; }
    private Integer month { get; set; }

    public InvoiceScheduler(Integer month, Integer year) {
        this.month = month;
        this.year = year;
    }

    public InvoiceScheduler() {
        this.month = System.today().month();
        this.year = System.today().year();
    }

    public void execute(SchedulableContext sc) {
        calloutInvoices(month, year);
    }

    private static List<EventLog__c> logs { get {
        if (logs == null) {
            logs = new List<EventLog__c>();
        }
        return  logs;
    } set; }

    @Future(Callout=true)
    public static void calloutInvoices(Integer month, Integer year) {
        logs.clear();

        String accessToken = getAccessTokenOrWriteErrorLogs();
        getInvoicesWithInsertionOrWriteErrorLogs(accessToken, new List<Integer>{month, year});

        insert logs;
    }

    private static String getAccessTokenOrWriteErrorLogs() {
        String accessToken = '';
        if (Test.isRunningTest()) {
            accessToken = 'TOKEN_TEST';
        } else {
            HttpRequest accessTokenRequest = prepareRequestToPostAccessToken();
            try {
                HttpResponse res = new Http().send(accessTokenRequest);
                if (res.getStatusCode() == 200) {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    accessToken = String.valueOf(responseMap.get('access_token'));
                } else {
                    writeErrorLog('CALLOUT ERROR. STATUS: ' + res.getStatus() + '\nSTATUS CODE: ' + res.getStatusCode() + '\nRESPONSE BODY: ' + res.getBody());
                }
            } catch (Exception ex) {
                writeErrorLog((ex.getTypeName()).toUpperCase() + ' EXCEPTION. MESSAGE: ' + ex.getMessage() + '\nLINE: ' + ex.getStackTraceString());
            }
        }
        return accessToken;
    }

    private static HttpRequest prepareRequestToPostAccessToken() {
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('content-type', 'application/x-www-form-urlencoded');
        req.setEndpoint(InvoiceHelper.getAccessTokenEndpoint());
        req.setBody(String.format('grant_type=&username={0}&password={1}&scope=&client_id=&client_secret=', InvoiceHelper.getUserNameAndPassword()));
        return req;
    }

    private static void getInvoicesWithInsertionOrWriteErrorLogs(String accessToken, List<Integer> monthYear) {
        // Bearer Authentication
        HttpRequest req = prepareRequestToGetInvoices(accessToken, monthYear);

        try {
            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() == 200) {
                List<InvoiceHelper.InvoiceResponse> response = (List<InvoiceHelper.InvoiceResponse>)
                            JSON.deserializeStrict(res.getBody(), List<InvoiceHelper.InvoiceResponse>.class);

                Map<String, Invoice__c> strikeIDsToInvoice = new Map<String, Invoice__c>();
                for (InvoiceHelper.InvoiceResponse invoice :response) {
                    strikeIDsToInvoice.put(invoice.strike_id, InvoiceHelper.setInvoice(invoice));
                }

                Map<String, Invoice__c> existingInvoices = getExistingInvoicesByMonthYearID(monthYear, strikeIDsToInvoice.keySet());
                List<Invoice__c> invoicesToUpsert = new List<Invoice__c>();
                for (String strikeId :strikeIDsToInvoice.keySet()) {
                    Invoice__c invoiceFromResponse = strikeIDsToInvoice.get(strikeId);
                    Invoice__c existingInvoice = existingInvoices.get(strikeId);
                    System.debug('### invoiceFromResponse: ' + invoiceFromResponse);
                    System.debug('### existingInvoice: ' + existingInvoice);
                    if (existingInvoice == null) {
                        invoicesToUpsert.add(invoiceFromResponse);
                    } else {
                        Boolean doUpsert = isInvoiceDifferent(existingInvoice, invoiceFromResponse);
                        Boolean ignoreInvoiceAmountDifference = existingInvoice.Checked__c;
                        System.debug('### doUpsert: ' + doUpsert);
                        if (doUpsert) {
                            invoiceFromResponse.Id = existingInvoice.Id;
                            if (ignoreInvoiceAmountDifference) {
                                invoiceFromResponse.Invoice_Amount__c = existingInvoice.Invoice_Amount__c;
                            }
                            invoicesToUpsert.add(invoiceFromResponse);
                        }
                    }
                }
                upsert invoicesToUpsert;
            } else {
                writeErrorLog('CALLOUT ERROR. STATUS: ' + res.getStatus() + '\nSTATUS CODE: ' + res.getStatusCode() + '\nRESPONSE BODY: ' + res.getBody());
            }
        } catch (Exception ex) {
            writeErrorLog((ex.getTypeName()).toUpperCase() + ' EXCEPTION. MESSAGE: ' + ex.getMessage() + '\nLINE: ' + ex.getStackTraceString());
        }
    }

    private static HttpRequest prepareRequestToGetInvoices(String accessToken, List<Integer> monthYear) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(InvoiceHelper.getEndpointUrl(String.valueOf(monthYear[0]), String.valueOf(monthYear[1])));
        req.setTimeout(60000);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        return req;
    }

    private static void writeErrorLog(String msg) {
        logs.add(EventLog.createEventLog(msg, EventLog.STATUS_ERROR, EventLog.STRIKE_DATA_CALLOUT));
    }

    private static Map<String, Invoice__c> getExistingInvoicesByMonthYearID(List<Integer> monthYear, Set<String> strikeIDs) {
        Date invoiceDate = Date.newInstance(monthYear[1], monthYear[0], 01);
        Map<String, Invoice__c> strikeIdToInvoice = new Map<String, Invoice__c>();
        List<Invoice__c> existingInvoices = [
            SELECT Id, Start_Date__c, End_Date__c, Invoice_Amount__c, Due_Date__c, Strike_Id__c, Checked__c, Contract__c, IO__c, PO__c, Payment_Type__c, CurrencyIsoCode,
                    Agency_Name__c, Billing_Profile__c, Region__c, Brand_Name__c, Client_Service_Name__c, Xero_Contact_Name__c
            FROM Invoice__c
            WHERE Start_Date__c >= :invoiceDate AND End_Date__c < :invoiceDate.addMonths(1) AND Strike_Id__c IN :strikeIDs
        ];
        for (Invoice__c existingInvoice :existingInvoices) {
            strikeIdToInvoice.put(existingInvoice.Strike_Id__c, existingInvoice);
        }
        return strikeIdToInvoice;
    }

    private static Boolean isInvoiceDifferent(Invoice__c existingInvoice, Invoice__c invoiceFromResponse) {

        return existingInvoice.Start_Date__c != invoiceFromResponse.Start_Date__c ||
            existingInvoice.End_Date__c != invoiceFromResponse.End_Date__c ||
            existingInvoice.Due_Date__c != invoiceFromResponse.Due_Date__c ||
            existingInvoice.Contract__c != invoiceFromResponse.Contract__c ||
            existingInvoice.IO__c != invoiceFromResponse.IO__c ||
            existingInvoice.PO__c != invoiceFromResponse.PO__c ||
            existingInvoice.Payment_Type__c != invoiceFromResponse.Payment_Type__c ||
            existingInvoice.CurrencyIsoCode != invoiceFromResponse.CurrencyIsoCode ||
            existingInvoice.Agency_Name__c != invoiceFromResponse.Agency_Name__c ||
            existingInvoice.Billing_Profile__c != invoiceFromResponse.Billing_Profile__c ||
            existingInvoice.Region__c != invoiceFromResponse.Region__c ||
            existingInvoice.Brand_Name__c != invoiceFromResponse.Brand_Name__c ||
            existingInvoice.Client_Service_Name__c != invoiceFromResponse.Client_Service_Name__c ||
            existingInvoice.Xero_Contact_Name__c != invoiceFromResponse.Xero_Contact_Name__c ||
            existingInvoice.Invoice_Amount__c != invoiceFromResponse.Invoice_Amount__c;
    }
}