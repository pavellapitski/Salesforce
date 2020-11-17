/**
 * Created by Pavel Lapitski on 2020-03-25.
 */

public with sharing class BillingConditionHandler implements ITrigger {

    public void bulkBefore() {}

    public void bulkAfter() {}

    public void beforeInsert(List<SObject> so) {}

    public void beforeUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {}

    public void beforeDelete(List<SObject> so) {}

    public void afterInsert(List<SObject> so) {}

    public void afterUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {

        Set<Id> changedBCIds = new Set<Id>();
        for (Id bcId :so.keySet()) {
            BillingCondition__c newBC = (BillingCondition__c) so.get(bcId), oldBC = (BillingCondition__c) oldSo.get(bcId);

            Boolean isRebateChanged = newBC.Rebate_Rate__c != oldBC.Rebate_Rate__c,
                    isRecordTypeChanged = newBC.RecordTypeId != oldBC.RecordTypeId,
                    isStrikeProfitChanged = newBC.Strike_Profit__c != oldBC.Strike_Profit__c,
                    isRebateRateChanged = newBC.Rebate_Rate__c != oldBC.Rebate_Rate__c,
                    isDefaultMarginChanged = newBC.Default_Margin__c != oldBC.Default_Margin__c;

            if (isRebateChanged || isRecordTypeChanged || isStrikeProfitChanged || isDefaultMarginChanged || isRebateRateChanged) {
                changedBCIds.add(bcId);
            }
        }

        // for all active campaigns (contracts) find projects to have invoice amount recalculated
        List<Payment__c> projects = [SELECT Id FROM Payment__c WHERE Project__r.Campaign_Status__c != 'Finished' AND End_Date__c > TODAY AND Payment__r.Checked__c = FALSE AND Project__r.BillingCondition__c IN :changedBCIds];
        update projects;
    }

    public void afterDelete(List<SObject> so) {}

    public void andFinally() {}

}