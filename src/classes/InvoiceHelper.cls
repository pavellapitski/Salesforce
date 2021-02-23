/**
 * Created by Pavel Lapitski on 2020-06-02.
 */

public with sharing class InvoiceHelper {
    @TestVisible private static final String LINE_ITEM_DESCRIPTION_CAMPAIGN_ID = 'Campaign ID: ';
    @TestVisible private static final String LINE_ITEM_DESCRIPTION_CAMPAIGN_NAME = 'Campaign Name: ';
    @TestVisible private static final String LINE_ITEM_DESCRIPTION_PO = 'PO: ';
    @TestVisible private static final String LINE_ITEM_DESCRIPTION_IO = 'IO: ';
    @TestVisible private static final String LINE_ITEM_DESCRIPTION_INVOICING_PERIOD = 'Invoicing Period: ';

    @TestVisible private static final AppSettings__c settings = AppSettings__c.getInstance('Default');

    public static final String INVOICE_AMOUNT_MODIFICATION_ERROR_MSG = 'You cannot modify Invoice Amount value for Checked record';

    /*public static String getAuthorizationHeader() {
        Blob header = Blob.valueOf(settings.StrikeDataWarehouseUser__c + ':' + settings.StrikeDataWarehouseToken__c);
        return 'BASIC ' + EncodingUtil.base64Encode(header);
    }*/

    public static String getEndpointUrl(String month, String year) {
        return settings.StrikeInvoiceURL__c + String.format('invoices?month={0}&year={1}', new List<String>{month, year});
    }

    public static String getAccessTokenEndpoint() {
        return settings.StrikeInvoiceURL__c + 'login/access-token';
    }

    public static List<String> getUserNameAndPassword() {
        return new List<String>{settings.StrikeInvoiceUser__c, settings.StrikeInvoicePassword__c};
    }

    public class Invoice {
        String xeroExternalId { get; set; }
        String paymentType { get; set; }
        String strikeId { get; set; }
        String contract { get; set; }
        String po { get; set;}
        String io { get; set;}
        String type { get; set;}
        String billingProfile { get; set; }
        String currencyIsoCode { get; set; }
        Id xeroEntityId { get; set; }
        Date startDate { get; set; }
        Date endDate { get; set; }
        Date dueDate { get; set; }
        Decimal invoiceAmount { get; set; }
    }

    public static Invoice createInstance(Invoice__c invoice) {
        Invoice instance = new Invoice();
        instance.xeroExternalId = invoice.Xero_Id__c;
        instance.xeroEntityId = invoice.Xero_Entity__c;
        instance.billingProfile = invoice.Billing_Profile__c;
        instance.currencyIsoCode = invoice.CurrencyIsoCode;
        instance.po = invoice.PO__c;
        instance.io = invoice.IO__c;            // "IO #" the same as invoice.Contract__c
        instance.type = invoice.Type__c;
        instance.startDate = invoice.Start_Date__c;
        instance.dueDate = invoice.Due_Date__c;
        instance.endDate = invoice.End_Date__c;
        instance.paymentType = invoice.Payment_Type__c;
        instance.contract = invoice.Contract__c;
        instance.invoiceAmount = invoice.Invoice_Amount__c;
        instance.strikeId = invoice.Strike_Id__c;
        return instance;
    }

    public static XeroSync.InvoiceWrapper sendInvoice(Invoice__c invoiceRecord) {
        Invoice invoice = createInstance(invoiceRecord);
        XeroSync.InvoiceWrapper response;
        try {
            XeroSettings__c xeroSettings = XeroSync.getXeroSettingsByIds(new Set<Id>{invoice.xeroEntityId})[0];

            List<XeroWrappers.XeroInvoice> xeroInvoices = new List<XeroWrappers.XeroInvoice>{prepareXeroInvoice(invoice, xeroSettings)};

            XeroWrappers.XeroInvoiceResponse xeroInvoiceResponse = XeroAPI.postInvoices(xeroInvoices, xeroSettings);
            if (xeroInvoiceResponse.statusCode == 200 || xeroInvoiceResponse.statusCode == 201) {
                XeroWrappers.XeroInvoice submittedInvoice = (XeroWrappers.XeroInvoice) xeroInvoiceResponse.xeroObjects[0];
                if (!submittedInvoice.hasErrors) {
                    Invoice__c invoiceRecordToUpdate = new Invoice__c(Id = invoiceRecord.Id);
                    invoiceRecordToUpdate.Xero_Invoice_Id__c = submittedInvoice.invoiceID;
                    invoiceRecordToUpdate.Xero_Invoice_Name__c = submittedInvoice.invoiceNumber;
                    update invoiceRecordToUpdate;
                    response = new XeroSync.InvoiceWrapper(invoiceRecord.Id, XeroSync.STATUS_SUCCESS, 'Invoice successfully created in Xero');
                } else {
                    response = new XeroSync.InvoiceWrapper(invoiceRecord.Id, XeroSync.STATUS_FAILED, String.join(submittedInvoice.validationErrors, ' '));
                }
            } else {
                response = new XeroSync.InvoiceWrapper(invoiceRecord.Id, XeroSync.STATUS_FAILED, 'STATUS CODE: ' + xeroInvoiceResponse.statusCode);
            }
        } catch (Exception ex) {
            response = new XeroSync.InvoiceWrapper(invoiceRecord.Id, XeroSync.STATUS_FAILED, ex.getMessage());
        }
        return response;
    }

    private static XeroWrappers.XeroInvoice prepareXeroInvoice(Invoice invoiceData, XeroSettings__c xeroSettings) {
        Id xeroEntityId = invoiceData.xeroEntityId;
        String xeroItemQuery = ' SELECT ItemCode__c FROM XeroItem__c WHERE XeroSettings__c = :xeroEntityId AND ' +
                ' BillingProfile__c INCLUDES (\'' + invoiceData.billingProfile + '\')';

        List<XeroItem__c> xeroItems = Database.query(xeroItemQuery);

        XeroWrappers.XeroInvoice invoice = new XeroWrappers.XeroInvoice();
        invoice.contact = new XeroWrappers.XeroContact(invoiceData.xeroExternalId);
        invoice.currencyCode = invoiceData.currencyIsoCode;
        invoice.invoiceDate = invoiceData.endDate;
        invoice.dueDate = invoiceData.dueDate;

        List<XeroWrappers.XeroLineItem> lineItems = new List<XeroWrappers.XeroLineItem>();
        String itemCode = !xeroItems.isEmpty() ? xeroItems[0].ItemCode__c : '';
        lineItems.add(createXeroLineItem(invoiceData, xeroSettings, itemCode, invoiceData.invoiceAmount));

        invoice.lineItems = lineItems;
        invoice.type = XeroWrappers.XeroInvoiceType.ACCREC;
        invoice.status = XeroWrappers.XeroInvoiceStatus.SUBMITTED;
        /*if (invoiceData.invoiceLayout == 'Media/Strike Fee' && invoiceData.billingProfile == 'Strike') {
            lineItems.add(createXeroLineItem(invoiceData, xeroSettings, 'Media Cost', invoiceData.mediaSpend));
            lineItems.add(createXeroLineItem(invoiceData, xeroSettings, '111', invoiceData.invoiceAmount - invoiceData.mediaSpend));
        } */

        Datetime endDateTime = Datetime.newInstanceGmt(invoiceData.startDate.year(), invoiceData.startDate.month(), invoiceData.startDate.day());
        invoice.reference = endDateTime.formatGmt('MMM') + ' - ' + invoiceData.contract
                + (String.isNotBlank(invoiceData.strikeId) ? ' - ' + invoiceData.strikeId : '');
        return invoice;
    }

    private static XeroWrappers.XeroLineItem createXeroLineItem(Invoice invoiceData, XeroSettings__c xeroSettings, String itemCode, Decimal amount) {
        XeroWrappers.XeroLineItem lineItem = new XeroWrappers.XeroLineItem();
        lineItem.description = prepareLineItemDescription(invoiceData);
        lineItem.quantity = 1;
        lineItem.accountCode = xeroSettings.AccountCode__c;
        lineItem.lineAmount = amount;
        lineItem.unitAmount = lineItem.lineAmount;
        if (String.isNotBlank(itemCode)) {
            lineItem.itemCode = itemCode;
        }
        return lineItem;
    }

    private static String prepareLineItemDescription(Invoice invoiceData) {
        String retVal = LINE_ITEM_DESCRIPTION_CAMPAIGN_ID + invoiceData.strikeId + '\n'
                + LINE_ITEM_DESCRIPTION_CAMPAIGN_NAME + invoiceData.contract + '\n';

        if (String.isNotBlank(invoiceData.po)) {
            retVal +=  LINE_ITEM_DESCRIPTION_PO + invoiceData.po + '\n';
        }

        retVal += LINE_ITEM_DESCRIPTION_IO + (String.isBlank(invoiceData.io) == false ? String.valueOf(invoiceData.io) : '')+ '\n'
                + LINE_ITEM_DESCRIPTION_INVOICING_PERIOD + invoiceData.startDate.format() + ' - ' + invoiceData.endDate.format();

        return retVal;
    }

    public static String getAllowedCurrency(String currencyToCheck) {
        Set<String> validCurrencies = new Set<String>();
        for (Schema.PicklistEntry plVal :Invoice__c.CurrencyIsoCode.getDescribe().getPicklistValues()){
            validCurrencies.add(plVal.getValue());
        }
        return validCurrencies.contains(currencyToCheck) ? currencyToCheck : 'USD';
    }

    // Data Model Class for response received from Project-Creator API
    public class InvoiceResponse {
        String contract_id { get; set; }                // external Id
        public String strike_id { get; set; }           // i.e. TV012183A
        String contract_name { get; set; }              // i.e. 012183
        String agency_name { get; set; }
        String brand_name { get; set; }
        String client_service_name { get; set; }
        String currency_code { get; set; }
        String xero_contact { get; set; }

        String client_io { get; set; }
        String po { get; set; }
        String region { get; set; }                 // NA; EMEA; APAC
        String billing_profile { get; set; }        // Client/Strike
        String payment_type { get; set; }           // "Net 30" / "Net 45" / "Net 60" / "Net 90" / "Net 120" / "50/50" / "100% Upfront"
        String invoice_type { get; set; }
        public Decimal invoice_amount { get; set; }
        String start_date { get; set; }
        String end_date { get; set; }
        String due_date { get; set; }
    }

    public static Invoice__c setInvoice(InvoiceResponse invoice) {
        return new Invoice__c(
            Billing_Profile__c = invoice.billing_profile,
            Contract__c = invoice.contract_name,
            Invoice_Amount__c = invoice.invoice_amount,
            Start_Date__c = Date.valueOf(invoice.start_date),
            End_Date__c = Date.valueOf(invoice.end_date),
            Due_Date__c = (String.isBlank(invoice.due_date)) ? null : Date.valueOf(invoice.due_date),
            Payment_Type__c = (String.isNotBlank(invoice.payment_type)) ? invoice.payment_type.replace('_',' ') : invoice.payment_type,
            Strike_Id__c = invoice.strike_id,
            Contract_Id__c = invoice.contract_id,
            Type__c = invoice.invoice_type,
            PO__c = invoice.po,
            IO__c = invoice.client_io,
            Region__c = invoice.region,
            Agency_Name__c = invoice.agency_name,
            Brand_Name__c = invoice.brand_name,
            Client_Service_Name__c = invoice.client_service_name,
            CurrencyIsoCode = getAllowedCurrency(invoice.currency_code),
            Xero_Contact_Name__c = invoice.xero_contact
        );
    }

    public class ResponseMockSuccess implements HttpCalloutMock {
        @TestVisible private Integer invoice_amount = 5;

        public HttpResponse respond(HttpRequest req) {
            System.assertEquals('GET', req.getMethod());

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(JSON.serialize(getBodyFor5Records()));
            res.setStatusCode(200);
            return res;
        }

        @TestVisible private List<InvoiceResponse> getBodyFor5Records() {
            List<InvoiceResponse> invoices = new List<InvoiceResponse>();

            Date startDate = Date.newInstance(System.today().year(), System.today().month(), 01),
                    endDate = Date.newInstance(System.today().year(), System.today().addMonths(1).month(), 01).addDays(-1), // last day in current month
                    dueDate = Date.today().addMonths(1).addDays(-3);

            String startDateString = startDate.year() + '-' + startDate.month() + '-' + startDate.day(),
                    endDateString = endDate.year() + '-' + endDate.month() + '-' + endDate.day(),
                    dueDateString = dueDate.year() + '-' + dueDate.month() + '-' + dueDate.day();

            for (Integer i = 1; i <= invoice_amount; i++) {
                InvoiceResponse invoice = new InvoiceResponse();
                invoice.contract_id = 'ExtCId' + i;
                invoice.contract_name = 'ContractName' + i;
                invoice.strike_id = 'TVName' + i;
                invoice.invoice_type = 'Monthly';
                invoice.invoice_amount = (1000 * i / (1 + i * 0.5)).setScale(4);
                invoice.start_date = startDateString;
                invoice.end_date = endDateString;
                invoice.due_date = dueDateString;
                invoice.billing_profile = 'Strike';
                invoice.payment_type = 'Net 30';
                invoice.client_io = 'IO Text' + i;
                invoice.po = 'PO Text' + i;
                invoice.region = 'APAC';
                invoice.agency_name = 'Publicis Group APAC';
                invoice.brand_name = 'P&G';
                invoice.client_service_name = 'Karen Chen';
                invoices.add(invoice);
            }
            return invoices;
        }
    }

}