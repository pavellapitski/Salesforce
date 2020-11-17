public class NewContactOpportunityController {
    
    public Id opportunityId { get; set; }
    public List<Contact_Opportunity__c> contactRoles { get; set; }
    public Integer contactRoleRow { get; set; }

    public NewContactOpportunityController(ApexPages.StandardSetController stdController) {
        opportunityId = ApexPages.currentPage().getParameters().get('id');
        contactRoles = new List<Contact_Opportunity__c>{
                new Contact_Opportunity__c(Opportunity__c = opportunityId)
        };
    }

    public PageReference save() {
        if (!contactRoles.isEmpty()) {
            database.upsert(contactRoles,false);
        }
        return new PageReference('/' + opportunityId);
    }

    public void addNewContactRole() {
        contactRoles.add(new Contact_Opportunity__c(Opportunity__c = opportunityId));
    }

    public void deleteContactRole() {
        Boolean success = true;
        Contact_Opportunity__c recordToDelete = contactRoles[contactRoleRow];

        if (!string.isBlank(recordToDelete.Id)) {
            try {
                delete recordToDelete;
            } catch (DmlException ex) {
                success = false;
                ApexPages.addMessage(new ApexPages.Message(Apexpages.Severity.ERROR, ex.getDMLMessage(0)));
            }
        }

        if (success) {
            contactRoles.remove(contactRoleRow);
        }
    }

}