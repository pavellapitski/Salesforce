@IsTest
private class PostSandboxRefreshTest {
    @IsTest public static void runAllTest() {
        Test.startTest();
        PostSandboxRefresh.createObjectsForOpportunity();
        System.assertEquals(2, [SELECT COUNT() FROM Account]);

        String oppName = 'TestOppName';
        PostSandboxRefresh.createOpportunityPreMeeting(oppName);

        System.assertEquals(1, [SELECT COUNT() FROM Opportunity WHERE Name = :oppName]);
        Test.stopTest();
    }
}