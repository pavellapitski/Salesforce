global class PodDashboardCtrl {
    
    public String selectedAccount {get; set;}
    public String selectedBrand {get; set;}
    public String selectedClientServicesRep {get; set;}
    
    @RemoteAction
    global static List<ClientWrapper> getClients(Integer pageSize, Integer offset, String filter) {
        List<ClientWrapper> clients = new List<ClientWrapper>();
        Set<String> brandAccountIds = new Set<String>();
        Map<String, Object> filterMap = new Map<String, Object>();
        
        if (!string.isBlank(filter)){
            filterMap = (Map<String, Object>)JSON.deserializeUntyped(filter);
        }
        
        String query = ' SELECT Count(Id), Max(BrandAccount__c) BrandAccountId FROM Project__c WHERE Name != NULL AND BrandAccount__c != NULL ';
        
        for(String filteredField : filterMap.keySet())
        {
            query += ' AND ' + filterMap.get(filteredField);               
        }
        
        query += ' Group BY BrandAccount__r.Accounts__r.Name ORDER BY BrandAccount__r.Accounts__r.Name LIMIT :pageSize OFFSET :offset '; 
			        
        for (AggregateResult ar : Database.query(query))
        {
            brandAccountIds.add(String.valueOf(ar.get('BrandAccountId')));             
        }  
        
        for (Brand_Account__c brandAccount : getBrandAccountsById(brandAccountIds))
        {
            clients.add(new ClientWrapper(brandAccount));                
        }
        
        return clients;
    }
    
    @RemoteAction
    global static List<Sub_Project__c> readAwaitingPayments(Integer pageSize, Integer offset, String filter)
    {
        Map<String, Object> filterMap = new Map<String, Object>();
        Date paymentEndDate = System.Today().addDays(-5);
        Date paymentsEarliestDate = Date.newInstance(2016, 1, 1);
    
        if (!string.isBlank(filter)) {
            filterMap = (Map<String, Object>)JSON.deserializeUntyped(filter);
        }
    
        String query = ' SELECT Id, Invoice_Amount__c, End_Date__c, Name, Project__c, Project__r.Name, Project__r.Account__c, Project__r.Account__r.Name, ';
        query += ' ProjectID__c, Start_Date__c ';
        query += ' FROM Sub_Project__c ';
        query += ' WHERE End_Date__c <= :paymentEndDate AND  End_Date__c > :paymentsEarliestDate AND Synced_with_Xero__c = false ';
        
        for(String filteredField : filterMap.keySet())
        {
            query += ' AND Project__r.' + filterMap.get(filteredField);               
        }
        
        query += ' ORDER BY Project__r.Name ASC LIMIT :pageSize OFFSET :offset ';
        
        return Database.query(query);
    }
    
    @RemoteAction
    global static List<Project__c> readMyContracts(Integer pageSize, Integer offset, String filter)
    {
        Map<String, Object> filterMap = new Map<String, Object>();
    
        if (!string.isBlank(filter)) {
            filterMap = (Map<String, Object>)JSON.deserializeUntyped(filter);
        }
    
        String query = ' SELECT Id, Client_Spend__c, End_Date__c, isRunning__c, Name, Account__c, Account__r.Name, Project_ID__c, Start_Date__c FROM Project__c ';
        query += ' WHERE End_Date__c >= TODAY ';
        
        for(String filteredField : filterMap.keySet())
        {
            query += ' AND ' + filterMap.get(filteredField);               
        }
        
        query += ' ORDER BY Name LIMIT :pageSize OFFSET :offset ';
        
        return Database.query(query);
    }
    
    @RemoteAction
    global static List<Opportunity> readMyOpportunities(Integer pageSize, Integer offset, String filter)
    {
        Map<String, Object> filterMap = new Map<String, Object>();
        String stageWon = 'Closed Won';
        String stageLost = 'Closed Lost';
    
        if (!string.isBlank(filter)) {
            filterMap = (Map<String, Object>)JSON.deserializeUntyped(filter);
        }
    
        String query = ' SELECT Id, Amount, Name, AccountId, Account.Name, CloseDate, Flight_End__c, Flight_Start__c, StageName ';
        query += ' FROM Opportunity ';
        query += ' WHERE StageName != :stageWon AND StageName != :stageLost ';
        
        for(String filteredField : filterMap.keySet())
        {
            query += ' AND ' + filterMap.get(filteredField);               
        }
        
        query += ' ORDER BY Name LIMIT :pageSize OFFSET :offset ';
        
        return Database.query(query);
    }
    
    @RemoteAction
    global static ClientWrapper readContracts(String clientId) {
        
        Brand_Account__c brandAccount = getDataForBrandAccount(clientId);
        
        ClientWrapper retVal = new ClientWrapper(brandAccount); 
        
        return retVal;
    }
    
    private static Brand_Account__c getDataForBrandAccount(String clientId)
    {
         return [SELECT Accounts__c, Accounts__r.Name, Brand__c, Brand__r.Name,
                       (SELECT Id, CurrencyIsoCode, Name, Start_Date__c, End_Date__c, Client_Spend__c, Project_ID__c
                        FROM Contracts__r 
                        WHERE Start_Date__c <= TODAY AND End_Date__c >= TODAY),
                       (SELECT Id, CurrencyIsoCode, Name, Amount, CloseDate, Flight_Start__c, Flight_End__c 
                        FROM Opportunities__r 
                        WHERE StageName != 'Closed Won' AND StageName != 'Closed Lost')
                FROM Brand_Account__c 
                WHERE Id = :clientId];          
    }
    
    private static List<Brand_Account__c> getBrandAccountsById(Set<String> brandAccountIds)
    {
        return [SELECT Accounts__c, Accounts__r.Name, Brand__c, Brand__r.Name,
                       (SELECT Id
                        FROM Contracts__r 
                        WHERE Start_Date__c <= TODAY AND End_Date__c >= TODAY
                        LIMIT 1),
                       (SELECT Id
                        FROM Opportunities__r 
                        WHERE StageName != 'Closed Won' AND StageName != 'Closed Lost'
                        LIMIT 1)
                FROM Brand_Account__c 
                WHERE Id IN :brandAccountIds
                ORDER BY Accounts__r.Name];           
    }
    
    global class ClientWrapper
    {
        public Brand_Account__c client {get; set;}
        public Boolean isActive {get; set;}
        public List<Project__c> contracts {get; set;}
        public List<Opportunity> opportunities {get; set;}
        
        public ClientWrapper(Brand_Account__c brandAccount)
        {
            contracts = new List<Project__c>();
            opportunities = new List<Opportunity>();
            client = brandAccount;
            isActive = !brandAccount.Contracts__r.isEmpty() || !brandAccount.Opportunities__r.isEmpty();
            
            if (!brandAccount.Contracts__r.isEmpty())
            {
                contracts.addAll(brandAccount.Contracts__r);                   
            }
            
            if (!brandAccount.Opportunities__r.isEmpty())
            {
                opportunities.addAll(brandAccount.Opportunities__r);                      
            }
        }
    }
}