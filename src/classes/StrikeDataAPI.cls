/**
 * Created by Pavel Lapitski on 2019-10-10.
 */

public class StrikeDataAPI {

    public enum PackageType { FACEBOOK, ADWORDS, DV360 }

    @TestVisible private static final String NONE = 'None';
    @TestVisible private static final Decimal ZERO = 0;


    private static final AppSettings__c settings = AppSettings__c.getInstance('Default');
    private static final List<Platform__c> platforms = [SELECT Prefix__c, Provider__c FROM Platform__c LIMIT 500];

    //public class StrikeDataAPIException extends Exception {}

    @TestVisible private static final String ERROR_CANNOT_RECEIVE_SPENDS = 'Cannot receive spends.';

    public static SpendCalloutResult getSpendsLastNDays(Integer lastNDays, PackageType packageType) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(getAPIUrl(packageType, null));
        req.setTimeout(60000);
        req.setMethod('GET');
        req.setHeader('Authorization', getAuthorizationHeader());

        SpendCalloutResult calloutResult = new SpendCalloutResult();
        try {
            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() == 200) {
                Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                System.debug('### response: ' + response);
                calloutResult.spends = mapResponseSpending((List<Object>) response.get('metrics'));
                calloutResult.isValid = true;
            } else  {
                calloutResult.setFailure(res.getBody());
            }
        } catch (Exception ex) {
            calloutResult.setFailure(ex.getMessage());
        }
        return calloutResult;
    }

    public static Map<String, SpendCalloutResult> getSpendsByProjectNames(Map<String, Id> projectNamesToContractIds) {
        Map<String, SpendCalloutResult> projectNameToCalloutResult = new Map<String, SpendCalloutResult>();
        List<EventLog__c> logs = new List<EventLog__c>();
        PackageType packageType;
        for (String projectName :projectNamesToContractIds.keySet()) {
            SpendCalloutResult calloutResult = new SpendCalloutResult();
            projectNameToCalloutResult.put(projectName, calloutResult);
            packageType = getPackageTypeByProjectName(projectName);
            if (packageType == null) {
                calloutResult.setFailure(ERROR_CANNOT_RECEIVE_SPENDS);
            } else {
                HttpRequest req = new HttpRequest();
                req.setEndpoint(getAPIUrl(packageType, projectName));
                req.setTimeout(60000);
                req.setMethod('GET');
                req.setHeader('Authorization', getAuthorizationHeader());

                try {
                    HttpResponse res = new Http().send(req);
                    System.debug('### res BODY: ' + res.getBody());
                    if (res.getStatusCode() == 200) {
                        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                        calloutResult.spends = mapResponseSpending((List<Object>) response.get('metrics'));
                        calloutResult.isValid = true;

                        EventLog__c log = EventLog.createEventLog(
                            packageType.name() + ' spends have been received.',
                            EventLog.STATUS_INFO,
                            EventLog.STRIKE_DATA_CALLOUT,
                            projectNamesToContractIds.get(projectName)
                        );
                        logs.add(log);
                    } else  {
                        calloutResult.setFailure(res.getBody());
                        EventLog__c log = EventLog.createEventLog(
                            packageType.name() + ' callout error: ' + res.getBody(),
                            EventLog.STATUS_ERROR,
                            EventLog.STRIKE_DATA_CALLOUT,
                            projectNamesToContractIds.get(projectName)
                        );
                        logs.add(log);
                    }
                } catch (Exception ex) {
                    System.debug('### ex: ' + ex.getStackTraceString());
                    logs.add(EventLog.createMediaManagerLog('Callout exception', EventLog.STATUS_ERROR, EventLog.TYPE_INVOICE_API_SYNC, ex.getMessage()));
                    calloutResult.setFailure(ex.getMessage());
                }
            }
        }
        insert logs;
        return projectNameToCalloutResult;
    }

    public static String getAPIUrl(PackageType packageType, String projectName) {
        String apiUrl = settings.StrikeDataWarehouseURL__c  + '/platform/' + packageType.name().toLowerCase();
        if (String.isNotBlank(projectName)) {
            apiUrl += '/project/' + projectName;
        }
        return apiUrl;
    }

    public static PackageType getPackageTypeByProjectName(String projectName) {
        PackageType packageType;
        for (Platform__c platform :platforms) {
            if (!projectName.startsWithIgnoreCase(platform.Prefix__c)) continue;
            if (platform.Provider__c == 'Facebook') {
                packageType = StrikeDataAPI.PackageType.FACEBOOK;
            } else if (platform.Provider__c == 'DBM') {
                packageType = StrikeDataAPI.PackageType.DV360;
            } else if (platform.Provider__c == 'AdWords') {
                packageType = StrikeDataAPI.PackageType.ADWORDS;
            } else if (platform.Provider__c == 'LinkedIn' || platform.Provider__c == 'Pinterest' || platform.Provider__c == 'Snapchat' || platform.Provider__c == 'Twitter') {
                // not implemented yet
            }
        }
        return packageType;
    }

    public static PackageType getPackageTypeByPackageName(String packageTypeName) {
        PackageType packageType;
        if (packageTypeName == StrikeDataAPI.PackageType.FACEBOOK.name()) {
            packageType = StrikeDataAPI.PackageType.FACEBOOK;
        } else if (packageTypeName == StrikeDataAPI.PackageType.DV360.name()) {
            packageType = StrikeDataAPI.PackageType.DV360;
        } else if (packageTypeName == StrikeDataAPI.PackageType.ADWORDS.name()) {
            packageType = StrikeDataAPI.PackageType.ADWORDS;
        }
        return packageType;
    }

    @TestVisible private static List<SpendInfo> mapResponseSpending(List<Object> metrics) {
        List<SpendInfo> spends = new List<SpendInfo>();
        for (Object spendMetric :metrics) {
            Map<String, Object> obj = (Map<String, Object>) spendMetric;

            SpendInfo spendInfo = new SpendInfo();
            spendInfo.projectId = String.valueOf(obj.get('project_id'));
            spendInfo.spendDate = String.valueOf(obj.get('date'));
            spendInfo.accountId = String.valueOf(obj.get('account_id'));
            spendInfo.spendCurrency = String.valueOf(obj.get('currency'));
            spendInfo.costStructure = String.valueOf(obj.get('cost_structure'));
            spendInfo.spendAmount = String.valueOf(obj.get('spend'));
            spendInfo.clicks = String.valueOf(obj.get('clicks'));
            spendInfo.views = String.valueOf(obj.get('views'));
            spendInfo.impressions = String.valueOf(obj.get('impressions'));
            spendInfo.engagements = String.valueOf(obj.get('engagements'));
            spendInfo.delivered = String.valueOf(obj.get('delivered'));
            spends.add(spendInfo);
        }
        return spends;
    }

    private static String getAuthorizationHeader() {
        Blob header = Blob.valueOf(settings.StrikeDataWarehouseUser__c + ':' + settings.StrikeDataWarehouseToken__c);
        return 'BASIC ' + EncodingUtil.base64Encode(header);
    }

    private static String getAuthorizationHeaderForSync() {
        Blob header = Blob.valueOf(settings.StrikeDataWarehouseSyncUser__c + ':' + settings.StrikeDataWarehouseSyncToken__c);
        return 'BASIC ' + EncodingUtil.base64Encode(header);
    }

    public class SpendCalloutResult {
        public Boolean isValid { get; set;}
        public String message { get; set;}
        public List<SpendInfo> spends { get; set;}

        public SpendCalloutResult() {
            isValid = false;
            message = '';
            spends = new List<SpendInfo>();
        }

        public void setFailure(String errorMessage) {
            isValid = false;
            message = errorMessage;
        }
    }

    public class SpendInfo {
        public String projectId { get; set; }
        public String spendDate { get; set; }
        public String accountId { get; set; }
        public String spendCurrency { get; set; }
        public String costStructure{ get; set; }
        public String spendAmount { get; set; }
        public String clicks { get; set; }
        public String views { get; set; }
        public String impressions { get; set; }
        public String engagements { get; set; }
        public String delivered { get; set; }
    }

    private static Project__c getContractForCalloutById(Id contractId) {
        return [
            SELECT Order_Type__c, Media_Order__c, Margin__c, Margin_Type__c, Client_Spend__c, CurrencyIsoCode, Geo__c, MediaBuyer__r.Name, ActualGrossProfit__c,
                    Actual_Rebate__c, Agency__c, Video_Length__c, Account_Type__c, Brand__r.Name, ClientServicesRep__r.Name, Verticals__c, CSEmailFromBrandAccount__c,
                    Gross_Profit__c, ExpectedRebate__c, Total_Revenue__c, Client_IO__c, InvoicingType__c, Language__c, More_Info__c, More_Invoicing_Info__c,
                    Payment_Type__c, PO__c, Region__c, Start_Date__c, End_Date__c, Targeting__c, Final_Margin__c,
                (SELECT Id FROM Payments__r),
                (SELECT Id, Name, Commission_Type__c, Percentage_of_GP_Allocation__c, Commission_Profile__r.Name FROM Sales_Reps__r)
            FROM Project__c
            WHERE Id = :contractId
        ];
    }

    private static List<Payment__c> getProjectsByIds(Set<Id> projectIds) {
        return [
            SELECT Pixel_Tracking__c, UnitCost__c, StrikeId__c, Start_Date__c, Quantity__c, Name, Platform_Type__c, PaymentType__c, Objectives__c, Metric__c,
                    AdWordsSpend__c, Media_Order__c, Margin_Type__c, Margin__c, KPI__c, InvoiceAmount__c, Gender__c, Facebook_Page__c, End_Date__c, Action_Type__c,
                    AmountDelivered__c, CTA_Overlay_Text__c, CostStructure__c, Companion_Banner__c, Client_Spend__c, BillingCondition__c, Age__c,
                    Actual_Gross_Profit_New__c, OpportunityPlatform__r.PlatformAccount__c, OpportunityPlatform__c, Account_Type__c, Timezone__c,
                (SELECT Id, Creative__r.CopyUrl__c, Creative__r.Name, Creative__r.Format__c, Creative__r.Url__c,  Creative__r.StartDate__c, Creative__r.EndDate__c
                    FROM Project2Creatives__r)
            FROM Payment__c
            WHERE Id IN :projectIds
        ];
    }

    private static List<OpportunityAdPlacement__c> getOpportunityAdPlacementByOppPlatformIds(Set<Id> oppPlatformIds) {
        return [
            SELECT Id, AdPlacement__r.Name, OpportunityPlatform__c
            FROM OpportunityAdPlacement__c
            WHERE OpportunityPlatform__c IN :oppPlatformIds
        ];
    }

    public static void notifyAboutChanges(Id contractId) {
        Project__c contract = getContractForCalloutById(contractId);

        Set<Id> projectIds = new Set<Id>();
        if (!contract.Payments__r.isEmpty()) {
            for (Payment__c project :contract.Payments__r) {
                projectIds.add(project.Id);
            }
        }
        Map<Id, Payment__c> projectsMap = new Map<Id, Payment__c>(getProjectsByIds(projectIds));

        Set<Id> oppPlatformIds = new Set<Id>();
        for (Payment__c project :projectsMap.values()) {
            oppPlatformIds.add(project.OpportunityPlatform__c);
        }
        Map<Id, String> oppPlatformId2OppAdPlacementsMap = new Map<Id, String>();
        for (OpportunityAdPlacement__c oppAdPlacement :getOpportunityAdPlacementByOppPlatformIds(oppPlatformIds)) {
            if (!oppPlatformId2OppAdPlacementsMap.containsKey(oppAdPlacement.OpportunityPlatform__c)) {
                oppPlatformId2OppAdPlacementsMap.put(oppAdPlacement.OpportunityPlatform__c, '');
            }
            String adPlacements = oppPlatformId2OppAdPlacementsMap.get(oppAdPlacement.OpportunityPlatform__c);
            adPlacements += (String.isEmpty(adPlacements)) ? oppAdPlacement.AdPlacement__r.Name : ';' + oppAdPlacement.AdPlacement__r.Name;
            oppPlatformId2OppAdPlacementsMap.put(oppAdPlacement.OpportunityPlatform__c, adPlacements);
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(settings.StrikeDataWarehouseSyncURL__c);
        req.setTimeout(100);
        req.setMethod('POST');
        req.setHeader('Authorization', getAuthorizationHeaderForSync());
        req.setBody(JSON.serialize(new ContractData(contract, projectsMap, oppPlatformId2OppAdPlacementsMap)));

        System.debug('### req.Body: ' + req.getBody());

        HttpResponse res = new Http().send(req);
        System.debug('### res: ' + res);
    }

    @TestVisible private class CreativeData {
        String url, name, format;
        Date startDate, endDate;

        CreativeData(ProjectToCreatives__c p2c) {
            url = p2c.Creative__r.Url__c;
            name = p2c.Creative__r.Name;
            format = p2c.Creative__r.Format__c;
            startDate = p2c.Creative__r.StartDate__c;
            endDate = p2c.Creative__r.EndDate__c;
        }
    }

    @TestVisible private class ProjectData {
        List<CreativeData> creatives { get; set; }

        Decimal actualGrossProfit, unitCost, adWordsSpend, mediaOrder, margin, invoiceAmount, clientSpend;
        Date endDate, startDate;
        Integer quantity, amountDelivered;
        String age, costStructure, pixelTracking, projectId, name, platformType, paymentType, objectives, metric, marginType, kpi, gender,
                facebookPage, ctaOverlayText, companionBanner, accountType, billingCondition, actionType, accountId, adPlacements;

        ProjectData(Payment__c project, String adPlacements) {
            creatives = new List<CreativeData>();

            this.adPlacements = adPlacements;

            startDate = project.Start_Date__c;
            endDate = project.End_Date__c;

            unitCost = (project.UnitCost__c != null) ? project.UnitCost__c : ZERO;
            adWordsSpend = (project.AdWordsSpend__c != null) ? project.AdWordsSpend__c : ZERO;
            mediaOrder = (project.Media_Order__c != null) ? project.Media_Order__c : ZERO;
            margin = (project.Margin__c != null) ? project.Margin__c : ZERO;
            invoiceAmount = (project.InvoiceAmount__c != null) ? project.InvoiceAmount__c : ZERO;
            clientSpend = (project.Client_Spend__c != null) ? project.Client_Spend__c : ZERO;
            actualGrossProfit = (project.Actual_Gross_Profit_New__c != null) ? project.Actual_Gross_Profit_New__c : ZERO;

            pixelTracking = (project.Pixel_Tracking__c != null) ? project.Pixel_Tracking__c : NONE;
            projectId = (project.StrikeId__c != null) ? project.StrikeId__c : NONE;
            quantity = (project.Quantity__c != null) ? (Integer) project.Quantity__c : 0;
            name = (project.Name != null) ? project.Name : NONE;
            platformType = (project.Platform_Type__c != null) ? project.Platform_Type__c : NONE;
            paymentType = (project.PaymentType__c != null) ? project.PaymentType__c : NONE;
            objectives = (project.Objectives__c != null) ? project.Objectives__c : NONE;
            metric = (project.Metric__c != null) ? project.Metric__c : NONE;
            marginType = (project.Margin_Type__c != null) ? project.Margin_Type__c : NONE;
            kpi = (project.KPI__c != null) ? project.KPI__c : NONE;
            gender = (project.Gender__c != null) ? project.Gender__c : NONE;
            facebookPage = (project.Facebook_Page__c != null) ? project.Facebook_Page__c : NONE;
            amountDelivered = (project.AmountDelivered__c != null) ? (Integer) project.AmountDelivered__c : 0;
            ctaOverlayText = (project.CTA_Overlay_Text__c != null) ? project.CTA_Overlay_Text__c : NONE;
            costStructure = (project.CostStructure__c != null) ? project.CostStructure__c : NONE;
            companionBanner = (project.Companion_Banner__c != null) ? project.Companion_Banner__c : NONE;
            accountType = (project.Account_Type__c != null) ? project.Account_Type__c : NONE;
            billingCondition = (project.BillingCondition__c != null) ? project.BillingCondition__c : NONE;
            age = (project.Age__c != null) ? project.Age__c : NONE;
            actionType = (project.Action_Type__c != null) ? project.Action_Type__c : NONE;
            accountId = (project.OpportunityPlatform__r.PlatformAccount__c != null) ? project.OpportunityPlatform__r.PlatformAccount__c : NONE;

            for (ProjectToCreatives__c p2c :project.Project2Creatives__r) {
                creatives.add(new CreativeData(p2c));
            }
        }
    }

    @TestVisible private class SalesRepData {
        String name, commissionType;
        Decimal percentageOfGPAllocation;

        SalesRepData(Contract_Sales_Rep__c salesRep) {
            commissionType = salesRep.Commission_Type__c;
            percentageOfGPAllocation = salesRep.Percentage_of_GP_Allocation__c;
            name = salesRep.Commission_Profile__r.Name;
        }
    }

    @TestVisible private class ContractData {
        List<ProjectData> projects { get; set; }
        List<SalesRepData> salesReps { get; set; }

        Decimal mediaOrder, margin, clientSpend, actualGrossProfit, actualRebate, grossProfit, expectedRebate, expectedRevenue, finalMargin;
        String moreInvoicingInfo, paymentType, io, invoicingType, language, csEmailFromBrandAccount, verticals,
                clientServicesRep, brandName, accountType, videoLength, agency, mediaBuyer, geo, currencyIsoCode, marginType,
                orderType, po, region, targeting;
        Date startDate, endDate;

        ContractData(Project__c contract, Map<Id, Payment__c> projectsMap, Map<Id, String> oppPlatformId2OppAdPlacementsMap) {
            projects = new List<ProjectData>();
            salesReps = new List<SalesRepData>();

            startDate = contract.Start_Date__c;
            endDate = contract.End_Date__c;

            mediaOrder = (contract.Media_Order__c != null) ? contract.Media_Order__c : ZERO;
            margin = (contract.Margin__c != null) ? contract.Margin__c : ZERO;
            clientSpend = (contract.Client_Spend__c != null) ? contract.Client_Spend__c : ZERO;
            actualGrossProfit = (contract.ActualGrossProfit__c != null) ? contract.ActualGrossProfit__c : ZERO;
            actualRebate = (contract.Actual_Rebate__c != null) ? contract.Actual_Rebate__c : ZERO;
            grossProfit = (contract.Gross_Profit__c != null) ? contract.Gross_Profit__c : ZERO;
            expectedRebate = (contract.ExpectedRebate__c != null) ? contract.ExpectedRebate__c : ZERO;
            expectedRevenue = (contract.Total_Revenue__c != null) ? contract.Total_Revenue__c : ZERO;
            finalMargin = (contract.Final_Margin__c != null) ? contract.Final_Margin__c : ZERO;

            orderType = (contract.Order_Type__c != null) ? contract.Order_Type__c : NONE;
            marginType = (contract.Margin_Type__c != null) ? contract.Margin_Type__c : NONE;
            currencyIsoCode = (contract.CurrencyIsoCode != null) ? contract.CurrencyIsoCode : NONE;
            geo = (contract.Geo__c != null) ? contract.Geo__c : NONE;
            mediaBuyer = (contract.MediaBuyer__r.Name != null) ? contract.MediaBuyer__r.Name : NONE;
            agency = (contract.Agency__c != null) ? contract.Agency__c : NONE;
            videoLength = (contract.Video_Length__c != null) ? contract.Video_Length__c : NONE;
            accountType = (contract.Account_Type__c != null) ? contract.Account_Type__c : NONE;
            brandName = (contract.Brand__r.Name != null) ? contract.Brand__r.Name : NONE;
            clientServicesRep = (contract.ClientServicesRep__r.Name != null) ? contract.ClientServicesRep__r.Name : NONE;
            verticals = (contract.Verticals__c != null) ? contract.Verticals__c : NONE;
            csEmailFromBrandAccount = (contract.CSEmailFromBrandAccount__c != null) ? contract.CSEmailFromBrandAccount__c : NONE;
            io = (contract.Client_IO__c != null) ? contract.Client_IO__c : NONE;
            invoicingType = (contract.InvoicingType__c != null) ? contract.InvoicingType__c : NONE;
            language = (contract.Language__c != null) ? contract.Language__c : NONE;
            moreInvoicingInfo = (contract.More_Invoicing_Info__c != null) ? contract.More_Invoicing_Info__c : NONE;
            paymentType = (contract.Payment_Type__c != null) ? contract.Payment_Type__c : NONE;
            po = (contract.PO__c != null) ? contract.PO__c : NONE;
            region = (contract.Region__c != null) ? contract.Region__c : NONE;
            targeting = (contract.Targeting__c != null) ? contract.Targeting__c : NONE;

            for (Payment__c project :contract.Payments__r) {
                if (projectsMap.containsKey(project.Id)) {
                    Payment__c projectRecord = projectsMap.get(project.Id);
                    String adPlacementsToProject = (oppPlatformId2OppAdPlacementsMap.containsKey(projectRecord.OpportunityPlatform__c)) ? oppPlatformId2OppAdPlacementsMap.get(projectRecord.OpportunityPlatform__c) : '';
                    projects.add(new ProjectData(projectRecord, adPlacementsToProject));
                }
            }

            if (!contract.Sales_Reps__r.isEmpty()) {
                for (Contract_Sales_Rep__c salesRep :contract.Sales_Reps__r) {
                    salesReps.add(new SalesRepData(salesRep));
                }
            }
        }
    }

}