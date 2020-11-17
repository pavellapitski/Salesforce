/*
The class is a script used to create test data for a refreshed sandbox
*/

public class PostSandboxRefresh {
    public static Map<String, Platform__c> platformsMap = new Map<String, Platform__c>();
    private static List <Platform__c> platforms;

    public static Map <String, Object []> createObjectsForOpportunity () {
        Map <String, Object []> objects = new Map <String, Object []> ();

        Account acc0 = new Account();
        acc0.Name  		   	= 'testAcc0';
        acc0.Agency__c	   	= 'testAgency0';
        acc0.Region__c		= 'NA';
        acc0.Website		= 'www.test0.com';
        acc0.BillingCountry = 'USA';
        acc0.BillingCity	= 'Chicago';
        acc0.BillingState   = 'IL';

        Account acc1 = new Account();
        acc1.Name  		   	= 'testAcc1';
        acc1.Agency__c	   	= 'testAgency1';
        acc1.Region__c		= 'NA';
        acc1.Website		= 'www.test1.com';
        acc1.BillingCountry = 'France';
        acc1.BillingCity	= 'Paris';
        acc1.BillingState   = 'SomeState1';

        Account [] accounts = new Account [] {acc0, acc1};
        Database.insert (accounts, false);

        Brand__c brand0 = new Brand__c ();
        brand0.Name = 'BR0';

        Brand__c brand1 = new Brand__c ();
        brand1.Name = 'BR2';

        Brand__c [] brands = new Brand__c [] {brand0, brand1};
        Database.insert(brands, false);

        BillingCondition__c bc0 = TestHelper.createBillingCondition('Normal', false);
        bc0.Active__c = true;

        BillingCondition__c bc1 = TestHelper.createBillingCondition('Rebate 10% / 30%', false);
        bc1.Active__c = true;

        List<BillingCondition__c> billingConditions = new List<BillingCondition__c>{bc0, bc1};
        Database.insert(billingConditions, false);

        Platform__c platformFB = createPlatform('Facebook', 'FB'),
                    platformIG = createPlatform('Instagram', 'IG'),
                    platformTV = createPlatform('TrueView', 'TV'),
                    platformTW = createPlatform('Twitter', 'TW'),
                    platformLN = createPlatform('LinkedIn', 'LN');

        platformFB.CostStructures__c = 'CPC;CPAC';
        platformIG.CostStructures__c = 'CPC;CPE';
        platformLN.CostStructures__c = 'CPC;CPAC';
        platformTV.CostStructures__c = 'CPE';
        platformTW.CostStructures__c = 'CPE;CPAC';

        Platform__c [] platforms = new Platform__c [] {platformFB, platformIG, platformTV, platformTW, platformLN};
        for (Platform__c existingPlatform : PlatformRepository.getAvailablePlatforms()) {
            for (Integer i = 0; i < platforms.size(); i++)
            {
                if (existingPlatform.Name.equals (platforms [i].Name)) platforms.remove(i);
            }
        }
        insert platforms;

        AdPlacement__c adPlacement = createAdPlacement([SELECT Id, Name FROM Platform__c WHERE Name LIKE 'Facebook'] [0].Id, 'testAdPlacement');
        if ([SELECT Name FROM AdPlacement__c WHERE Name = 'testAdPlacement'].size() < 2) {
            insert adPlacement;
        }
        User usr = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        objects.put ('Users', new User [] {usr});
        objects.put ('Accounts', [SELECT Id, Name FROM Account WHERE Name LIKE 'testAcc%']);
        objects.put ('Brands', [SELECT Id, Name FROM Brand__c WHERE Name LIKE 'BR%']);
        objects.put ('BillingConditions', [SELECT Id, Name FROM BillingCondition__c WHERE Name LIKE 'Rebate%']);
        objects.put ('Platforms', [SELECT Id, Name FROM Platform__c ORDER BY Name]);

        return objects;
    }

    public static void createOpportunityPreMeeting (String name) {
        platforms = PlatformRepository.getAvailablePlatforms();
        for (Platform__c pl : platforms) {
            platformsMap.put (pl.Prefix__c, pl);
        }

        Map <String, Object []> objectsForOpportunity = createObjectsForOpportunity ();
        Opportunity opp = new Opportunity ();
        opp.Name = name;
        opp.Brand__c = ((Brand__c []) objectsForOpportunity.get ('Brands')) [0].Id;
        opp.AccountId = ((Account []) objectsForOpportunity.get ('Accounts')) [0].Id;
        opp.BillingCondition__c = ((BillingCondition__c []) objectsForOpportunity.get ('BillingConditions')) [0].Id;
        opp.OwnerId = ((User []) objectsForOpportunity.get ('Users')) [0].Id;
        opp.Flight_Start__c = Date.newInstance(System.today().year() + 1, 1, 1);
        opp.Flight_End__c = Date.newInstance(System.today().year() + 1, 3, 31);
        opp.CloseDate = Date.newInstance(System.today().year() + 1, 3, 31);
        opp.MeetingDate__c = System.today();
        opp.StageName = 'Qualification';
        opp.Amount = 1000000;
        opp.CurrencyIsoCode = 'USD';
        opp.IO__c = '5';
        insert opp;

        OpportunityPlatform__c oppPlatformFB = new OpportunityPlatform__c ();
        oppPlatformFB.Opportunity__c = opp.Id;
        oppPlatformFB.Platform__c = platformsMap.get ('FB').Id; // ((Platform__c) objectsForOpportunity.get ('Platforms') [3]).Id;
        oppPlatformFB.NoCostStructure__c = true;
        oppPlatformFB.Facebook_page__c = 'FB fb page';
        oppPlatformFB.Objectives__c = 'Offer Claims;Brand Awareness';
        oppPlatformFB.Companion_Banner__c = 'Yes';
        oppPlatformFB.Pixel_Tracking__c = 'Yes';
        oppPlatformFB.CTA_Overlay_Text__c = 'CTA FB';
        oppPlatformFB.PlatformAccount__c = '12345';
        oppPlatformFB.Account_Entity__c = 'US';
        oppPlatformFB.Gender__c = 'Male;Female';
        oppPlatformFB.Age_min__c = 28;
        oppPlatformFB.Age_max__c = 33;
        oppPlatformFB.KPI__c = 'FB KPI';
        insert oppPlatformFB;

        OpportunityPlatform__c oppPlatformIG = new OpportunityPlatform__c ();
        oppPlatformIG.Opportunity__c = opp.Id;
        oppPlatformIG.Platform__c = platformsMap.get ('IG').Id; // ((Platform__c) objectsForOpportunity.get ('Platforms') [5]).Id;
        oppPlatformIG.NoCostStructure__c = true;
        oppPlatformIG.Objectives__c = 'Video Views;Post Engagements;App Installs';
        oppPlatformIG.Companion_Banner__c = 'Yes';
        oppPlatformIG.Pixel_Tracking__c = 'Yes';
        oppPlatformIG.CTA_Overlay_Text__c = 'CTA IG';
        oppPlatformIG.Facebook_page__c = 'IG fb page';
        oppPlatformIG.PlatformAccount__c = '12345';
        oppPlatformIG.Account_Entity__c = 'US';
        oppPlatformIG.Gender__c = 'Female';
        oppPlatformIG.Age_min__c = 18;
        oppPlatformIG.Age_max__c = 23;
        oppPlatformIG.KPI__c = 'IG KPI';
        insert oppPlatformIG;

        OpportunityPlatform__c oppPlatformTV = new OpportunityPlatform__c ();
        oppPlatformTV.Opportunity__c = opp.Id;
        oppPlatformTV.Platform__c = platformsMap.get ('TV').Id; //((Platform__c) objectsForOpportunity.get ('Platforms') [9]).Id;
        oppPlatformTV.NoCostStructure__c = true;
        oppPlatformTV.Objectives__c = 'Conversions;Reach';
        oppPlatformTV.Companion_Banner__c = 'Yes';
        oppPlatformTV.Pixel_Tracking__c = 'Yes';
        oppPlatformTV.CTA_Overlay_Text__c = 'CTA TV';
        oppPlatformTV.PlatformAccount__c = '111-222-3333';
        oppPlatformTV.Facebook_page__c = 'TV fb page';
        oppPlatformTV.Gender__c = 'Male';
        oppPlatformTV.KPI__c = 'TV KPI';
        oppPlatformTV.Age__c = '25-34';
        insert oppPlatformTV;
    }

    public static Platform__c createPlatform(String platformName, String prefix) {
        if (!platformsMap.containsKey(prefix)) {
            Platform__c platform = new Platform__c();
            platform.Name = platformName;
            platform.Prefix__c = prefix;

            if (platformName == 'TrueView' || platformName == 'AdWords')
            platform.Provider__c = 'AdWords';

            else platform.Provider__c = 'DBM';

            if (platformName != 'TrueView') platform.Type__c = 'Social';
            else platform.Type__c = 'YT';
            platformsMap.put(prefix, platform);
        }
        System.debug ('');
        return platformsMap.get(prefix);
    }

    public static AdPlacement__c createAdPlacement(Id platformId, String adPlacementName) {
        AdPlacement__c adPlacement = new AdPlacement__c();
        adPlacement.Name = adPlacementName;
        adPlacement.Platform__c = platformId;

        return adPlacement;
    }
}