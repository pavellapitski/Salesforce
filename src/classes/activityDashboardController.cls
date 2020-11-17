public with sharing class activityDashboardController {
    
    public string[] getCalls()
    {
        string[] myList = new string[]{};
       
        Date today = (date.today());
        for (Task a : [SELECT Id,Subject,WhatId,WhoId,ActivityDate,OwnerId,AccountId  FROM Task WHERE ActivityDate = :today and Subject Like '%call%'] )
                 {
                    myList.add(JSON.serializePretty(a)); 
                 }
      return myList; 
    }
    
    public string[] getEmails()
    {
        string[] myList = new string[]{};
       
        Date today = (date.today());
        for (Task a : [SELECT Id,Subject,WhatId,WhoId,ActivityDate,OwnerId,AccountId  FROM Task WHERE ActivityDate = :today and Subject Like '%email%'] )
                 {
                    myList.add(JSON.serializePretty(a)); 
                 }
      return myList; 
    }
    
    public string[] getMeetings()
    {
        string[] myList = new string[]{};
       
        Date today = (date.today());
        for (Task a : [SELECT Id,Subject,WhatId,WhoId,ActivityDate,OwnerId,AccountId  FROM Task WHERE ActivityDate = :today and Subject Like '%meeting%'] )
                 {
                    myList.add(JSON.serializePretty(a)); 
                 }
      return myList; 
    }
    
    public string[] getopportunities()
    {
        string[] myList = new string[]{};
       
        Date today = (date.today());
        for (Opportunity a : [SELECT AccountId,CloseDate,Id,Name FROM Opportunity WHERE CloseDate = :today] )
                 {
                    myList.add(JSON.serializePretty(a)); 
                 }
      return myList; 
    }
}