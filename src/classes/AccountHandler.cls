public with sharing class AccountHandler implements ITrigger {
    public static Id RT_ID_BRAND_DIRECT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Brand Direct').getRecordTypeId();

	public AccountHandler() {}

	public void bulkBefore() {}

    public void bulkAfter() {}

    public void beforeInsert(List<SObject> so) {
    	Map<Id,List<Account>> parentIdToAccounts = new Map<Id,List<Account>>();

    	for (Account acc :(List<Account>) so) {
    		if (String.isBlank(acc.Xero_Id__c) == true && String.isBlank(acc.ParentId) == false) {
    			if (!parentIdToAccounts.containsKey(acc.ParentId)) {
                    parentIdToAccounts.put(acc.ParentId, new List<Account>());
                }
                parentIdToAccounts.get(acc.ParentId).add(acc);
    		}
    	}

    	if (!parentIdToAccounts.isEmpty()) {
    		List<Account> parentAccounts = [SELECT Id, Xero_Id__c, Xero_Entity__c FROM Account WHERE Id IN: parentIdToAccounts.keySet()];
			for (Account parent :parentAccounts) {
				for (Account a :parentIdToAccounts.get(parent.Id)) {
					a.Xero_Id__c = parent.Xero_Id__c;
					a.Xero_Entity__c = parent.Xero_Entity__c;
				}
			}
    	}
    }

    public void beforeUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {
        Map<Id, Account> accounts = (Map<Id, Account>) so;
        Map<Id, Account> oldMap = (Map<Id, Account>) oldSo;
        Map<String, List<Id>> accountXeroId = new Map<String, List<Id>>();
        for (Account acc :accounts.values()) {
            if (String.isNotBlank(acc.Xero_Id__c) && (String.isBlank(acc.XeroObject__c) || acc.Xero_Id__c != oldMap.get(acc.Id).Xero_Id__c)) {
                if (!accountXeroId.containsKey(acc.Xero_Id__c)) {
                    accountXeroId.put(acc.Xero_Id__c, new List<Id>());
                }
                accountXeroId.get(acc.Xero_Id__c).add(acc.Id);
            }
        }
        if (!accountXeroId.isEmpty()) {
            updateXeroObjects(accountXeroId, accounts);
        }
    }

    public void beforeDelete(List<SObject> so) {}

    public void afterInsert(List<SObject> so) {}

    public void afterUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {
        Map<Id,Account> oldAccounts = (Map<Id,Account>) oldSo;
        Set<Id> accountsWithChangedName = new Set<Id>();
        for (Account acc: ((Map<Id,Account>) so).values()) {
            if (acc.Name != oldAccounts.get(acc.Id).Name) {
                accountsWithChangedName.add(acc.Id);
            }
        }

        List<Project__c> contracts = [SELECT Id FROM Project__c WHERE Account__c IN :accountsWithChangedName];
        for(Project__c contract :contracts) {
            contract.PerformMMSync__c=true;
            contract.LastModifiedBy__c = UserInfo.getUserId();
        }
        update contracts;
    }

    public void afterDelete(List<SObject> so) {}

    public void andFinally() {}

    private void updateXeroObjects(Map<String, List<Id>> accountXeroId, Map<Id, Account> accounts) {
        for (XeroEntity__c xeroObject :[SELECT Id, XeroId__c FROM XeroEntity__c WHERE XeroId__c IN :accountXeroId.keySet()]) {
            for (Id accountId :accountXeroId.get(xeroObject.XeroId__c)) {
                accounts.get(accountId).XeroObject__c = xeroObject.Id;
            }
        }
    }
}