@isTest
public class PlatformRepositoryTest {

    @isTest
    public static void getAvailablePlatformsTest()
    {
        Platform__c platformFB = TestHelper.createPlatform('Facebook', 'FB'),
            		platformIG = TestHelper.createPlatform('Instagram', 'IG');
        insert new Platform__c [] {platformFB, platformIG};
            
        System.assertEquals ('Facebook', PlatformRepository.getAvailablePlatforms() [0].Name);
    }
    
    @isTest
    public static void getAvailableOpportunityAdPlacements ()
    {
        Platform__c platformFB = TestHelper.createPlatform('Facebook', 'FB');
        insert platformFB;
        AdPlacement__c placement = TestHelper.createAdPlacement(platformFB.Id, 'adPlacement1');
        insert placement;
        Opportunity opp = TestHelper.createOpportunity(TestHelper.createUser(), TestHelper.createAccount()),
                    opp2 = TestHelper.createOpportunity(TestHelper.createUser('striketestuser@strike.com'), TestHelper.createAccount('accName'));
        
        insert new Opportunity [] {opp, opp2};
        OpportunityPlatform__c oppPlatform = TestHelper.createOpportunityPlatform(opp.Id, platformFB.Id);
        insert oppPlatform;
        OpportunityAdPlacement__c plac = TestHelper.createOpportunityAdPlacement(opp.Id, placement.Id);
        plac.OpportunityPlatform__c = oppPlatform.Id;
        insert plac;
        Set <Id> opps = new Set <Id> ();
        opps.add (opp.Id);
        opps.add(opp2.Id);
        Map<Id, List<OpportunityAdPlacement__c>> results = PlatformRepository.getOpportunityAdPlacementsForOpportunities(opps);
        System.assertEquals(plac.Opportunity__c, results.values() [0][0].Opportunity__c);
        System.assertEquals(plac.AdPlacement__c, results.values() [0][0].AdPlacement__c);
    }
    
    @isTest
    public static void getAvailableOpportunityAdPlacements_TwoAdPlacements ()
    {
        Platform__c platformFB = TestHelper.createPlatform('Facebook', 'FB');
        insert platformFB;
        AdPlacement__c placement1 = TestHelper.createAdPlacement(platformFB.Id, 'adPlacement1');
        AdPlacement__c placement2 = TestHelper.createAdPlacement(platformFB.Id, 'adPlacement2');
        insert new List <AdPlacement__c> {placement1, placement2};
        Opportunity opp = TestHelper.createOpportunity(TestHelper.createUser(), TestHelper.createAccount()),
                    opp2 = TestHelper.createOpportunity(TestHelper.createUser('striketestuser@strike.com'), TestHelper.createAccount('accName'));
        
        insert new Opportunity [] {opp, opp2};
        OpportunityPlatform__c oppPlatform = TestHelper.createOpportunityPlatform(opp.Id, platformFB.Id);
        insert oppPlatform;
        OpportunityAdPlacement__c plac1 = TestHelper.createOpportunityAdPlacement(opp.Id, placement1.Id),
            						plac2 = TestHelper.createOpportunityAdPlacement(opp.Id, placement2.Id);
        plac1.OpportunityPlatform__c = oppPlatform.Id;
        plac2.OpportunityPlatform__c = oppPlatform.Id;
        insert new OpportunityAdPlacement__c [] {plac1,plac2};
        Set <Id> opps = new Set <Id> ();
        opps.add (opp.Id);
        opps.add(opp2.Id);
        Map<Id, List<OpportunityAdPlacement__c>> results = PlatformRepository.getOpportunityAdPlacementsForOpportunities(opps);
        System.assertEquals(plac1.Opportunity__c, results.values() [0][0].Opportunity__c);
        System.assertEquals(plac1.AdPlacement__c, results.values() [0][0].AdPlacement__c);
    }    
 
}