@IsTest
public class TestHelper {
    public static List<Account> accounts = new List<Account>();

    private final static String ACCOUNT_NAME = 'Test Account';
    private final static String COST_STRUCTURE = 'CPV';

    public static List<Project__c> contracts    = new List<Project__c>();
    public static List<Sub_Project__c> payments = new List<Sub_Project__c>();
    public static Map<String, Platform__c> platformsMap = new Map<String, Platform__c>();

    public static User usrRecord;

    public static Opportunity oppRecord;
    public static Project__c contract;

    public static Account createAccount() {
        return createAccount(ACCOUNT_NAME);
    }

    public static Account createAccount(String accName) {
        return createAccount(accName, true);
    }

    public static Account createAccount(String accName, Boolean doInsert) {
        Account newAccount = new Account(
            Name = accName,
            Agency__c = 'testAgency',
            BillingCountry = 'USA',
            BillingCity = 'Chicago',
            BillingState = 'Michigan',
            Region__c = 'NA'
        );
        if (doInsert) {
            insert newAccount;
        }
        accounts.add(newAccount);
        return newAccount;
    }

    public static Account createAccountByRecType(Id recordTypeId, Boolean doInsert) {
        Account newAccount = createAccount(ACCOUNT_NAME, false);
        newAccount.RecordTypeId = recordTypeId;
        if (doInsert) {
            insert newAccount;
        }
        return newAccount;
    }

    public static void createAppSettings() {
        AppSettings__c appSettings = new AppSettings__c(Name = 'Default');
        appSettings.CurrencyAPIKey__c = '123';
        appSettings.InvoiceNotificationRecipients__c = 'recipient@test.com';
        appSettings.InvoiceNotificationBcc__c = 'BccRecipient@test.com';
        appSettings.CreditNotesNotificationRecipients__c = 'recipient@test.com';
        appSettings.CreditNotesNotificationBcc__c = 'BccRecipient@test.com';
        appSettings.StrikeDataWarehouseURL__c = 'http://INVOICE_API_URL.strike.com';
        appSettings.StrikeDataWarehouseSyncToken__c = 'TOKEN';
        appSettings.StrikeDataWarehouseSyncURL__c = 'http://SYNC_API_URL.strike.com';
        appSettings.StrikeDataWarehouseSyncUser__c = 'USER';
        appSettings.StrikeDataWarehouseUser__c = 'user';
        appSettings.StrikeDataWarehouseToken__c = 'token';
        insert appSettings;
    }

    public static BillingCondition__c createBillingCondition(String conditionName) {
        return createBillingCondition(conditionName, true);
    }

    public static BillingCondition__c getBillingCondition(String conditionName) {
        if (billingConditionRecord == null) {
            createBillingCondition(conditionName, true);
        }
        return billingConditionRecord;
    }

    public static Brand__c createBrand(String brandName, Boolean doInsert) {
        brandRecord = new Brand__c(Name = brandName);
        if (doInsert) {
            insert brandRecord;
        }
        return brandRecord;
    }

    public static Brand__c createBrand(String brandName) {
        return createBrand(brandName, true);
    }

    public static Brand_Account__c createBrandAccount(Id accountId, Id brandId, Boolean doInsert) {
        Brand_Account__c brandAccount = new Brand_Account__c(Accounts__c = accountId, Brand__c = brandId);
        if (doInsert) {
            insert brandAccount;
        }
        return brandAccount;
    }

    public static Brand_Account__c createBrandAccount(Id accountId, Id brandId) {
        return createBrandAccount(accountId, brandId, true);
    }

    public static CreditNote__c createCreditNoteNoInsert(Id paymentId) {
        return new CreditNote__c(Amount__c = 1000, Payment__c = paymentId, Status__c = CreditNote.STATUS_SUBMITTED, Description__c = 'description');
    }

    public static String generateUniqueEmail() {
        return (String.valueOf(Math.round(Math.random()*1000)) + String.valueOf(System.now().format('ddMMYYYhhmmss')) + '@' + Url.getSalesforceBaseUrl().getHost()).toLowerCase();
    }

    /*

    * final
    String randStr = '';
    while (randStr.length() < len) {
       Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
       randStr += chars.substring(idx, idx+1);
    }
    return randStr;
    */

    public static String generateUniqueAlias() {
        String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randomAlias = '';
        while (randomAlias.length() < 8) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randomAlias += chars.substring(idx, idx+1);
        }
        return randomAlias;
    }

    public static User createUser(String userName, Id profileId, Boolean doInsert) {
        String uniqueEmail = generateUniqueEmail(); // 'standarduser@testorg.com'
        String uniqueAlias = generateUniqueAlias(); // 'standd'
        usrRecord = new User(
            Alias = uniqueAlias, Email = uniqueEmail, EmailEncodingKey = 'UTF-8',
            LastName = 'Testing', Username = userName, ProfileId = profileId,
            LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/Los_Angeles'
        );
        if (doInsert) {
            insert usrRecord;
        }
        return usrRecord;
    }

    public static User createUser(String userName) {
        Profile profile = profiles.get(STANDARD_USER_PROFILE_NAME);
        return createUser(userName, profile.Id, true);
    }

    public static User createClientServiceUserNoInsert() {
        Profile profile = profiles.get(CLIENT_SERVICES_PROFILE_NAME);
        usrRecord = createUser('clientService@strike.com', profile.Id, false);
        usrRecord.Client_Services_Rep__c = true;
        usrRecord.Email = 'clientServiceEmail@strike.com';
        return usrRecord;
    }

    public static User createClientServiceUser() {
        usrRecord = createClientServiceUserNoInsert();
        insert usrRecord;
        return usrRecord;
    }

    public static User createUser() {
        return createUser(generateUniqueEmail());
    }

    public static Contract_Sales_Rep__c createContractSalesRep(Id contractId) {
        Contract_Sales_Rep__c salesRep = createContractSalesRepNoInsert(contractId);
        insert salesRep;
        return salesRep;
    }

    public static Contract_Sales_Rep__c createContractSalesRepNoInsert(Id contractId, Id commissionProfileId) {
        Contract_Sales_Rep__c salesRep = new Contract_Sales_Rep__c();
        salesRep.Contract__c 		   = contractId;
        salesRep.Commission_Profile__c = commissionProfileId;
        return salesRep;
    }

    public static Contract_Sales_Rep__c createContractSalesRepNoInsert(Id contractId) {
        return new Contract_Sales_Rep__c(
            Contract__c = contractId,
            Commission_Profile__c = createSalesCommissionProfile().Id
        );
    }

    public static Commission_Profile__c createSalesCommissionProfile() {
        Commission_Profile__c commissionProfile = new Commission_Profile__c(
            CommissionType__c = Label.COMMISSION_TYPE_DEFAULT,
            GP_Bonus__c = true,
            Salesforce_User__c = (usrRecord != null && String.isNotBlank(usrRecord.Id)) ? usrRecord.Id : createUser().Id
        );
        insert commissionProfile;
        return commissionProfile;
    }

    public static Commission_Profile__c createSalesCommissionProfile_Shared() {
        Commission_Profile__c commissionProfile = new Commission_Profile__c(
            CommissionType__c = Label.COMMISSION_TYPE_SHARED_INSIDE_SALES,
            Salesforce_User__c = (usrRecord != null && String.isNotBlank(usrRecord.Id)) ? usrRecord.Id : createUser().Id
        );
        insert commissionProfile;
        return commissionProfile;
    }

    public static Opportunity createOpportunity(User user, Account account) {
        Id salesUserProfileId = profiles.get(SALES_USER_PROFILE_NAME).Id;
        Date startDate = Date.newInstance(2015, 1, 1);
        Integer endDateDifference = 15;
        return createOpportunity(user, account, 'Test Opp', salesUserProfileId, startDate, endDateDifference, getBillingCondition('Normal'));
    }

    public static Opportunity createOpportunity(User user, Account account, String oppName, Id profileId, Date sDate, Integer endDateDifference, BillingCondition__c billingCondition) {
        Date startDate = sDate;
        Date endDate = sDate.addDays(endDateDifference);

        User clientRep = createUser('clientreptestuser@testorg.com' + Math.random(), profileId, false);

        oppRecord = new Opportunity(
            Account_Type__c = 'Strike',
            AccountId = account.Id,
            Name = oppName,
            BillingCondition__c = billingCondition.Id,
            Brand_Lift_Study__c = 'Yes',
            IO__c = 'Test IO',
            Additional_Rep__c = clientRep.Id,
            Amount = 100,
            CurrencyIsoCode = 'USD',
            Flight_End__c = endDate,
            Gender__c = 'Male',
            Geo__c = 'Test Geo',
            KPI__c = 'Test KPI',
            Percent_Margin__c = 0.10,
            MeetingNotes__c = 'meeting note',
            More_Info__c = 'Test mor info',
            OwnerId = user.Id,
            Payment_Type__c = 'Net 30',
            Flight_Start__c = startDate,
            Targeting__c = 'Test targeting',
            Verticals__c = 'Auto',
            Video_Length__c = ':15 sec',
            StageName = 'Meeting',
            CloseDate = System.today(),
            MeetingDate__c = System.today()-3,
            MeetingStatus__c = 'Short-Term Follow Up'
        );
        return oppRecord;
    }

    public static Project__c createContract(String accountId, String contractName, String oppId) {
        Project__c project = createContractNoInsert(accountId, contractName, oppId);
        insert project;
        contracts.add(project);
        return project;
    }

    public static Project__c createContractNoInsert(String accountId, String contractName, String oppId) {
        Date startDate = Date.valueOf('2015-01-01');
        Date endDate = startDate.addDays(40);
        Platform__c platformTV = getTrueViewPlatform();

        if (brandRecord.Id == null) {
            brandRecord = createBrand('testBrand' + Crypto.getRandomInteger());
        }

        if (String.isBlank(oppId)) {
            Opportunity opp;

            if (oppRecord != null) {
                opp = oppRecord;
            } else {
                accountRecord = accounts.isEmpty() ? createAccount() : accounts[0];
                if (usrRecord == null) {
                    createUser();
                }
                opp = createOpportunity(usrRecord, accountRecord);
            }

            if (String.isBlank(opp.Id)) {
                insert opp;
            }
            oppId = opp.Id;
        }

        if ([SELECT Id FROM OpportunityPlatform__c WHERE Opportunity__c = :oppId].isEmpty()) {
            insert createOpportunityPlatform(oppId, platformTV.Id);
        }

        Project__c project = new Project__c();
        project.Account__c = accountId;
        project.Account_Type__c = 'Strike';
        project.BillingCondition__c = getBillingCondition('Normal').Id;
        project.Client_Spend__c = 1234.12;
        project.Opportunity__c = oppId;
        project.CurrencyIsoCode = 'USD';
        project.End_Date__c = endDate;
        project.Geo__c = 'Test Geo';
        project.Margin__c = 0.1;
        project.Name = contractName;
        project.Start_Date__c = startDate;
        project.Brand__c = brandRecord.Id;
        return project;
    }

    // CONTRACT
    public static Project__c createContract(String accountId, String contractName) {
        return createContract(accountId, contractName, '');
    }

    public static Project__c createContract(String accountId) {
        return createContract(accountId, 'Test Contract', null);
    }

    // PAYMENT for CONTRACT
    public static Sub_Project__c createPaymentNoInsert(String contractId) {
        return new Sub_Project__c(
            Project__c = contractId,
            Name = 'Name will be changed',
            End_Date__c = Date.valueOf('2015-01-30'),
            Start_Date__c = Date.valueOf('2015-01-01'),
            Client_Spend__c = 100
        );
    }

    public static Sub_Project__c createPaymentNoInsert(Project__c contract) {
        Sub_Project__c payment = createPaymentNoInsert(contract.Id);
        payment.Client_Spend__c = contract.Client_Spend__c;
        payment.End_Date__c = contract.End_Date__c;
        payment.Start_Date__c = contract.Start_Date__c;
        payment.Margin__c = contract.Margin__c;
        return payment;
    }

    public static Payment__c createProject(Sub_Project__c payment, Boolean doInsert) {
        Payment__c project = new Payment__c(
            Name = 'Name will be changed',
            Payment__c = payment.Id,
            Project__c = payment.Project__c,
            Client_Spend__c	= payment.Client_Spend__c,
            End_Date__c = payment.End_Date__c,
            Start_Date__c = payment.Start_Date__c
        );
        if (doInsert) {
            insert project;
        }
        return project;
    }

    public static Payment__c createProject(String contractId, Date startDate, Date endDate) {
        Payment__c project = new Payment__c();
        project.CostStructure__c = COST_STRUCTURE;
        project.Project__c = contractId;
        project.Name = 'Test Payment';
        project.Client_Spend__c = 100;
        project.End_Date__c = endDate;
        project.Start_Date__c = startDate;
        project.UnitCost__c	= 0.05;
        project.OpportunityPlatform__c = createOpportunityPlatform(null, contractId, null).Id;

        return project;
    }

    // PLATFORM
    public static Platform__c createPlatform(String platformName, String prefix) {
        if (!platformsMap.containsKey(prefix)) {
            Platform__c platform = new Platform__c();
            platform.Name = platformName;
            platform.Prefix__c = prefix;

            if (platformName == 'TrueView' || platformName == 'AdWords' || platformName == 'AdWords CPM' || platformName == 'Google Search' || platformName == 'Google Display Network') {
                platform.Provider__c = 'AdWords';
            } else if (platformName == 'Facebook' || platformName == 'Instagram') {
                platform.Provider__c = 'Facebook';
            } else if (platformName == 'DBM TrueView' || platformName == 'DBM RTB') {
                platform.Provider__c = 'DBM';
            } else if (platformName == 'LinkedIn') {
                platform.Provider__c = 'LinkedIn';
            } else if (platformName == 'Pinterest') {
                platform.Provider__c = 'Pinterest';
            } else if (platformName == 'Snapchat') {
                platform.Provider__c = 'Snapchat';
            } else if (platformName == 'Twitter') {
                platform.Provider__c = 'Twitter';
            }

            if (platformName != 'TrueView') {
                platform.Type__c = 'Social';
            } else {
                platform.Type__c = 'YT';
            }
            platformsMap.put(prefix, platform);
        }
        return platformsMap.get(prefix);
    }

    public static OpportunityPlatform__c createOpportunityPlatform(String oppId, String contractId, String platformId) {
        OpportunityPlatform__c oppPlatform = createOpportunityPlatform(oppId, platformId);
        oppPlatform.Contract__c = contractId;
        oppPlatform.CTA_Overlay_Text__c = 'Z';
        return oppPlatform;
    }

    public static OpportunityPlatform__c createOpportunityPlatform(String oppId, String platformId) {
        OpportunityPlatform__c oppPlatform = new OpportunityPlatform__c();
        oppPlatform.CostStructure__c = COST_STRUCTURE;
        oppPlatform.Opportunity__c = oppId;
        oppPlatform.Platform__c = String.isNotBlank(platformId) ? platformId : createPlatform('TrueView', 'TV').Id;
        oppPlatform.CPV__c = 0.88;
        oppPlatform.CTA_Overlay_Text__c = 'Test CTA Overlay TEXT';
        oppPlatform.KPI__c = 'Test KPI';
        oppPlatform.Companion_Banner__c = 'Yes';
        oppPlatform.Pixel_Tracking__c = 'Yes';
        oppPlatform.PlatformAccount__c = '1234567890';
        oppPlatform.Account_Entity__c = 'US';
        return oppPlatform;
    }

    public static OpportunityPlatform__c createOpportunityPlatform(String oppId, Platform__c platform) {
        OpportunityPlatform__c oppPlatform = createOpportunityPlatform(oppId, platform.Id);
        if (platform.Name == 'Facebook') {
            oppPlatform.PlatformAccount__c = '1789741037925615';
            oppPlatform.Account_Entity__c = 'US';
        } else if (platform.Name == 'DBM TrueView') {
            oppPlatform.PlatformAccount__c = '1910138';
        } else if (platform.Name == 'TrueView') {
            oppPlatform.PlatformAccount__c = '000-111-2222';
        } else {
            oppPlatform.PlatformAccount__c = '1234567890';
        }
        return oppPlatform;
    }

    public static AdPlacement__c createAdPlacement(Id platformId, String adPlacementName) {
        AdPlacement__c adPlacement = new AdPlacement__c();
        adPlacement.Name = adPlacementName;
        adPlacement.Platform__c = platformId;

        return adPlacement;
    }

    public static OpportunityAdPlacement__c createOpportunityAdPlacement(String oppId, String adPlacementId) {
        OpportunityAdPlacement__c oppAdPlacement = new OpportunityAdPlacement__c();
        oppAdPlacement.Opportunity__c = oppId;
        oppAdPlacement.AdPlacement__c = adPlacementId;

        return oppAdPlacement;
    }

    public static void createMediaSpend(Id projectId, Double amount, Double views, Double impressions) {
        Decimal delivered = (views != null && views > 0) ? views : impressions;
        Project_Media_Spend__c ms = createMediaSpend(projectId, amount, delivered);
        insert ms;
    }

    public static Project_Media_Spend__c createMediaSpend(Id projectId, Decimal amount, Decimal delivered) {
        return new Project_Media_Spend__c( Project__c = projectId, Delivered__c = delivered, Amount__c = amount );
    }

    public static MM_Spendings__c createMediaSpendings(Id contractId, Date spendDate) {
        return createMediaSpendings(contractId, spendDate, 12, 1222.8, getTrueViewPlatform().Id, 'Facebook');
    }

    public static MM_Spendings__c createMediaSpendings(Id contractId, Date spendDate, Decimal delivered, Decimal mediaSpend, String platformId, String type) {
        MM_Spendings__c mm = new MM_Spendings__c(
            Contract__c = contractId,
            CurrencyIsoCode = 'USD',
            Date__c = spendDate,
            BypassValidationRule__c = true,
            Media_Spend__c = mediaSpend,
            Platform__c = platformId,
            Delivered__c = delivered,
            Type__c = type
        );
        return mm;
    }

    public static VideoUrl__c createVideoUrl() {
        VideoUrl__c videoUrl = new VideoUrl__c();
        videoUrl.Url__c = 'https://www.youtube.com/videoId';
        videoUrl.Platform__c = 'TrueView';
        videoUrl.Format__c	 = 'Video';
        videoUrl.IsPlaceholder__c = false;
        return videoUrl;
    }

    public static VideoUrl__c createVideoUrl(Opportunity opp) {
        VideoUrl__c videoUrl = createVideoUrl();
        videoUrl.Opportunity__c = opp.Id;
        videoUrl.Platform__c = 'TrueView';
        videoUrl.Format__c	 = 'Video';
        videoUrl.StartDate__c = opp.Flight_Start__c;
        videoUrl.EndDate__c = opp.Flight_End__c;
        return videoUrl;
    }

    public static Strike_Settings__c createCustomSettings() {
        Strike_Settings__c settings  = new Strike_Settings__c();
        settings.Default_Approver__c = 'test@email.test';
        settings.Second_Approver__c  = 'test@email.test2';
        settings.Admin_Emails__c     = 'test@email.test2;test@email.test';

        return settings;
    }

    // method to setup all needed records
    public static void setupEnv() {
        usrRecord = createUser();
        accountRecord = createAccount();

        Platform__c platform = createPlatform('TrueView', 'TV');
        if (String.isBlank(platform.Id)) {
            insert platform;
        }
        oppRecord = createOpportunity(usrRecord, accountRecord);
        contract   = createContract(accountRecord.Id,  'Test Contract Manual', oppRecord.Id);
    }

    public static XeroEntity__c createXeroObject(XeroSettings__c xs) {
        XeroEntity__c xeroObject = new XeroEntity__c();
        xeroObject.XeroName__c = 'testXeroName';
        xeroObject.XeroSettings__c = xs.Id;
        return xeroObject;
    }

    public static XeroSettings__c createXeroEntityByRegion(String region, Boolean doInsert) {
        XeroSettings__c xs = new XeroSettings__c(
            AccountCode__c = '400',
            ConsumerKey__c = '1234',
            ConsumerSecret__c = '1234',
            Name = 'TestXero',
            Region__c = region,
            PrivateKey__c = 'MIICXQIBAAKBgQCzMy0ZLpZMil3FBG7MgjrpvV7PA6qm9WlZonisWYKcWsHthYcZ' +
                'SNL60CkAU59bxrMZ4JveMRSt9mtOetyQMZFruia+rdmEvgFfX0I9jjOt5F9tlG4s' +
                '4JsxBAXx7005/N7v6ADqbL2t0BX0mAaQ7oUf9DDXZbmsQxw0TiIcg/ju8wIDAQAB' +
                'AoGAQ3NT2lKqyAyc1vegLOIoAqsA8LLUnRtqmA6LlXPrsaaHsDu+akn6/+UySakw' +
                'Jn9YErl0ceHPgttp8JRWSQAfV+fq0bZbEhkbHzomCekjN9BUyKSDYkmEBbLFh1Ts' +
                'xkiqK59qCnS0KeEYnWM4zkzzoCSO11I4fWG6gfyibgy8ZOECQQDZoTEC2MH7p2KT' +
                'RO33UOLgzStEhUeLFozIN9sPObVF3B1HZvrQboXMQwIOdBpegN3vP5UV7fVXAcTy' +
                '1p6o/HudAkEA0stxA1SxHXTCQLS/owl4vkhmfxuX8p1EEIRNUAfx6oWUjTLC1TxI' +
                'i/SBFrqr+CX+xOasxu9geQkA0i3IgFd3zwJBAIEOZdIaWG6zxHEw3y1aejB1esMX' +
                'hmWk6beR6AYPYsAa2AIPv4z6/b0zv3RyxXBlWzcVrYNjqan/EpwvScdMcsECQEL4' +
                '7CEYyWUIcadJRhGwsrISIq6Dv9UPbk6pGj8xJwVSB46M8CX7jzkYJ+Nmz7h5qeY5' +
                'O+/AojASUjZ04V0VbTUCQQDIWRHAuVuPNuefHFv+0i62YKWDIfvUOcFin5l5mYcI' +
                '29zP6jreswkO5FYqMfw4z7opMrdIrDporlkUb6JbERKv'
        );
        if (doInsert) {
            insert xs;
        }
        return xs;
    }

    public static XeroSettings__c createXeroEntity() {
        return createXeroEntityByRegion('NA', true);
    }

    public static Platform__c getFacebookPlatform() {
        Platform__c platformFB = createPlatform('Facebook', 'FB');
        if (String.isBlank(platformFB.Id)) {
            insert platformFB;
        }
        return platformFB;
    }

    public static Platform__c getTrueViewPlatform() {
        Platform__c platformTV = createPlatform('TrueView', 'TV');
        if (String.isBlank(platformTV.Id)) {
            insert platformTV;
        }
        return platformTV;
    }

    public static Project__c createContractWithTwoOppPlatformsNoInsert(String accountId, String contractName, String oppId) {
        Date startDate = Date.valueOf('2015-01-01');
        Date endDate = startDate.addDays(40);

        if (brandRecord == null) {
            brandRecord = createBrand('testBrand' + Crypto.getRandomInteger());
        }

        if (String.isBlank(oppId)) {
            Opportunity opp = createOpportunity(createUser(), createAccount());
            if (String.isBlank(opp.Id)) {
                insert opp;
            }
            oppId = opp.Id;
        }

        Project__c project = new Project__c();
        project.Account__c = accountId;
        project.Account_Type__c = 'Strike';
        project.BillingCondition__c = getBillingCondition('Normal').Id;
        project.Client_Spend__c = 1234.12;
        project.Opportunity__c = oppId;
        project.CurrencyIsoCode = 'USD';
        project.End_Date__c = endDate;
        project.Geo__c = 'Test Geo';
        project.Margin__c = 0.1;
        project.Name = contractName;
        project.Start_Date__c = startDate;
        project.Brand__c = brandRecord.Id;

        return project;
    }

    public static Project__c createContractWithoutOppPlatformNoInsert(String accountId, String contractName, String oppId) {
        Date startDate          = Date.valueOf('2015-01-01');
        Date endDate            = startDate.addDays(40);

        if (brandRecord == null) {
            brandRecord = createBrand('testBrand' + Crypto.getRandomInteger());
        }

        if (String.isBlank(oppId)) {
            Opportunity opp;

            if (oppRecord != null) {
                opp = oppRecord;
            } else {
                accountRecord = accounts.isEmpty() ? createAccount() : accounts[0];
                if (usrRecord == null) {
                    createUser();
                }
                opp = createOpportunity(usrRecord, accountRecord);
            }
            if (String.isBlank(opp.Id)){
                insert opp;
            }
            oppId = opp.Id;
        }

        Project__c project           = new Project__c();
        project.Account__c           = accountId;
        project.Account_Type__c      = 'Strike';
        project.BillingCondition__c  = getBillingCondition('Normal').Id;
        project.Client_Spend__c      = 1234.12;
        project.Opportunity__c       = oppId;
        project.CurrencyIsoCode      = 'USD';
        project.End_Date__c          = endDate;
        project.Geo__c               = 'Test Geo';
        project.Margin__c            = 0.1;
        project.Name                 = contractName;
        project.Start_Date__c        = startDate;
        project.Brand__c             = brandRecord.Id;

        return project;
    }

    public static Opportunity prepare1MonthOpportunityWith4Platforms(Utility.BILLING_PROFILES billingProfile, String stage, BillingCondition__c bc) {
        Platform__c platformFB = createFacebookPlatform(),
                platformPI = createPinterestPlatform(),
                platformTV = createTrueViewPlatform(),
                platformLN = createLinkedInPlatform();

        List<Platform__c> platforms = new List<Platform__c> {platformTV, platformFB, platformPI, platformLN};
        insert platforms;

        if (bc == null) bc = TestHelper.createBillingCondition('Normal');
        if (bc.Id == null) insert bc;

        Date startDate = Date.newInstance(System.today().addMonths(1).year(), System.today().addMonths(1).month(), 1),
                endDate = startDate.addMonths(1).addDays(-1);

        Opportunity opportunityRecord = TestHelper.createOpportunity(billingProfile);
        opportunityRecord.Amount = 100;
        opportunityRecord.BillingCondition__c = bc.Id;
        opportunityRecord.Percent_Margin__c = 21;
        opportunityRecord.Payment_Type__c = 'Net 30';
        opportunityRecord.Flight_Start__c = startDate;
        opportunityRecord.Flight_End__c = endDate;
        opportunityRecord.StageName = 'Meeting';
        insert opportunityRecord;

        List<OpportunityPlatform__c> opportunityPlatformRecords = new List<OpportunityPlatform__c>();
        for (Platform__c platform :platforms) {
            opportunityPlatformRecords.add(new OpportunityPlatform__c(
                Opportunity__c = opportunityRecord.Id,
                Platform__c = platform.Id,
                NoCostStructure__c = true,
                CTA_Overlay_Text__c = 'CTA Text',
                Pixel_Tracking__c = 'Yes',
                KPI__c = 'KPI'
            ));
        }
        insert opportunityPlatformRecords;

        // Please assign platform before closing opportunity.
        opportunityRecord.StageName = stage;
        update opportunityRecord;

        return opportunityRecord;
    }

    public static Contact createSimpleContact(Integer incCounter) {
        return createContact('ContactLastName' + incCounter, false);
    }

    public static Contact createSimpleContactWithAccount(Integer incCounter, Id accountId) {
        Contact newContact = createContact('ContactLastName' + incCounter, false);
        newContact.AccountId = accountId;
        return newContact;
    }

    public static Contact createContact(String lastName, Boolean doInsert) {
        Contact newContact = new Contact(
            LastName = lastName,
            Status__c = 'Open',
            MailingCity = 'City',
            MailingState = 'State',
            MailingCountry = 'Country',
            Outreach_Stage__c = 'Approaching'
        );
        if (doInsert) {
            insert newContact;
        }
        return newContact;
    }


    // NEW
    private final static String CLIENT_SERVICES_PROFILE_NAME = 'Client Services';
    private final static String STANDARD_USER_PROFILE_NAME = 'Standard User';
    private final static String SALES_USER_PROFILE_NAME = 'Sales User';

    public static final Date START_DATE = Date.newInstance(System.today().year(), 1, 1);
    public static final Date END_DATE = START_DATE.addMonths(2);

    private static Map<String, Profile> profiles { get {
        if (profiles == null) {
            profiles = new Map<String, Profile>();
            for (Profile prof :[SELECT Id, Name FROM Profile]) {
                profiles.put(prof.name, prof);
            }
        }
        return profiles;
    } set;}

    public static User standardUser { get {
        if (standardUser == null) {
            standardUser = new User(
                Alias = generateUniqueAlias(), Email = generateUniqueEmail(), EmailEncodingKey = 'UTF-8',
                LastName = 'Testing', Username = 'StandardUserName@test.com', ProfileId = profiles.get(STANDARD_USER_PROFILE_NAME).Id,
                LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/Los_Angeles'
            );
        }
        return standardUser;
    } set; }

    public static User salesRepUser { get {
        if (salesRepUser == null) {
            salesRepUser = new User(
                Alias = generateUniqueAlias(), Email = generateUniqueEmail(), EmailEncodingKey = 'UTF-8',
                LastName = 'Testing', Username = 'SalesRepUserName@test.com', ProfileId = profiles.get(SALES_USER_PROFILE_NAME).Id,
                LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/Los_Angeles'
            );
        }
        return salesRepUser;
    } set; }

    public static Account accountRecord { get {
        if (accountRecord == null) {
            accountRecord = new Account(Name = ACCOUNT_NAME, Agency__c = 'Agency', BillingCountry = 'USA', BillingCity = 'Chicago', BillingState = 'Michigan', Region__c = 'NA');
        }
        return accountRecord;
    } set; }

    public static Brand__c brandRecord { get {
        if (brandRecord == null) {
            brandRecord = new Brand__c(Name = 'Test Brand');
        }
        return brandRecord;
    } set; }

    public static Opportunity opportunityRecord { get; set; }
    public static Project__c contractRecord { get; set; }
    public static BillingCondition__c billingConditionRecord { get; set; }

    public class TestHelperException extends Exception {}

    public static Opportunity createOpportunity(Utility.BILLING_PROFILES billingProfile) {
        return createOpportunity(null, null, null, billingProfile, false);
    }

    public static Opportunity createMeetingOppWithoutOppPlatform(Utility.BILLING_PROFILES billingProfile, BillingCondition__c bc, Decimal clientSpend, Decimal margin, String marginType, Boolean doInsert) {
        Date startDate = Date.newInstance(System.today().addMonths(-1).year(), System.today().addMonths(-1).month(), 1),
                endDate = startDate.addDays(25);

        Opportunity opportunityRecord = TestHelper.createOpportunity(billingProfile);
        opportunityRecord.Amount = clientSpend;
        opportunityRecord.BillingCondition__c = bc.Id;
        opportunityRecord.Percent_Margin__c = margin;
        opportunityRecord.Payment_Type__c = 'Net 30';
        opportunityRecord.Flight_Start__c = startDate;
        opportunityRecord.Flight_End__c = endDate;
        opportunityRecord.StageName = 'Meeting';
        opportunityRecord.Margin_Type__c = marginType;

        if (doInsert) insert opportunityRecord;
        return opportunityRecord;
    }

    public static Opportunity createOpportunity(Date sDate, Date eDate, Platform__c platform, Utility.BILLING_PROFILES billingProfile, Boolean doInsert) {
        if (accountRecord.Id == null) {
            insert accountRecord;
        }
        if (brandRecord.Id == null) {
            insert brandRecord;
        }
        if (billingConditionRecord == null || billingConditionRecord.Id == null) {
            createBillingCondition('Normal', true);
        }

        List<User> users2Insert = new List<User>();
        if (standardUser.Id == null) users2Insert.add(standardUser);
        if (salesRepUser.Id == null) users2Insert.add(salesRepUser);
        insert users2Insert;

        if (sDate == null) sDate = START_DATE;
        if (eDate == null) eDate = END_DATE;

        opportunityRecord = new Opportunity(
            Name = 'Test Opportunity',
            Flight_End__c = eDate,
            Flight_Start__c = sDate,
            Account_Type__c = billingProfile.name(),
            AccountId = accountRecord.Id,
            BillingCondition__c = billingConditionRecord.Id,
            Additional_Rep__c = salesRepUser.Id,
            Brand__c = brandRecord.Id,
            Amount = 100,
            Percent_Margin__c = 0.10,
            OwnerId = standardUser.Id,
            CloseDate = System.today(),
            MeetingDate__c = System.today()-3,
            Margin_Type__c = '% of Budget',
            Brand_Lift_Study__c = 'Yes', IO__c = 'Test IO', Geo__c = 'Test Geo',  KPI__c = 'Test KPI', MeetingNotes__c = 'Meeting Note',
            More_Info__c = 'SOME INFO', StageName = 'Meeting',  MeetingStatus__c = 'Short-Term Follow Up', CurrencyIsoCode = 'USD',
            Payment_Type__c = 'Net 30', Targeting__c = 'Targeting', Verticals__c = 'Auto', Video_Length__c = ':15 sec', Gender__c = 'Male'
        );

        if (doInsert) {
            if (platform == null || platform.Id == null) {
                throw new TestHelperException('Platform should be defined for Opportunity Insert!');
            }
            insert opportunityRecord;
            insert createOpportunityPlatform(opportunityRecord.Id, platform.Id);
        }
        return opportunityRecord;
    }

    public static Project__c createContract(Boolean doInsert) {
        return createContract('Test Contract', null, null, doInsert);
    }

    public static Project__c createContract(String contractName, Date sDate, Date eDate, Boolean doInsert) {
        if (sDate == null) {
            sDate = TestHelper.START_DATE;
        }
        if (eDate == null) {
           eDate = TestHelper.END_DATE;
        }

        if (opportunityRecord == null || String.isBlank(opportunityRecord.Id)) {
            createOpportunity(sDate, eDate, getTrueViewPlatform(), Utility.BILLING_PROFILES.Strike, true);
        }

        contractRecord = Utility.copyOpportunityDataToContract(opportunityRecord);
        contractRecord.Name = contractName;
        //contract.Client_Spend__c = 1234.12;

        if (doInsert) {
            insert contractRecord;
        }
        return contractRecord;
    }

    public static Payment__c createProjectBasedOnPayment(Project__c contract, Sub_Project__c payment, Boolean doInsert) {
        Payment__c project = createProject(contract, payment.Start_Date__c, payment.End_Date__c, false);
        project.Name = 'NAME FOR PROJECT BASED ON PAYMENT';
        project.Payment__c = payment.Id;
        project.CostStructure__c = COST_STRUCTURE;

        if (doInsert) {
            insert project;
        }
        return project;
    }

    public static Payment__c createProject(Project__c contract, Date sDate, Date eDate, Boolean doInsert) {
        Payment__c project = Utility.copyContractDataToProject(contract);
        project.Start_Date__c = sDate;
        project.End_Date__c = eDate;
        project.Client_Spend__c = 100;
        project.UnitCost__c	= 0.05;

        project.CostStructure__c = COST_STRUCTURE;
        project.OpportunityPlatform__c = createOpportunityPlatform(project.Opportunity__c, contract.Id, null).Id;

        if (doInsert) {
            insert project;
        }
        return project;
    }

    public static Sub_Project__c createPayment(Project__c contract, Boolean doInsert) {
        Sub_Project__c payment = Utility.copyContractDataToPayment(contract);
        payment.Name = 'TestNameThatBeChanged';
        payment.Client_Spend__c = contract.Client_Spend__c;
        payment.End_Date__c = contract.End_Date__c;
        payment.Start_Date__c = contract.Start_Date__c;
        if (doInsert) {
            insert payment;
        }
        return payment;
    }

    public static BillingCondition__c createBillingCondition(String conditionName, Boolean doInsert) {
        billingConditionRecord = new BillingCondition__c(Name = conditionName, Active__c = true);

        Id rtId = null;
        if (conditionName == 'Normal') {
            rtId = Schema.SObjectType.BillingCondition__c.getRecordTypeInfosByName().get('Normal').getRecordTypeId();
            billingConditionRecord.Rebate_Type__c = 'Normal';
        } else if (conditionName.startsWith('Rebate')) {
            rtId = Schema.SObjectType.BillingCondition__c.getRecordTypeInfosByName().get('Normal').getRecordTypeId();
            billingConditionRecord.Strike_Profit__c = null;
            billingConditionRecord.Rebate_Rate__c = 30;
            billingConditionRecord.Rebate_Type__c = 'Normal';
        } else if (conditionName.startsWith('Margin Split')) {
            rtId = Schema.SObjectType.BillingCondition__c.getRecordTypeInfosByName().get('Normal').getRecordTypeId();
            billingConditionRecord.Strike_Profit__c = 50;
            billingConditionRecord.Rebate_Rate__c = 30;
            billingConditionRecord.Rebate_Type__c = 'Normal';
        } else if (conditionName.startsWith('Instant Rebate')) {
            rtId = Schema.SObjectType.BillingCondition__c.getRecordTypeInfosByName().get('Rebate').getRecordTypeId();
            billingConditionRecord.Strike_Profit__c = 50;
            billingConditionRecord.Rebate_Type__c = 'Instant';
        } else {
            // all other names :)
            rtId = Schema.SObjectType.BillingCondition__c.getRecordTypeInfosByName().get('Normal').getRecordTypeId();
            billingConditionRecord.Strike_Profit__c = 50;
            billingConditionRecord.Rebate_Type__c = 'Normal';
        }

        billingConditionRecord.RecordTypeId = rtId;

        /*
        if (conditionName == 'Normal' || conditionName.startsWith('Rebate ') || conditionName.startsWith('Margin Split ')) {
            billingConditionRecord.RecordTypeId = Schema.SObjectType.BillingCondition__c.getRecordTypeInfosByName().get('Normal').getRecordTypeId();
            if (conditionName.startsWith('Rebate ') || conditionName.startsWith('Margin Split ')) {
                billingConditionRecord.Rebate_Rate__c = 30;
            }
        } else {
            //billingConditionRecord.Rebate_Rate__c = 50;
            billingConditionRecord.Strike_Profit__c = 50;
            billingConditionRecord.Rebate_Type__c = 'Normal';
            billingConditionRecord.RecordTypeId = Schema.SObjectType.BillingCondition__c.getRecordTypeInfosByName().get('Rebate').getRecordTypeId();
        }*/

        if (doInsert) {
            insert billingConditionRecord;
        }
        return billingConditionRecord;
    }

    public static Platform__c createTrueViewPlatform() {
        return new Platform__c(Name = 'TrueView' , Prefix__c = 'TV', Provider__c = 'AdWords', Type__c = 'YT');
    }

    public static Platform__c createAdWordsPlatform() {
        return new Platform__c(Name = 'AdWords CPM' , Prefix__c = 'AV', Provider__c = 'AdWords', Type__c = 'Social');
    }

    public static Platform__c createFacebookPlatform() {
        return new Platform__c(Name = 'Facebook' , Prefix__c = 'FB', Provider__c = 'Facebook', Type__c = 'Social');
    }

    public static Platform__c createDBMTrueViewPlatform() {
        return new Platform__c(Name = 'DBM TrueView', Prefix__c = 'DT', Provider__c = 'DBM', Type__c = 'Social');
    }

    public static Platform__c createLinkedInPlatform() {
        return new Platform__c(Name = 'LinkedIn', Prefix__c = 'LN', Provider__c = 'LinkedIn', Type__c = 'Social');
    }

    public static Platform__c createPinterestPlatform() {
        return new Platform__c(Name = 'Pinterest', Prefix__c = 'PN', Provider__c = 'Pinterest', Type__c = 'Social');
    }

    public static Platform__c createSnapchatPlatform() {
        return new Platform__c(Name = 'Snapchat', Prefix__c = 'SN', Provider__c = 'Snapchat', Type__c = 'Social');
    }

    public static Platform__c createTwitterPlatform() {
        return new Platform__c(Name = 'Twitter', Prefix__c = 'TW', Provider__c = 'Twitter', Type__c = 'Social');
    }

    public static void prepareData(Boolean checkErrors) {
        if (standardUser.Id == null) {
            insert standardUser;
        }
        if (accountRecord.Id == null) {
            insert accountRecord;
        }
        if (brandRecord.Id == null) {
            insert brandRecord;
        }
        if (billingConditionRecord == null || billingConditionRecord.Id == null) {
            createBillingCondition('Normal', true);
        }

        Platform__c platformTV = createTrueViewPlatform();
        insert platformTV;

        if (opportunityRecord == null || opportunityRecord.Id == null) {
            createOpportunity(START_DATE, END_DATE, platformTV, Utility.BILLING_PROFILES.Strike, true);
        }
        if (contractRecord == null || contractRecord.Id == null) {
            createContract('Test Contract Name', START_DATE, END_DATE, true);
        }

        if (checkErrors) {
            System.assertEquals([SELECT COUNT() FROM Account], 1);
            System.assertEquals([SELECT COUNT() FROM Brand__c], 1);
            System.assertEquals([SELECT COUNT() FROM BillingCondition__c], 1);
            System.assertEquals([SELECT COUNT() FROM Opportunity], 1);
            System.assertEquals([SELECT COUNT() FROM Project__c], 1);
        }
    }

    public static Invoice__c createInvoice(Double invAmount, Id xe, String region, Boolean doInsert) {
        Invoice__c invoice =  new Invoice__c(
            Billing_Profile__c = 'Client',
            Contract__c = '',
            Invoice_Amount__c = invAmount,
            Start_Date__c = System.today(),
            End_Date__c = System.today().addDays(4),
            Due_Date__c = System.today().addMonths(1).addDays(-4),
            IO__c = 'IO Text',
            Payment_Type__c = 'Net 30',
            PO__c = 'PO Text',
            //Project__c = '',
            Region__c = region,
            Status__c = '',
            Type__c = 'Monthly',
            Xero_Id__c = 'c412389e-49f5-4c81-a2a1-9e1e4fb7707f', // Xero Contract Id
            Xero_Entity__c = xe,
            Xero_Invoice_Id__c = '',
            Xero_Invoice_Name__c = '',
            Strike_Id__c = 'FB000008A'
        );
        if (doInsert) {
            insert invoice;
        }
        return invoice;
    }

}