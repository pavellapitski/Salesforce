public class OpportunityNotificationCSRepCtrl
{
    public String clientService {get; set;}
    public String instanceUrl {get; set;}
    public Integer notificationAdvance {get; set;}
    
    public OpportunityNotificationCSRepCtrl() 
    {
        instanceUrl = System.URL.getSalesforceBaseUrl().toExternalForm();
    }
    
    public List<Opportunity> getClosingOpportunities()
    {
        return OpportunityRepository.getClientServiceClosingOpportunities(clientService, System.today().addDays(notificationAdvance));
    }
}