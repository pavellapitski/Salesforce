@IsTest
private class OpportunityEditExtTest {

    private static Platform__c platformTrueView;
    private static Platform__c platformFacebook;
    private static Platform__c platformLinkedIn;
    private static AdPlacement__c adPlacementInStream;
    private static AdPlacement__c adPlacementInSearch;
    private static AdPlacement__c adPlacementInDisplay;
    private static AdPlacement__c adPlacementDesktopNewsFeed;
    private static AdPlacement__c adPlacementInstagram;
    private static AdPlacement__c adPlacementInbox;

    private static void setupPlatforms() {
        platformTrueView = TestHelper.createPlatform('TrueView', 'TV');
        platformFacebook = TestHelper.createPlatform('Facebook', 'FB');
        platformLinkedIn = TestHelper.createPlatform('Linkedin', 'LN');
        insert new List<Platform__c>{platformFacebook, platformTrueView, platformLinkedIn};

        adPlacementInStream = TestHelper.createAdPlacement(platformTrueView.Id, 'InStream');
        adPlacementInSearch = TestHelper.createAdPlacement(platformTrueView.Id, 'InSearch');
        adPlacementInDisplay = TestHelper.createAdPlacement(platformTrueView.Id, 'InDisplay');
        adPlacementDesktopNewsFeed = TestHelper.createAdPlacement(platformFacebook.Id, 'Desktop News Feed');
        adPlacementInstagram = TestHelper.createAdPlacement(platformFacebook.Id, 'Instagram');
        adPlacementInbox = TestHelper.createAdPlacement(platformLinkedIn.Id, 'Linkedin');
        insert new List<AdPlacement__c> {adPlacementInStream, adPlacementInSearch, adPlacementInDisplay, adPlacementDesktopNewsFeed, adPlacementInstagram, adPlacementInbox};
    }

    private static void assignPlatformsToOpportunity(OpportunityEditExt oppController) {
        oppController.platformsMap.get(platformTrueView.Id).isSelected = true;
        oppController.platformsMap.get(platformTrueView.Id).adPlacementsMap.get(adPlacementInStream.Id).isSelected = true;
        oppController.platformsMap.get(platformTrueView.Id).adPlacementsMap.get(adPlacementInSearch.Id).isSelected = true;
        oppController.platformsMap.get(platformFacebook.Id).isSelected = true;
        oppController.platformsMap.get(platformFacebook.Id).adPlacementsMap.get(adPlacementInstagram.Id).isSelected = true;
        oppController.saveOpportunity();
    }

    @IsTest  private static void willCreateNewBrand() {
        String newBrandName = 'NewTestBrand';

        User usr = TestHelper.createUser();
        Account acc = TestHelper.createAccount();
        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        opp.Brand__c = null;

        Test.setCurrentPage(Page.OpportunityEdit);
        Test.startTest();
        OpportunityEditExt oppController = new OpportunityEditExt(new ApexPages.StandardController(opp));
        oppController.createBrand();
        oppController.cancelCreateBrand();
        oppController.brandUpdated();
        oppController.createBrand();
        oppController.brand.Name = newBrandName;
        oppController.saveOpportunity();
        Test.stopTest();

        System.assertEquals(newBrandName, [SELECT Brand__r.Name FROM Opportunity WHERE Id = :oppController.opp.Id].Brand__r.Name);
    }

    @IsTest  private static void willCreateVideoUrl() {
        Test.setCurrentPage(Page.OpportunityEdit);

        Account acc = TestHelper.createAccount();
        User usr = TestHelper.createUser();
        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        insert opp;

        VideoUrl__c videoUrl = TestHelper.createVideoUrl();
        videoUrl.Opportunity__c = opp.Id;
        videoUrl.Platform__c = 'TrueView';
        videoUrl.Format__c = 'Video';
        videoUrl.StartDate__c = opp.Flight_Start__c;
        videoUrl.EndDate__c = opp.Flight_End__c;
        insert videoUrl;

        Test.startTest();
        OpportunityEditExt controller = new OpportunityEditExt(new ApexPages.StandardController(opp));
        System.assertEquals(1, controller.videoURLs.size());

        controller.videoUrlRow = 0;
        controller.deleteVideoUrl();
        System.assertEquals(0, controller.videoURLs.size());

        controller.addNewVideoUrl();
        System.assertEquals(1, controller.videoURLs.size());

        controller.videoURLs[0].Name = 'Placeholder';
        controller.videoURLs[0].IsPlaceholder__c = true;
        controller.videoURLs[0].Platform__c = 'TrueView';
        controller.videoURLs[0].Format__c = 'Video';
        controller.videoURLs[0].StartDate__c = opp.Flight_Start__c;
        controller.videoURLs[0].EndDate__c = opp.Flight_End__c;
        controller.saveOpportunity();
        Test.stopTest();

        List<VideoUrl__c> insertedUrl = [SELECT IsPlaceholder__c FROM VideoUrl__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, insertedUrl.size());
        System.assertEquals(true, insertedUrl[0].IsPlaceholder__c);
    }

    @IsTest  private static void createNewAccount() {
        Test.setCurrentPage(Page.OpportunityEdit);
        Test.startTest();
            OpportunityEditExt controller = new OpportunityEditExt(new ApexPages.StandardController(new Opportunity()));
            controller.createAccount();
            controller.newAccount = TestHelper.createAccount('MyAccName', false);
            System.assert(String.isBlank(controller.newAccount.Id));

            controller.saveAccount();
        Test.stopTest();

        System.assert(!String.isBlank(controller.newAccount.Id));
        System.assertEquals(controller.newAccount.Id, controller.opp.AccountId);
    }

    @IsTest  private static void setPlatformsOnInsert() {
        Test.setCurrentPage(Page.OpportunityEdit);

        Account acc = TestHelper.createAccount();
        User usr = TestHelper.createUser();
        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        setupPlatforms();

        Test.startTest();
        OpportunityEditExt controller = new OpportunityEditExt(new ApexPages.StandardController(opp));
        System.assertEquals(3, controller.getPlatforms().size());

        PlatformWrapper TVPlatform = controller.platformsMap.get(platformTrueView.Id);
        TVPlatform.oppPlatform.CostStructure__c = 'CPV';
        TVPlatform.oppPlatform.CTA_Overlay_Text__c = 'Test CTA Overlay TEXT';
        TVPlatform.oppPlatform.KPI__c = 'Test KPI';
        TVPlatform.oppPlatform.Companion_Banner__c = 'Yes';
        TVPlatform.oppPlatform.Pixel_Tracking__c = 'Yes';
        TVPlatform.oppPlatform.Brand_Lift_Study__c = 'Yes';
        System.assertEquals(3, TVPlatform.adPlacementsMap.size());

        PlatformWrapper facebookPlatform = controller.platformsMap.get(platformFacebook.Id);
        facebookPlatform.oppPlatform.CostStructure__c = 'CPV';
        facebookPlatform.oppPlatform.CTA_Overlay_Text__c = 'Test CTA Overlay TEXT';
        facebookPlatform.oppPlatform.KPI__c = 'Test KPI';
        facebookPlatform.oppPlatform.Companion_Banner__c = 'Yes';
        facebookPlatform.oppPlatform.Pixel_Tracking__c = 'Yes';
        facebookPlatform.oppPlatform.Brand_Lift_Study__c = 'Yes';
        System.assertEquals(2, facebookPlatform.adPlacementsMap.size());

        PlatformWrapper linkedInPlatform = controller.platformsMap.get(platformLinkedIn.Id);
        linkedInPlatform.oppPlatform.CostStructure__c = 'CPM';
        linkedInPlatform.oppPlatform.CostStructure__c = 'CPM';
        linkedInPlatform.oppPlatform.CTA_Overlay_Text__c = 'Test CTA Overlay TEXT';
        linkedInPlatform.oppPlatform.KPI__c = 'Test KPI';
        linkedInPlatform.oppPlatform.Companion_Banner__c = 'Yes';
        linkedInPlatform.oppPlatform.Pixel_Tracking__c = 'Yes';
        linkedInPlatform.oppPlatform.Brand_Lift_Study__c = 'Yes';
        System.assertEquals(1, linkedInPlatform.adPlacementsMap.size());

        assignPlatformsToOpportunity(controller);
        Test.stopTest();

        System.assertEquals(2, [SELECT Id FROM OpportunityPlatform__c WHERE Opportunity__c = :opp.Id].size());
        System.assertEquals(3, [SELECT Id FROM OpportunityAdPlacement__c WHERE Opportunity__c = :opp.Id].size());
    }

    @IsTest  private static void updatePlatforms() {
        Test.setCurrentPage(Page.OpportunityEdit);

        Account acc = TestHelper.createAccount();
        User usr = TestHelper.createUser();
        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        insert opp;
        setupPlatforms();

        Test.startTest();
        OpportunityEditExt oppControllerNew = new OpportunityEditExt(new ApexPages.StandardController(opp));

        PlatformWrapper TVPlatform = oppControllerNew.platformsMap.get(platformTrueView.Id);
        TVPlatform.oppPlatform.CostStructure__c = 'CPV';
        TVPlatform.oppPlatform.CostStructure__c = 'CPV';
        TVPlatform.oppPlatform.CTA_Overlay_Text__c = 'Test CTA Overlay TEXT';
        TVPlatform.oppPlatform.KPI__c = 'Test KPI';
        TVPlatform.oppPlatform.Companion_Banner__c = 'Yes';
        TVPlatform.oppPlatform.Pixel_Tracking__c = 'Yes';
        TVPlatform.oppPlatform.Brand_Lift_Study__c = 'Yes';

        PlatformWrapper facebookPlatform = oppControllerNew.platformsMap.get(platformFacebook.Id);
        facebookPlatform.oppPlatform.CostStructure__c = 'CPV';
        facebookPlatform.oppPlatform.CostStructure__c = 'CPV';
        facebookPlatform.oppPlatform.CostStructure__c = 'CPV';
        facebookPlatform.oppPlatform.CTA_Overlay_Text__c = 'Test CTA Overlay TEXT';
        facebookPlatform.oppPlatform.KPI__c = 'Test KPI';
        facebookPlatform.oppPlatform.Companion_Banner__c = 'Yes';
        facebookPlatform.oppPlatform.Pixel_Tracking__c = 'Yes';
        facebookPlatform.oppPlatform.Brand_Lift_Study__c = 'Yes';

        PlatformWrapper linkedInPlatform = oppControllerNew.platformsMap.get(platformLinkedIn.Id);
        linkedInPlatform.oppPlatform.CostStructure__c = 'CPM';
        linkedInPlatform.oppPlatform.CTA_Overlay_Text__c = 'Test CTA Overlay TEXT';
        linkedInPlatform.oppPlatform.KPI__c = 'Test KPI';
        linkedInPlatform.oppPlatform.Companion_Banner__c = 'Yes';
        linkedInPlatform.oppPlatform.Pixel_Tracking__c = 'Yes';
        linkedInPlatform.oppPlatform.Brand_Lift_Study__c = 'Yes';

        assignPlatformsToOpportunity(oppControllerNew);

        OpportunityEditExt oppControllerEdit = new OpportunityEditExt(new ApexPages.StandardController(opp));
        Map<Id, PlatformWrapper> platformsMap = oppControllerEdit.platformsMap;
        System.assertEquals(3, platformsMap.size());

        System.assert(platformsMap.get(platformTrueView.Id).isSelected);
        System.assert(platformsMap.get(platformFacebook.Id).isSelected);
        System.assert(!platformsMap.get(platformLinkedIn.Id).isSelected);
        platformsMap.get(platformFacebook.Id).isSelected = false;
        oppControllerEdit.saveOpportunity();
        Test.stopTest();

        System.assertEquals(1, [SELECT Id, Platform__r.Name FROM OpportunityPlatform__c WHERE Opportunity__c = :opp.Id].size());
        System.assertEquals(2, [SELECT Id FROM OpportunityAdPlacement__c WHERE Opportunity__c = :opp.Id].size());
    }

    @IsTest  private static void redirectOnClosedWon() {
        Test.setCurrentPage(Page.OpportunityEdit);

        Account acc = TestHelper.createAccount();
        User usr = TestHelper.createUser();
        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        opp.Brand__c = TestHelper.createBrand('testBrand').Id;
        insert opp;

        OpportunityPlatform__c oppPlatform = TestHelper.createOpportunityPlatform(opp.Id, TestHelper.getTrueViewPlatform().Id);
        oppPlatform.NoCostStructure__c = true;
        insert oppPlatform;

        Test.startTest();
        OpportunityEditExt oppController = new OpportunityEditExt(new ApexPages.StandardController(opp));
        oppController.opp.StageName = ContactOpportunityHandler.CLOSED_WON;
        PageReference page = oppController.saveOpportunity();
        Test.stopTest();

        List<Project__c> contract = [SELECT Id FROM Project__c WHERE Opportunity__c = :oppController.opp.Id];
        System.assert(page.getUrl().contains(contract[0].Id));
    }

    @IsTest  private static void createOpportunityClosedWon() {
        Test.setCurrentPage(Page.OpportunityEdit);

        Account acc = TestHelper.createAccount();
        User usr = TestHelper.createUser();
        setupPlatforms();
        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        opp.Brand__c = TestHelper.createBrand('testBrand').Id;

        Test.startTest();
        OpportunityEditExt oppController = new OpportunityEditExt(new ApexPages.StandardController(opp));
        oppController.opp.StageName = ContactOpportunityHandler.CLOSED_WON;

        PlatformWrapper selectedPlatform = oppController.platformsMap.get(platformTrueView.Id);
        selectedPlatform.isSelected = true;
        selectedPlatform.oppPlatform.CostStructure__c = 'CPV';
        selectedPlatform.oppPlatform.CTA_Overlay_Text__c = 'Test CTA Overlay TEXT';
        selectedPlatform.oppPlatform.KPI__c = 'Test KPI';
        selectedPlatform.oppPlatform.Companion_Banner__c = 'Yes';
        selectedPlatform.oppPlatform.Pixel_Tracking__c = 'Yes';
        selectedPlatform.oppPlatform.Brand_Lift_Study__c = 'Yes';

        PageReference page = oppController.saveOpportunity();
        Test.stopTest();

        List<Project__c> contract = [SELECT Id FROM Project__c WHERE Opportunity__c = :oppController.opp.Id];
        System.assert(page.getUrl().contains(contract[0].Id));
    }

    @IsTest private static void redirectNotWon() {
        Test.setCurrentPage(Page.OpportunityEdit);

        Account acc = TestHelper.createAccount();
        User usr = TestHelper.createUser();
        Opportunity opp = TestHelper.createOpportunity(usr, acc);

        Test.startTest();
        OpportunityEditExt oppController = new OpportunityEditExt(new ApexPages.StandardController(opp));
        PageReference page = oppController.saveOpportunity();
        Test.stopTest();

        System.assert(page.getUrl().contains(oppController.opp.Id));
    }

    @IsTest
    public static void updateRelatedOppPlatformsOnPlatformAccountUpdate_Error() {
        User user = TestHelper.createUser();
        insert TestHelper.brandRecord;
        Account account = new Account(Name = 'Test1 Acc');

        Platform__c platDBM = TestHelper.createPlatform('DBM TrueView', 'DT');
        Platform__c platAW = TestHelper.createPlatform('TrueView', 'TV');
        Platform__c platFB = TestHelper.createPlatform('Facebook', 'FB');
        platFB.Provider__c = 'Adwords';
        insert new List<Platform__c>{platDBM, platAW, platFB};

        Opportunity opp = TestHelper.createOpportunity(user, account);
        opp.Platforms__c = 'Facebook';
        insert opp;

        Project__c contract = TestHelper.createContractWithTwoOppPlatformsNoInsert(account.Id, 'ContractName', opp.Id);
        contract.Brand__c = TestHelper.brandRecord.Id;
        insert contract;

        OpportunityPlatform__c oppPlatform1 = TestHelper.createOpportunityPlatform(opp.Id, contract.Id, platAW.Id);
        OpportunityPlatform__c oppPlatform2 = TestHelper.createOpportunityPlatform(opp.Id, contract.Id, platDBM.Id);
        OpportunityPlatform__c oppPlatform3 = TestHelper.createOpportunityPlatform(opp.Id, contract.Id, platFB.Id);
        insert new List<OpportunityPlatform__c>{oppPlatform1, oppPlatform2, oppPlatform3};

        oppPlatform1.PlatformAccount__c = '191-038-1121';
        oppPlatform2.PlatformAccount__c = '191';
        oppPlatform3.PlatformAccount__c = '1789741037925615';
        update new List<OpportunityPlatform__c>{oppPlatform1, oppPlatform2, oppPlatform3};

        Test.startTest();
        OpportunityEditExt ctrl = new OpportunityEditExt(new ApexPages.StandardController(opp));
        ctrl.updateRelatedOppPlatforms();
        Test.stopTest();
        System.assertEquals(true, ApexPages.getMessages()[0].getSummary().contains(OpportunityEditExt.ERROR_DIFFERENT_PLATFORM_ACCOUNT));
    }

    @IsTest public static void updateRelatedOppPlatforms_On_PlatformAccountUpdate_Success() {
        User user = TestHelper.createUser();
        Account account = new Account(Name = 'Test1 Acc');
        insert TestHelper.brandRecord;

        Platform__c platDBM = TestHelper.createPlatform('DBM TrueView', 'DT');
        Platform__c platAW = TestHelper.createPlatform('TrueView', 'TV');
        Platform__c platFB = TestHelper.createPlatform('Facebook', 'FB');
        insert new List<Platform__c>{platDBM, platAW, platFB};

        Opportunity opp = TestHelper.createOpportunity(user, account);
        opp.Platforms__c = 'Facebook';
        opp.Brand__c = TestHelper.brandRecord.Id;
        insert opp;

        Project__c contract = TestHelper.createContractWithTwoOppPlatformsNoInsert(account.Id, 'ContractName', opp.Id);
        insert contract;

        OpportunityPlatform__c oppPlatform1 = TestHelper.createOpportunityPlatform(opp.Id, platAW);
        oppPlatform1.Contract__c = contract.Id;
        OpportunityPlatform__c oppPlatform2 = TestHelper.createOpportunityPlatform(opp.Id, platFB);
        oppPlatform2.Contract__c = contract.Id;
        // Do not set PlatformAccount for oppPlatform3
        OpportunityPlatform__c oppPlatform3 = TestHelper.createOpportunityPlatform(opp.Id, contract.Id, platFB.Id);
        oppPlatform3.PlatformAccount__c = '';
        insert new List<OpportunityPlatform__c>{oppPlatform1, oppPlatform2, oppPlatform3};

        OpportunityEditExt ctrl = new OpportunityEditExt(new ApexPages.StandardController(opp));
        ctrl.updateRelatedOppPlatforms();

        System.assertEquals(oppPlatform2.PlatformAccount__c, [SELECT Id, PlatformAccount__c FROM OpportunityPlatform__c WHERE Id = :oppPlatform3.Id].PlatformAccount__c);
    }

    @IsTest public static void updateRelatedOppPlatforms_On_PlatformAccountUpdate_SamePlatformAccs() {
        User usr = TestHelper.createUser();
        Account acc = new Account(Name = 'Test1 Acc');
        insert TestHelper.brandRecord;

        Platform__c platDBM = TestHelper.createPlatform('DBM TrueView', 'DT');
        Platform__c platAW = TestHelper.createPlatform('TrueView', 'TV');
        Platform__c platFB = TestHelper.createPlatform('Facebook', 'FB');
        insert new List<Platform__c>{platDBM, platAW, platFB};

        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        opp.Platforms__c = 'Facebook';
        opp.Brand__c = TestHelper.brandRecord.Id;
        insert opp;

        Project__c pr = TestHelper.createContractWithTwoOppPlatformsNoInsert(acc.Id, 'ContractName', opp.Id);
        insert pr;

        OpportunityPlatform__c oppPlatform1 = TestHelper.createOpportunityPlatform(opp.Id, platAW);
        oppPlatform1.Contract__c = pr.Id;
        OpportunityPlatform__c oppPlatform2 = TestHelper.createOpportunityPlatform(opp.Id, platFB);
        oppPlatform2.Contract__c = pr.Id;
        OpportunityPlatform__c oppPlatform3 = TestHelper.createOpportunityPlatform(opp.Id, pr.Id, platFB.Id);
        // set PlatformAccount as it's set on oppPlatform2
        oppPlatform3.PlatformAccount__c = oppPlatform2.PlatformAccount__c;
        insert new List<OpportunityPlatform__c>{oppPlatform1, oppPlatform2, oppPlatform3};

        OpportunityEditExt ctrl = new OpportunityEditExt(new ApexPages.StandardController(opp));
        ctrl.updateRelatedOppPlatforms();

        System.assertEquals(oppPlatform2.PlatformAccount__c, [SELECT Id, PlatformAccount__c FROM OpportunityPlatform__c WHERE Id = :oppPlatform3.Id].PlatformAccount__c);
    }

    @IsTest public static void updateOwnerTest() {
        User testUser = TestHelper.createUser();
        Platform__c platformFB = TestHelper.createPlatform('Facebook', 'FB');
        insert platformFB;

        Opportunity opp = TestHelper.createOpportunity(testUser, TestHelper.createAccount());
        opp.Platforms__c = 'Facebook';
        insert opp;

        User otherUser = [
            SELECT LastName,Id
            FROM User
            WHERE Id != :UserInfo.getUserId()
                AND IsActive = TRUE
                AND ProfileId IN (SELECT Id FROM Profile WHERE Name IN ('Sales User','Sales Manager'))
            LIMIT 1
        ];
        System.assert(otherUser != null);

        List<User> foundUsers = OpportunityEditExt.searchSalesUsers(otherUser.LastName);
        Test.startTest();
        OpportunityEditExt.updateOwner(opp.Id, foundUsers[0].Id);
        Test.stopTest();

        System.assertEquals(foundUsers[0].Id, [SELECT OwnerId FROM Opportunity WHERE Id = :opp.Id].OwnerId);
    }

    @IsTest static void cloneOpportunitySetParam() {
        Test.setCurrentPage(Page.OpportunityEdit);

        Account acc = TestHelper.createAccount();
        User usr = TestHelper.createUser();
        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        opp.Name = 'Test';
        insert opp;

        Test.startTest();
        OpportunityEditExt oppController = new OpportunityEditExt(new ApexPages.StandardController(opp));
        PageReference result = oppController.cloneOpportunity();
        Test.stopTest();

        String isCloned = result.getParameters().get('isCloned');
        System.assertEquals(String.valueOf(true), isCloned);
    }

    @IsTest static void cloneOpportunityChangeNames() {
        PageReference oppPage = Page.OpportunityEdit;
        oppPage.getParameters().put('isCloned', 'true');
        Test.setCurrentPage(oppPage);

        Account acc = TestHelper.createAccount();
        User usr = TestHelper.createUser();
        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        opp.Name = 'Test';
        insert opp;

        Test.startTest();
        OpportunityEditExt oppController = new OpportunityEditExt(new ApexPages.StandardController(opp));
        Test.stopTest();

        System.assertEquals('Test (COPY)',oppController.opp.Name);
    }

    @IsTest private static void cloneOpportunityWithoutAnyCreatives() {
        User standardUser = TestHelper.createUser(TestHelper.generateUniqueEmail());

        System.runAs(standardUser) {
            PageReference oppEditPage = Page.OpportunityEdit;
            Test.setCurrentPage(oppEditPage);

            Account acc = TestHelper.createAccount();
            Opportunity opp = TestHelper.createOpportunity(standardUser, acc);
            opp.Flight_Start__c = System.today();
            opp.Flight_End__c = System.today().addMonths(1);
            insert opp;

            List<VideoUrl__c> creativesToInsert = new List<VideoUrl__c>{ TestHelper.createVideoUrl(opp) };
            insert creativesToInsert;

            ApexPages.StandardController controller = new ApexPages.StandardController(opp);

            Test.startTest();
            List<VideoUrl__c> creatives = [SELECT Id FROM VideoUrl__c WHERE Opportunity__c = :opp.Id];
            System.assertEquals(creativesToInsert.size(), creatives.size());

            OpportunityEditExt pageExtension = new OpportunityEditExt(controller);

            PageReference pageForClonedOpp = pageExtension.cloneOpportunity();
            System.assertEquals(true, Boolean.valueOf(pageForClonedOpp.getParameters().get('isCloned')));
            Test.setCurrentPage(pageForClonedOpp);
            controller = new ApexPages.StandardController(opp);
            pageExtension = new OpportunityEditExt(controller);
            System.assertEquals(pageExtension.opp.Id, null, 'An Id should be NULL, because of Opp gets cloned.');

            PageReference pageForClonedAndSavedOpp = pageExtension.saveOpportunity();

            List<String> urlSplit = pageForClonedAndSavedOpp.getUrl().split('/');
            // get the last element
            String clonedOppId = urlSplit[urlSplit.size()-1];
            System.assertNotEquals((Id) opp.Id, (Id) clonedOppId, 'IDs should be different for cloned and initial OPPs.');
            System.assertEquals(0, [SELECT COUNT() FROM VideoUrl__c WHERE Opportunity__c = :clonedOppId], 'No Creatives should be cloned!');
            System.assertEquals(creativesToInsert.size(), [SELECT COUNT() FROM VideoUrl__c WHERE Opportunity__c = :opp.Id], 'Creatives for initial OPP stayed unchanged.');
            Test.stopTest();
        }
    }

    @IsTest private static void createOppFromBrandDirectAccount_BrandNotExists() {
        User standardUser = TestHelper.createUser(TestHelper.generateUniqueEmail());
        System.runAs(standardUser) {
            Account acc = TestHelper.createAccount('TestAccount', false);
            acc.RecordTypeId = AccountHandler.RT_ID_BRAND_DIRECT;
            insert acc;

            // Imitate clicking New Opportunity button from Brand Direct account page
            PageReference newOpportunityPage = Page.OpportunityEdit;
            newOpportunityPage.getParameters().put('accid', acc.Id);
            newOpportunityPage.getParameters().put('RecordType', OpportunityRepository.RT_ID_BRAND_DIRECT);
            newOpportunityPage.getParameters().put('ent', 'Opportunity');
            newOpportunityPage.getParameters().put('save_new', '1');
            Test.setCurrentPage(newOpportunityPage);

            Test.startTest();
            Opportunity newOpp = TestHelper.createOpportunity(standardUser, acc);
            newOpp.AccountId = acc.Id;
            newOpp.RecordTypeId = OpportunityRepository.RT_ID_BRAND_DIRECT;
            newOpp.StageName = 'Qualification';
            newOpp.Name = 'Test Brand Direct Opp Name';
            System.assert(String.isBlank(newOpp.Id), 'The Opportunity record should not be inserted.');

            OpportunityEditExt controller = new OpportunityEditExt(new ApexPages.StandardController(newOpp));

            System.assertEquals(controller.hideBrand, false, 'Brand doesn\'t exist, so the filed should be shown on the page.');
            controller.saveOpportunity();
            Test.stopTest();

            System.assert(String.isNotBlank(controller.opp.Id), 'A new Opportunity had to be created.');
            newOpp = [SELECT Id, Brand__c FROM Opportunity WHERE Id = :controller.opp.Id];
            System.assertEquals(newOpp.Brand__c, null, 'No Brand should be created');
        }
    }

    @IsTest private static void createOppFromBrandDirectAccount_BrandExists() {
        User standardUser = TestHelper.createUser(TestHelper.generateUniqueEmail());
        System.runAs(standardUser) {
            String brandAccountName = 'TestBrandAccount';

            Account acc = TestHelper.createAccount(brandAccountName, false);
            acc.RecordTypeId = AccountHandler.RT_ID_BRAND_DIRECT;
            insert acc;
            Brand__c brand = TestHelper.createBrand(brandAccountName);
            Brand_Account__c brandAccount = TestHelper.createBrandAccount(acc.Id, brand.Id);

            // Imitate clicking New Opportunity button from Brand Direct account page
            PageReference newOpportunityPage = Page.OpportunityEdit;
            newOpportunityPage.getParameters().put('accid', acc.Id);
            newOpportunityPage.getParameters().put('RecordType', OpportunityRepository.RT_ID_BRAND_DIRECT);
            newOpportunityPage.getParameters().put('ent', 'Opportunity');
            newOpportunityPage.getParameters().put('save_new', '1');
            Test.setCurrentPage(newOpportunityPage);

            Test.startTest();
            Opportunity newOpp = TestHelper.createOpportunity(standardUser, acc);
            newOpp.AccountId = acc.Id;
            newOpp.RecordTypeId = OpportunityRepository.RT_ID_BRAND_DIRECT;
            newOpp.StageName = 'Qualification';
            newOpp.Name = 'Test Brand Direct Opp Name';
            System.assert(String.isBlank(newOpp.Id), 'The Opportunity record should not be inserted.');

            OpportunityEditExt controller = new OpportunityEditExt(new ApexPages.StandardController(newOpp));

            System.assertEquals(controller.hideBrand, true, 'Brand has to exist, so the filed should be hidden on the page.');
            controller.saveOpportunity();
            Test.stopTest();

            System.assert(String.isNotBlank(controller.opp.Id), 'A new Opportunity had to be created.');
            newOpp = [SELECT Id, Brand__c FROM Opportunity WHERE Id = :controller.opp.Id];
            System.assertEquals(newOpp.Brand__c, brand.Id, 'No Brand should be linked.');
        }
    }

    @IsTest private static void addAndDeleteNewContactRole() {
        User usr = TestHelper.createUser();
        Account acc = TestHelper.createAccount();
        Contact c = new Contact(LastName = 'ContractTest', AccountId = acc.Id, Email = 'email@email.com');
        insert c;

        Opportunity opp = TestHelper.createOpportunity(usr, acc);
        opp.Brand__c = null;

        Test.setCurrentPage(Page.OpportunityEdit);
        Test.startTest();
        OpportunityEditExt controller = new OpportunityEditExt(new ApexPages.StandardController(opp));
        System.assertEquals(controller.contactRoles.size(), 0);
        Integer newContractRolesAmount = 2;
        for (Integer i = 0; i < newContractRolesAmount; i++) {
            controller.addNewContactRole();
        }
        System.assertEquals(controller.contactRoles.size(), newContractRolesAmount);

        // remove the last empty row
        controller.contactRoleRow = 1;
        controller.deleteContactRole();
        System.assertEquals(controller.contactRoles.size(), newContractRolesAmount -1 );

        controller.contactRoles[0].Contact__c = c.Id;
        controller.contactRoles[0].Role__c = 'Evaluator';

        controller.saveOpportunity();
        System.assertEquals([SELECT COUNT() FROM Contact_Opportunity__c WHERE Opportunity__c = :opp.Id], 1, 'Opportunity and Opportunity Contract should be created.');

        controller = new OpportunityEditExt(new ApexPages.StandardController(opp));
        System.assertEquals(controller.contactRoles.size(), 1, 'One Opportunity Contract should exist and be assigned to Opportunity.');
        controller.contactRoleRow = 0;
        controller.deleteContactRole();
        System.assertEquals([SELECT COUNT() FROM Contact_Opportunity__c WHERE Opportunity__c = :opp.Id], 0, 'Opportunity Contract should be deleted.');

        Test.stopTest();
    }

}