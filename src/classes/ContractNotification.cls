public with sharing class ContractNotification {

     public static List<NotificationUtil.NotificationResult> sendSalesRepNotifications()
     {
         List<Contact> contacts = new List<Contact>();
         List<Messaging.SingleEmailMessage> messages = getSalesRepNotifications(contacts);
         
         return NotificationUtil.sendNotifications(messages, contacts);
     }

     public static List<NotificationUtil.NotificationResult> sendCSRepNotifications()
     {
         List<Contact> contacts = new List<Contact>();
         List<Messaging.SingleEmailMessage> messages = getClientServiceNotifications(contacts);
         
         return NotificationUtil.sendNotifications(messages, contacts);
     }
     
     public static List<NotificationUtil.NotificationResult> sendCSRepPostLaunchNotifications()
     {
         List<Contact> contacts = new List<Contact>();
         List<Messaging.SingleEmailMessage> messages = getClientServicePostLaunchNotifications(contacts);
         
         return NotificationUtil.sendNotifications(messages, contacts);
     }
     
    public static List<Messaging.SingleEmailMessage> getSalesRepNotifications(List<Contact> contacts) {
        
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        Map<Id, Contact> contactsForProfiles = new Map<Id, Contact>();
        Set<Id> salesRepIds = new Set<Id>();
        
        for (Commission_Profile__c salesRep : [SELECT Id FROM Commission_Profile__c])
        {
            salesRepIds.add(salesRep.Id);
        }
    
        Map<Id, Set<Id>> launchingContracts = ContractRepository.getSalesRepLaunchingContracts(salesRepIds);
        
        if (!launchingContracts.isEmpty()) {
            AppSettings__c appSettings = AppSettings__c.getInstance('Default');
        
            Map<Id, Commission_Profile__c> commissionProfiles = new Map<Id, Commission_Profile__c> ([SELECT Salesforce_User__r.Email 
                                                                                                     FROM Commission_Profile__c 
                                                                                                     WHERE Id IN :launchingContracts.keySet() AND Salesforce_User__r.Email != NULL]);
            
            for (Commission_Profile__c commissionProfile : commissionProfiles.values()) 
            {
                Contact c = NotificationUtil.createContactForNotification(commissionProfile.Salesforce_User__r.Email);
            
                contactsForProfiles.put(commissionProfile.Id, c);
                contacts.add(c);
            }
            
            insert contacts;
            
            for (Id commissionProfileId : launchingContracts.keySet())
            {
                messages.add(NotificationUtil.prepareMessage(contactsForProfiles.get(commissionProfileId).Id, new List<String>(), new List<String>(), appSettings.PreLaunchNotificationBcc__c, 'CampaignLaunchSalesRep', commissionProfileId));
            }
        }    
        
        return messages;
    }  
    
    public static List<Messaging.SingleEmailMessage> getClientServiceNotifications(List<Contact> contacts) 
    {
        Map<Id, User> clientServices = new Map<Id, User>([SELECT Id, Email, PodEmail__c FROM User WHERE Client_Services_Rep__c = true AND Email != NULL]);
     
        Map<Id, List<Project__c>> launchingContracts = ContractRepository.getClientServiceLaunchingContracts(clientServices.keySet());
        
        return NotificationUtil.getClientServiceNotifications(clientServices, launchingContracts.keySet(), new List<String>(), contacts, 'CampaignLaunchCSRep', true);
    }  
    
    public static List<Messaging.SingleEmailMessage> getClientServicePostLaunchNotifications(List<Contact> contacts) 
    {
        Map<Id, User> clientServices = new Map<Id, User>([SELECT Id, Email, PodEmail__c FROM User WHERE Client_Services_Rep__c = true AND Email != NULL]);
     
        Map<Id, List<Project__c>> launchedContracts = ContractRepository.getClientServiceLaunchedContracts(clientServices.keySet());
        
        return NotificationUtil.getClientServiceNotifications(clientServices, launchedContracts.keySet(), new List<String>(), contacts, 'CampaignPostLaunchCSRep', true);
    }  
}