public class Contract {
    public static String BILLING_CONDITION_EXTECH = 'Extech';
    public static String BILLING_CONDITION_NORMAL = 'Normal';
    public static String INVOICING_TYPE_ONE = 'One Invoice';
    public static String PAYMENT_TYPE_NET_30 = 'Net 30';
    public static String PAYMENT_TYPE_NET_45 = 'Net 45';

    public static void updateContractFromOpportunity(Map<Id, Project__c> opportunityContract) {
        Map<Id, List<VideoUrl__c>> opportunityVideos = VideoUrlRepository.getVideosForOpportunities(opportunityContract.keySet());
        Map<Id, List<OpportunityAdPlacement__c>> opportunityAdPlacements = PlatformRepository.getOpportunityAdPlacementsForOpportunities(opportunityContract.keySet());
        Map<Id, List<OpportunityPlatform__c>> opportunityPlatforms = PlatformRepository.getPlatformsForOpportunities(opportunityContract.keySet());
        
        List<OpportunityPlatform__c> opportunityPlatformsToUpdate = new List<OpportunityPlatform__c>();
        List<OpportunityAdPlacement__c> opportunityAdPlacementsToUpdate = new List<OpportunityAdPlacement__c>();
        List<VideoUrl__c> videosToUpdate = new List<VideoUrl__c>();
        
        for (Id oppId : opportunityVideos.keySet()) {
            Id contractId = opportunityContract.get(oppId).Id;
            for (VideoUrl__c video : opportunityVideos.get(oppId)) {
                video.Contract__c = contractId;  
                videosToUpdate.add(video);
            }
        }
        
        for (Id oppId : opportunityAdPlacements.keySet()) {
            Id contractId = opportunityContract.get(oppId).Id;
            for (OpportunityAdPlacement__c opportunityAdPlacement : opportunityAdPlacements.get(oppId)) {
                opportunityAdPlacement.Contract__c = contractId;  
                opportunityAdPlacementsToUpdate.add(opportunityAdPlacement);
            }
        }
        
        for (Id oppId : opportunityPlatforms.keySet()) {
            Id contractId = opportunityContract.get(oppId).Id;
            for (OpportunityPlatform__c opportunityPlatform : opportunityPlatforms.get(oppId)) {
                opportunityPlatform.Contract__c = contractId;
                opportunityPlatformsToUpdate.add(opportunityPlatform);
            }
        }

        update videosToUpdate;
        update opportunityPlatformsToUpdate;
        update opportunityAdPlacementsToUpdate;
    }
    
    public static void createNewPayments(List<Project__c> contracts) {
        List<Sub_Project__c> subProjToInsert = new List<Sub_Project__c>();

        Integer monthsBetween;
        Sub_Project__c subProject;
        Date myDate;
        Decimal daysInMonth, totalClientSpend, totalDays;
        String startD, endD;

        for (Project__c pr : contracts) {
            totalDays = pr.Start_Date__c.daysBetween(pr.End_Date__c) + 1;
            monthsBetween = pr.Start_Date__c.monthsBetween(pr.End_Date__c) + 1;
            totalClientSpend = 0;

            if (monthsBetween == null || monthsBetween == 0 || pr.InvoicingType__c == Contract.INVOICING_TYPE_ONE) {
                monthsBetween = 1;
            }

            for (Integer i = 0; i < monthsBetween; i++) {
                subProject = Utility.copyContractDataToPayment(pr);
                myDate = pr.Start_Date__c.addMonths(i);
                if (i == 0) {
                    subProject.Start_Date__c = myDate;
                } else {
                    subProject.Start_Date__c = Date.newInstance(myDate.year(), myDate.month(), 1);
                }
                subProject.End_Date__c  = Date.newInstance(myDate.year(), myDate.month(), Date.daysInMonth(myDate.year(), myDate.month()));
                if (subProject.End_Date__c > pr.End_Date__c || (i == (monthsBetween - 1) )) {
                    subProject.End_Date__c = pr.End_Date__c;
                }
                daysInMonth  = subProject.Start_Date__c.daysBetween(subProject.End_Date__c) + 1;
                subProject.Client_Spend__c = (daysInMonth / totalDays * pr.Client_Spend__c).setscale(2) ;
                subProject.Client_Spend__c = (subProject.Client_Spend__c).round(System.RoundingMode.DOWN);
                totalClientSpend += subProject.Client_Spend__c;
                startD = String.valueOf(subProject.Start_Date__c).replaceAll('-', '.');
                endD = String.valueOf(subProject.End_Date__c).replaceAll('-', '.');
                subProject.Name = '[' + pr.Project_ID__c + ' - ' + startD + ' - ' + endD + ']';
                subProjToInsert.add(subProject);
            }
            
            if (pr.Client_Spend__c > totalClientSpend){
                subProject.Client_Spend__c += (pr.Client_Spend__c - totalClientSpend);
            }
        }

        if (!subProjToInsert.isEmpty()) {
            insert subProjToInsert;
        }
    }
}