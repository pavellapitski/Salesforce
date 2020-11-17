public with sharing class TriggerFactory {
    public static void createHandler(Schema.sObjectType soType) {
        ITrigger handler = getHandler(soType);
        if (handler == null) {
            throw new TriggerException('No Trigger Handler registered for Object Type: ' + soType);
        }
        execute(handler);
    }

    private static void execute(ITrigger handler) {
        switch on Trigger.operationType {
            when BEFORE_INSERT{
                handler.bulkBefore();
                handler.beforeInsert(Trigger.new);
            }
            when BEFORE_UPDATE {
                handler.bulkBefore();
                handler.beforeUpdate(Trigger.oldMap, Trigger.newMap);
            }
            when BEFORE_DELETE {
                handler.bulkBefore();
                handler.beforeDelete(Trigger.old);
            }
            when AFTER_INSERT{
                handler.bulkAfter();
                handler.afterInsert(Trigger.new);
            }
            when AFTER_UPDATE {
                handler.bulkAfter();
                handler.afterUpdate(Trigger.oldMap, Trigger.newMap);
            }
            when AFTER_DELETE {
                handler.bulkAfter();
                handler.afterDelete(Trigger.old);
            }
            when else {
            //do nothing for AFTER_UNDELETE, BEFORE_UNDELETE
            }
        }
        handler.andFinally();
    }

    private static ITrigger getHandler(Schema.sObjectType soType) {
        if (soType == Opportunity.sObjectType) {
            return new OpportunityHandler();
        }
        if (soType == BillingCondition__c.sObjectType) {
            return new BillingConditionHandler();
        }
        else if (soType == Project__c.sObjectType) {
            return new ProjectHandler();
        }
        else if (soType == Sub_Project__c.sObjectType) {
            return new SubProjectHandler();
        }
        else if (soType == Payment__c.sObjectType) {
            return new PaymentHandler();
        }
        else if (soType == MM_Spendings__c.sObjectType) {
            return new MMSpendingsHandler();
        }
        else if (soType == Account.sObjectType) {
            return new AccountHandler();
        }
        else if (soType == Brand__c.sObjectType) {
            return new BrandHandler();
        }
        else if (soType == Brand_Account__c.sObjectType) {
            return new BrandAccountHandler();
        }
        else if (soType == Contract_Sales_Rep__c.sObjectType) {
            return new ContractSalesRepHandler();
        }
        else if (soType == CreditNote__c.sObjectType) {
            return new CreditNoteHandler();
        }
        else if (soType == MakeGood__c.sObjectType) {
            return new MakeGoodHandler();
        }
        else if (soType == Monthly_Distribution__c.sObjectType) {
            return new MonthlyDistributionHandler();
        }
        else if (soType == OpportunityAdPlacement__c.sObjectType) {
            return new OpportunityAdPlacementHandler();
        }
        else if (soType == OpportunityPlatform__c.sObjectType) {
            return new OpportunityPlatformHandler();
        }
        else if (soType == VideoUrl__c.sObjectType) {
            return new VideoUrlHandler();
        }
        else if (soType == Sales_Rep_MD__c.sObjectType) {
            return new SalesRepMDHandler();
        }
        return null;
    }
}