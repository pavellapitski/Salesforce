public class OpportunityNotificationSalesRepCtrl
{
    public String salesRep {get; set;}
    public String instanceUrl {get; set;}
    public Integer notificationAdvance {get; set;}
    
    public OpportunityNotificationSalesRepCtrl() 
    {
        instanceUrl = System.URL.getSalesforceBaseUrl().toExternalForm();
    }
    
    public List<Opportunity> getClosingOpportunities()
    {
        return OpportunityRepository.getSalesRepClosingOpportunities(salesRep, System.today().addDays(notificationAdvance));
    }
}