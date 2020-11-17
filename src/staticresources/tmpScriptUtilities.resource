!!!
delete [select Id from Daily_Distribution__c Limit 9999];

StrikeTech_Campaign__c[]  myList = new StrikeTech_Campaign__c[]{};
for (StrikeTech_Campaign__c a : [select id,Total_Revenue__c,tmpRev__c from StrikeTech_Campaign__c])
     {
         a.tmpRev__c = a.Total_Revenue__c;
         myList.add(a);
     }
update myList;
     
system.debug('Start');
Daily_Distribution__c[] myList = new Daily_Distribution__c[]{};
    integer co = 1;
system.debug(co);
for (StrikeTech_Campaign__c a : [select id,Start_Date__c,Date_of_Completion__c,Total_Campaign_Spend__c,Total_Revenue__c,Media_Costs_our_Acct__c,Buying_on_Client_Acct__c from StrikeTech_Campaign__c where tmpRollUp__c =0 ])
{
    if (a.Start_Date__c!=null&&a.Date_of_Completion__c!=null)
    {
        system.debug('query runs');
        system.debug(co);
        co++;
        integer numberDaysDue =  a.Start_Date__c.daysBetween(a.Date_of_Completion__c)+1;
        //system.debug(numberDaysDue);
        date dayOfDistribution = a.Start_Date__c;
        if (numberDaysDue >0 && numberDaysDue <365)
        {
            Integer it = 0;    
            while (it <  numberDaysDue)
            {
               
                Daily_Distribution__c base = new Daily_Distribution__c();
            	base.StrikeTech_Campaign__c = a.id;
            	if (a.Total_Campaign_Spend__c!=null)
            		{base.Daily_Campaign_Spend__c = a.Total_Campaign_Spend__c / numberDaysDue;}
            	if (a.Buying_on_Client_Acct__c!=null)
            		{base.Media_Costs_client_Acct__c  = a.Buying_on_Client_Acct__c / numberDaysDue;}
            	if (a.Media_Costs_our_Acct__c!=null)
            		{base.Media_Costs_our_Acct__c = a.Media_Costs_our_Acct__c / numberDaysDue;}        
                
                base.Daily_Revenue__c = a.Total_Revenue__c / numberDaysDue;
                base.Day__c = dayOfDistribution;
                dayOfDistribution = dayOfDistribution.addDays(1);
                myList.add(base);
                it++;
            }
            if (myList.size() >9000)
                {
                  insert myList;
                  myList.clear();
                  break;  
                }
        }
    }
}
system.debug(myList.size());
insert myList;



/* Sales_Rep__c[] myList = new Sales_Rep__c[]{};
 Map<Integer, String> m1 = new Map<Integer, String>();
m1.put(1,'005U0000003mGJM');
m1.put(2,'005U0000003mGJN');
m1.put(3,'005U0000003mGJS');
m1.put(4,'005U0000002Z0Mc');
m1.put(5,'005U0000003nV8Z');
m1.put(6,'005U0000002Z1gY');
m1.put(7,'005U0000002Z1fQ');
m1.put(8,'005U0000002Z1gd');
m1.put(9,'005U0000003nV8j');
m1.put(10,'005U0000003mGJP');
m1.put(11,'005U0000003k1dQ');
m1.put(12,'005U0000002Z1gi');
 FOR (StrikeTech_Campaign__c a : [select id,Sales_Rep__c,Sales_Commission__c from StrikeTech_Campaign__c   ])
 {
     Sales_Rep__c tmp = new Sales_Rep__c();
     tmp.User__c = m1.get((integer)a.Sales_Rep__c);
     tmp.StrikeTech_Campaign__c = a.id;
     tmp.Commision__c = a.Sales_Commission__c;
     tmp.Role__c = 'Sales Rep';
     if (tmp.User__c == null)
     	{          
     	tmp.User__c = 	'005U0000003mGJM';
        }
     myList.add(tmp);
 }
insert myList;
system.debug(myList.size());
*/
//delete [select Id from StrikeTech_Campaign__c];

//system.debug(decimal.valueOf('489.40'));