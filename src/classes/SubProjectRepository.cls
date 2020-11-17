public class SubProjectRepository {

    public static final String API_NAME = Schema.Sub_Project__c.SObjectType.getDescribe().getName();

    public static List<Sub_Project__c> getPaymentsByContractId(Id contractId) {
        return [
            SELECT Id, Project__c, End_Date__c, Start_Date__c, Client_Spend__c
            FROM Sub_Project__c
            WHERE Project__c = :contractId
        ];
    }

    public static List<Sub_Project__c> getInvoiceForXeroSubmission(String invoiceId) {
        return [
            SELECT Id, Name, Account__c, Account__r.Name, Account__r.Xero_Id__c, Account_Type__c, Account__r.Xero_Entity__c,
                AdWordsSpend__c, CurrencyIsoCode, Final_Margin__c, Invoice__c, Project__r.Margin__c, Margin_Type__c, Media_Order__c,
                Project__c, Project__r.AddXeroTax__c, Project__r.Name, Project__r.Xero_Id__c, Xero_Id__c, RecordType.DeveloperName,
                End_Date__c, Project__r.Account_Type__c, ProjectId__c, Project__r.Client_IO__c, Project__r.Start_Date__c,
                Project__r.End_Date__c, Project__r.PO__c, Start_Date__c, Invoice_Amount__c, PaymentType__c, Project__r.Xero_Entity__c,
                Project__r.Account__r.InvoiceLayout__c, Project__r.Custom_Xero_Campaign_Name__c
            FROM Sub_Project__c
            WHERE Id = :invoiceId
        ];
    }

    public static List<Sub_Project__c> getUnpaidPaymentsByXeroIds(Set<String> xeroIds) {
        return [SELECT Id, Xero_Id__c, XeroStatus__c FROM Sub_Project__c WHERE Xero_Id__c IN :xeroIds AND Paid__c = FALSE];
    }

    public static List<Sub_Project__c> getPaymentsWithProjects(List<Sub_Project__c> payments) {
        Set<Id> paymentIds = (new Map<Id,Sub_Project__c>(payments)).keySet();
        return getPaymentsByIDsWithProjects(paymentIds);
    }

    public static List<Sub_Project__c> getPaymentsByIDsWithProjects(Set<Id> Ids) {
        return [
            SELECT Id, Client_Spend__c, End_Date__c, Start_Date__c, Project__r.Gaps_Exist_Between_Projects__c,
                (SELECT Id, Client_Spend__c, Start_Date__c, End_Date__c, CostStructure__c, StrikeId__c, OpportunityPlatform__r.Platform__r.Name FROM Projects__r)
            FROM Sub_Project__c
            WHERE Id IN :Ids
        ];
    }

    public static Map<Id, List<Sub_Project__c>> getPaymentsForNotification(Set<Id> clientServiceIds) {
        Map<Id, List<Sub_Project__c>> paymentsForCSRep = new Map<Id, List<Sub_Project__c>>();
        List<Sub_Project__c> payments = [
            SELECT Id, Name, Project__c, Project__r.Name, Project__r.ClientServicesRep__c, Project__r.ClientServicesRep__r.Name
            FROM Sub_Project__c
            WHERE MediaSpendAssigned__c = true
                AND InvoiceNotificationSent__c = false
                AND InvoicingLocked__c = false AND Xero_Id__c = NULL
                AND Project__r.ClientServicesRep__c IN :clientServiceIds
            ORDER BY Project__r.Name
        ];

        for (Sub_Project__c payment :payments) {
            String key = payment.Project__r.ClientServicesRep__c;
            if (!paymentsForCSRep.containsKey(key)) {
                paymentsForCSRep.put(payment.Project__r.ClientServicesRep__c, new List<Sub_Project__c>());
            }
            paymentsForCSRep.get(payment.Project__r.ClientServicesRep__c).add(payment);
        }

        return paymentsForCSRep;
    }

    public static List<Sub_Project__c> getPaymentsSubmittedToXero() {
        return [
            SELECT Id, Name, Invoice__c, Xero_ID__c, Xero_Invoice__c, Project__r.Name
            FROM Sub_Project__c
            WHERE XeroStatus__c = :SubProject.XERO_STATUS_SUBMITTED
            ORDER BY Name
        ];
    }

    public static List<Sub_Project__c> getSubProjectsByIDs(Set<Id> subProjectIDs) {
        return [
            SELECT Name, Start_Date__c, End_Date__c, Client_Spend__c, AdWordsSpend__c, Delivered__c, Margin__c, Invoice_Amount__c, ActualGrossProfitCopy__c,
                    Actual_Gross_Profit_Social_Rollup__c, Actual_Gross_Profit_YT_Rollup__c, Gross_Profit_Report__c
            FROM Sub_Project__c
            WHERE Id IN :subProjectIDs
        ];
    }

}