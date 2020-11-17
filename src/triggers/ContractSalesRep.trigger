trigger ContractSalesRep on Contract_Sales_Rep__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

	if(Label.TRIGGER_SWITCH_ContractSalesRep==Utility.TRIGGER_ON) {        
    	TriggerFactory.createHandler(Contract_Sales_Rep__c.sObjectType);
    }
}