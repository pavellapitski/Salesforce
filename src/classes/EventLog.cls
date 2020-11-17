public without sharing class EventLog {

    public static final String STATUS_ERROR  = 'Error';
    public static final String STATUS_INFO   = 'Info';

    public static String TYPE_CONTRACT = 'Contract';
    public static final String STRIKE_DATA_CALLOUT = 'Invoice API Callouts';
    public static String TYPE_INVOICE_API_SYNC = 'Invoice API Sync';
    public static String TYPE_XERO_SYNC = 'Xero Sync';

    private static final String KEY_PREFIX_CONTRACT = Schema.Project__c.SObjectType.getDescribe().getKeyPrefix();
    private static final String KEY_PREFIX_PAYMENT = Schema.Sub_Project__c.SObjectType.getDescribe().getKeyPrefix();
    private static final String KEY_PREFIX_CREDIT_NOTE = Schema.CreditNote__c.SObjectType.getDescribe().getKeyPrefix();
    private static final String KEY_PREFIX_INVOICE = Schema.Invoice__c.SObjectType.getDescribe().getKeyPrefix();

    public static EventLog__c createMediaManagerLog(String info, String status, String type, String description) {
        EventLog__c log = createEventLog(info, status, type);
        log.Description__c = description;
        return log;
    }

    public static EventLog__c createEventLog(String info, String status, String type) {
        EventLog__c log = new EventLog__c();
        log.Info__c = info;
        log.Status__c = status;
        log.Type__c = type;
        return log;
    }

    public static EventLog__c createEventLog(String info, String status, String type, Id childRecordId) {
        EventLog__c log = createEventLog(info, status, type);

        String keyPrefix = String.valueOf(childRecordId).left(3);
        if (KEY_PREFIX_PAYMENT == keyPrefix) {
            log.Payment__c = childRecordId;
        } else if (KEY_PREFIX_CONTRACT == keyPrefix) {
            log.Contract__c = childRecordId;
        } else if (KEY_PREFIX_CREDIT_NOTE == keyPrefix) {
            log.CreditNote__c = childRecordId;
        } else if (KEY_PREFIX_INVOICE == keyPrefix) {
            log.Invoice__c = childRecordId;
        }
        return log;
    }
}