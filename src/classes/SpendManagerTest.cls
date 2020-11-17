/**
 * Created by Pavel Lapitski on 2019-10-17.
 */

@IsTest
private class SpendManagerTest {

    @IsTest static void assignAllSpends() {
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
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = true LIMIT 1].Id;
        insert contract;

        List<Payment__c> projects = [SELECT StrikeId__c, Start_Date__c, End_Date__c FROM Payment__c WHERE Project__c = :contract.Id];
        String projectName = '';
        for (Payment__c project :projects) {
            projectName = project.StrikeId__c;
        }

        Test.startTest();
        StrikeDataAPIMock.setRandomMetrics = true;
        Test.setMock(HttpCalloutMock.class, new StrikeDataAPIMock(projectName, StrikeDataAPI.PackageType.ADWORDS));
        Map<String, Utility.SpendAssignResult> assignResult = SpendManager.assignAllSpends(ContractRepository.getContractsByIdsForSpends(new Set<Id>{contract.Id})[0]);
        System.assertEquals(assignResult.get(projectName).isValid, true);

        List<MM_Spendings__c> newSpends = [SELECT Id FROM MM_Spendings__c WHERE Contract__c = :contract.Id];
        System.assertEquals(newSpends.size(), StrikeDataAPIMock.amountRecordsInResponseForSingleCall);
        Test.stopTest();
    }

    @IsTest static void assignFacebookSpends() {
        TestHelper.createAppSettings();

        Date sDate = Date.valueOf(Date.today().year() + '-' + Date.today().addMonths(-1).month() + '-01'),
                eDate = sDate.addDays(70);

        Platform__c fbPlatform = TestHelper.createFacebookPlatform();
        insert fbPlatform;

        TestHelper.createOpportunity(sDate, eDate, fbPlatform, Utility.BILLING_PROFILES.Strike, false);
        insert TestHelper.opportunityRecord;

        OpportunityPlatform__c opPlatform = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, fbPlatform);
        opPlatform.PlatformAccount__c = StrikeDataAPIMock.FACEBOOK_ACCOUNT_ID;
        insert opPlatform;

        Project__c contract = TestHelper.createContract('Test Contract', sDate, eDate, false);
        contract.SpendRefreshDate__c = null;
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = true LIMIT 1].Id;
        insert contract;

        List<Payment__c> projects = [SELECT StrikeId__c, Start_Date__c, End_Date__c FROM Payment__c WHERE Project__c = :contract.Id];
        String projectName = '';
        for (Payment__c project :projects) {
            projectName = project.StrikeId__c;
        }

        Test.startTest();
        StrikeDataAPIMock.setRandomMetrics = true;
        Test.setMock(HttpCalloutMock.class, new StrikeDataAPIMock(projectName, StrikeDataAPI.PackageType.FACEBOOK));
        Map<String, Utility.SpendAssignResult> assignResult = SpendManager.assignAllSpends(ContractRepository.getContractsByIdsForSpends(new Set<Id>{contract.Id})[0]);
        System.assertEquals(assignResult.get(projectName).isValid, true);

        List<MM_Spendings__c> newSpends = [SELECT Id FROM MM_Spendings__c WHERE Contract__c = :contract.Id];
        System.assertEquals(newSpends.size(), StrikeDataAPIMock.amountRecordsInResponseForSingleCall);
        Test.stopTest();
    }

    @IsTest static void assignDV360Spends() {
        TestHelper.createAppSettings();

        Date sDate = Date.valueOf(Date.today().year() + '-' + Date.today().addMonths(-1).month() + '-01'),
                eDate = sDate.addDays(70);

        Platform__c dv360Platform = TestHelper.createDBMTrueViewPlatform();
        insert dv360Platform;

        TestHelper.createOpportunity(sDate, eDate, dv360Platform, Utility.BILLING_PROFILES.Strike, false);
        insert TestHelper.opportunityRecord;

        OpportunityPlatform__c opPlatform = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, dv360Platform);
        opPlatform.PlatformAccount__c = StrikeDataAPIMock.DV360_ACCOUNT_ID;
        insert opPlatform;

        Project__c contract = TestHelper.createContract('Test Contract', sDate, eDate, false);
        contract.SpendRefreshDate__c = null;
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = true LIMIT 1].Id;
        insert contract;

        List<Payment__c> projects = [SELECT StrikeId__c, Start_Date__c, End_Date__c FROM Payment__c WHERE Project__c = :contract.Id];
        String projectName = '';
        for (Payment__c project :projects) {
            projectName = project.StrikeId__c;
        }

        Test.startTest();
        StrikeDataAPIMock.setRandomMetrics = true;
        Test.setMock(HttpCalloutMock.class, new StrikeDataAPIMock(projectName, StrikeDataAPI.PackageType.DV360));
        Map<String, Utility.SpendAssignResult> assignResult = SpendManager.assignAllSpends(ContractRepository.getContractsByIdsForSpends(new Set<Id>{contract.Id})[0]);
        System.debug('### assignDV360Spends.assignResult: ' + assignResult);
        // TODO: fails on production, reason?
        System.assertEquals(assignResult.get(projectName).isValid, true);

        List<MM_Spendings__c> newSpends = [SELECT Id FROM MM_Spendings__c WHERE Contract__c = :contract.Id];
        System.assertEquals(newSpends.size(), StrikeDataAPIMock.amountRecordsInResponseForSingleCall);
        Test.stopTest();
    }

    @IsTest static void assignAllSpendsWithAccountNotMatched() {
        TestHelper.createAppSettings();

        Date sDate = Date.valueOf(Date.today().year() + '-' + Date.today().addMonths(-1).month() + '-01'),
                eDate = sDate.addDays(70);

        Platform__c adWordsPlatform = TestHelper.createTrueViewPlatform();
        insert adWordsPlatform;

        TestHelper.createOpportunity(sDate, eDate, adWordsPlatform, Utility.BILLING_PROFILES.Strike, false);
        insert TestHelper.opportunityRecord;

        OpportunityPlatform__c opPlatform = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, adWordsPlatform);
        opPlatform.PlatformAccount__c = '926-395-1111';
        insert opPlatform;

        Project__c contract = TestHelper.createContract('Test Contract', sDate, eDate, false);
        contract.SpendRefreshDate__c = null;
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = true LIMIT 1].Id;
        insert contract;

        List<Payment__c> projects = [SELECT StrikeId__c, Start_Date__c, End_Date__c FROM Payment__c WHERE Project__c = :contract.Id];
        String projectName = '';
        for (Payment__c project :projects) {
            projectName = project.StrikeId__c;
        }

        Test.startTest();
        StrikeDataAPIMock.setRandomMetrics = true;
        Test.setMock(HttpCalloutMock.class, new StrikeDataAPIMock(projectName, StrikeDataAPI.PackageType.ADWORDS));
        Map<String, Utility.SpendAssignResult> assignResult = SpendManager.assignAllSpends(ContractRepository.getContractsByIdsForSpends(new Set<Id>{contract.Id})[0]);
        System.assertEquals(assignResult.get(projectName).isValid, false);
        System.assert(assignResult.get(projectName).message.contains(SpendManager.ERROR_DIFFERENT_ACCOUNT));

        List<MM_Spendings__c> newSpends = [SELECT Id FROM MM_Spendings__c WHERE Contract__c = :contract.Id];
        System.assertEquals(newSpends.size(), 0);
        Test.stopTest();
    }

    @IsTest static void assignAllSpendsWithDifferentCurrency() {
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
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = true LIMIT 1].Id;
        contract.CurrencyIsoCode = 'EUR';
        insert contract;

        System.assertNotEquals(StrikeDataAPIMock.currencyIsoCode, contract.CurrencyIsoCode, 'Currency Iso Code should be different.');

        List<Payment__c> projects = [SELECT StrikeId__c, Start_Date__c, End_Date__c FROM Payment__c WHERE Project__c = :contract.Id];
        String projectName = '';
        for (Payment__c project :projects) {
            projectName = project.StrikeId__c;
        }

        Test.startTest();
        StrikeDataAPIMock.setRandomMetrics = true;
        Test.setMock(HttpCalloutMock.class, new StrikeDataAPIMock(projectName, StrikeDataAPI.PackageType.ADWORDS));
        Map<String, Utility.SpendAssignResult> assignResult = SpendManager.assignAllSpends(ContractRepository.getContractsByIdsForSpends(new Set<Id>{contract.Id})[0]);
        System.assertEquals(assignResult.get(projectName).isValid, false);
        System.assert(assignResult.get(projectName).message.contains(SpendManager.ERROR_DIFFERENT_CURRENCY));

        List<MM_Spendings__c> newSpends = [SELECT Id FROM MM_Spendings__c WHERE Contract__c = :contract.Id];
        System.assertEquals(newSpends.size(), 0);
        Test.stopTest();
    }

    @IsTest static void assignAllSpendsNoMetricsReturned() {
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
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = true LIMIT 1].Id;
        insert contract;

        List<Payment__c> projects = [SELECT StrikeId__c, Start_Date__c, End_Date__c FROM Payment__c WHERE Project__c = :contract.Id];
        String projectName = '';
        for (Payment__c project :projects) {
            projectName = project.StrikeId__c;
        }

        Test.startTest();
        StrikeDataAPIMock.setEmptyMetrics = true;
        StrikeDataAPIMock.setRandomMetrics = true;
        Test.setMock(HttpCalloutMock.class, new StrikeDataAPIMock(projectName, StrikeDataAPI.PackageType.ADWORDS));
        Map<String, Utility.SpendAssignResult> assignResult = SpendManager.assignAllSpends(ContractRepository.getContractsByIdsForSpends(new Set<Id>{contract.Id})[0]);
        System.assertEquals(assignResult.get(projectName).isValid, false);

        System.assertEquals([SELECT COUNT() FROM MM_Spendings__c WHERE Contract__c = :contract.Id], 0);
        Test.stopTest();
    }

    @IsTest static void assignAllSpendsMetricsExistNoMetricsReplaced() {
        TestHelper.createAppSettings();

        Date firstSpendDate = Date.newInstance(Date.today().year(), Date.today().month(), 1),
                sDate = Date.valueOf(firstSpendDate.year() + '-' + firstSpendDate.month() + '-01'),
                eDate = sDate.addDays(70);
        String currencyIsoCode = 'AUD';
        String projectName = '';

        Platform__c adWordsPlatform = TestHelper.createTrueViewPlatform();
        insert adWordsPlatform;

        TestHelper.createOpportunity(sDate, eDate, adWordsPlatform, Utility.BILLING_PROFILES.Strike, false);
        insert TestHelper.opportunityRecord;

        OpportunityPlatform__c opPlatform = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, adWordsPlatform);
        opPlatform.PlatformAccount__c = StrikeDataAPIMock.accountId;
        insert opPlatform;

        Project__c contract = TestHelper.createContract('Test Contract', sDate, eDate, false);
        contract.SpendRefreshDate__c = null;
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = true LIMIT 1].Id;
        contract.CurrencyIsoCode = currencyIsoCode;
        insert contract;

        List<Payment__c> projects = [SELECT StrikeId__c, Start_Date__c, End_Date__c, Project__c FROM Payment__c WHERE Project__c = :contract.Id];
        for (Payment__c project :projects) {
            projectName = project.StrikeId__c;
        }
        Integer monthBetween = contract.Start_Date__c.monthsBetween(contract.End_Date__c);
        System.assertEquals((monthBetween + 1), projects.size());

        List<MM_Spendings__c> mmSpendsToInsert = new List<MM_Spendings__c>();
        Decimal spendAmount = 25185.95;
        Integer amountDelivered = 4000;
        for (Integer i = 0; i < projects.size(); i++ ) {
            Payment__c project = projects[i];
            mmSpendsToInsert.add(new MM_Spendings__c(
                StrikeId__c = project.StrikeId__c,
                Media_Spend__c = spendAmount,
                Delivered__c = amountDelivered,
                Date__c = firstSpendDate.addDays(i),
                Contract__c = project.Project__c,
                Type__c = StrikeDataAPI.PackageType.ADWORDS.name(),
                CurrencyIsoCode = currencyIsoCode,
                Is_Sync__c = true
            ));
        }
        insert mmSpendsToInsert;
        Map<Id,MM_Spendings__c> existingSpendsMap = new Map<Id, MM_Spendings__c>(mmSpendsToInsert);

        // create a custom metrics that will be a response body
        List<String> metricsList = new List<String>();
        for (Integer i = 0; i < mmSpendsToInsert.size(); i++) {
            MM_Spendings__c existingSpend = mmSpendsToInsert[i];

            String accountId = opPlatform.PlatformAccount__c ;
            Datetime spendDateTime = Datetime.newInstance(existingSpend.Date__c.year(), existingSpend.Date__c.month(), existingSpend.Date__c.day(), 10, 0, 0);
            Long dateTimeOfSpend = spendDateTime.getTime();
            Decimal randomClicksAmount = ((Decimal)(1000*Math.random()+1)).setScale(0);
            Decimal randomViewsAmount = ((Decimal)(1000*Math.random()+1)).setScale(0);
            Decimal randomImpressionsAmount = ((Decimal)(10000*Math.random()+1)).setScale(0);
            metricsList.add(
                '{\"project_id\":\"' + projectName + '\",' +
                    '\"date\":' + String.valueOf(dateTimeOfSpend) + ',' +
                    '\"account_id\":\"' + accountId + '\",' +
                    '\"currency\":\"' + existingSpend.CurrencyIsoCode + '\",' +
                    '\"cost_structure\":\"CPC\",' +
                    '\"spend\": ' + existingSpend.Media_Spend__c + ',' +
                    '\"clicks\": ' + randomClicksAmount + ',' +
                    '\"views\": ' + randomViewsAmount + ',' +
                    '\"impressions\": ' + randomImpressionsAmount + ',' +
                    '\"engagements\":0.0,' +
                    '\"delivered\": ' + existingSpend.Delivered__c +
                '}'
            );
        }
        String customMetrics = '{"metrics":[' + String.join(metricsList, ',') + ']}';

        Test.startTest();
        StrikeDataAPIMock.customMetrics = customMetrics;
        Test.setMock(HttpCalloutMock.class, new StrikeDataAPIMock(projectName, StrikeDataAPI.PackageType.ADWORDS));
        Map<String, Utility.SpendAssignResult> assignResult = SpendManager.assignAllSpends(ContractRepository.getContractsByIdsForSpends(new Set<Id>{contract.Id})[0]);
        System.assertEquals(assignResult.get(projectName).isValid, true);
        System.assertEquals(assignResult.get(projectName).message, 'Spends Imported Successfully.'); // see Utility.SpendAssignResult.setSuccess()
        Test.stopTest();

        List<MM_Spendings__c> spendsAfterRetrieve = [SELECT Id, StrikeId__c, Media_Spend__c, Delivered__c, Date__c, Contract__c, Type__c FROM MM_Spendings__c WHERE Contract__c = :contract.Id];
        for (MM_Spendings__c spendAfterRetrieve :spendsAfterRetrieve) {
            System.assert(existingSpendsMap.containsKey(spendAfterRetrieve.Id), 'No new spend from retrieved metrics should be added.');
            existingSpendsMap.remove(spendAfterRetrieve.Id);
        }
        System.assertEquals(0, existingSpendsMap.size(), 'Amount of spends records should stay unchanged.');
    }

    @IsTest static void assignAllSpendsMetricsExistAllMetricsReplaced() {
        TestHelper.createAppSettings();

        Date firstSpendDate = Date.newInstance(Date.today().year(), Date.today().month(), 1),
                sDate = Date.valueOf(firstSpendDate.year() + '-' + firstSpendDate.month() + '-01'),
                eDate = sDate.addDays(70);
        String currencyIsoCode = 'AUD';
        String projectName = '';

        Platform__c adWordsPlatform = TestHelper.createTrueViewPlatform();
        insert adWordsPlatform;

        TestHelper.createOpportunity(sDate, eDate, adWordsPlatform, Utility.BILLING_PROFILES.Strike, false);
        insert TestHelper.opportunityRecord;

        OpportunityPlatform__c opPlatform = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, adWordsPlatform);
        opPlatform.PlatformAccount__c = StrikeDataAPIMock.accountId;
        insert opPlatform;

        Project__c contract = TestHelper.createContract('Test Contract', sDate, eDate, false);
        contract.SpendRefreshDate__c = null;
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = true LIMIT 1].Id;
        contract.CurrencyIsoCode = currencyIsoCode;
        insert contract;

        List<Payment__c> projects = [SELECT StrikeId__c, Start_Date__c, End_Date__c, Project__c FROM Payment__c WHERE Project__c = :contract.Id];
        for (Payment__c project :projects) {
            projectName = project.StrikeId__c;
        }
        Integer monthBetween = contract.Start_Date__c.monthsBetween(contract.End_Date__c);
        System.assertEquals((monthBetween + 1), projects.size());

        List<MM_Spendings__c> mmSpendsToInsert = new List<MM_Spendings__c>();
        Decimal spendAmount = 25185.95;
        Integer amountDelivered = 4000;
        for (Integer i = 0; i < projects.size(); i++ /*Payment__c project :projects*/) {
            Payment__c project = projects[i];
            mmSpendsToInsert.add(new MM_Spendings__c(
                    StrikeId__c = project.StrikeId__c,
                    Media_Spend__c = spendAmount,
                    Delivered__c = amountDelivered,
                    Date__c = firstSpendDate.addDays(i),
                    Contract__c = project.Project__c,
                    Type__c = StrikeDataAPI.PackageType.ADWORDS.name(),
                    CurrencyIsoCode = currencyIsoCode
            ));
        }
        insert mmSpendsToInsert;
        Map<Id,MM_Spendings__c> existingSpendsMap = new Map<Id, MM_Spendings__c>(mmSpendsToInsert);

        // create a custom metrics that will be a response body
        List<String> metricsList = new List<String>();
        for (Integer i = 0; i < mmSpendsToInsert.size(); i++) {
            MM_Spendings__c existingSpend = mmSpendsToInsert[i];

            String accountId = opPlatform.PlatformAccount__c ;
            Datetime spendDateTime = Datetime.newInstance(existingSpend.Date__c.year(), existingSpend.Date__c.month(), existingSpend.Date__c.day(), 10, 0, 0);
            Long dateTimeOfSpend = spendDateTime.getTime();
            Decimal randomClicksAmount = ((Decimal)(1000*Math.random()+1)).setScale(0);
            Decimal randomViewsAmount = ((Decimal)(1000*Math.random()+1)).setScale(0);
            Decimal randomImpressionsAmount = ((Decimal)(10000*Math.random()+1)).setScale(0);
            Decimal randomDeliveredAmount = ((Decimal)(100000*Math.random()+1)).setScale(0);
            Decimal randomSpendAmount = ((Decimal)(1000*Math.random()+1)).setScale(2);
            System.assertNotEquals(randomDeliveredAmount, existingSpend.Delivered__c, 'Delivered value should be different to for metrics replacement.');
            System.assertNotEquals(randomSpendAmount, existingSpend.Media_Spend__c, 'Spend Amount value should be different to for metrics replacement.');
            metricsList.add(
                '{\"project_id\":\"' + projectName + '\",' +
                    '\"date\":' + String.valueOf(dateTimeOfSpend) + ',' +
                    '\"account_id\":\"' + accountId + '\",' +
                    '\"currency\":\"' + existingSpend.CurrencyIsoCode + '\",' +
                    '\"cost_structure\":\"CPC\",' +
                    '\"spend\": ' + randomSpendAmount + ',' +
                    '\"clicks\": ' + randomClicksAmount + ',' +
                    '\"views\": ' + randomViewsAmount + ',' +
                    '\"impressions\": ' + randomImpressionsAmount + ',' +
                    '\"engagements\":0.0,' +
                    '\"delivered\": ' + randomDeliveredAmount +
                '}'
            );
        }
        String customMetrics = '{"metrics":[' + String.join(metricsList, ',') + ']}';

        Test.startTest();
        StrikeDataAPIMock.customMetrics = customMetrics;
        Test.setMock(HttpCalloutMock.class, new StrikeDataAPIMock(projectName, StrikeDataAPI.PackageType.ADWORDS));
        Map<String, Utility.SpendAssignResult> assignResult = SpendManager.assignAllSpends(ContractRepository.getContractsByIdsForSpends(new Set<Id>{contract.Id})[0]);
        System.assertEquals(assignResult.get(projectName).isValid, true);
        System.assertEquals(assignResult.get(projectName).message, 'Spends Imported Successfully.'); // see Utility.SpendAssignResult.setSuccess()
        Test.stopTest();

        List<MM_Spendings__c> spendsAfterRetrieve = [SELECT Id, StrikeId__c, Media_Spend__c, Delivered__c, Date__c, Contract__c, Type__c FROM MM_Spendings__c WHERE Contract__c = :contract.Id];
        for (MM_Spendings__c spendAfterRetrieve :spendsAfterRetrieve) {
            System.assert(!existingSpendsMap.containsKey(spendAfterRetrieve.Id), 'All new MM_Spendings__c records should be newly created.');
            existingSpendsMap.remove(spendAfterRetrieve.Id);
        }
        System.assertNotEquals(0, existingSpendsMap.size());
        System.assertEquals(spendsAfterRetrieve.size(), existingSpendsMap.size());
    }

    @IsTest static void assignAllSpends_MetricsExist_ExistingMetricsNotDeleted_NewMetricsAdded() {
        TestHelper.createAppSettings();

        Date firstSpendDate = Date.newInstance(Date.today().year(), Date.today().month(), 1),
                sDate = Date.valueOf(firstSpendDate.year() + '-' + firstSpendDate.month() + '-01'),
                eDate = sDate.addDays(70);
        String currencyIsoCode = 'AUD';
        String projectName = '';

        Platform__c adWordsPlatform = TestHelper.createTrueViewPlatform();
        insert adWordsPlatform;

        TestHelper.createOpportunity(sDate, eDate, adWordsPlatform, Utility.BILLING_PROFILES.Strike, false);
        insert TestHelper.opportunityRecord;

        OpportunityPlatform__c opPlatform = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, adWordsPlatform);
        opPlatform.PlatformAccount__c = StrikeDataAPIMock.accountId;
        insert opPlatform;

        Project__c contract = TestHelper.createContract('Test Contract', sDate, eDate, false);
        contract.SpendRefreshDate__c = null;
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = true LIMIT 1].Id;
        contract.CurrencyIsoCode = currencyIsoCode;
        insert contract;

        List<Payment__c> projects = [SELECT StrikeId__c, Start_Date__c, End_Date__c, Project__c FROM Payment__c WHERE Project__c = :contract.Id];
        for (Payment__c project :projects) {
            projectName = project.StrikeId__c;
        }
        Integer monthBetween = contract.Start_Date__c.monthsBetween(contract.End_Date__c);
        System.assertEquals((monthBetween + 1), projects.size());

        List<MM_Spendings__c> mmSpendsToInsert = new List<MM_Spendings__c>();
        Decimal spendAmount = 25185.95;
        Integer amountDelivered = 4000;
        Integer existingRecordsAmount = 10;
        for (Integer i = 0; i < existingRecordsAmount; i++) {
            mmSpendsToInsert.add(new MM_Spendings__c(
                StrikeId__c = projects[projects.size()-1].StrikeId__c,
                Media_Spend__c = spendAmount,
                Delivered__c = amountDelivered,
                Date__c = contract.Start_Date__c.addDays(i),
                Contract__c = projects[projects.size()-1].Project__c,
                Type__c = StrikeDataAPI.PackageType.ADWORDS.name(),
                CurrencyIsoCode = currencyIsoCode
            ));
        }
        insert mmSpendsToInsert;
        Map<Id,MM_Spendings__c> existingSpendsMap = new Map<Id, MM_Spendings__c>(mmSpendsToInsert);

        // create a custom metrics that will be a response body
        List<String> metricsList = new List<String>();
        for (Integer i = 0; i < mmSpendsToInsert.size(); i++) {
            MM_Spendings__c existingSpend = mmSpendsToInsert[i];
            String accountId = opPlatform.PlatformAccount__c ;
            Datetime spendDateTime = Datetime.newInstance(StrikeDataAPIMock.EARLIEST_SPEND_DATE).addDays(i); // The date should be different from record in mmSpendsToInsert
            Long dateTimeOfSpend = spendDateTime.getTime();
            Decimal randomClicksAmount = ((Decimal)(1000*Math.random()+1)).setScale(0);
            Decimal randomViewsAmount = ((Decimal)(1000*Math.random()+1)).setScale(0);
            Decimal randomImpressionsAmount = ((Decimal)(10000*Math.random()+1)).setScale(0);
            Decimal randomDeliveredAmount = ((Decimal)(100000*Math.random()+1)).setScale(0);
            Decimal randomSpendAmount = ((Decimal)(1000*Math.random()+1)).setScale(2);
            System.assertNotEquals(randomDeliveredAmount, existingSpend.Delivered__c, 'Delivered value should be different to for metrics replacement.');
            System.assertNotEquals(randomSpendAmount, existingSpend.Media_Spend__c, 'Spend Amount value should be different to for metrics replacement.');
            metricsList.add(
                '{\"project_id\":\"' + projectName + '\",' +
                    '\"date\":' + String.valueOf(dateTimeOfSpend) + ',' +
                    '\"account_id\":\"' + accountId + '\",' +
                    '\"currency\":\"' + existingSpend.CurrencyIsoCode + '\",' +
                    '\"cost_structure\":\"CPC\",' +
                    '\"spend\": ' + randomSpendAmount + ',' +
                    '\"clicks\": ' + randomClicksAmount + ',' +
                    '\"views\": ' + randomViewsAmount + ',' +
                    '\"impressions\": ' + randomImpressionsAmount + ',' +
                    '\"engagements\":0.0,' +
                    '\"delivered\": ' + randomDeliveredAmount +
                '}'
            );
        }
        String customMetrics = '{"metrics":[' + String.join(metricsList, ',') + ']}';

        Test.startTest();
        StrikeDataAPIMock.customMetrics = customMetrics;
        Test.setMock(HttpCalloutMock.class, new StrikeDataAPIMock(projectName, StrikeDataAPI.PackageType.ADWORDS));
        Map<String, Utility.SpendAssignResult> assignResult = SpendManager.assignAllSpends(ContractRepository.getContractsByIdsForSpends(new Set<Id>{contract.Id})[0]);
        System.assertEquals(assignResult.get(projectName).isValid, true);
        System.assertEquals(assignResult.get(projectName).message, 'Spends Imported Successfully.'); // see Utility.SpendAssignResult.setSuccess()
        Test.stopTest();

        List<MM_Spendings__c> spendsAfterRetrieve = [SELECT Id, StrikeId__c, Media_Spend__c, Delivered__c, Date__c, Contract__c, Type__c FROM MM_Spendings__c WHERE Contract__c = :contract.Id];
        for (MM_Spendings__c spendAfterRetrieve :spendsAfterRetrieve) {
            if (existingSpendsMap.containsKey(spendAfterRetrieve.Id)) {
                existingSpendsMap.remove(spendAfterRetrieve.Id);
            }
        }
        System.assertEquals(metricsList.size() + existingRecordsAmount, spendsAfterRetrieve.size(), 'Nothing is deleted. New spends are added.');
        System.assertEquals(0, existingSpendsMap.size());
    }

    @IsTest static void assignAllSpendsForUnsupportedPlatforms() {
        TestHelper.createAppSettings();

        Date sDate = Date.valueOf(Date.today().year() + '-' + Date.today().addMonths(-1).month() + '-01'),
                eDate = sDate.addDays(70);

        Platform__c linkedInPlatform = TestHelper.createLinkedInPlatform(),
                pinterestPlatform = TestHelper.createPinterestPlatform(),
                snapchatPlatform = TestHelper.createSnapchatPlatform(),
                twitterPlatform = TestHelper.createTwitterPlatform();
        insert new List<Platform__c> {linkedInPlatform, pinterestPlatform, snapchatPlatform, twitterPlatform};

        TestHelper.createOpportunity(sDate, eDate, linkedInPlatform, Utility.BILLING_PROFILES.Strike, false);
        insert TestHelper.opportunityRecord;

        insert new List<OpportunityPlatform__c> {
            TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, linkedInPlatform),
            TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, pinterestPlatform),
            TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, snapchatPlatform),
            TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, twitterPlatform)
        };
        StrikeDataAPI.PackageType packageType = StrikeDataAPI.PackageType.ADWORDS;//no matter what package type it is, error appears earlier, without making callouts

        Project__c contract = TestHelper.createContract('Test Contract', sDate, eDate, false);
        contract.SpendRefreshDate__c = null;
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = true LIMIT 1].Id;
        insert contract;

        List<Payment__c> projects = [SELECT StrikeId__c, Start_Date__c, End_Date__c FROM Payment__c WHERE Project__c = :contract.Id];
        String projectName = '';
        for (Payment__c project :projects) {
            projectName = project.StrikeId__c;
        }

        Test.startTest();
        StrikeDataAPIMock.setRandomMetrics = true;
        Test.setMock(HttpCalloutMock.class, new StrikeDataAPIMock(projectName, packageType));
        Map<String, Utility.SpendAssignResult> assignResult = SpendManager.assignAllSpends(ContractRepository.getContractsByIdsForSpends(new Set<Id>{contract.Id})[0]);
        System.assertEquals(assignResult.get(projectName).isValid, false);
        System.assertEquals(assignResult.get(projectName).message, StrikeDataAPI.ERROR_CANNOT_RECEIVE_SPENDS);
        System.assertEquals([SELECT COUNT() FROM MM_Spendings__c WHERE Contract__c = :contract.Id], 0);
        Test.stopTest();
    }

    @IsTest static void assignAllSpends_MetricsExist_NewMetricsAdded_10Projects() {
        TestHelper.createAppSettings();

        Datetime firstSpendDate = Datetime.newInstance(StrikeDataAPIMock.EARLIEST_SPEND_DATE);
        Date sDate = Date.valueOf(firstSpendDate.year() + '-' + firstSpendDate.addMonths(-2).month() + '-01'),
                eDate = sDate.addDays(15);
        String currencyIsoCode = 'AUD';

        Platform__c adWordsPlatform = TestHelper.createTrueViewPlatform();
        insert adWordsPlatform;

        TestHelper.createOpportunity(sDate, eDate, adWordsPlatform, Utility.BILLING_PROFILES.Strike, false);
        insert TestHelper.opportunityRecord;

        OpportunityPlatform__c opPlatform = TestHelper.createOpportunityPlatform(TestHelper.opportunityRecord.Id, adWordsPlatform);
        opPlatform.PlatformAccount__c = StrikeDataAPIMock.accountId;
        insert opPlatform;

        Project__c contract = TestHelper.createContract('Test Contract', sDate, eDate, false);
        contract.SpendRefreshDate__c = null;
        contract.ClientServicesRep__c = [SELECT Id FROM User WHERE Client_Services_Rep__c = true LIMIT 1].Id;
        contract.CurrencyIsoCode = currencyIsoCode;
        insert contract;

        Integer monthBetween = contract.Start_Date__c.monthsBetween(contract.End_Date__c);
        List<Payment__c> projects = [SELECT StrikeId__c, Start_Date__c, End_Date__c, Project__c FROM Payment__c WHERE Project__c = :contract.Id];
        System.assertEquals((monthBetween + 1), projects.size());
        List<Sub_Project__c> payments = [SELECT Id, Project__c, Start_Date__c, End_Date__c, Client_Spend__c FROM Sub_Project__c WHERE Project__c = :contract.Id];
        System.assertEquals((monthBetween + 1), payments.size());

        List<Payment__c> newProjects = new List<Payment__c>();
        for (Integer i = projects.size(); i<= 10; i++) {
            Payment__c project = TestHelper.createProjectBasedOnPayment(contract, payments[0], false);
            project.OpportunityPlatform__c = opPlatform.Id;
            newProjects.add(project);
        }
        PaymentHandler.skipInsertValidation = true;
        insert newProjects;
        PaymentHandler.skipInsertValidation = false;

        Set<String> projectNames = new Set<String>();
        projects = [SELECT StrikeId__c, Start_Date__c, End_Date__c, Project__c FROM Payment__c WHERE Project__c = :contract.Id];
        System.assert(10 < projects.size(), 'There should be more than 10+ projects for unit test.');
        for (Payment__c project :projects) {
            projectNames.add(project.StrikeId__c);
        }
        List<String> projectNamesList = new List<String>(projectNames);

        // create a custom metrics that will be a response body
        List<String> metricsList = new List<String>();
        for (Integer i = 0; i < projectNames.size(); i++) {
            String projectName = projectNamesList[i];
            String accountId = opPlatform.PlatformAccount__c ;
            Datetime spendDateTime = Datetime.newInstance(StrikeDataAPIMock.EARLIEST_SPEND_DATE).addDays(i); // The date should be different from record in mmSpendsToInsert
            Long dateTimeOfSpend = spendDateTime.getTime();
            Decimal randomClicksAmount = ((Decimal)(1000*Math.random()+1)).setScale(0);
            Decimal randomViewsAmount = ((Decimal)(1000*Math.random()+1)).setScale(0);
            Decimal randomImpressionsAmount = ((Decimal)(10000*Math.random()+1)).setScale(0);
            Decimal randomDeliveredAmount = ((Decimal)(100000*Math.random()+1)).setScale(0);
            Decimal randomSpendAmount = ((Decimal)(1000*Math.random()+1)).setScale(2);
            metricsList.add(
                '{\"project_id\":\"' + projectName + '\",' +
                    '\"date\":' + String.valueOf(dateTimeOfSpend) + ',' +
                    '\"account_id\":\"' + accountId + '\",' +
                    '\"currency\":\"' + currencyIsoCode + '\",' +
                    '\"cost_structure\":\"CPC\",' +
                    '\"spend\": ' + randomSpendAmount + ',' +
                    '\"clicks\": ' + randomClicksAmount + ',' +
                    '\"views\": ' + randomViewsAmount + ',' +
                    '\"impressions\": ' + randomImpressionsAmount + ',' +
                    '\"engagements\":0.0,' +
                    '\"delivered\": ' + randomDeliveredAmount +
                '}'
            );
        }
        String customMetrics = '{"metrics":[' + String.join(metricsList, ',') + ']}';

        Test.startTest();
        StrikeDataAPIMock.customMetrics = customMetrics;
        Test.setMock(HttpCalloutMock.class, new StrikeDataAPIMock(projectNamesList[0], StrikeDataAPI.PackageType.ADWORDS));
        Map<String, Utility.SpendAssignResult> assignResult = SpendManager.assignAllSpends(ContractRepository.getContractsByIdsForSpends(new Set<Id>{contract.Id})[0]);
        System.debug('### assignResult: ' + assignResult);
        for (String projectName :projectNamesList) {
            System.assertEquals(assignResult.get(projectName).isValid, true);
            System.assertEquals(assignResult.get(projectName).message, 'Spends Imported Successfully.'); // see Utility.SpendAssignResult.setSuccess()
        }
        Test.stopTest();

        List<MM_Spendings__c> spendsAfterRetrieve = [SELECT Id, StrikeId__c, Media_Spend__c, Delivered__c, Date__c, Contract__c, Type__c FROM MM_Spendings__c WHERE Contract__c = :contract.Id];
        System.assertEquals(metricsList.size(), spendsAfterRetrieve.size());
    }
}