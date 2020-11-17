public with sharing class CampaignReportsController {
    public static String campaignId { get; set; }

    public CampaignReportsController(){
        campaignId = ApexPages.currentPage().getParameters().get('cId');
    }
    
    public List<CampaignMember> getCampaignMembers() {
        List<CampaignMember> campaigns = [SELECT Id, Contact.FirstName, Contact.LastName, Contact.Email, Contact.Account.Name, Contact.Mailingcity, Contact.Mailingstate, Contact.Mailingpostalcode, Status FROM CampaignMember WHERE CampaignId = :campaignId];
        return campaigns;
    }
}