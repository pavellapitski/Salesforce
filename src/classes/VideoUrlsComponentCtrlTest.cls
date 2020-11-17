@isTest
private class VideoUrlsComponentCtrlTest
{
    private static testMethod void testCreateNewVideoForContract()
    {
        Account acc = TestHelper.createAccount();
        
        Project__c contract = TestHelper.createContractNoInsert(acc.Id, 'testContract', NULL);
        insert contract;
        
        test.startTest();
        
        VideoUrlsComponentCtrl ctrl = new VideoUrlsComponentCtrl();
        ctrl.contract = contract.Id;
        
        ctrl.addNewVideoUrl();
        ctrl.urls[0].Name = 'Placeholder';
        ctrl.urls[0].Platform__c = 'TrueView';
        ctrl.urls[0].Format__c = 'Video';
        ctrl.urls[0].isPlaceholder__c = true;
        ctrl.urls[0].StartDate__c = Contract.Start_date__c;
        ctrl.urls[0].EndDate__c = Contract.End_Date__c;
        ctrl.urls[0].Rotation__c = 1;
        
        ctrl.addNewVideoUrl();
        
        System.assertEquals(2, ctrl.getVideoUrls().size());
        
        ctrl.videoUrlRow = 1;
        ctrl.cancelNewVideoUrl();
        
        ctrl.saveVideoUrls();
        
        test.stopTest();
        
        List<VideoUrl__c> videoUrls = [SELECT Id FROM VideoUrl__c WHERE Contract__c = :contract.id];
        
        System.assertEquals(1, videoUrls.size());
    }
    
    private static testMethod void testCreateNewVideoForOpportunity()
    {
        Account acc = TestHelper.createAccount();
        
        User usr = TestHelper.createUser('testUser@strike.com');
        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        insert opp;
        
        test.startTest();
        
        VideoUrlsComponentCtrl ctrl = new VideoUrlsComponentCtrl();
        ctrl.opportunity = opp.Id;
        
        ctrl.addNewVideoUrl();
        ctrl.urls[0].Name = 'Placeholder';
        ctrl.urls[0].Platform__c = 'TrueView';
        ctrl.urls[0].Format__c = 'Video';
        ctrl.urls[0].isPlaceholder__c = true;
        ctrl.urls[0].StartDate__c = opp.Flight_Start__c;
        ctrl.urls[0].EndDate__c = opp.Flight_End__c;
        ctrl.urls[0].Rotation__c = 1;        
        
        ctrl.addNewVideoUrl();
        
        System.assertEquals(2, ctrl.getVideoUrls().size());
        
        ctrl.videoUrlRow = 1;
        ctrl.cancelNewVideoUrl();
        
        ctrl.saveVideoUrls();
        
        test.stopTest();
        
        List<VideoUrl__c> videoUrls = [SELECT Id FROM VideoUrl__c WHERE Opportunity__c = :opp.id];
        
        System.assertEquals(1, videoUrls.size());
    }
    
    private static testmethod void uploadFiles_whenSuccess() {
		Account acc = TestHelper.createAccount();        
        Project__c contract = TestHelper.createContractNoInsert(acc.Id, 'testContract', NULL);
        insert contract;
        
        test.startTest();        
        VideoUrlsComponentCtrl ctrl = new VideoUrlsComponentCtrl();
        ctrl.contract = contract.Id;   
        ctrl.csvFileBody=Blob.valueOf('Creative Name,Platform,Format,URL,Placeholder,Click Through  URL,Text,Start Date,End Date,Rotation\nTest,TrueView,Video,https://www.youtube.com/test,false,https://www.youtube.com/test,Text,09/20/2017,09/21/2017,2');
        ctrl.importCSVFile();        
        Test.stopTest();
        
        List<VideoUrl__c> videoUrls = [SELECT Id FROM VideoUrl__c WHERE Contract__c = :contract.id];
        
        System.assertEquals(1, videoUrls.size());        
    }
    
    private static testmethod void upload_When_Date_Wrong() {
		Account acc = TestHelper.createAccount();        
        Project__c contract = TestHelper.createContractNoInsert(acc.Id, 'testContract', NULL);
        insert contract;
        
        test.startTest();        
        VideoUrlsComponentCtrl ctrl = new VideoUrlsComponentCtrl();
        ctrl.csvFileBody=Blob.valueOf('Creative Name,Platform,Format,URL,Placeholder,Click Through  URL,Text,Start Date,End Date,Rotation\nTest,TrueView,Video,https://www.youtube.com/test,false,https://www.youtube.com/test,Text,2017-09-20,2017-09-21,0');
        ctrl.importCSVFile();        
        Test.stopTest();
        
        List<VideoUrl__c> videoUrls = [SELECT Id FROM VideoUrl__c WHERE Contract__c = :contract.id];        
        System.assertEquals(0, videoUrls.size());
        List<ApexPages.Message> msgList = ApexPages.getMessages();
        System.assert(msgList.size() > 0); 
        System.assertEquals('Date should be in DD/MM/YYYY or D/M/YYYY format.', msgList [0].getSummary());        
    }   
    
    private static testmethod void upload_When_Rotation_Null() {       
		Account acc = TestHelper.createAccount();        
        Project__c contract = TestHelper.createContractNoInsert(acc.Id, 'testContract', NULL);
        insert contract;
        
        test.startTest();        
        VideoUrlsComponentCtrl ctrl = new VideoUrlsComponentCtrl();
        ctrl.contract = contract.Id;   
        ctrl.csvFileBody=Blob.valueOf('Creative Name,Platform,Format,URL,Placeholder,Click Through  URL,Text,Start Date,End Date,Rotation\nTest,TrueView,Video,https://www.youtube.com/test,false,https://www.youtube.com/test,Text,09/20/2017,09/20/2017,');
        ctrl.importCSVFile();        
        Test.stopTest();
        
        List<VideoUrl__c> videoUrls = [SELECT Id FROM VideoUrl__c WHERE Contract__c = :contract.id];        
        System.assertEquals(1, videoUrls.size());
    }   
    
    private static testmethod void upload_When_Rotation_Decimal_And_Null() {       
		Account acc = TestHelper.createAccount();        
        Project__c contract = TestHelper.createContractNoInsert(acc.Id, 'testContract', NULL);
        insert contract;
        
        test.startTest();        
        VideoUrlsComponentCtrl ctrl = new VideoUrlsComponentCtrl();
        ctrl.contract = contract.Id;   
        ctrl.csvFileBody=Blob.valueOf('Creative Name,Platform,Format,URL,Placeholder,Click Through  URL,Text,Start Date,End Date,Rotation\nTest,TrueView,Video,https://www.youtube.com/test,false,https://www.youtube.com/test,Text,09/20/2017,09/21/2017,0.1\r\n' +
            				+ 'Test1,TrueView,Video,https://www.youtube.com/test,false,https://www.youtube.com/test,Text,09/20/2017,09/21/2017,0.3\r\n' +
            				+ 'Test2,TrueView,Video,https://www.youtube.com/test,false,https://www.youtube.com/test,Text,09/20/2017,09/21/2017,5\r\n' +
            				+ 'Test3,TrueView,Video,https://www.youtube.com/test,false,https://www.youtube.com/test,Text,09/20/2017,09/21/2017,\r\n' +
            				+ 'Test4,TrueView,Video,https://www.youtube.com/test,false,https://www.youtube.com/test,Text,09/20/2017,09/21/2017,6\r\n');
        ctrl.importCSVFile();        
        Test.stopTest();
        
        List<VideoUrl__c> videoUrls = [SELECT Id FROM VideoUrl__c WHERE Contract__c = :contract.id];        
        System.assertEquals(5, videoUrls.size());
    }   
    
    private static testmethod void uploadFiles_whenError() {
		Account acc = TestHelper.createAccount();        
        Project__c contract = TestHelper.createContractNoInsert(acc.Id, 'testContract', NULL);
        insert contract;
        
        test.startTest();        
        VideoUrlsComponentCtrl ctrl = new VideoUrlsComponentCtrl();
        ctrl.csvFileBody=Blob.valueOf('Creative Name,Platform,Format,URL,Placeholder,Click Through  URL,Text,Start Date,End Date,Rotation\nTest,TrueView,Video,https://www.youtube.com/test,false,https://www.youtube.com/test,Text,09/20/2017,09/21/2017,2)');
        ctrl.importCSVFile();        
        Test.stopTest();
        
        List<VideoUrl__c> videoUrls = [SELECT Id FROM VideoUrl__c WHERE Contract__c = :contract.id];        
        System.assertEquals(0, videoUrls.size());
        List<ApexPages.Message> msgList = ApexPages.getMessages();
        System.assertEquals(1, msgList.size());        
    }    
    
    private static testmethod void uploadFiles_showError_WhenPlatformMissing() {
		Account acc = TestHelper.createAccount();        
        Project__c contract = TestHelper.createContractNoInsert(acc.Id, 'testContract', NULL);
        insert contract;
        
        test.startTest();        
        VideoUrlsComponentCtrl ctrl = new VideoUrlsComponentCtrl();
        ctrl.csvFileBody=Blob.valueOf('Creative Name,Platform,Format,URL,Placeholder,Click Through  URL,Text,Start Date,End Date,Rotation\nTest,,Video,https://www.youtube.com/test,false,https://www.youtube.com/test,Text,09/20/2017,09/21/2017,2');
        ctrl.importCSVFile();        
        Test.stopTest();
        
        List<VideoUrl__c> videoUrls = [SELECT Id FROM VideoUrl__c WHERE Contract__c = :contract.id];        
        System.assertEquals(0, videoUrls.size());
        List<ApexPages.Message> msgList = ApexPages.getMessages();
        System.assertEquals(1, msgList.size());        
    }    
    
    private static testmethod void noFileSelected_ShowError() {
		Account acc = TestHelper.createAccount();        
        Project__c contract = TestHelper.createContractNoInsert(acc.Id, 'testContract', NULL);
        insert contract;
        
        test.startTest();        
        VideoUrlsComponentCtrl ctrl = new VideoUrlsComponentCtrl();
        ctrl.importCSVFile();        
        Test.stopTest();
        
        List<ApexPages.Message> msgList = ApexPages.getMessages();
        System.assertEquals(1, msgList.size()); 
        System.assertEquals('No file selected!', msgList [0].getSummary());
    }  
    
    
}