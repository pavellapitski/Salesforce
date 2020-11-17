/**
 * Created by Pavel Lapitski on 2020-06-01.
 */

public with sharing class InvoicingCtrl {

    @AuraEnabled
    public static Invoice__c fetchInvoice(String recordId) {
        return getInvoice(recordId);
    }

    @AuraEnabled
    public static XeroSync.InvoiceWrapper doInvoicing(String recordId) {
        return InvoiceHelper.sendInvoice(getInvoice(recordId));
    }

    private static Invoice__c getInvoice(String recordId) {
        return [SELECT Id , Xero_Id__c, CurrencyIsoCode, PO__c, IO__c, Type__c, Xero_Invoice_Id__c, Billing_Profile__c, Invoice_Amount__c,
                Start_Date__c, Due_Date__c, Payment_Type__c, Project__c, Contract__c, Xero_Entity__c, Xero_Invoice_Name__c
                FROM Invoice__c WHERE Id = :recordId
        ];
    }
}