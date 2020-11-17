public class ContractPreLaunchCSRepNotifyCtrl
{
    public String clientService {get; set;}
    public String instanceUrl {get; set;}
    
    public ContractPreLaunchCSRepNotifyCtrl() 
    {
        instanceUrl = System.URL.getSalesforceBaseUrl().toExternalForm();
    }
    
    public List<Project__c> getPreLaunchContracts()
    {
        return ContractRepository.getClientServiceLaunchingContracts(clientService);
    }
}