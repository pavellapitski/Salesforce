public class ContractPostLaunchCSRepNotifyCtrl
{
    public String clientService {get; set;}
    public String instanceUrl {get; set;}
    
    public ContractPostLaunchCSRepNotifyCtrl() 
    {
        instanceUrl = System.URL.getSalesforceBaseUrl().toExternalForm();
    }
    
    public List<Project__c> getLaunchedContracts()
    {
        return ContractRepository.getClientServiceLaunchedContracts(clientService);
    }
}