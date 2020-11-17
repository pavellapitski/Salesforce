global class NotificatorJob implements Schedulable, Database.AllowsCallouts {
    public final static String JOB_NAME;
    static {
        if (Test.isRunningTest()) {
            JOB_NAME='Notificator_Test';
        } else {
            JOB_NAME='Notificator';
        }              
    }
    
 
    global void execute(SchedulableContext ctx) {
        notify();
    }

    @future(callout=true)
    public static void notify(){
        NotificatorEmail email = new NotificatorEmail();
        List<SObject> objectsToUpdate = new List<SObject>();

        List<StorageOCR> storages = NotificatorSingleton.getStorages();
        for (StorageOCR storage: storages) {
            email.addStorage(storage);
            if (storage.isUpdateRequired()) objectsToUpdate.add(storage.getObjectToUpdate());
        }
                        
        email.sendNotification();    
        update objectsToUpdate;
    }
}