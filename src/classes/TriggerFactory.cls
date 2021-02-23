public with sharing class TriggerFactory {
    public static void createHandler(Schema.SObjectType soType) {
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

    private static ITrigger getHandler(Schema.SObjectType soType) {
        if (soType == Opportunity.SObjectType) {
            return new OpportunityHandler();
        }
        if (soType == BillingCondition__c.SObjectType) {
            return new BillingConditionHandler();
        }
        else if (soType == Project__c.SObjectType) {
            return new ProjectHandler();
        }
        else if (soType == Sub_Project__c.SObjectType) {
            return new SubProjectHandler();
        }
        else if (soType == Payment__c.SObjectType) {
            return new PaymentHandler();
        }
        else if (soType == MM_Spendings__c.SObjectType) {
            return new MMSpendingsHandler();
        }
        else if (soType == Account.SObjectType) {
            return new AccountHandler();
        }
        else if (soType == Brand__c.SObjectType) {
            return new BrandHandler();
        }
        else if (soType == Brand_Account__c.SObjectType) {
            return new BrandAccountHandler();
        }
        else if (soType == Contract_Sales_Rep__c.SObjectType) {
            return new ContractSalesRepHandler();
        }
        else if (soType == CreditNote__c.SObjectType) {
            return new CreditNoteHandler();
        }
        else if (soType == MakeGood__c.SObjectType) {
            return new MakeGoodHandler();
        }
        else if (soType == Monthly_Distribution__c.SObjectType) {
            return new MonthlyDistributionHandler();
        }
        else if (soType == OpportunityAdPlacement__c.SObjectType) {
            return new OpportunityAdPlacementHandler();
        }
        else if (soType == OpportunityPlatform__c.SObjectType) {
            return new OpportunityPlatformHandler();
        }
        else if (soType == VideoUrl__c.SObjectType) {
            return new VideoUrlHandler();
        }
        else if (soType == Sales_Rep_MD__c.SObjectType) {
            return new SalesRepMDHandler();
        }
        else if (soType == Invoice__c.SObjectType) {
            return new InvoiceHandler();
        }
        return null;
    }
}