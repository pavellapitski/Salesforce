public class SubProjectMediaSpendExceededNotifyCtrl
{
    public String clientService {get; set;}
    public String instanceUrl {get; set;}
    
    public SubProjectMediaSpendExceededNotifyCtrl() 
    {
        instanceUrl = System.URL.getSalesforceBaseUrl().toExternalForm();
    }
    
    public List<Sub_Project__c> getMediaSpendExceededExtechPayments()
    {
        return new List<Sub_Project__c>();
    }
}