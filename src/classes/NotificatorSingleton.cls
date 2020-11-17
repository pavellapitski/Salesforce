public class NotificatorSingleton {
    
    private static NotificatorSetting__c notificator;
    public static NotificatorSetting__c getNotificator() {
            if (notificator == null) init();
            return notificator;
    }
    
    private static List<StorageOCR> storages;
    public static List<StorageOCR> getStorages() {
            if (storages == null) init();
            return storages;
    }
    
    private static void init() {
        try {
            loadNotificator();
        } catch (System.QueryException ex) {
            initNewNotificator();
        }
    }

    private static void loadNotificator() {
        notificator = [
                SELECT recipient__c, (
                        SELECT ID, Name, InfoPercentageThreshold__c, WarningPercentageThreshold__c, Status__c, Setting__c
                        FROM NotificatorStorages__r LIMIT 100
                )
                FROM NotificatorSetting__c LIMIT 1
        ];

        storages = new List<StorageOCR>();
        for (NotificatorStorage__c nt: notificator.NotificatorStorages__r) {
            storages.add(new StorageOCR(nt));
        }
    }

    public static void initNewNotificator() {
        notificator = new NotificatorSetting__c();
        initStorageList();
    }

    
    private static void initStorageList() {
        List<String> storageNames = new List<String> {
            StorageDictionary.DataByLanguage.get(UserInfo.getLanguage()),
            StorageDictionary.FileByLanguage.get(UserInfo.getLanguage())                
        };
        storages = new List<StorageOCR>();

        for (String name: storageNames) {
            NotificatorStorage__c ns = new NotificatorStorage__c(Name = name);
            StorageOCR ocr = new StorageOCR(ns);
            if(ocr.isValid) storages.add(ocr);              
        }
    }

}