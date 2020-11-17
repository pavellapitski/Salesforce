public class VideoUrlRepository {

    public static List<VideoUrl__c> getVideosForOpportunity(Id opportunityId) {
        Map<Id, List<VideoUrl__c>> opportunityVideos = getVideosForOpportunities(new Set<Id>{opportunityId});

        List<VideoUrl__c> creatives = new List<VideoUrl__c>();
        if (opportunityVideos.containsKey(opportunityId)) {
            creatives = opportunityVideos.get(opportunityId);
        }
        return creatives;
    }
    
    public static Map<Id, List<VideoUrl__c>> getVideosForOpportunities(Set<Id> opportunityIds) {
        List<VideoUrl__c> creatives = getCreativesByOppIds(opportunityIds);

        Map<Id, List<VideoUrl__c>> creativesMap = new Map<Id, List<VideoUrl__c>>();
        for (VideoUrl__c videoUrl :creatives) {
            if (!creativesMap.containsKey(videoUrl.Opportunity__c)) {
                creativesMap.put(videoUrl.Opportunity__c, new List<VideoUrl__c>());
            }
            creativesMap.get(videoUrl.Opportunity__c).add(videoUrl);

        }
        return creativesMap;
    }

    private static List<VideoUrl__c> getCreativesByOppIds(Set<Id> opportunityIds) {
        return [
            SELECT Name, Archive__c, ClickThroughURL__c, Contract__c, EndDate__c, Format__c, Opportunity__c, Platform__c, IsPlaceholder__c, Rotation__c,
                StartDate__c, Text__c, Url__c
            FROM VideoUrl__c
            WHERE Opportunity__c IN :opportunityIds
            ORDER BY Name ASC
        ];
    }
    
    public static List<VideoUrl__c> getVideosForContract(String contractId) {
        return [
            SELECT Name, Archive__c, ClickThroughURL__c, Contract__c, EndDate__c, Format__c, Opportunity__c, Platform__c, IsPlaceholder__c, Rotation__c,
                StartDate__c, Text__c, Url__c
            FROM VideoUrl__c
            WHERE Contract__c = :contractId
            ORDER BY StartDate__c ASC
        ];
    }
}