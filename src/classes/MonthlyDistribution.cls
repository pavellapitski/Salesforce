public class MonthlyDistribution {

    public static void assignMonthlyDistributionToSalesRep(List<Monthly_Distribution__c> monthlyDistributions) {
        Map<Id, List<Monthly_Distribution__c>> monthlyDistributionsForContracts = new Map<Id, List<Monthly_Distribution__c>>();
        for (Monthly_Distribution__c monthlyDistribution :monthlyDistributions) {
            if (!monthlyDistributionsForContracts.containsKey(monthlyDistribution.ContractID__c)) {
                monthlyDistributionsForContracts.put(monthlyDistribution.ContractID__c, new List<Monthly_Distribution__c>{monthlyDistribution});
            } else {
                monthlyDistributionsForContracts.get(monthlyDistribution.ContractID__c).add(monthlyDistribution);
            }
        }

        Map<Id, Set<Id>> salesRepsForContracts = new Map<Id, Set<Id>>();
        for (Contract_Sales_Rep__c salesRep :[SELECT Id, Contract__c FROM Contract_Sales_Rep__c WHERE Contract__c In :monthlyDistributionsForContracts.keySet()]) {
            if (!salesRepsForContracts.containsKey(salesRep.Contract__c)) {
                salesRepsForContracts.put(salesRep.Contract__c, new Set<Id> {salesRep.Id});
            } else {
                salesRepsForContracts.get(salesRep.Contract__c).add(salesRep.Id);
            }
        }
        assignMonthlyDistributions(salesRepsForContracts, monthlyDistributionsForContracts);
    }

    private static void assignMonthlyDistributions(Map<Id, Set<Id>> salesRepsForContracts, Map<Id, List<Monthly_Distribution__c>> monthlyDistributionsForContracts) {
        List<Sales_Rep_MD__c> salesRepMonthlyDistributions = new List<Sales_Rep_MD__c>();
        for (Id contractId : salesRepsForContracts.keySet()) {
            for (Id salesRepId : salesRepsForContracts.get(contractId)) {
                if (monthlyDistributionsForContracts.containsKey(contractId)) {
                    for (Monthly_Distribution__c md :monthlyDistributionsForContracts.get(contractId)) {
                        salesRepMonthlyDistributions.add(new Sales_Rep_MD__c(
                            Sales_Rep__c = salesRepId,
                            Monthly_Distribution__c = md.Id
                        ));
                    }
                }
            }
        }
        insert salesRepMonthlyDistributions;
    }

    public static void assignSalesRepToMonthlyDistribution(List<Contract_Sales_Rep__c> salesReps) {
        Map<Id, Set<Id>> salesRepsForContracts = new Map<Id, Set<Id>>();
        Map<Id, List<Monthly_Distribution__c>> monthlyDistributionsForContracts = new Map<Id, List<Monthly_Distribution__c>>();
        for (Contract_Sales_Rep__c salesRep : salesReps) {
            if (!salesRepsForContracts.containsKey(salesRep.Contract__c)) {
                salesRepsForContracts.put(salesRep.Contract__c, new Set<Id> {salesRep.Id});
            } else {
                salesRepsForContracts.get(salesRep.Contract__c).add(salesRep.Id);
            }
        }
        for (Monthly_Distribution__c monthlyDistribution : [SELECT Id, Project__c,Project__r.Payment__r.Project__c  FROM Monthly_Distribution__c WHERE Project__r.Payment__r.Project__c IN :salesRepsForContracts.keySet()]) {
            if (!monthlyDistributionsForContracts.containsKey(monthlyDistribution.Project__r.Payment__r.Project__c)) {
                monthlyDistributionsForContracts.put(monthlyDistribution.Project__r.Payment__r.Project__c, new List<Monthly_Distribution__c>{monthlyDistribution});
            } else {
                monthlyDistributionsForContracts.get(monthlyDistribution.Project__r.Payment__r.Project__c).add(monthlyDistribution);
            }
        }
        assignMonthlyDistributions(salesRepsForContracts, monthlyDistributionsForContracts);
    }

    public static void createMonthlyDistribution(List<Payment__c> projects)  {
        List<Monthly_Distribution__c> monthlyDistributions = new List<Monthly_Distribution__c>();

        Set<Id> paymentIds = new Map<Id,Payment__c>(projects).keySet();
        delete [SELECT Id FROM Monthly_Distribution__c WHERE Project__c IN :paymentIds];

        for (Payment__c project :projects) {
            Date startDate = project.Start_Date__c;

            while (startDate <= project.End_Date__c) {
                Monthly_Distribution__c monthlyDistribution = new Monthly_Distribution__c(CurrencyIsoCode = project.CurrencyIsoCode);
                monthlyDistribution.Project__c = project.Id;
                monthlyDistribution.Start_Date__c = startDate;
                monthlyDistribution.End_Date__c = Date.newInstance(startDate.year(), startDate.month() + 1, 1).addDays(-1);
                monthlyDistribution.Brand_Lookup__c = project.Project__r.Brand__r.Id;

                if (monthlyDistribution.End_Date__c > project.End_Date__c) {
                    monthlyDistribution.End_Date__c = project.End_Date__c;
                }
                Integer monthlyDistributionLength = monthlyDistribution.Start_Date__c.daysBetween(monthlyDistribution.End_Date__c) + 1;
                if (project.Client_Spend__c != null) {
                    monthlyDistribution.Client_Spend__c = (project.Client_Spend__c/project.Days_Running__c * monthlyDistributionLength).setScale(4, System.RoundingMode.HALF_DOWN);
                }
                if (project.Actual_Gross_Profit_New__c != null) {
                    monthlyDistribution.Actual_Gross_Profit__c = (project.Actual_Gross_Profit_New__c/project.Days_Running__c * monthlyDistributionLength).setScale(4, System.RoundingMode.HALF_DOWN);
                }
                if (project.Expected_Gross_Profit_New__c != null) {
                    monthlyDistribution.Expected_Gross_Profit__c = (project.Expected_Gross_Profit_New__c/project.Days_Running__c * monthlyDistributionLength).setScale(4, System.RoundingMode.HALF_DOWN);
                }
                if (project.Expected_Revenue__c != null) {
                    monthlyDistribution.Expected_Revenue__c = (project.Expected_Revenue__c/project.Days_Running__c * monthlyDistributionLength).setScale(4, System.RoundingMode.HALF_DOWN);
                }
                if (project.Actual_Revenue__c != null) {
                    monthlyDistribution.Actual_Revenue__c = (project.Actual_Revenue__c/project.Days_Running__c * monthlyDistributionLength).setScale(4, System.RoundingMode.HALF_DOWN);
                }
                if (project.Media_Order__c != null) {
                    monthlyDistribution.Media_Order__c = (project.Media_Order__c/project.Days_Running__c * monthlyDistributionLength).setScale(4, System.RoundingMode.HALF_DOWN);
                }
                startDate = monthlyDistribution.End_Date__c.addDays(1);
                monthlyDistributions.add(monthlyDistribution);
            }
        }

        insert monthlyDistributions;
    }
}