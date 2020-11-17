public class ContractPreLaunchSalesRepNotifyCtrl
{
    public string salesRep {get; set;}
    public String instanceUrl {get; set;}
    
    public ContractPreLaunchSalesRepNotifyCtrl()
    {
        instanceUrl = System.URL.getSalesforceBaseUrl().toExternalForm();
    }
    
    public List<Project__c> getPreLaunchContracts()
    {
        return ContractRepository.getContractsForPreLaunchNotification(ContractRepository.getSalesRepLaunchingContracts(salesRep));
    }
}