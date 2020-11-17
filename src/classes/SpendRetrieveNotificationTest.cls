@isTest
public class SpendRetrieveNotificationTest {

	/*@isTest static void getResponseInvalidError() {
		TestHelper.createAppSettings();
		User usr = TestHelper.createUser();

		Id salesUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales User'].Id;
		Date oppStartDate = Date.newInstance(Date.today().year(), Date.today().addDays(-35).month(), 1);
		Integer endDateDifference = 45;
		BillingCondition__c billingCondition = TestHelper.getBillingCondition('Normal');
		Date firstSpendDate = Date.today().addDays(-4);
		Id clientServicesRepId = [SELECT Id FROM User WHERE Client_Services_Rep__c = true LIMIT 1].Id;

		Platform__c dbmtvPlatform = TestHelper.createPlatform('DBM TrueView', 'DT');
		insert TestHelper.platformsMap.values();

		Integer recordsAmount = 1;
		List<Account> accounts = new List<Account>();
		for (Integer i = 0; i < recordsAmount; i++) {
			accounts.add(TestHelper.createAccount('TestAccount'+i, false));
		}
		insert accounts;

		List<Opportunity> opps = new List<Opportunity>();
		for (Integer i = 0; i < recordsAmount; i++) {
			opps.add(TestHelper.createOpportunity(usr, accounts[i], 'TestOpp'+i, salesUserProfileId, oppStartDate, endDateDifference, billingCondition));
		}
		insert opps;

		List<OpportunityPlatform__c> oppPlatforms = new List<OpportunityPlatform__c>();
		for (Integer i = 0; i < recordsAmount; i++) {
			OpportunityPlatform__c oppPlatform = TestHelper.createOpportunityPlatform(opps[i].Id, dbmtvPlatform);
			oppPlatform.PlatformAccount__c = DBMAPIMockResponse.ADVERTISERID + i;
			oppPlatforms.add(oppPlatform);
		}
		insert oppPlatforms;

		List<Project__c> contracts = new List<Project__c>();
		for (Integer i = 0; i < recordsAmount; i++) {
			Project__c contract = TestHelper.createContractNoInsert(accounts[i].Id, 'TestContract'+i, opps[i].Id);
			contract.Start_Date__c = Date.valueOf(firstSpendDate.year() + '-' + firstSpendDate.month() + '-01');
			contract.End_Date__c = contract.Start_Date__c.addDays(28); // simplify test for having one month for contract
			contract.SpendRefreshDate__c = contract.Start_Date__c;
			contract.ClientServicesRep__c = clientServicesRepId;
			contract.Platforms__c = dbmtvPlatform.Name;

			contracts.add(contract);
		}
		insert contracts;

		System.assertEquals(recordsAmount, [SELECT COUNT() FROM Project__c WHERE Opportunity__c IN :opps], 'There should be only ' + recordsAmount + ' contracts!');

		List<Payment__c> projects = [SELECT Id, PlatformPrefixText__c, StrikeId__c FROM Payment__c WHERE Project__c IN :contracts];
		for (Payment__c project :projects) {
			System.assertEquals(dbmtvPlatform.Prefix__c, project.PlatformPrefixText__c);
		}

		Integer monthBetween = contracts[0].Start_Date__c.monthsBetween(contracts[0].End_Date__c);
		System.assertEquals(recordsAmount * (monthBetween + 1), projects.size());
		System.assertEquals([SELECT COUNT() FROM MM_Spendings__c WHERE Contract__c IN :contracts], 0, 'No Spends should exist');

		for (Integer i = 0; i < recordsAmount; i++) {
			String advertiserId = DBMAPIMockResponse.ADVERTISERID + i;
			String customResponse = '[{"request_token_id":"e4b9ef938042d49c8f3db1e8b20bce36","metrics":[]}]';
			DBMAPIMockResponse.BATCH_RESPONSE.put(advertiserId, customResponse);
		}

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, DBMAPIMockResponse.getInstance());
		DBMSpendContractRetrieveBatch retrieveBatch = new DBMSpendContractRetrieveBatch();
		Database.executeBatch(retrieveBatch, recordsAmount);
		Test.stopTest();

		System.assertEquals(1, SpendRetrieveNotification.errorsMap.size(), 'Error should be thrown');
		if (SpendRetrieveNotification.errorsMap.size() == 1) {
			String firstMapKey = (new List<String>(SpendRetrieveNotification.errorsMap.keySet()))[0];
			List<String> errorsList = SpendRetrieveNotification.errorsMap.get(firstMapKey);
			for (String error :errorsList) {
				Boolean isErrorFound = false;
				for (Project__c contract :contracts) {
					isErrorFound |= error.contains(SpendRetrieveNotification.getContractLink(contract.Id));
				}
				System.assertEquals(isErrorFound, true, 'An error should contain Contact Link');
			}
		}
	}*/

	/*@isTest static void getNoDataReceivedError() {
		TestHelper.createAppSettings();
		User usr = TestHelper.createUser();

		Id salesUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales User'].Id;
		Date oppStartDate = Date.newInstance(Date.today().year(), Date.today().addDays(-35).month(), 1);
		Integer endDateDifference = 45;
		BillingCondition__c billingCondition = TestHelper.getBillingCondition('Normal');
		Date firstSpendDate = Date.today().addDays(-4);
		Id clientServicesRepId = [SELECT Id FROM User WHERE Client_Services_Rep__c = true LIMIT 1].Id;

		Platform__c dbmtvPlatform = TestHelper.createPlatform('DBM TrueView', 'DT');
		insert TestHelper.platformsMap.values();

		Integer recordsAmount = 1;
		List<Account> accounts = new List<Account>();
		for (Integer i = 0; i < recordsAmount; i++) {
			accounts.add(TestHelper.createAccount('TestAccount'+i, false));
		}
		insert accounts;

		List<Opportunity> opps = new List<Opportunity>();
		for (Integer i = 0; i < recordsAmount; i++) {
			opps.add(TestHelper.createOpportunity(usr, accounts[i], 'TestOpp'+i, salesUserProfileId, oppStartDate, endDateDifference, billingCondition));
		}
		insert opps;

		List<OpportunityPlatform__c> oppPlatforms = new List<OpportunityPlatform__c>();
		for (Integer i = 0; i < recordsAmount; i++) {
			OpportunityPlatform__c oppPlatform = TestHelper.createOpportunityPlatform(opps[i].Id, dbmtvPlatform);
			oppPlatform.PlatformAccount__c = DBMAPIMockResponse.ADVERTISERID + i;
			oppPlatforms.add(oppPlatform);
		}
		insert oppPlatforms;

		List<Project__c> contracts = new List<Project__c>();
		for (Integer i = 0; i < recordsAmount; i++) {
			Project__c contract = TestHelper.createContractNoInsert(accounts[i].Id, 'TestContract'+i, opps[i].Id);
			contract.Start_Date__c = Date.valueOf(firstSpendDate.year() + '-' + firstSpendDate.month() + '-01');
			contract.End_Date__c = contract.Start_Date__c.addDays(28); // simplify test for having one month for contract
			contract.SpendRefreshDate__c = contract.Start_Date__c;
			contract.ClientServicesRep__c = clientServicesRepId;
			contract.Platforms__c = dbmtvPlatform.Name;

			contracts.add(contract);
		}
		insert contracts;

		System.assertEquals(recordsAmount, [SELECT COUNT() FROM Project__c WHERE Opportunity__c IN :opps], 'There should be only ' + recordsAmount + ' contracts!');

		List<Payment__c> projects = [SELECT Id, PlatformPrefixText__c, StrikeId__c FROM Payment__c WHERE Project__c IN :contracts];
		for (Payment__c project :projects) {
			System.assertEquals(dbmtvPlatform.Prefix__c, project.PlatformPrefixText__c);
		}

		Integer monthBetween = contracts[0].Start_Date__c.monthsBetween(contracts[0].End_Date__c);
		System.assertEquals(recordsAmount * (monthBetween + 1), projects.size());
		System.assertEquals([SELECT COUNT() FROM MM_Spendings__c WHERE Contract__c IN :contracts], 0, 'No Spends should exist');

		for (Integer i = 0; i < recordsAmount; i++) {
			String advertiserId = DBMAPIMockResponse.ADVERTISERID + i;
			String customResponse = '[]';
			DBMAPIMockResponse.BATCH_RESPONSE.put(advertiserId, customResponse);
		}

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, DBMAPIMockResponse.getInstance());
		DBMSpendContractRetrieveBatch retrieveBatch = new DBMSpendContractRetrieveBatch();
		Database.executeBatch(retrieveBatch, recordsAmount);
		Test.stopTest();

		System.assertEquals(1, SpendRetrieveNotification.errorsMap.size(), 'Error should be thrown');
		if (SpendRetrieveNotification.errorsMap.size() == 1) {
			String firstMapKey = (new List<String>(SpendRetrieveNotification.errorsMap.keySet()))[0];
			System.assert(firstMapKey.contains(SpendRetrieveNotification.ERR_NO_DATA_PATTERN));
			List<String> errorsList = SpendRetrieveNotification.errorsMap.get(firstMapKey);
			for (String error :errorsList) {
				Boolean isErrorFound = false;
				for (Project__c contract :contracts) {
					isErrorFound |= error.contains(SpendRetrieveNotification.getContractLink(contract.Id));
				}
				System.assertEquals(isErrorFound, true, 'An error should contain Contact Link');
			}
		}
	}*/

	/*@isTest static void getCurrencyDifferenceError() {
		TestHelper.createAppSettings();
		User usr = TestHelper.createUser();

		Id salesUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales User'].Id;
		Date oppStartDate = Date.newInstance(Date.today().year(), Date.today().addDays(-35).month(), 1);
		Integer endDateDifference = 45;
		BillingCondition__c billingCondition = TestHelper.getBillingCondition('Normal');
		Date firstSpendDate = Date.today().addDays(-4);
		Id clientServicesRepId = [SELECT Id FROM User WHERE Client_Services_Rep__c = true LIMIT 1].Id;

		Platform__c dbmtvPlatform = TestHelper.createPlatform('DBM TrueView', 'DT');
		insert TestHelper.platformsMap.values();

		Integer recordsAmount = 5;
		List<Account> accounts = new List<Account>();
		for (Integer i = 0; i < recordsAmount; i++) {
			accounts.add(TestHelper.createAccount('TestAccount'+i, false));
		}
		insert accounts;

		List<Opportunity> opps = new List<Opportunity>();
		for (Integer i = 0; i < recordsAmount; i++) {
			opps.add(TestHelper.createOpportunity(usr, accounts[i], 'TestOpp'+i, salesUserProfileId, oppStartDate, endDateDifference, billingCondition));
		}
		insert opps;

		List<OpportunityPlatform__c> oppPlatforms = new List<OpportunityPlatform__c>();
		for (Integer i = 0; i < recordsAmount; i++) {
			OpportunityPlatform__c oppPlatform = TestHelper.createOpportunityPlatform(opps[i].Id, dbmtvPlatform);
			oppPlatform.PlatformAccount__c = DBMAPIMockResponse.ADVERTISERID + i;
			oppPlatforms.add(oppPlatform);
		}
		insert oppPlatforms;

		List<Project__c> contracts = new List<Project__c>();
		for (Integer i = 0; i < recordsAmount; i++) {
			Project__c contract = TestHelper.createContractNoInsert(accounts[i].Id, 'TestContract'+i, opps[i].Id);
			contract.Start_Date__c = Date.valueOf(firstSpendDate.year() + '-' + firstSpendDate.month() + '-01');
			contract.End_Date__c = contract.Start_Date__c.addDays(28); // simplify test for having one month for contract
			contract.SpendRefreshDate__c = contract.Start_Date__c;
			contract.ClientServicesRep__c = clientServicesRepId;
			contract.Platforms__c = dbmtvPlatform.Name;
			contract.CurrencyIsoCode = 'EUR';

			contracts.add(contract);
		}
		insert contracts;

		System.assertEquals(recordsAmount, [SELECT COUNT() FROM Project__c WHERE Opportunity__c IN :opps], 'There should be only ' + recordsAmount + ' contracts!');

		List<Payment__c> projects = [SELECT Id, PlatformPrefixText__c, StrikeId__c FROM Payment__c WHERE Project__c IN :contracts];
		for (Payment__c project :projects) {
			System.assertEquals(dbmtvPlatform.Prefix__c, project.PlatformPrefixText__c);
		}

		Integer monthBetween = contracts[0].Start_Date__c.monthsBetween(contracts[0].End_Date__c);
		System.assertEquals(recordsAmount * (monthBetween + 1), projects.size());
		System.assertEquals([SELECT COUNT() FROM MM_Spendings__c WHERE Contract__c IN :contracts], 0, 'No Spends should exist');

		for (Integer i = 0; i < recordsAmount; i++) {
			String advertiserId = DBMAPIMockResponse.ADVERTISERID + i;
			String customResponse = '[{' +
					'"impressions":3,' +
					'"views":0,' +
					'"clicks":0,' +
					'"engagements":0,' +
					'"spend":0.0,' +
					'"currency":"USD",' +
					'"cost_structure":"CPV",' +
					'"start_date":"' + parseDate(firstSpendDate) + '",' +
					'"end_date":"' + parseDate(firstSpendDate.addDays(10)) + '",' +
					'"delivered":0,' +
					'"advertiser_id":' + advertiserId + ',' +
					'"date":"' + parseDate(firstSpendDate) + '",' +
					'"signature":"[' + projects[i].StrikeId__c + ' - ' + Date.today().year() + '.' + Date.today().month() + '.21 - '+ Date.today().year() + '.' + Date.today().month() + '.31]",' +
					'"project_id":"' + projects[i].StrikeId__c + '"' +
					'}]';
			DBMAPIMockResponse.BATCH_RESPONSE.put(advertiserId, customResponse);
		}

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, DBMAPIMockResponse.getInstance());
		DBMSpendContractRetrieveBatch retrieveBatch = new DBMSpendContractRetrieveBatch();
		Database.executeBatch(retrieveBatch, recordsAmount);
		Test.stopTest();

		System.assertEquals(1, SpendRetrieveNotification.errorsMap.size(), 'Error should be thrown');
		if (SpendRetrieveNotification.errorsMap.size() == 1) {
			String firstMapKey = (new List<String>(SpendRetrieveNotification.errorsMap.keySet()))[0];
			System.assert(firstMapKey.contains(MMSpendingsRepository.CURR_ERR));
			List<String> errorsList = SpendRetrieveNotification.errorsMap.get(firstMapKey);
			for (String error :errorsList) {
				Boolean isErrorFound = false;
				for (Project__c contract :contracts) {
					isErrorFound |= error.contains(contract.Name);

				}
				System.assertEquals(isErrorFound, true, 'An error should contain information about Contact.');

				isErrorFound = false;
				for (Project__c contract :contracts) {
					isErrorFound |= error.contains(SpendRetrieveNotification.getContractLink(contract.Id));
				}
				System.assertEquals(isErrorFound, true, 'An error should contain Contact Link.');

				isErrorFound = false;
				for (Project__c contract :contracts) {
					isErrorFound |= error.contains(Contract.CurrencyIsoCode);
				}
				System.assertEquals(isErrorFound, true, 'An error should contain Contact CurrencyISOCode.');
			}
		}
	}*/

	/*@isTest static void getContractNotFoundError() {
		TestHelper.createAppSettings();
		User usr = TestHelper.createUser();

		Id salesUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales User'].Id;
		Date oppStartDate = Date.newInstance(Date.today().year(), Date.today().addDays(-35).month(), 1);
		Integer endDateDifference = 45;
		BillingCondition__c billingCondition = TestHelper.getBillingCondition('Normal');
		Date firstSpendDate = Date.today().addDays(-4);
		Id clientServicesRepId = [SELECT Id FROM User WHERE Client_Services_Rep__c = true LIMIT 1].Id;

		Platform__c dbmtvPlatform = TestHelper.createPlatform('DBM TrueView', 'DT');
		insert TestHelper.platformsMap.values();

		Integer recordsAmount = 5;
		List<Account> accounts = new List<Account>();
		for (Integer i = 0; i < recordsAmount; i++) {
			accounts.add(TestHelper.createAccount('TestAccount'+i, false));
		}
		insert accounts;

		List<Opportunity> opps = new List<Opportunity>();
		for (Integer i = 0; i < recordsAmount; i++) {
			opps.add(TestHelper.createOpportunity(usr, accounts[i], 'TestOpp'+i, salesUserProfileId, oppStartDate, endDateDifference, billingCondition));
		}
		insert opps;

		List<OpportunityPlatform__c> oppPlatforms = new List<OpportunityPlatform__c>();
		for (Integer i = 0; i < recordsAmount; i++) {
			OpportunityPlatform__c oppPlatform = TestHelper.createOpportunityPlatform(opps[i].Id, dbmtvPlatform);
			oppPlatform.PlatformAccount__c = DBMAPIMockResponse.ADVERTISERID + i;
			oppPlatforms.add(oppPlatform);
		}
		insert oppPlatforms;

		List<Project__c> contracts = new List<Project__c>();
		for (Integer i = 0; i < recordsAmount; i++) {
			Project__c contract = TestHelper.createContractNoInsert(accounts[i].Id, 'TestContract'+i, opps[i].Id);
			contract.Start_Date__c = Date.valueOf(firstSpendDate.year() + '-' + firstSpendDate.month() + '-01');
			contract.End_Date__c = contract.Start_Date__c.addDays(28); // simplify test for having one month for contract
			contract.SpendRefreshDate__c = contract.Start_Date__c;
			contract.ClientServicesRep__c = clientServicesRepId;
			contract.Platforms__c = dbmtvPlatform.Name;
			contract.CurrencyIsoCode = 'EUR';

			contracts.add(contract);
		}
		insert contracts;

		System.assertEquals(recordsAmount, [SELECT COUNT() FROM Project__c WHERE Opportunity__c IN :opps], 'There should be only ' + recordsAmount + ' contracts!');

		List<Payment__c> projects = [SELECT Id, PlatformPrefixText__c, StrikeId__c FROM Payment__c WHERE Project__c IN :contracts];
		for (Payment__c project :projects) {
			System.assertEquals(dbmtvPlatform.Prefix__c, project.PlatformPrefixText__c);
		}

		Integer monthBetween = contracts[0].Start_Date__c.monthsBetween(contracts[0].End_Date__c);
		System.assertEquals(recordsAmount * (monthBetween + 1), projects.size());
		System.assertEquals([SELECT COUNT() FROM MM_Spendings__c WHERE Contract__c IN :contracts], 0, 'No Spends should exist');

		for (Integer i = 0; i < recordsAmount; i++) {
			String advertiserId = DBMAPIMockResponse.ADVERTISERID + i;
			String projectIdNotExisting = projects[i].StrikeId__c + i;
			String customResponse = '[{' +
					'"impressions":3,' +
					'"views":0,' +
					'"clicks":0,' +
					'"engagements":0,' +
					'"spend":0.0,' +
					'"currency":"USD",' +
					'"cost_structure":"CPV",' +
					'"start_date":"' + parseDate(firstSpendDate) + '",' +
					'"end_date":"' + parseDate(firstSpendDate.addDays(10)) + '",' +
					'"delivered":0,' +
					'"advertiser_id":' + advertiserId + ',' +
					'"date":"' + parseDate(firstSpendDate) + '",' +
					'"signature":"[' + projectIdNotExisting + ' - ' + Date.today().year() + '.' + Date.today().month() + '.21 - '+ Date.today().year() + '.' + Date.today().month() + '.31]",' +
					'"project_id":"' + projectIdNotExisting + '"' +
					'}]';
			DBMAPIMockResponse.BATCH_RESPONSE.put(advertiserId, customResponse);
		}

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, DBMAPIMockResponse.getInstance());
		DBMSpendContractRetrieveBatch retrieveBatch = new DBMSpendContractRetrieveBatch();
		Database.executeBatch(retrieveBatch, recordsAmount);
		Test.stopTest();

		System.assertEquals(1, SpendRetrieveNotification.errorsMap.size(), 'Error should be thrown');
		if (SpendRetrieveNotification.errorsMap.size() == 1) {
			String firstMapKey = (new List<String>(SpendRetrieveNotification.errorsMap.keySet()))[0];
			System.assert(firstMapKey.contains(MMSpendingsRepository.NO_CONTRACT));
			List<String> errorsList = SpendRetrieveNotification.errorsMap.get(firstMapKey);
			for (String error :errorsList) {
				Boolean isErrorFound = false;
				for (Payment__c project :projects) {
					isErrorFound |= error.contains(project.StrikeId__c);
				}
				System.assertEquals(isErrorFound, true, 'An error should contain information about Contact Name.');
			}
		}
	}*/

	/*@isTest static void getAccountDifferenceError() {
		TestHelper.createAppSettings();
		User usr = TestHelper.createUser();

		Id salesUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales User'].Id;
		Date oppStartDate = Date.newInstance(Date.today().year(), Date.today().addDays(-35).month(), 1);
		Integer endDateDifference = 45;
		BillingCondition__c billingCondition = TestHelper.getBillingCondition('Normal');
		Date firstSpendDate = Date.today().addDays(-4);
		Id clientServicesRepId = [SELECT Id FROM User WHERE Client_Services_Rep__c = true LIMIT 1].Id;

		Platform__c dbmtvPlatform = TestHelper.createPlatform('DBM TrueView', 'DT');
		insert TestHelper.platformsMap.values();

		Integer recordsAmount = 5;
		List<Account> accounts = new List<Account>();
		for (Integer i = 0; i < recordsAmount; i++) {
			accounts.add(TestHelper.createAccount('TestAccount'+i, false));
		}
		insert accounts;

		List<Opportunity> opps = new List<Opportunity>();
		for (Integer i = 0; i < recordsAmount; i++) {
			opps.add(TestHelper.createOpportunity(usr, accounts[i], 'TestOpp'+i, salesUserProfileId, oppStartDate, endDateDifference, billingCondition));
		}
		insert opps;

		List<OpportunityPlatform__c> oppPlatforms = new List<OpportunityPlatform__c>();
		for (Integer i = 0; i < recordsAmount; i++) {
			OpportunityPlatform__c oppPlatform = TestHelper.createOpportunityPlatform(opps[i].Id, dbmtvPlatform);
			oppPlatform.PlatformAccount__c = DBMAPIMockResponse.ADVERTISERID + i;
			oppPlatforms.add(oppPlatform);
		}
		insert oppPlatforms;

		List<Project__c> contracts = new List<Project__c>();
		for (Integer i = 0; i < recordsAmount; i++) {
			Project__c contract = TestHelper.createContractNoInsert(accounts[i].Id, 'TestContract'+i, opps[i].Id);
			contract.Start_Date__c = Date.valueOf(firstSpendDate.year() + '-' + firstSpendDate.month() + '-01');
			contract.End_Date__c = contract.Start_Date__c.addDays(28); // simplify test for having one month for contract
			contract.SpendRefreshDate__c = contract.Start_Date__c;
			contract.ClientServicesRep__c = clientServicesRepId;
			contract.Platforms__c = dbmtvPlatform.Name;
			contract.CurrencyIsoCode = 'USD';

			contracts.add(contract);
		}
		insert contracts;

		System.assertEquals(recordsAmount, [SELECT COUNT() FROM Project__c WHERE Opportunity__c IN :opps], 'There should be only ' + recordsAmount + ' contracts!');

		List<Payment__c> projects = [SELECT Id, PlatformPrefixText__c, StrikeId__c FROM Payment__c WHERE Project__c IN :contracts];
		for (Payment__c project :projects) {
			System.assertEquals(dbmtvPlatform.Prefix__c, project.PlatformPrefixText__c);
		}

		Integer monthBetween = contracts[0].Start_Date__c.monthsBetween(contracts[0].End_Date__c);
		System.assertEquals(recordsAmount * (monthBetween + 1), projects.size());
		System.assertEquals([SELECT COUNT() FROM MM_Spendings__c WHERE Contract__c IN :contracts], 0, 'No Spends should exist');

		for (Integer i = 0; i < recordsAmount; i++) {
			Integer incIndex = i + 10;
			String advertiserIdNonExisting = DBMAPIMockResponse.ADVERTISERID + incIndex;
			String advertiserId = DBMAPIMockResponse.ADVERTISERID + i;
			String projectId = projects[i].StrikeId__c;
			String customResponse = '[{' +
					'"impressions":3,' +
					'"views":0,' +
					'"clicks":0,' +
					'"engagements":0,' +
					'"spend":0.0,' +
					'"currency":"USD",' +
					'"cost_structure":"CPV",' +
					'"start_date":"' + parseDate(firstSpendDate) + '",' +
					'"end_date":"' + parseDate(firstSpendDate.addDays(10)) + '",' +
					'"delivered":0,' +
					'"advertiser_id":' + advertiserIdNonExisting + ',' +
					'"date":"' + parseDate(firstSpendDate) + '",' +
					'"signature":"[' + projectId + ' - ' + Date.today().year() + '.' + Date.today().month() + '.21 - '+ Date.today().year() + '.' + Date.today().month() + '.31]",' +
					'"project_id":"' + projectId + '"' +
				'}]';
			DBMAPIMockResponse.BATCH_RESPONSE.put(advertiserId, customResponse);
		}

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, DBMAPIMockResponse.getInstance());
		DBMSpendContractRetrieveBatch retrieveBatch = new DBMSpendContractRetrieveBatch();
		Database.executeBatch(retrieveBatch, recordsAmount);
		Test.stopTest();

		System.assertEquals(1, SpendRetrieveNotification.errorsMap.size(), 'Error should be thrown');
		if (SpendRetrieveNotification.errorsMap.size() == 1) {
			String firstMapKey = (new List<String>(SpendRetrieveNotification.errorsMap.keySet()))[0];
			System.assert(firstMapKey.contains(MMSpendingsRepository.DBM_ACCOUNT_ERR));
			List<String> errorsList = SpendRetrieveNotification.errorsMap.get(firstMapKey);
			for (String error :errorsList) {
				Boolean isErrorFound = false;
				for (Payment__c project :projects) {
					isErrorFound |= error.contains(project.StrikeId__c);
				}
				System.assertEquals(isErrorFound, true, 'An error should contain information about Contact Name.');

				isErrorFound = false;
				Integer i = 0;
				for (Payment__c project :projects) {
					Integer incIndex = i + 10;
					String advertiserIdNonExisting = DBMAPIMockResponse.ADVERTISERID + incIndex;
					isErrorFound |= error.contains(advertiserIdNonExisting);
					i++;
				}
				System.assertEquals(isErrorFound, true, 'An error should contain information about account that doesn\'t exist.');

				isErrorFound = false;
				i = 0;
				for (Payment__c project :projects) {
					String advertiserIdReal = DBMAPIMockResponse.ADVERTISERID + i;
					isErrorFound |= error.contains(advertiserIdReal);
					i++;
				}
				System.assertEquals(isErrorFound, true, 'An error should contain information about account that exists.');
			}
		}
	}*/

}