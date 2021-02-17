public class OpportunityRepository {

    public static String STAGE_CLOSED_WON = 'Closed Won';
    public static String STAGE_CLOSED_LOST = 'Closed Lost';

    public static Opportunity getOpportunityById(String oppId) {
        return getOpportunityByIds(new Set<Id>{oppId})[0];
    }

    public static List<Opportunity> getOpportunityByIds(Set<Id> oppIds) {
        return [
            SELECT AccountId, Account_Type__c, Account.Name, Account.Custom_Xero_Naming__c, Additional_Rep__c, Additional_Rep__r.Name,
                Amount, Annual_TrueView_Spend__c, Audit__c , BillingCondition__c, BillingCondition__r.Name,
                Brand__c, Brand__r.Name, Brand__r.Verticals__c, Brand_Lift_Study__c, BillingCondition__r.Rebate_Rate__c,
                ClientServicesRep__c, ClientServicesRep__r.Name, Client_s_Ad_Account_Numbers__c, Client_s_Biggest_Challenge__c,
                Client_s_Biggest_Challenge_Details__c, Client_s_Top_Priority__c, Client_s_Top_Priority_Details__c,
                Closed_Lost_Reason__c, CloseDate, Competitor_Description__c, CreatedById, CreatedDate, CustomXeroCampaignName__c,
                Expected_Revenue__c, ExpectedRebate__c, Email_Notifications_Off__c, Features_Needed__c, Features_Wanted__c,
                Final_Negotiating_Considerations__c, Flight_End__c, Flight_Start__c, Further_Steps__c, Gender__c, Geo__c,
                Gross_Profit__c, InsideSalesRep__c, InsideSalesRep__r.Name, InvoicingType__c, IO__c, KPI__c, KPI_picklist__c,
                Language__c, LastModifiedById, LastModifiedDate, Lost_Notes__c, Margin_Type__c, Media_Process_Type__c,
                Media_Spendings__c, MeetingDate__c, MeetingNotes__c, MeetingStatus__c, Momentum__c, More_Info__c, Name,
                Negotiation_Notes__c, Non_Salesforce_Rep__c, Order_Type__c, Owner.Name, OwnerId, Payment_Type__c, Percent_Margin__c,
                Platform__c, Probability__c, Proposal__c, Qualification_Notes__c, RecordTypeId, RecordType.Name, Region__c,
                RFP_Due_Date__c, StageName, Strike_ID__c, Targeting__c, Trial_Notes__c, Verticals__c, Video_Length__c,
                (SELECT Id, Opportunity__c, AdPlacement__c, AdPlacement__r.Name, AdPlacement__r.Platform__c FROM OpportunityAdPlacements__r),
                (SELECT Id, Opportunity__c, Contact__c, Role__c FROM Contact_Opportunities__r),
                (SELECT Id, Account_Entity__c, CostStructure__c, Opportunity__c, Platform__c, Platform__r.Name, PlatformAccount__c,
                    VariableCPAC__c, VariableCPA__c, VariableCPCO__c, VariableCPC__c, VariableCPDPV__c, VariableCPER__c, VariableCPE__c,
                    VariableCPF__c, VariableCPI__c, VariableCPLC__c, VariableCPLP__c, VariableCPL__c, VariableCPM__c, VariableCPPL__c,
                    VariableCPSU__c, VariableCPS__c, VariableCPVC__c, VariableCPV__c, VariableCPCV__c,
                    CPAC__c, CPA__c, CPCO__c, CPC__c, CPDPV__c, CPER__c, CPE__c, CPF__c, CPI__c, CPLC__c, CPLP__c, CPL__c,
                    CPM__c, CPPL__c, CPSU__c, CPS__c, CPVC__c, CPV__c, CPCV__c
                FROM OpportunityPlatforms__r),
                (SELECT Id FROM Projects__r)
            FROM Opportunity
            WHERE Id = :oppIds
        ];
    }

    public static List<Opportunity> getClientServiceClosingOpportunities(String clientServiceId, Date endDate) {
        List<Opportunity> retVal = new List<Opportunity>();
        Map<String, List<Opportunity>> clientServiceOpportunities = getClientServiceClosingOpportunities(new Set<String> {clientServiceId}, endDate);
        if (clientServiceOpportunities.containsKey(clientServiceId)) {
            retVal = clientServiceOpportunities.get(clientServiceId);
        }
        return retVal;
    }

    public static List<Opportunity> getSalesRepClosingOpportunities(String salesRepId, Date endDate) {
        List<Opportunity> retVal = new List<Opportunity>();
        Map<String, List<Opportunity>> salesRepOpportunities = getSalesRepClosingOpportunities(new Set<String> {salesRepId}, endDate);
        if (salesRepOpportunities.containsKey(salesRepId)) {
            retVal = salesRepOpportunities.get(salesRepId);
        }
        return retVal;
    }

    public static Map<String, List<Opportunity>> getClientServiceClosingOpportunities(Set<String> clientServiceIds, Date endDate) {
        Map<String, List<Opportunity>> retVal = new Map<String, List<Opportunity>>();

        List<Opportunity> notClosedOpportunities = [
            SELECT Id, CloseDate, ClientServicesRep__c, ClientServicesRep__r.Email, Name, Account.Name, Brand__c, Brand__r.Name
            FROM Opportunity
            WHERE CloseDate = :endDate
                AND ClientServicesRep__c IN :clientServiceIds
                AND ClientServicesRep__r.Email != NULL
                AND StageName != :STAGE_CLOSED_WON
                AND StageName != :STAGE_CLOSED_LOST
            ORDER BY Name
        ];

        for (Opportunity opp :notClosedOpportunities) {
            if (!retVal.containsKey(opp.ClientServicesRep__c)) {
                retVal.put(opp.ClientServicesRep__c, new List<Opportunity> {opp} );
            } else {
                retVal.get(opp.ClientServicesRep__c).add(opp);
            }
        }
        return retVal;
    }

    public static Map<String, List<Opportunity>> getSalesRepClosingOpportunities(Set<String> salesRepIds, Date endDate) {
        Map<String, List<Opportunity>> retVal = new Map<String, List<Opportunity>>();

        List<Opportunity> notClosedOpportunities = [
            SELECT Id, Account.Name, Brand__c, Brand__r.Name, CloseDate, OwnerId, Owner.Email, Name
            FROM Opportunity
            WHERE CloseDate = :endDate
                AND OwnerId IN :salesRepIds
                AND Owner.Email != NULL
                AND StageName != :STAGE_CLOSED_WON
                AND StageName != :STAGE_CLOSED_LOST
            ORDER BY Name
        ];

        for (Opportunity opp :notClosedOpportunities) {
            if (!retVal.containsKey(opp.OwnerId)) {
                retVal.put(opp.OwnerId, new List<Opportunity> {opp} );
            } else {
                retVal.get(opp.OwnerId).add(opp);
            }
        }
        return retVal;
    }

    public final static Id RT_ID_BRAND_DIRECT {
        get {
            return recordTypeMap.get('Brand Direct').getRecordTypeId();
        }
    }

    public final static Id RT_ID_AGENCY {
        get {
            return recordTypeMap.get('Agency').getRecordTypeId();
        }
    }

    private static Map<String,Schema.RecordTypeInfo> recordTypeMap {
        get {
            if (recordTypeMap == null) {
                recordTypeMap = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
            }
            return recordTypeMap;
        }
        set;
    }
}