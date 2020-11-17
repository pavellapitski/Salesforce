@IsTest
private class MMSpendingsHandlerTest {

    @TestSetup public static void initTestData() {
        TestHelper.setupEnv();

        List<MM_Spendings__c> mediaSpends = new List<MM_Spendings__c>{
            TestHelper.createMediaSpendings(TestHelper.contract.Id, TestHelper.contract.End_Date__c),
            TestHelper.createMediaSpendings(TestHelper.contract.Id, TestHelper.contract.End_Date__c.addDays(-1))
        };
        insert mediaSpends;
    }

    @IsTest static void insertNewMMSpendings() {
        Project__c contract = [SELECT Id, End_Date__c, Start_Date__c FROM Project__c LIMIT 1];
        List<Payment__c>  projects = [
            SELECT Id, Start_Date__c, End_Date__c, ProjectID__c, StrikeId__c, (SELECT Date__c FROM ContractMediaSpends__r)
            FROM Payment__c
        ];
        // here should be two projects because of Start and End Date for contract ('2015-01-01' to '2015-01-01' + 40days)
        System.assertEquals(projects.size(), 2, 'Please check contract Start/End dates to fit two months');

        List<MM_Spendings__c> newMediaSpends = new List<MM_Spendings__c>{
            TestHelper.createMediaSpendings(contract.Id, contract.Start_Date__c.addDays(1)),
            TestHelper.createMediaSpendings(contract.Id, contract.Start_Date__c.addDays(2))
        };

        List<Project_Media_Spend__c> existingProjectMediaSpends = [SELECT Id, MMSpending__c, Project__c,Date__c FROM Project_Media_Spend__c];

        Test.startTest();
        insert newMediaSpends;
        Test.stopTest();

        System.assertEquals(existingProjectMediaSpends.size() + newMediaSpends.size(), [SELECT Id FROM Project_Media_Spend__c].size());
    }

    @IsTest static void willUpdateRelatedSpending() {
        MM_Spendings__c mediaSpending1, mediaSpending2;
        Set<String> strikeIds = new Set<String>();

        Project__c contract = [SELECT Id, End_Date__c, Start_Date__c FROM Project__c LIMIT 1];
        // there are two existing MMSpendings
        List<MM_Spendings__c> spendings = [SELECT Date__c, Delivered__c, Media_Spend__c, Contract__c, Strike_ID__c FROM MM_Spendings__c WHERE Contract__c = :contract.Id];
        System.assertEquals(2, spendings.size());

        for (MM_Spendings__c mSpending :spendings) {
            strikeIds.add(mSpending.Strike_ID__c);

            if (mSpending.Date__c == contract.End_Date__c) {
                mediaSpending1 = mSpending;
            } else {
                mediaSpending2 = mSpending;
            }
        }
        System.assertNotEquals(mediaSpending1, null);
        System.assertNotEquals(mediaSpending2, null);

        Map<Id, MM_Spendings__c> mediaSpendings = new Map<Id, MM_Spendings__c>{
            mediaSpending1.Id => mediaSpending1,
            mediaSpending2.Id => mediaSpending2
        };

        Test.startTest();
        mediaSpending1.Media_Spend__c = 999;
        mediaSpending1.Delivered__c = 999;
        mediaSpending1.BypassValidationRule__c = true;
        update mediaSpending1;
        Test.stopTest();

        Map<Id, Project_Media_Spend__c> contractSpendingForMediaManagerSpending = new Map<Id, Project_Media_Spend__c>();
        List<Project_Media_Spend__c> pmss = [SELECT Delivered__c, Amount__c, Project__r.ProjectID__c, Date__c, MMSpending__c FROM Project_Media_Spend__c WHERE Project__r.ProjectID__c IN :strikeIds];
        for (Project_Media_Spend__c pms :pmss) {
            for (Id msId :mediaSpendings.keySet()) {
                if (pms.Date__c == mediaSpendings.get(msId).Date__c) {
                    contractSpendingForMediaManagerSpending.put(msId, pms);
                }
            }
        }

        System.assertEquals(mediaSpending1.Media_Spend__c, contractSpendingForMediaManagerSpending.get(mediaSpending1.Id).Amount__c);
        System.assertEquals(mediaSpending2.Media_Spend__c, contractSpendingForMediaManagerSpending.get(mediaSpending2.Id).Amount__c);

        System.assertEquals(mediaSpending1.Delivered__c, contractSpendingForMediaManagerSpending.get(mediaSpending1.Id).Delivered__c);
        System.assertEquals(mediaSpending2.Delivered__c, contractSpendingForMediaManagerSpending.get(mediaSpending2.Id).Delivered__c);

        System.assertEquals(mediaSpending1.Id, contractSpendingForMediaManagerSpending.get(mediaSpending1.Id).MMSpending__c);
        System.assertEquals(mediaSpending2.Id, contractSpendingForMediaManagerSpending.get(mediaSpending2.Id).MMSpending__c);
    }

    @IsTest static void willDeleteRelatedSpending() {
        MM_Spendings__c mediaSpending1, mediaSpending2;
        Project__c contract = [SELECT Id, End_Date__c, Start_Date__c FROM Project__c LIMIT 1];

        List<MM_Spendings__c> spendings = [SELECT Date__c, Delivered__c, Media_Spend__c, Contract__c, Strike_ID__c FROM MM_Spendings__c WHERE Contract__c = :contract.Id];
        Set<String> strikeIds = new Set<String>();
        // there are two existing MMSpendings
        System.assertEquals(2, spendings.size());

        for (MM_Spendings__c mSpending :spendings) {
            strikeIds.add(mSpending.Strike_ID__c);
            if (mSpending.Date__c == contract.End_Date__c) {
                mediaSpending1 = mSpending;
            } else {
                mediaSpending2 = mSpending;
            }
        }
        System.assertNotEquals(mediaSpending1, null);
        System.assertNotEquals(mediaSpending2, null);

        Map<Id, MM_Spendings__c> mediaSpendings = new Map<Id, MM_Spendings__c>{
            mediaSpending1.Id => mediaSpending1,
            mediaSpending2.Id => mediaSpending2
        };

        Test.startTest();
        delete mediaSpending1;
        Test.stopTest();

        Map<Id, Project_Media_Spend__c> contractSpendingForMediaManagerSpending = new Map<Id, Project_Media_Spend__c>();
        List<Project_Media_Spend__c> pmss = [SELECT Delivered__c, Amount__c, Project__r.ProjectID__c, Date__c, MMSpending__c FROM Project_Media_Spend__c WHERE Project__r.ProjectID__c IN :strikeIds];
        for (Project_Media_Spend__c contractMediaSpend :pmss) {
            for (Id mediaSpendingId : mediaSpendings.keySet()) {
                if (contractMediaSpend.Date__c == mediaSpendings.get(mediaSpendingId).Date__c) {
                    contractSpendingForMediaManagerSpending.put(mediaSpendingId, contractMediaSpend);
                }
            }
        }

        //MediaSpending1 was deleted
        System.assert(!contractSpendingForMediaManagerSpending.containsKey(mediaSpending1.Id));
        System.assert(contractSpendingForMediaManagerSpending.containsKey(mediaSpending2.Id));
    }

    @IsTest static void willReplaceMediaSpendingForTheSameDay() {
        MM_Spendings__c mmsDuplicate, mediaSpending1, mediaSpending2;

        Project__c contract = [SELECT Id, End_Date__c FROM Project__c LIMIT 1];
        // there are two existing MMSpendings
        List<MM_Spendings__c> spendings = [SELECT Date__c, Delivered__c, Media_Spend__c, Contract__c FROM MM_Spendings__c WHERE Contract__c = :contract.Id];
        System.assertEquals(2, spendings.size());
        for (MM_Spendings__c mSpending :spendings) {
            if (mSpending.Date__c == contract.End_Date__c) {
                mediaSpending1 = mSpending;
            } else {
                mediaSpending2 = mSpending;
            }
        }
        System.assertNotEquals(mediaSpending1, null);

        Test.startTest();
        // creating a new duplicated MMSpending record
        mmsDuplicate = TestHelper.createMediaSpendings(mediaSpending1.Contract__c, mediaSpending1.Date__c);
        mmsDuplicate.Media_Spend__c = mediaSpending1.Media_Spend__c * 2;
        mmsDuplicate.Delivered__c = mediaSpending1.Media_Spend__c * 2;
        insert mmsDuplicate;
        Test.stopTest();

        spendings = [SELECT Date__c, Delivered__c, Media_Spend__c FROM MM_Spendings__c WHERE Contract__c = :contract.Id];
        // no additional records are created, still two
        System.assertEquals(2, spendings.size());

        for (MM_Spendings__c mSpending :spendings) {
            if (mSpending.Date__c == mmsDuplicate.Date__c) {
                // Media_Spend__c and Delivered__c are replaced with values from Duplicated Record
                System.assertEquals(mmsDuplicate.Media_Spend__c, mSpending.Media_Spend__c);
                System.assertEquals(mmsDuplicate.Delivered__c, mSpending.Delivered__c);
            } else {
                // No changes here for mediaSpending2
                System.assertEquals(mediaSpending2.Media_Spend__c, mSpending.Media_Spend__c);
                System.assertEquals(mediaSpending2.Delivered__c, mSpending.Delivered__c);
            }
        }
    }

    @IsTest static void recalculateProjectInvoiceAmountAfterMMSpendingDeleted() {
        MM_Spendings__c mediaSpending1, mediaSpending2;
        Project__c contract = [SELECT Id, End_Date__c, Start_Date__c FROM Project__c LIMIT 1];

        List<MM_Spendings__c> spendings = [SELECT Date__c, Delivered__c, Media_Spend__c, Contract__c, Strike_ID__c FROM MM_Spendings__c WHERE Contract__c = :contract.Id];
        Set<String> strikeIds = new Set<String>();
        // there are two existing MMSpendings
        System.assertEquals(2, spendings.size());
        for (MM_Spendings__c mSpending :spendings) {
            strikeIds.add(mSpending.Strike_ID__c);

            if (mSpending.Date__c == contract.End_Date__c) {
                mediaSpending1 = mSpending;
            } else {
                mediaSpending2 = mSpending;
            }
        }
        System.assertNotEquals(mediaSpending1, null);
        System.assertNotEquals(mediaSpending2, null);

        List<Project_Media_Spend__c> cmss = [SELECT Id, Amount__c, Date__c, Delivered__c, Project__c FROM Project_Media_Spend__c WHERE MMSpending__c IN :spendings];
        Set<Id> projectIds = new Set<Id>();
        for (Project_Media_Spend__c cms :cmss) {
            projectIds.add(cms.Project__c);
        }
        List<Payment__c> projects = [SELECT Id, InvoiceAmount__c, Start_Date__c, End_Date__c, Project__c FROM Payment__c WHERE Id IN :projectIds];

        System.assertEquals(projects.size(), 1, 'There should be one project for the MMSpendings above.');

        Test.startTest();
        delete mediaSpending1;
        Payment__c projectWithDeletedMMSpending = [SELECT Id, InvoiceAmount__c, Start_Date__c, End_Date__c, Project__c FROM Payment__c WHERE Id = :projects[0].Id];
        System.assert(projects[0].InvoiceAmount__c > projectWithDeletedMMSpending.InvoiceAmount__c, 'Invoice Amount should be decreased regarding deletion of MMSpending record');
        Test.stopTest();
    }

    @IsTest static void logErrorWhenSpendNotAssigned() {
        Project__c contract = [SELECT Id, End_Date__c, Start_Date__c FROM Project__c LIMIT 1];

        Test.startTest();
        insert new List<MM_Spendings__c> {
            TestHelper.createMediaSpendings(contract.Id, contract.End_Date__c),
            TestHelper.createMediaSpendings(contract.Id, contract.End_Date__c.addDays(1)) // for that record a log should be created
        };
        Test.stopTest();

        List<EventLog__c> logs = [SELECT Id, MMSpending__c, Contract__c FROM EventLog__c WHERE Status__c = :EventLog.STATUS_ERROR AND Type__c = :EventLog.TYPE_INVOICE_API_SYNC];
        System.assertEquals(1, logs.size());
    }

    @IsTest static void checkingForDuplicateSpendsOnInsert() {
        Project__c contract = [SELECT Id, End_Date__c, Start_Date__c FROM Project__c LIMIT 1];

        List<MM_Spendings__c> newMediaSpends = new List<MM_Spendings__c> {
            TestHelper.createMediaSpendings(contract.Id, contract.Start_Date__c),
            TestHelper.createMediaSpendings(contract.Id, contract.Start_Date__c), // duplicate
            TestHelper.createMediaSpendings(contract.Id, contract.Start_Date__c)  // duplicate
        };
        List<Project_Media_Spend__c> existingProjectMediaSpends = [SELECT Id, MMSpending__c, Project__c,Date__c FROM Project_Media_Spend__c];

        Test.startTest();
        insert newMediaSpends;
        Test.stopTest();

        System.assertEquals(existingProjectMediaSpends.size() + 1, [SELECT Id FROM Project_Media_Spend__c].size());
    }

    @IsTest static void updateExistingMMSpendsWhileProjectMediaSpendNoExist() {
        Project__c contract = [SELECT Id, End_Date__c, Start_Date__c FROM Project__c LIMIT 1];

        List<Payment__c> projects = [SELECT StrikeId__c FROM Payment__c WHERE Project__c = :contract.Id];
        System.assertEquals(2, projects.size());
        String strikeId = projects[0].StrikeId__c;


        List<MM_Spendings__c> existingMediaSpends = [SELECT Id, Delivered__c, Media_Spend__c, StrikeId__c FROM MM_Spendings__c WHERE Contract__c = :contract.Id];
        List<Project_Media_Spend__c> existingProjectMediaSpends = [SELECT Id, MMSpending__c, Project__c,Date__c FROM Project_Media_Spend__c];
        delete existingProjectMediaSpends;
        System.assertEquals([SELECT Id FROM Project_Media_Spend__c].size(), 0, 'No Contract Media Spends should exist.');

        Test.startTest();
        for (MM_Spendings__c existingMediaSpend :existingMediaSpends) {
            existingMediaSpend.Delivered__c = existingMediaSpend.Delivered__c + 10;
            existingMediaSpend.Media_Spend__c = existingMediaSpend.Media_Spend__c + 100;
            existingMediaSpend.StrikeId__c = strikeId;
        }
        update existingMediaSpends;
        Test.stopTest();

        System.assertEquals([SELECT Id FROM Project_Media_Spend__c].size(), existingProjectMediaSpends.size(), 'By updating Media Spends new Contract Media Spends should be created.');
    }

}