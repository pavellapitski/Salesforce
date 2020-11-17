public abstract class SObjectOCR {
    
    public static final string STATUS_OK ='OK';
    public static final string STATUS_INFO ='Info';
    public static final string STATUS_WARNING ='Warning';

    public String newStatus;    
    public Boolean isValid { get; protected set; } 
    protected SObject settings { get; set; }        
    protected HTMLParser parser;    
    private String oldStatus;
  
    protected SObjectOCR(SObject settings) {
        this.settings=settings;
        oldStatus = String.valueOf(settings.get('Status__c'));  
    }

    public Boolean isNotificationRequired() {
        if (newStatus == SObjectOCR.STATUS_OK || oldStatus == newStatus || oldStatus == SObjectOCR.STATUS_WARNING)
            return false;
        
        return true;
    }

    public Boolean isUpdateRequired() {  
        if (newStatus == oldStatus) return false;
        return true;
    }

    public SObject getObjectToUpdate() {
        settings.put('Status__c',newStatus);
        return settings;
    }    

    abstract String calculateNewStatus();    
}