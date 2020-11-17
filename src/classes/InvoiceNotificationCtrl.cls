public class InvoiceNotificationCtrl {
    
    public String clientService {get; set;}
    public String instanceUrl {get; set;}
    
    public InvoiceNotificationCtrl() 
    {
        instanceUrl = System.URL.getSalesforceBaseUrl().toExternalForm();
    }
    
    public List<Sub_Project__c> getPayments()
    {
        List<Sub_Project__c> payments = new List<Sub_Project__c>();
        
        Map<Id, List<Sub_Project__c>> paymentsMap = SubProjectRepository.getPaymentsForNotification(new Set<Id> {clientService});
        
        if (paymentsMap.containsKey(clientService))
        {
            payments = paymentsMap.get(clientService);
        }
        
        return payments;
    }
}