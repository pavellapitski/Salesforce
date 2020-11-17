public class StorageOCR extends SObjectOCR {

    public String storageLimit { get; private set; }
    public String Usage { get; private set; }
    public String sPercent { get; private set; }
    public Integer iPercent { get; private set;}
    public NotificatorStorage__c getSettings() { 
        return (NotificatorStorage__c) settings; 
    }

    public StorageOCR(NotificatorStorage__c settings) {
        super(settings);
        translateName(settings);

        try {
            isValid = true;
            parser = new HTMLParser(storagesPageRawData, settings.Name, 0);
            storageLimit = parser.parseField();
            Usage = parser.parseField();
            sPercent = parser.parseField();
            iPercent = integer.valueof(sPercent.removeEnd('%'));
            
            newStatus = calculateNewStatus();

        } catch (HTMLParser.ParserException ex) {
            isValid = false;
        }
    }
    
    private void translateName(NotificatorStorage__c settings) {
        String userLang = UserInfo.getLanguage();
        if(settings.Name != StorageDictionary.FileByLanguage.get(userLang ) && 
          settings.Name != StorageDictionary.DataByLanguage.get(userLang)) {
            if(StorageDictionary.FileNames.contains(settings.Name))
                settings.Name=StorageDictionary.FileByLanguage.get(userLang);
             else if(StorageDictionary.DataNames.contains(settings.Name))
                settings.Name=StorageDictionary.DataByLanguage.get(userLang);
        } 
    }
    
    private String calculateNewStatus() {
        NotificatorStorage__c settings = getSettings();
        if (settings.WarningPercentageThreshold__c != null && iPercent >= settings.WarningPercentageThreshold__c) return SObjectOCR.STATUS_WARNING; 
        else if (settings.InfoPercentageThreshold__c != null && iPercent >= settings.InfoPercentageThreshold__c) return SObjectOCR.STATUS_INFO; 
        else return SObjectOCR.STATUS_OK;
    }

    private Static String storagesPageRawData {
        get {
            if (storagesPageRawData != null) return storagesPageRawData;

            Organization orgDetails = [select Id, Name, Country from Organization limit 1];
            Id orgId = orgDetails.Id;

            PageReference storagePage = new PageReference('/setup/org/orgstorageusage.jsp?id=' + orgId);

            if (Test.isRunningTest()) {
                storagesPageRawData = NotificatorTestUtils.StoragesPageRawData;
            } else {
                storagesPageRawData = storagePage.getContent().toString();
            }

            return storagesPageRawData;
        }
        private set;
    }
}