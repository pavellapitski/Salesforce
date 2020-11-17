/**
 * Created by Pavel Lapitski on 2019-11-05.
 */

@IsTest
private class SpendRetrieveTest {

    private static final Datetime dt = Datetime.now().addSeconds(5);
    private static final String CRON_EXP = dt.second() + ' ' + dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();

    @IsTest static void assignSpendsAdWords() {
        TestHelper.createAppSettings();

        Date sDate = Date.valueOf(Date.today().year() + '-' + Date.today().addMonths(-1).month() + '-01'),
                eDate = sDate.addDays(70);

        Platform__c adWordsPlatform = TestHelper.createTrueViewPlatform();
        insert adWordsPlatform;

        TestHelper.createOpportunity(sDate, eDate, adWordsPlatform, Utility.BILLING_PROFILES.Strike, false);
        insert TestHelper.opportunityRecord;

        OpportunityPlatform__c opPlatform = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, adWordsPlatform);
        opPlatform.PlatformAccount__c = StrikeDataAPIMock.accountId;
        insert opPlatform;

        Project__c contract = TestHelper.createContract('Test Contract', sDate, eDate, false);
        contract.SpendRefreshDate__c = null;
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = TRUE LIMIT 1].Id;
        contract.CurrencyIsoCode = 'AUD';
        insert contract;

        List<Payment__c> projects = [SELECT StrikeId__c, Start_Date__c, End_Date__c FROM Payment__c WHERE Project__c = :contract.Id];
        String projectName = '';
        for (Payment__c project :projects) {
            projectName = project.StrikeId__c;
        }

        Test.startTest();
        StrikeDataAPIMock.setRandomMetrics = true;
        StrikeDataAPIMock.projectNames = new List<String>{projectName};
        StrikeDataAPIMock.accountIDs = new List<String>{StrikeDataAPIMock.accountId};

        Test.setMock(HttpCalloutMock.class, new StrikeDataAPIMock(StrikeDataAPI.PackageType.ADWORDS));
        String jobId = System.schedule('ScheduledApexTest', CRON_EXP, new SpendRetrieve(StrikeDataAPI.PackageType.ADWORDS));
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);

        SpendRetrieve.run(StrikeDataAPI.PackageType.ADWORDS.name());
        System.assertEquals([SELECT COUNT() FROM MM_Spendings__c WHERE Contract__c = :contract.Id], 0, 'Zero MM_Spending__c records should exist.');
        Test.stopTest();
        System.assertEquals([SELECT COUNT() FROM MM_Spendings__c WHERE Contract__c = :contract.Id], StrikeDataAPIMock.amountRecordsInResponseForJobCallPerPlatformName);
    }

    @IsTest static void assignSpendsAdWordsNotFound() {
        TestHelper.createAppSettings();

        Date sDate = Date.valueOf(Date.today().year() + '-' + Date.today().addMonths(-1).month() + '-01'),
                eDate = sDate.addDays(70);

        Platform__c adWordsPlatform = TestHelper.createTrueViewPlatform();
        insert adWordsPlatform;

        TestHelper.createOpportunity(sDate, eDate, adWordsPlatform, Utility.BILLING_PROFILES.Strike, false);
        insert TestHelper.opportunityRecord;

        OpportunityPlatform__c opPlatform = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, adWordsPlatform);
        opPlatform.PlatformAccount__c = StrikeDataAPIMock.accountId;
        insert opPlatform;

        Project__c contract = TestHelper.createContract('Test Contract', sDate, eDate, false);
        contract.SpendRefreshDate__c = null;
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = TRUE LIMIT 1].Id;
        insert contract;

        Test.startTest();
        StrikeDataAPIMock.setRandomMetrics = true;

        Test.setMock(HttpCalloutMock.class, new StrikeDataAPIMock(StrikeDataAPI.PackageType.ADWORDS));
        System.schedule('ScheduledApexTest', CRON_EXP, new SpendRetrieve(StrikeDataAPI.PackageType.ADWORDS));
        System.assertEquals([SELECT COUNT() FROM MM_Spendings__c WHERE Contract__c = :contract.Id], 0, 'Zero MM_Spending__c records should exist.');
        SpendRetrieve.run(StrikeDataAPI.PackageType.ADWORDS.name());

        Test.stopTest();

        System.assertEquals(SpendRetrieveNotification.errorsMap.containsKey(SpendManager.ERROR_NAME_NOT_FOUND), true);
        System.assertEquals(SpendRetrieveNotification.errorsMap.get(SpendManager.ERROR_NAME_NOT_FOUND).size(), StrikeDataAPIMock.projectNames.size());
        System.assertEquals([SELECT COUNT() FROM MM_Spendings__c WHERE Contract__c = :contract.Id], 0, 'No metrics assigned to contract.');
    }

    @IsTest static void assignSpendsAdWordsAccountNotMatched() {
        TestHelper.createAppSettings();

        Date sDate = Date.valueOf(Date.today().year() + '-' + Date.today().addMonths(-1).month() + '-01'),
                eDate = sDate.addDays(70);

        Platform__c adWordsPlatform = TestHelper.createTrueViewPlatform();
        insert adWordsPlatform;

        TestHelper.createOpportunity(sDate, eDate, adWordsPlatform, Utility.BILLING_PROFILES.Strike, false);
        insert TestHelper.opportunityRecord;

        OpportunityPlatform__c opPlatform = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, adWordsPlatform);
        opPlatform.PlatformAccount__c = StrikeDataAPIMock.accountId;
        insert opPlatform;

        Project__c contract = TestHelper.createContract('Test Contract', sDate, eDate, false);
        contract.SpendRefreshDate__c = null;
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = TRUE LIMIT 1].Id;
        contract.CurrencyIsoCode = 'AUD';
        insert contract;

        List<Payment__c> projects = [SELECT StrikeId__c, Start_Date__c, End_Date__c FROM Payment__c WHERE Project__c = :contract.Id];
        String projectName = '';
        for (Payment__c project :projects) {
            projectName = project.StrikeId__c;
        }

        Test.startTest();
        System.assertEquals([SELECT COUNT() FROM MM_Spendings__c WHERE Contract__c = :contract.Id], 0, 'Zero MM_Spending__c records should exist.');

        StrikeDataAPIMock.setRandomMetrics = true;
        StrikeDataAPIMock.projectNames = new List<String>{projectName};
        StrikeDataAPIMock.accountIDs = new List<String>{'111-111-1111'};

        Test.setMock(HttpCalloutMock.class, new StrikeDataAPIMock(StrikeDataAPI.PackageType.ADWORDS));
        System.schedule('ScheduledApexTest', CRON_EXP, new SpendRetrieve(StrikeDataAPI.PackageType.ADWORDS));
        SpendRetrieve.run(StrikeDataAPI.PackageType.ADWORDS.name());
        System.assertEquals([SELECT COUNT() FROM MM_Spendings__c WHERE Contract__c = :contract.Id], 0, 'Zero MM_Spending__c records should exist.');
        Test.stopTest();

        System.assertEquals(SpendRetrieveNotification.errorsMap.containsKey(SpendManager.ERROR_DIFFERENT_ACCOUNT), true);
        System.assertEquals(SpendRetrieveNotification.errorsMap.get(SpendManager.ERROR_DIFFERENT_ACCOUNT).size(), StrikeDataAPIMock.projectNames.size());
        System.assertEquals([SELECT COUNT() FROM MM_Spendings__c WHERE Contract__c = :contract.Id], 0, 'No metrics assigned to contract.');
    }

    @IsTest static void assignSpendsAdWordsDifferentCurrency() {
        TestHelper.createAppSettings();

        Date sDate = Date.valueOf(Date.today().year() + '-' + Date.today().addMonths(-1).month() + '-01'),
                eDate = sDate.addDays(70);

        Platform__c adWordsPlatform = TestHelper.createTrueViewPlatform();
        insert adWordsPlatform;

        TestHelper.createOpportunity(sDate, eDate, adWordsPlatform, Utility.BILLING_PROFILES.Strike, false);
        insert TestHelper.opportunityRecord;

        OpportunityPlatform__c opPlatform = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, adWordsPlatform);
        opPlatform.PlatformAccount__c = StrikeDataAPIMock.accountId;
        insert opPlatform;

        Project__c contract = TestHelper.createContract('Test Contract', sDate, eDate, false);
        contract.SpendRefreshDate__c = null;
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = TRUE LIMIT 1].Id;
        contract.CurrencyIsoCode = 'EUR';
        insert contract;

        List<Payment__c> projects = [SELECT StrikeId__c, Start_Date__c, End_Date__c FROM Payment__c WHERE Project__c = :contract.Id];
        String projectName = '';
        for (Payment__c project :projects) {
            projectName = project.StrikeId__c;
        }

        Test.startTest();
        System.assertEquals([SELECT COUNT() FROM MM_Spendings__c WHERE Contract__c = :contract.Id], 0, 'Zero MM_Spending__c records should exist.');

        StrikeDataAPIMock.setRandomMetrics = true;
        StrikeDataAPIMock.projectNames = new List<String>{projectName};
        StrikeDataAPIMock.accountIDs = new List<String>{StrikeDataAPIMock.accountId};

        Test.setMock(HttpCalloutMock.class, new StrikeDataAPIMock(StrikeDataAPI.PackageType.ADWORDS));
        System.schedule('ScheduledApexTest', CRON_EXP, new SpendRetrieve(StrikeDataAPI.PackageType.ADWORDS));
        SpendRetrieve.run(StrikeDataAPI.PackageType.ADWORDS.name());
        System.assertEquals([SELECT COUNT() FROM MM_Spendings__c WHERE Contract__c = :contract.Id], 0, 'Zero MM_Spending__c records should exist.');
        Test.stopTest();

        System.assertEquals(SpendRetrieveNotification.errorsMap.containsKey(SpendManager.ERROR_DIFFERENT_CURRENCY), true);
        System.assertEquals(SpendRetrieveNotification.errorsMap.get(SpendManager.ERROR_DIFFERENT_CURRENCY).size(), StrikeDataAPIMock.projectNames.size());
        System.assertEquals([SELECT COUNT() FROM MM_Spendings__c WHERE Contract__c = :contract.Id], 0, 'No metrics assigned to contract.');
    }

    @IsTest static void assignSpendsAdWords_MetricsExist_NoMetricsReplaced() {
        TestHelper.createAppSettings();

        Platform__c adWordsPlatform1 = TestHelper.createPlatform('TrueView','AV');
        Platform__c adWordsPlatform2 = TestHelper.createPlatform('TrueView','AD');
        Platform__c adWordsPlatform3 = TestHelper.createPlatform('TrueView', 'TV');
        Platform__c adWordsPlatform4 = TestHelper.createPlatform('TrueView', 'AS');
        insert TestHelper.platformsMap.values();

        Datetime firstSpendDate = Datetime.newInstance(StrikeDataAPIMock.EARLIEST_SPEND_DATE);
        Date sDate = Date.valueOf(firstSpendDate.year() + '-' + firstSpendDate.addMonths(-1).month() + '-01'),
                eDate = sDate.addDays(100);

        TestHelper.createOpportunity(sDate, eDate, adWordsPlatform1, Utility.BILLING_PROFILES.Strike, false);
        insert TestHelper.opportunityRecord;

        OpportunityPlatform__c opPlatform1 = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, adWordsPlatform1);
        opPlatform1.PlatformAccount__c = StrikeDataAPIMock.accountIDs[0];
        OpportunityPlatform__c opPlatform2 = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, adWordsPlatform2);
        opPlatform2.PlatformAccount__c = StrikeDataAPIMock.accountIDs[1];
        OpportunityPlatform__c opPlatform3 = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, adWordsPlatform3);
        opPlatform3.PlatformAccount__c = StrikeDataAPIMock.accountIDs[2];
        OpportunityPlatform__c opPlatform4 = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, adWordsPlatform4);
        opPlatform4.PlatformAccount__c = StrikeDataAPIMock.accountIDs[3];
        insert new List<OpportunityPlatform__c>{opPlatform1, opPlatform2, opPlatform3, opPlatform4};

        Project__c contract = TestHelper.createContract('Test Contract', sDate, eDate, false);
        contract.SpendRefreshDate__c = null;
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = TRUE LIMIT 1].Id;
        contract.CurrencyIsoCode = 'USD';
        insert contract;

        List<Payment__c> projects = [SELECT StrikeId__c, Start_Date__c, End_Date__c, OpportunityPlatform__r.Platform__r.Name, OpportunityPlatform__r.PlatformAccount__c FROM Payment__c WHERE Project__c = :contract.Id ORDER BY StrikeId__c];
        System.assert(projects.size() >= StrikeDataAPIMock.projectNames.size(), 'To make sure that projects amount is enough for "StrikeDataAPIMock.getResponseForNLastDays()".');
        // replace projectNames in Mock Response
        Map<String, String> projectNameToAccountId = new Map<String, String>();
        for (Payment__c project :projects) {
            projectNameToAccountId.put(project.StrikeId__c, project.OpportunityPlatform__r.PlatformAccount__c);
        }
        StrikeDataAPIMock.projectNames = new List<String>(projectNameToAccountId.keySet());
        StrikeDataAPIMock.accountIDs = new List<String>(projectNameToAccountId.values());

        // prepare spendToInsert based on Mock Response we get after a callout
        String metricsJSONToBeRetrieved = StrikeDataAPIMock.getResponseForNLastDays();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(metricsJSONToBeRetrieved);
        List<StrikeDataAPI.SpendInfo> metricsInfo = StrikeDataAPI.mapResponseSpending((List<Object>) response.get('metrics'));
        List<MM_Spendings__c> spendToInsert = new List<MM_Spendings__c>();
        for (StrikeDataAPI.SpendInfo spendInfo :metricsInfo) {
            spendToInsert.add(new MM_Spendings__c(
                StrikeId__c = spendInfo.projectId,
                Media_Spend__c = Decimal.valueOf(spendInfo.spendAmount),
                Delivered__c = Decimal.valueOf(spendInfo.delivered),
                Date__c = Date.valueOf(Datetime.newInstance(Long.valueOf(spendInfo.spendDate))),
                Contract__c = contract.Id,
                Type__c = StrikeDataAPI.PackageType.ADWORDS.name(),
                CurrencyIsoCode = spendInfo.spendCurrency,
                Is_Sync__c = true
            ));
        }
        insert spendToInsert;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StrikeDataAPIMock(StrikeDataAPI.PackageType.ADWORDS));
        String jobId = System.schedule('ScheduledApexTest', CRON_EXP, new SpendRetrieve(StrikeDataAPI.PackageType.ADWORDS));
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);

        SpendRetrieve.run(StrikeDataAPI.PackageType.ADWORDS.name());
        System.assertEquals([SELECT COUNT() FROM MM_Spendings__c WHERE Contract__c = :contract.Id], spendToInsert.size(), spendToInsert.size() + ' MM_Spending__c records should exist.');
        Test.stopTest();

        System.assertEquals(SpendRetrieveNotification.errorsMap.size(), 0, 'No errors should be.');

        Map<Id, MM_Spendings__c> spendToInsertMap = new Map<Id,MM_Spendings__c>(spendToInsert);
        System.debug('### spendToInsertMap: ' + spendToInsertMap.keySet());

        List<MM_Spendings__c> spendsAfterJobRan = [SELECT Id FROM MM_Spendings__c WHERE Contract__c = :contract.Id];
        System.assert(spendsAfterJobRan.size() == spendToInsert.size(), 'Amount of spend records after job ran should stay unchanged.');
        for (MM_Spendings__c spendAfterJobRan :spendsAfterJobRan) {
            System.assert(spendToInsertMap.containsKey(spendAfterJobRan.Id), 'No new spend from retrieved metrics should be added.');
            spendToInsertMap.remove(spendAfterJobRan.Id);
        }
        System.assertEquals(0, spendToInsertMap.size(), 'Amount of existing records before job started should stay unchanged.');
    }

    @IsTest static void assignSpendsAdWords_MetricsExist_ExistingNotDeleted_NewMetricsAdded() {
        TestHelper.createAppSettings();

        Platform__c adWordsPlatform1 = TestHelper.createPlatform('TrueView','AV');
        Platform__c adWordsPlatform2 = TestHelper.createPlatform('TrueView','AD');
        Platform__c adWordsPlatform3 = TestHelper.createPlatform('TrueView', 'TV');
        Platform__c adWordsPlatform4 = TestHelper.createPlatform('TrueView', 'AS');
        insert TestHelper.platformsMap.values();

        Datetime firstSpendDate = Datetime.newInstance(StrikeDataAPIMock.EARLIEST_SPEND_DATE);
        Date sDate = Date.valueOf(firstSpendDate.year() + '-' + firstSpendDate.addMonths(-1).month() + '-01'),
                eDate = sDate.addDays(100);

        TestHelper.createOpportunity(sDate, eDate, adWordsPlatform1, Utility.BILLING_PROFILES.Strike, false);
        insert TestHelper.opportunityRecord;

        OpportunityPlatform__c opPlatform1 = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, adWordsPlatform1);
        opPlatform1.PlatformAccount__c = StrikeDataAPIMock.accountIDs[0];
        OpportunityPlatform__c opPlatform2 = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, adWordsPlatform2);
        opPlatform2.PlatformAccount__c = StrikeDataAPIMock.accountIDs[1];
        OpportunityPlatform__c opPlatform3 = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, adWordsPlatform3);
        opPlatform3.PlatformAccount__c = StrikeDataAPIMock.accountIDs[2];
        OpportunityPlatform__c opPlatform4 = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, adWordsPlatform4);
        opPlatform4.PlatformAccount__c = StrikeDataAPIMock.accountIDs[3];
        insert new List<OpportunityPlatform__c>{opPlatform1, opPlatform2, opPlatform3, opPlatform4};

        Project__c contract = TestHelper.createContract('Test Contract', sDate, eDate, false);
        contract.SpendRefreshDate__c = null;
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = TRUE LIMIT 1].Id;
        contract.CurrencyIsoCode = 'USD';
        insert contract;

        List<Payment__c> projects = [SELECT StrikeId__c, Start_Date__c, End_Date__c, OpportunityPlatform__r.Platform__r.Name, OpportunityPlatform__r.PlatformAccount__c FROM Payment__c WHERE Project__c = :contract.Id ORDER BY StrikeId__c];
        System.assert(projects.size() >= StrikeDataAPIMock.projectNames.size(), 'To make sure that projects amount is enough for "StrikeDataAPIMock.getResponseForNLastDays()".');
        // replace projectNames in Mock Response
        Map<String, String> projectNameToAccountId = new Map<String, String>();
        for (Payment__c project :projects) {
            projectNameToAccountId.put(project.StrikeId__c, project.OpportunityPlatform__r.PlatformAccount__c);
        }
        StrikeDataAPIMock.projectNames = new List<String>(projectNameToAccountId.keySet());
        StrikeDataAPIMock.accountIDs = new List<String>(projectNameToAccountId.values());

        List<MM_Spendings__c> spendToInsert = new List<MM_Spendings__c>();
        Integer existingSpendAmount = 10;
        for (Integer i = 0; i < existingSpendAmount; i++) {
            Decimal randomDeliveredAmount = ((Decimal)(100000*Math.random()+1)).setScale(0);
            Decimal randomSpendAmount = ((Decimal)(1000*Math.random()+1)).setScale(2);
            spendToInsert.add(new MM_Spendings__c(
                StrikeId__c = new List<String>(projectNameToAccountId.keySet())[projectNameToAccountId.size()-1], // get the last StrikeId
                Media_Spend__c = randomSpendAmount,
                Delivered__c = randomDeliveredAmount,
                Date__c = Date.valueOf(firstSpendDate).addDays(i),
                Contract__c = contract.Id,
                Type__c = StrikeDataAPI.PackageType.ADWORDS.name(),
                CurrencyIsoCode = contract.CurrencyIsoCode
            ));
        }
        insert spendToInsert;
        System.debug('### spendToInsert: ' + spendToInsert);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StrikeDataAPIMock(StrikeDataAPI.PackageType.ADWORDS));
        String jobId = System.schedule('ScheduledApexTest', CRON_EXP, new SpendRetrieve(StrikeDataAPI.PackageType.ADWORDS));
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);

        SpendRetrieve.run(StrikeDataAPI.PackageType.ADWORDS.name());
        System.assertEquals([SELECT COUNT() FROM MM_Spendings__c WHERE Contract__c = :contract.Id], existingSpendAmount, existingSpendAmount + ' MM_Spending__c records should exist.');
        Test.stopTest();

        System.assertEquals(SpendRetrieveNotification.errorsMap.size(), 0, 'No errors should be.');

        Map<Id, MM_Spendings__c> spendToInsertMap = new Map<Id,MM_Spendings__c>(spendToInsert);
        List<MM_Spendings__c> spendsAfterJobRan = [SELECT Id FROM MM_Spendings__c WHERE Contract__c = :contract.Id];
        System.assert(spendsAfterJobRan.size() > existingSpendAmount, 'Amount of spend records after job ran should stay be increased on amount of records from the response.');
        for (MM_Spendings__c spendAfterJobRan :spendsAfterJobRan) {
            if (spendToInsertMap.containsKey(spendAfterJobRan.Id)) {
                spendToInsertMap.remove(spendAfterJobRan.Id);
            }
        }
        System.assertEquals(0, spendToInsertMap.size(), 'Existing spends should not be deleted.');
    }
}