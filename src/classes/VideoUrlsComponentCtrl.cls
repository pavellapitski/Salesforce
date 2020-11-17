public class VideoUrlsComponentCtrl
{
    public String contract {get; set;}
    public String opportunity {get; set;}
    public List<VideoUrl__c> urls {get; set;}
    public Integer videoUrlRow {get; set;}
    public Blob csvFileBody{get;set;}
    public string csvAsString{get;set;}
    
    public VideoUrlsComponentCtrl()
    {
        urls = new List<VideoUrl__c>();
    }
    
    public List<SelectOption> getAvailablePlatforms() {
        
        Set<SelectOption> platforms;
        String projectId = contract;
        List<SelectOption> retVal = new List<SelectOption>();
        
        if (!string.isBlank(projectId) && platforms == NULL)
        {
            platforms = new Set<SelectOption>();
            Map<Id, List<OpportunityPlatform__c>> contractPlatforms = PlatformRepository.getPlatformsForContracts(new Set<Id> {projectId});
            
            if (contractPlatforms.containsKey(projectId))
            {
                for(OpportunityPlatform__c contractPlatform : contractPlatforms.get(projectId)) 
                {
                    platforms.add(new SelectOption(contractPlatform.Platform__r.Name, contractPlatform.Platform__r.Name));
                }
                
                for(VideoUrl__c url: urls) {
                    if(url.Platform__c!=null && url.Platform__c!='')
                        platforms.add(new SelectOption(url.Platform__c, url.Platform__c));
                }
            }
        }
        
        if (!string.isBlank(opportunity) && platforms == NULL)
        {
            platforms = new Set<SelectOption>();
            Opportunity opp = OpportunityRepository.getOpportunityById(opportunity);
            
            for(OpportunityPlatform__c oppPlatform : opp.OpportunityPlatforms__r) 
            {
                platforms.add(new SelectOption(oppPlatform.Platform__r.Name, oppPlatform.Platform__r.Name));
            }
            
            for(VideoUrl__c url: urls) {
                if(url.Platform__c!=null && url.Platform__c!='')
                    platforms.add(new SelectOption(url.Platform__c, url.Platform__c));
            }            
            
        }        
        
        if(platforms.size()>1) {
            retVal.add(new SelectOption('', ''));
        }
        retVal.addAll(platforms);        
        return retVal;
    }
    
    public PageReference importCSVFile(){ 
        try{
            try
            {
                csvAsString= csvFileBody.toString();
            }
            catch (NullPointerException e)
            {
                ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,'No file selected!');
                ApexPages.addMessage(errorMessage);
                return null;                    
            }
            
            String[] csvFileLines = csvAsString.split('\n'); 
            List<VideoUrl__c> newUrls = new List<VideoUrl__c>();
            for(Integer i=1;i<csvFileLines.size();i++){
                VideoUrl__c newUrl = new VideoUrl__c();
                if (!string.isBlank(contract))
                {
                    newUrl.Contract__c = contract;
                }
                else if (!string.isBlank(opportunity))
                {
                    newUrl.Opportunity__c = opportunity;
                }               
                csvFileLines[i] = csvFileLines[i].replaceAll (',,', ', ,');
                if (csvFileLines[i].endsWith (',')) csvFileLines[i] += ' ';
                String [] csvRecordData = csvFileLines[i].split(',');
                newUrl.name = csvRecordData[0];
                
                newUrl.Platform__c=csvRecordData[1];
                
                newUrl.Format__c=csvRecordData[2];
                newUrl.Url__c=csvRecordData[3];
                if (csvRecordData [4] != ' '){
                    newUrl.IsPlaceholder__c=Boolean.valueOf(csvRecordData[4]);
                }
                newUrl.ClickThroughURL__c=csvRecordData[5];
                newUrl.Text__c=csvRecordData[6]; 
                try
                {
                    if (csvRecordData [7] != ' ')
                    {
                        String [] startDateFields = csvRecordData[7].split ('/');
                        for (String dateField : startDateFields)
                        {
                            if (dateField.startsWith ('0'))
                            {
                                dateField = dateField.removeStart('0');
                            }
                        }
                        newUrl.StartDate__c=Date.newInstance (Integer.valueOf (startDateFields [2]), Integer.valueOf (startDateFields [0]),
                                                              Integer.valueOf (startDateFields [1]));
                    }   
                    
                    if (csvRecordData [8] != ' ')
                    {
                        String [] endDateFields = csvRecordData[8].split ('/');
                        for (String dateField : endDatefields)
                        {
                            if (dateField.startsWith ('0'))
                            {
                                dateField = dateField.removeStart('0');
                            }
                        }
                        newUrl.EndDate__c =Date.newInstance (Integer.valueOf (endDateFields [2]), Integer.valueOf (endDateFields [0]),
                                                             Integer.valueOf (endDateFields [1]));
                    }
                }
                catch (ListException e)
                {
                    String mes = e.getMessage();
                    
                    ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,'Date should be in DD/MM/YYYY or D/M/YYYY format.');
                    ApexPages.addMessage(errorMessage);
                    return null;
                }
                
                try
                {
                    if (!String.isBlank(csvRecordData [9])){
                        String before = csvRecordData[9];
                        String after = csvRecordData[9].remove ('\n');
                        after = after.remove('\r');
                        newUrl.Rotation__c= Decimal.valueOf(after);
                    }
                }
                catch (TypeException e)
                {
                    String mes = e.getMessage();
                    ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,'Rotation field should be a number!');
                    ApexPages.addMessage(errorMessage);
                    return null;
                }
                
                newUrls.add(newUrl);   
            }
            insert newUrls;
        }
        catch (DmlException e)
        {
            String mes = e.getMessage();
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured while importin data. Please make sure input csv file is correct' +
                                                                   '\n' + mes);
            ApexPages.addMessage(errorMessage);
            return null;
        }    
        
        PageReference pr = ApexPages.currentPage();
        pr.setRedirect(true);
        return pr;
    }
    
    public List<VideoUrl__c> getVideoUrls()
    {
        if (urls.isEmpty())
        {
            if (!string.isBlank(contract))
            {
                urls = VideoUrlRepository.getVideosForContract(contract);
            }
            else if (!string.isBlank(opportunity))
            {
                urls = VideoUrlRepository.getVideosForOpportunity(opportunity);
            }
        }
        
        return urls;
    }
    
    public void addNewVideoUrl()
    {
        VideoUrl__c videoUrl = new VideoUrl__c();
        
        if (!string.isBlank(contract))
        {
            List<Project__c> contracts = [SELECT Id, Start_Date__c, End_Date__c FROM Project__c
                                          WHERE Id =: contract];
            videoUrl.Contract__c = contract;
            videoUrl.StartDate__c=contracts[0].Start_Date__c;
            videoUrl.EndDate__c=contracts[0].End_Date__c;
        }
        else if (!string.isBlank(opportunity))
        {
            Opportunity opp = OpportunityRepository.getOpportunityById(opportunity);
            videoUrl.Opportunity__c = opportunity;
            videoUrl.StartDate__c = opp.Flight_Start__c;
            videoUrl.EndDate__c=opp.Flight_End__c;
        }
        List<SelectOption> platforms = getAvailablePlatforms();
        if(platforms.size()==1 && 
           (platforms[0].getLabel() =='Adwords CPM' || platforms[0].getLabel() =='TrueView'))
            videoUrl.format__c='Video';
        
        urls.add(videoUrl);     
    }
    
    public void cancelNewVideoUrl()
    {
        if (urls.size() > videoUrlRow) {
            urls.remove(videoUrlRow);
        }
    }
    
    public void saveVideoUrls()
    {
        Boolean isSuccess = true;
        
        try
        {
            upsert urls;
            List<Project__c> contracts = [SELECT Id FROM Project__c WHERE Id=:contract];
            if(contracts.size()>0) {
                contracts[0].PerformMMSync__c = true;
                contracts[0].LastModifiedBy__c = UserInfo.getUserId();
            }
            update contracts;
            
        }
        catch (DMLException ex)
        {
            ApexPages.addMessage(new ApexPages.Message(Apexpages.Severity.ERROR, ex.getDMLMessage(0)));
            isSuccess = false;
        }
        
        if (isSuccess)
        {
            ApexPages.addMessage(new ApexPages.Message(Apexpages.Severity.INFO, 'Saved successfully.'));
        }
    }
    
    public PageReference getCSVTemplate_Redirect ()
    {
        PageReference pr = Page.CreativesUploadCSVDownloader;
        pr.setRedirect(true);
        return pr;
    }
}