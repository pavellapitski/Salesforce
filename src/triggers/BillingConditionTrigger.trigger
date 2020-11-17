/**
 * Created by Pavel Lapitski on 2020-03-25.
 */

trigger BillingConditionTrigger on BillingCondition__c (after update) {

    TriggerFactory.createHandler(BillingCondition__c.sObjectType);
}