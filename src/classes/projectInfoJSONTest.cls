@isTest
private class projectInfoJSONTest {

    @isTest static void testContructor() {
        TestHelper.setupEnv();
        Project__c contract = TestHelper.contracts[0];

        VideoUrl__c url1 = TestHelper.createVideoUrl();
        url1.Contract__c = contract.Id;
        url1.Name += '1';
        url1.Platform__c = 'TrueView';
        url1.Format__c = 'Video';
        url1.Url__c += '1';
        url1.StartDate__c = contract.Start_date__c;
        url1.EndDate__c = contract.End_Date__c;
        url1.Rotation__c = 1;
		url1.Salesforce_ID__c = 'a0A5B0000015XdKUAU';

        VideoUrl__c url2 = TestHelper.createVideoUrl();
        url2.Contract__c = contract.Id;
        url2.Name += '2';
        url2.Platform__c = 'TrueView';
        url2.Format__c = 'Video';
        url2.Url__c += '2';
        url2.StartDate__c = contract.Start_date__c;
        url2.EndDate__c = contract.End_Date__c;
        url2.Rotation__c = 1;
        url2.Salesforce_ID__c = 'a0A5B0000015XdKUAT';

        insert new List<VideoUrl__c> { url1, url2};

        Test.startTest();
            projectInfoJSON str = new projectInfoJSON(ContractRepository.getContractForMMSync(contract.Id));
        Test.stopTest();

        System.assertNotEquals('', str.strike_project_id);
        System.assertNotEquals('missing in SF', str.name);
        System.assertEquals(2, str.youtube_urls.size());

        ProjectInfoJSON.VideoUrl video1 = (ProjectInfoJSON.VideoUrl)str.youtube_urls[0];
        ProjectInfoJSON.VideoUrl video2 = (ProjectInfoJSON.VideoUrl)str.youtube_urls[1];

        System.assertEquals(url1.Salesforce_ID__c, video1.salesforce_id);
        System.assertEquals(url2.Salesforce_ID__c, video2.salesforce_id);
    }

    @isTest static void videoUrl_assignId_OnExternalIdNull() {
        TestHelper.setupEnv();
        Project__c contract = TestHelper.contracts[0];

        VideoUrl__c url1 = TestHelper.createVideoUrl();
        url1.Contract__c = contract.Id;
        url1.Name += '1';
        url1.Platform__c = 'TrueView';
        url1.Format__c = 'Video';
        url1.Url__c += '1';
        url1.StartDate__c = contract.Start_date__c;
        url1.EndDate__c = contract.End_Date__c;
        url1.Rotation__c = 1;

        VideoUrl__c url2 = TestHelper.createVideoUrl();
        url2.Contract__c = contract.Id;
        url2.Name += '2';
        url2.Platform__c = 'TrueView';
        url2.Format__c = 'Video';
        url2.Url__c += '2';
        url2.StartDate__c = contract.Start_date__c;
        url2.EndDate__c = contract.End_Date__c;
        url2.Rotation__c = 1;

        insert new List<VideoUrl__c> { url1, url2};

        Test.startTest();
            projectInfoJSON str = new projectInfoJSON(ContractRepository.getContractForMMSync(contract.Id));
        Test.stopTest();

        System.assertNotEquals('', str.strike_project_id);
        System.assertNotEquals('missing in SF', str.name);
        System.assertEquals(2, str.youtube_urls.size());

        ProjectInfoJSON.VideoUrl video1 = (ProjectInfoJSON.VideoUrl)str.youtube_urls[0];
        ProjectInfoJSON.VideoUrl video2 = (ProjectInfoJSON.VideoUrl)str.youtube_urls[1];

        System.assertEquals(url1.id, video1.salesforce_id);
        System.assertEquals(url2.id, video2.salesforce_id);
    }

	@isTest static void contract_AssignId_OnExternalIdNull() {
        TestHelper.setupEnv();
        Project__c contract = TestHelper.contracts[0];

        Test.startTest();
            projectInfoJSON str = new projectInfoJSON(ContractRepository.getContractForMMSync(contract.Id));
        Test.stopTest();

        System.assertEquals(contract.Id, str.salesforce_id);
    }    

    @isTest static void contract_AssignId_OnExternalIdNotNull() {
        TestHelper.setupEnv();
        Project__c contract = TestHelper.contracts[0];

        Test.startTest();
            projectInfoJSON str = new projectInfoJSON(ContractRepository.getContractForMMSync(contract.Id));
        Test.stopTest();

        System.assertEquals(contract.Id, str.salesforce_id);
    }

	@isTest static void testJSONFormat() {
        TestHelper.setupEnv();
        Project__c contract = TestHelper.contracts[0];

        projectInfoJSON str = new projectInfoJSON(ContractRepository.getContractForMMSync(contract.Id));

        Test.startTest();
            String result = str.getJSONFormat();
        Test.stopTest();
    }
}