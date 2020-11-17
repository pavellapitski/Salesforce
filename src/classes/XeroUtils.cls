public class XeroUtils {
    public Static String LINE_ITEM_DESCRIPTION_CAMPAIGN_ID = 'Campaign ID: ';
    public Static String LINE_ITEM_DESCRIPTION_CAMPAIGN_NAME = 'Campaign Name: ';
    public Static String LINE_ITEM_DESCRIPTION_PO = 'PO: ';
    public Static String LINE_ITEM_DESCRIPTION_IO = 'IO: ';
    public Static String LINE_ITEM_DESCRIPTION_INVOICING_PERIOD = 'Invoicing Period: ';


    public static string prepareLineItemDescription(Sub_Project__c payment) {
        String customName = (payment.Project__r.Custom_Xero_Campaign_Name__c != null) ? payment.Project__r.Custom_Xero_Campaign_Name__c : payment.Project__r.Name;

        String retVal = LINE_ITEM_DESCRIPTION_CAMPAIGN_ID + payment.ProjectId__c + '\n'
                      + LINE_ITEM_DESCRIPTION_CAMPAIGN_NAME + customName + '\n';

        if (String.isNotBlank(payment.Project__r.PO__c)) {
            retVal +=  LINE_ITEM_DESCRIPTION_PO + payment.Project__r.PO__c + '\n';
        }

        retVal += LINE_ITEM_DESCRIPTION_IO + (String.IsBlank(payment.Project__r.Client_IO__c) == false ? String.valueOf(payment.Project__r.Client_IO__c) : '')+ '\n'
               + LINE_ITEM_DESCRIPTION_INVOICING_PERIOD + payment.Start_Date__c.format() + ' to ' + payment.End_Date__c.format();

        return retVal;
    }
}