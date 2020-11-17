public class SubProjectEndingBatch implements Schedulable, Database.Batchable<SObject>  {

   public void execute(SchedulableContext sc) {
       Database.executeBatch(new SubProjectEndingBatch(), 200);
   }

    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id, Project__c, Project__r.Contract_Ended__c, Contract_Ended__c FROM Sub_Project__c WHERE Contract_End_Issue__c = true]);
    }

    public void execute(Database.BatchableContext BC, List<Sub_Project__c> scope){
        Set<ID> contractIDs = new Set<Id>();
        for (Sub_Project__c payment: scope) {
            payment.Contract_Ended__c = payment.Project__r.Contract_Ended__c;
            contractIDs.add(payment.Project__c);
        }
        update scope;

        List<Contract_Sales_Rep__c> salesReps = [
            SELECT Commission__c, Expected_commission__c, ExpectedCommission__c, GrossProfitperRep__c, Expected_Gross_Profit_per_Rep__c
            FROM Contract_Sales_Rep__c
            WHERE Contract__c IN :contractIDs AND Commission__c = NULL
                AND Contract__r.Payment_Type__c = '100% Upfront'
                AND Contract__r.InvoicesPaid__c = true
                AND Contract__r.Contract_Ended__c = true
        ];
        ProjectHandler.copySalesRepCommissions(salesReps);
        update salesReps;
    }

    public void finish(Database.BatchableContext BC) {}

}