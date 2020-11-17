public class ContractRepository {

    public static final Integer HISTORIES_SOQL_LIMIT = 10;

    public static Integer preLaunchNotificationAdvance = 2;
    public static Integer postLaunchNotificationDelay = -2;

    public static Project__c getContractByOppIdWithPaymentsAndProjects(Id opportunityId) {
        return [
            SELECT Id, Opportunity__c, BillingCondition__c, Margin_Type__c, Account_Type__c, Margin__c, ExpectedRebate__c, Actual_Gross_Profit__c, Gross_Profit__c, Actual_Rebate__c,
                (SELECT Quantity__c, Id, Media_Order__c, AdWordsSpend__c, Margin_Type__c, UnitCost__c, Start_Date__c, End_Date__c, StrikeId__c, Client_Spend__c, Actual_Rebate__c, InvoiceAmount__c FROM Payments__r),
                (SELECT Id, Margin__c, Invoice_Amount__c, Client_Spend__c, Media_Order__c, Delivered__c, AdWordsSpend__c, Margin_Type__c, Start_Date__c, Checked__c,
                        Billing_Profile__c, Contract_Billing_Condition_Id__c
                FROM Sub_Projects__r)
            FROM Project__c
            WHERE Opportunity__c = :opportunityId LIMIT 1
        ];
    }

    public static Project__c getContractWithPayments(Id contractId) {
        return [
            SELECT Client_Spend__c, (SELECT Client_Spend__c FROM Sub_Projects__r)
            FROM Project__c
            WHERE Id = :contractId
        ];
    }

    public static Set<Id> getSalesRepLaunchingContracts(Id salesRepId) {
        Set<Id> retVal = new Set<Id>();
        Map<Id, Set<Id>> salesRepContracts = getSalesRepLaunchingContracts(new Set<Id> {salesRepId});
        if (salesRepContracts.containsKey(salesRepId)) {
            retVal = salesRepContracts.get(salesRepId);
        }
        return retVal;
    }

    public static Map<Id, Set<Id>> getSalesRepLaunchingContracts(Set<Id> salesRepIds) {
        Date startDate = System.today().addDays(preLaunchNotificationAdvance);
        List<Contract_Sales_Rep__c> contractSalesReps = [
            SELECT Contract__c, Commission_Profile__c
            FROM Contract_Sales_Rep__c
            WHERE Contract__r.Start_Date__c = :startDate AND Commission_Profile__c IN :salesRepIds
        ];

        Map<Id, Set<Id>> retVal = new Map<Id, Set<Id>>();
        for (Contract_Sales_Rep__c contractSalesRep :contractSalesReps) {
            if (!retVal.containsKey(contractSalesRep.Commission_Profile__c)) {
                retVal.put(contractSalesRep.Commission_Profile__c, new Set<Id> {contractSalesRep.Contract__c} );
            } else {
                retVal.get(contractSalesRep.Commission_Profile__c).add(contractSalesRep.Contract__c);
            }
        }
        return retVal;
    }

    public static List<Project__c> getClientServiceLaunchingContracts(Id clientServiceId) {
        List<Project__c> retVal = new List<Project__c>();
        Map<Id, List<Project__c>> clientServiceContracts = getClientServiceLaunchingContracts(new Set<Id> {clientServiceId});
        if (clientServiceContracts.containsKey(clientServiceId)) {
            retVal = clientServiceContracts.get(clientServiceId);
        }
        return retVal;
    }

    public static List<Project__c> getClientServiceLaunchedContracts(Id clientServiceId) {
        List<Project__c> retVal = new List<Project__c>();
        Map<Id, List<Project__c>> clientServiceContracts = getClientServiceLaunchedContracts(new Set<Id>{clientServiceId});
        if (clientServiceContracts.containsKey(clientServiceId)) {
            retVal = clientServiceContracts.get(clientServiceId);
        }
        return retVal;
    }

    public static Map<Id, List<Project__c>> getClientServiceLaunchingContracts(Set<Id> clientServiceId) {
        Date startDate = System.today().addDays(preLaunchNotificationAdvance);
        return getClientServiceContracts(startDate, clientServiceId);
    }

    public static Map<Id, List<Project__c>> getClientServiceLaunchedContracts(Set<Id> clientServiceIds) {
        Date startDate = System.today().addDays(postLaunchNotificationDelay);
        return getClientServiceContracts(startDate, clientServiceIds);
    }

    private static Map<Id, List<Project__c>> getClientServiceContracts(Date startDate, Set<Id> clientServiceIds) {
        Map<Id, List<Project__c>> retVal = new Map<Id, List<Project__c>>();
        List<Project__c> contracts = [
            SELECT Id, ClientServicesRep__c, ClientServicesRep__r.Email, Margin__c, Margin_Type__c, Name, Client_Spend__c, End_Date__c,
                Account__r.Name, Account_Type__c, Brand__c, Brand__r.Name, BillingConditionName__c, CurrencyIsoCode, Start_Date__c
            FROM Project__c
            WHERE Start_Date__c = :startDate AND ClientServicesRep__c IN :clientServiceIds AND ClientServicesRep__r.Email != NULL
            ORDER BY Name
        ];

        for (Project__c contract :contracts) {
            if (!retVal.containsKey(contract.ClientServicesRep__c)) {
                retVal.put(contract.ClientServicesRep__c, new List<Project__c> {contract} );
            } else {
                retVal.get(contract.ClientServicesRep__c).add(contract);
            }
        }
        return retVal;
    }

    public static List<Project__c> getContractsForPreLaunchNotification(Set<Id> contractIds) {
        return [
            SELECT Account__r.Name, Account_Type__c, Brand__c, Brand__r.Name, BillingConditionName__c, CurrencyIsoCode, Margin__c, Margin_Type__c, Name, Start_Date__c, End_Date__c, Client_Spend__c
            FROM Project__c
            WHERE Id IN :contractIds
            ORDER BY Name
        ];
    }

    //NOTE: Please review ProjectHandler logic of updating PerformMMSync__c field, when adding new field for MM Sync
    public static Project__c getContractForMMSync(Id contractId) {
        return getContractsForMMSync(new Set<String> { contractId })[0];
    }

    public static List<Project__c> getContractsForMMSync(Set<String> contractIds) {
        return [
            SELECT Id, Account__r.Agency__c, Account__r.Name, Account_Type__c,  Brand__c, Brand__r.Name, Brand__r.Verticals__c, CurrencyIsoCode,
					Client_Spend__c, ClientServicesRep__c, ClientServicesRep__r.Email, ClientServicesRep__r.Name, End_Date__c, Geo__c, Language__c, 
            		LastModifiedBy.Email, LastModifiedBy__c, LastModifiedBy__r.Email, Margin__c, Margin_Type__c, MediaBuyer__c, Media_Order__c, 
            		More_Info__c, Name, Project_ID__c, Region__c, Start_Date__c, Sync_with_MM__c, Targeting__c, Verticals__c, Video_Length__c,
                (SELECT Id, Archive__c, ClickThroughURL__c, EndDate__c, Format__c, IsPlaceholder__c, Name, Platform__c, Rotation__c, Salesforce_ID__c, StartDate__c, Text__c, Url__c FROM YouTubeURLs__r),
                (SELECT Id, Action_Type__c, Age__c, AgeText__c, ApplyStrikeIdSuffix__c, Brand_Lift_Study__c, Client_Spend__c, Companion_Banner__c, CostStructure__c, 
                 		CTA_Overlay_Text__c, End_Date__c, Facebook_Page__c, Gender__c, IsOverlapping__c, KPI__c, Objectives__c, 
                 		OpportunityPlatform__r.Platform__r.Name, OpportunityPlatform__r.NoCostStructure__c, OpportunityPlatform__r.Salesforce_ID__c, 
                 		Payment__c, Pixel_Tracking__c, Project__c, ProjectID__c, Quantity__c, Start_Date__c, StrikeId__c, StrikeIdFormula__c, UnitCost__c
                        FROM Payments__r),
                (SELECT Account_Entity__c, Platform__r.Name, Platform__c, Platform__r.Provider__c, Salesforce_ID__c, PlatformAccount__c FROM ContractPlatforms__r),
                (SELECT AdPlacement__r.Name, OpportunityPlatform__c FROM ContractAdPlacements__r)
            FROM Project__c
            WHERE Id IN :contractIds
        ];
    }

    public static List<Project__c> getContractsByIdsForSpends(Set<Id> contractIDs) {
        return [
            SELECT Id, ClientServicesRep__r.Name, CurrencyIsoCode, End_Date__c, Name, Project_ID__c, Start_Date__c, Strike_ID__c,
                (SELECT Id, Account_Entity__c, Platform__c, Platform__r.Name, PlatformAccount__c FROM ContractPlatforms__r),
                (SELECT StrikeId__c, Start_Date__c, End_Date__c FROM Payments__r)
            FROM Project__c
            WHERE Id IN :contractIDs
        ];
    }

    public static Project__c getContractById(Id recId) {
        return getContractByIds(new Set<Id>{recId})[0];
    }

    public static List<Project__c> getContractByIds(Set<Id> recIds) {
        return [
            SELECT Account__c, Account__r.Custom_Xero_Naming__c, Account_Type__c, ActualGrossProfit__c, Actual_Discount__c, Actual_Rebate__c,AddXeroTax__c,
                AdWords_Spend__c, BillingCondition__c, BillingCondition__r.Rebate_Rate__c, BillingConditionName__c, Brand__c, Brand__r.Verticals__c,
                Campaign_Status__c, Client_IO__c, Client_Spend__c, Client_Spend_Defined_on_IO__c, ClientServicesRep__c, Commission_Paid__c, Gaps_Exist_Between_Projects__c,
                Commission_Paid_Date__c, ConsultancyFeePaid__c, ConsultancyFeePaidDate__c, CreatedById, CreatedDate, CurrencyIsoCode, Custom_Xero_Campaign_Name__c,
                Days_running__c, Discount_Terms__c, End_Date__c, ExpectedRebate__c, Final_Margin__c, Geo__c, Gross_Profit__c, Expected_Gross_Profit__c,
                Id, Invoice_Amount_Roll_Up__c, InvoicesPaid__c, InvoicingType__c, IsDeleted, LastActivityDate, LastModifiedById, LastModifiedDate, LastReferencedDate,
                LastViewedDate, Language__c, Margin__c, Margin_Type__c, MaxPaymentEndDate__c, Media_Order__c, MediaBuyer__c, MinPaymentStartDate__c, More_Info__c,
                More_Invoicing_Info__c, Name, Net_Profit__c, NumberOfPlatforms__c, Opportunity__c, Opportunity__r.StageName, Order_Type__c, OwnerId, Payment_Type__c,
                PaymentMaxEndDateMatches__c, PaymentMinStartDateMatches__c, PO__c, Project_ID__c, Project_Number__c, Region__c, Sales_Commission_rollup__c, Start_Date__c, Start_Date_R__c,
                Sync_with_MM__c, SystemModstamp, Targeting__c, Total_Revenue__c, Total_Revenue_RollUp__c, Verticals__c, Video_Length__c, WeeklyReportingSchedule__c,
                Xero_Contact__c, Xero_Entity__c, Xero_ID__c,
                (SELECT Id, Opportunity__c, AdPlacement__c, AdPlacement__r.Name, AdPlacement__r.Platform__c FROM ContractAdPlacements__r),
                (SELECT Id, Account_Entity__c, CostStructure__c, NoCostStructure__c, /*VariableCPA__c, CPA__c, VariableCPAC__c, CPAC__c, VariableCPC__c, CPC__c, VariableCPE__c,
                    CPE__c, VariableCPER__c, CPER__c, VariableCPF__c, CPF__c, VariableCPI__c, CPI__c, VariableCPL__c, CPL__c, VariableCPLC__c, CPLC__c,
                    VariableCPM__c, CPM__c, VariableCPPL__c, CPPL__c, VariableCPS__c, CPS__c, VariableCPSU__c, CPSU__c, VariableCPV__c, CPV__c,*/
                    Opportunity__c, Platform__c, Platform__r.Name, PlatformAccount__c FROM ContractPlatforms__r),
                (SELECT CreatedById, CreatedDate, Field, Id, NewValue, OldValue, ParentId, Parent.CurrencyIsoCode FROM Histories ORDER BY CreatedDate DESC LIMIT :HISTORIES_SOQL_LIMIT),
                (SELECT Id, Commission_Profile__c, Commission_Type__c, Notes__c, Percentage_of_GP_Allocation__c FROM Sales_Reps__r)
            FROM Project__c
            WHERE Id IN :recIds
        ];
    }
}