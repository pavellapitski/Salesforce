public class VideoUrlHandler implements ITrigger {
    public VideoUrlHandler() {}
    
    public void bulkBefore() {}

    public void bulkAfter() {}

    public void beforeInsert(List<SObject> so) {
        List<VideoUrl__c> videoUrls = (List<VideoUrl__c>)so;
        updateContractOpportunityReference(videoUrls);  
        setUniqueFields(videoUrls);
    }

    public void beforeUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {
        Map<Id, VideoUrl__c> newMap = (Map<Id, VideoUrl__c>)so;
        setUniqueFields(newMap.values());
    }
    
    public void beforeDelete(List<SObject> so) {}

    public void afterInsert(List<SObject> so) {
        List<VideoUrl__c> videoUrls = (List<VideoUrl__c>) so;

        markForMMSync(videoUrls);
        List<VideoUrl__c> toModify = new List<VideoUrl__c>();
        for (VideoUrl__c videoURL :videoUrls) {
            if (!Test.isRunningTest() && (null == videoURL.Salesforce_ID__c || String.isBlank(videoURL.Salesforce_ID__c))) {
                toModify.add(new VideoUrl__c (Id = videoURL.Id, Salesforce_ID__c = videoURL.Id));
            }
        }
        update toModify;
    }
    
    public void afterUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {
        Map<Id, VideoUrl__c> oldMap = (Map<Id, VideoUrl__c>) oldSo;
        Map<Id, VideoUrl__c> newMap = (Map<Id, VideoUrl__c>) so;
        
        List<VideoUrl__c> updatedVideos = new List<VideoUrl__c>();
        for (VideoUrl__c videoUrl :newMap.values()) {
            if (videoUrl.Name != oldMap.get(videoUrl.Id).Name 
                || videoUrl.Url__c != oldMap.get(videoUrl.Id).Url__c 
                || videoUrl.isPlaceholder__c != oldMap.get(videoUrl.Id).isPlaceholder__c
                || videoUrl.ClickThroughURL__c != oldMap.get(videoUrl.Id).ClickThroughURL__c 
                || videoUrl.Archive__c != oldMap.get(videoUrl.Id).Archive__c 
                || videoUrl.StartDate__c != oldMap.get(VideoUrl.Id).StartDate__c
                || videoUrl.EndDate__c != oldMap.get(VideoUrl.Id).EndDate__c
                || videoUrl.Rotation__c != oldMap.get(VideoUrl.Id).Rotation__c)
            {
                updatedVideos.add(videoUrl);
            }
        }

        if (!updatedVideos.isEmpty()) {
            markForMMSync(updatedVideos);
        }
    }
        
    public void afterDelete(List<SObject> so) {}

    public void andFinally() {} 
    
    private void updateContractOpportunityReference(List<VideoUrl__c> videoUrls) {
        Map<Id, List<VideoUrl__c>> videoUrlsForOpportunities = new Map<Id, List<VideoUrl__c>>();
        Map<Id, List<VideoUrl__c>> videoUrlsForContracts = new Map<Id, List<VideoUrl__c>>();
        for (VideoUrl__c videoUrl : videoUrls) {
            if (String.isNotBlank(videoUrl.Opportunity__c) && String.isBlank(videoUrl.Contract__c)) {
            	if (!videoUrlsForOpportunities.containsKey(videoUrl.Opportunity__c)) {
                    videoUrlsForOpportunities.put(videoUrl.Opportunity__c, new List<VideoUrl__c> {videoUrl} );
                } else {
                    videoUrlsForOpportunities.get(videoUrl.Opportunity__c).add(videoUrl);                     
                }
            } else if (String.isNotBlank(videoUrl.Contract__c) && String.isBlank(videoUrl.Opportunity__c)) {
            	if (!videoUrlsForContracts.containsKey(videoUrl.Contract__c)) {
                    videoUrlsForContracts.put(videoUrl.Contract__c, new List<VideoUrl__c> {videoUrl} );
                } else {
                    videoUrlsForContracts.get(videoUrl.Contract__c).add(videoUrl);                     
                }
            }
        }
        
        if (!videoUrlsForOpportunities.isEmpty()) {
        	for (Opportunity opp :OpportunityRepository.getOpportunityByIds(videoUrlsForOpportunities.keySet())) {
            	if (!opp.Projects__r.isEmpty()) {
                	for (VideoUrl__c videoUrl :videoUrlsForOpportunities.get(opp.Id)) {
                    	videoUrl.Contract__c = opp.Projects__r[0].Id;                          
                    }
                }
            }                
        }
        
        if (!videoUrlsForContracts.isEmpty()) {
        	for (Project__c contract :ContractRepository.getContractByIds(videoUrlsForContracts.keySet())) {
            	if (String.isNotBlank(contract.Opportunity__c)) {
                	for (VideoUrl__c videoUrl :videoUrlsForContracts.get(contract.Id)) {
                    	videoUrl.Opportunity__c = contract.Opportunity__c;                          
                    }
                }
            }                
        }        
    }
    
    private void markForMMSync(List<VideoUrl__c> videoUrls) {
        Map<Id, Project__c> contractsToSyncWithMM = new Map<Id, Project__c>();
        for (VideoUrl__c videoUrl :videoUrls) {
            if (videoUrl.ShouldSyncWithMM__c) {
                contractsToSyncWithMM.put(
                    videoUrl.Contract__c,
                    new Project__c(Id = videoUrl.Contract__c, PerformMMSync__c = true)
                );
            }
        }
        update contractsToSyncWithMM.values();
    }
    
    private void setUniqueFields(List<VideoUrl__c> videoUrls) {
        for (VideoUrl__c videoUrl :videoUrls) {
            if (!videoUrl.IsPlaceholder__c) {
                videoUrl.copyUrl__c = videoUrl.Opportunity__c + '-' + videoUrl.Contract__c + '-' + videoUrl.Url__c;
            }
            videoUrl.CopyName__c = videoUrl.Opportunity__c + '-' + videoUrl.Contract__c + '-' + videoUrl.Name;
        }
    }
}