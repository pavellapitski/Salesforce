public class ContactOpportunityHandler {

    public static final String CLOSED_WON = 'Closed Won';
    @TestVisible private static final String VALIDATING_BENEFITS = 'Validating Benefits';
    @TestVisible private static final String EVALUATION = 'Evaluation';
    @TestVisible private static final String DISCOVERY_CALL = 'Discovery Call';
    @TestVisible private static final String DISCOVERY_MEETING = 'Discovery Meeting';
    @TestVisible private static final String ACTIVE_CLIENT = 'Active Client';

    public static void setUniqueID(List<Contact_Opportunity__c> cos) {
        for (Contact_Opportunity__c co: cos) {
            co.Unique_ID__c = co.Contact__c+'#'+co.Opportunity__c;
        }
    }

    public static void replicateOpportunityStatus(Map<Id,Opportunity> opportunities) {
        // 1) the following below happens to all type of Opps
        Map<Id, Contact_Opportunity__c> contactOpps = new Map<Id, Contact_Opportunity__c>([
            SELECT Id, Opportunity__c, Contact__c, Opportunity__r.AccountId, Opportunity__r.RecordTypeId
            FROM Contact_Opportunity__c
            WHERE Opportunity__c IN :opportunities.keySet()
        ]);

        Map<Id, Contact> contactsByContactOpportunity = new Map<Id,Contact>([
            SELECT Id, Outreach_Stage__c, Status__c, AccountId
            FROM Contact
            WHERE Id IN (SELECT Contact__c FROM Contact_Opportunity__c WHERE Id IN :contactOpps.keySet())
        ]);

        Map<Id, Opportunity> opportunitiesMap = new Map<Id, Opportunity>(opportunities);
        for (Contact_Opportunity__c contactOpp :contactOpps.values()) {
            Contact relatedContact = contactsByContactOpportunity.get(contactOpp.Contact__c);
            if (relatedContact == null) {
                continue;
            }

            // Update Media_Process_Type__c field on Contact record
            String mediaProcess = opportunitiesMap.get(contactOpp.Opportunity__c).Media_Process_Type__c;
            if (mediaProcess != null) {
                relatedContact.Media_Process_Type__c = mediaProcess;
            }

            // Update Outreach_Stage__c field on Contact record
            String oppStage = opportunitiesMap.get(contactOpp.Opportunity__c).StageName;
            if (String.isNotBlank(oppStage)) {
                if (oppStage == DISCOVERY_CALL && relatedContact.Outreach_Stage__c != ACTIVE_CLIENT) {
                    relatedContact.Outreach_Stage__c = DISCOVERY_MEETING;
                } else if (oppStage == EVALUATION && relatedContact.Outreach_Stage__c != ACTIVE_CLIENT) {
                    relatedContact.Outreach_Stage__c = EVALUATION;
                } else if (oppStage == VALIDATING_BENEFITS && relatedContact.Outreach_Stage__c != ACTIVE_CLIENT) {
                    relatedContact.Outreach_Stage__c = VALIDATING_BENEFITS;
                } else if (oppStage == CLOSED_WON) {
                    relatedContact.Outreach_Stage__c = ACTIVE_CLIENT;
                }
            }
        }
        // add changed contacts
        Map<Id,Contact> contactsToUpdateMap = new Map<Id, Contact>(contactsByContactOpportunity);

        // 2) the following below happens to CLOSED_WON type of Opp
        Set<Id> accountIdsByClosedWonOpp = new Set<Id>();
        for (Opportunity opp :opportunities.values()) {
            if (opp.StageName == CLOSED_WON) {
                accountIdsByClosedWonOpp.add(opp.AccountId);
            }
        }
        for (Account accByOpp :[SELECT Id, (SELECT Id, Outreach_Stage__c FROM Contacts) FROM Account WHERE Id IN: accountIdsByClosedWonOpp AND RecordTypeId = :AccountHandler.RT_ID_BRAND_DIRECT]) {
            for (Contact relatedContact :accByOpp.Contacts) {
                // if Account related to Closed Won has more than one Contact, then
                // all Contacts are being updated
                relatedContact.Outreach_Stage__c = ACTIVE_CLIENT;
                contactsToUpdateMap.put(relatedContact.Id, relatedContact);
            }
        }

        // update Contact for 1,2 cases
        update contactsToUpdateMap.values();
    }

    public static void setContactStatus(List<Contact_Opportunity__c> cos) {
        Set<Id> oppIds = getOppIds(cos);
        replicateOpportunityStatus(new Map<Id, Opportunity>([
            SELECT Id, StageName, MeetingStatus__c, Media_Process_Type__c, AccountId
            FROM Opportunity
            WHERE Id IN :oppIds
        ]));
    }

    public static void createOpportunityContactRoles(List<Contact_Opportunity__c> cos) {
        Set<Id> oppIds = getOppIds(cos);
        delete [SELECT Id FROM OpportunityContactRole WHERE OpportunityId IN :oppIds];

        List<OpportunityContactRole> roles = new List<OpportunityContactRole>();
        List<Opportunity> opportunities = [
            SELECT Id, (SELECT Id, OpportunityId, ContactId, Role FROM OpportunityContactRoles),
                (SELECT Id, Unique_ID__c, Role__c, Contact__c, Opportunity__c FROM Contact_Opportunities__r)
            FROM Opportunity
            WHERE Id IN :oppIds
        ];

        for (Opportunity opp :opportunities) {
            for (Contact_Opportunity__c co :opp.Contact_Opportunities__r) {
                roles.add(new OpportunityContactRole(
                    OpportunityId = co.Opportunity__c,
                    ContactId = co.Contact__c,
                    Role = co.Role__c
                ));
            }
        }
        insert roles;
    }

    public static void deleteOpportunityContactRoles(List<Contact_Opportunity__c> cos) {
        Set<Id> oppIds = getOppIds(cos);
        List<OpportunityContactRole> rolesToDelete = new List<OpportunityContactRole>();
        for(OpportunityContactRole role :[SELECT OpportunityId, ContactId FROM OpportunityContactRole WHERE OpportunityId IN :oppIds]) {
            for (Contact_Opportunity__c co: cos){
                if (co.Opportunity__c == role.OpportunityId && co.Contact__c==role.ContactId) {
                    rolesToDelete.add(role);
                }
            }
        }
        delete rolesToDelete;
    }

    private static Set<Id> getOppIds(List<Contact_Opportunity__c> cos) {
        Set<Id> oppIds = new Set<Id>();
        for (Contact_Opportunity__c co :cos) {
            oppIds.add(co.Opportunity__c);
        }
        return oppIds;
    }

}