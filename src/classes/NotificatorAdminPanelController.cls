public with sharing class NotificatorAdminPanelController {
    public List<StorageOCR> storages { get; private set; }

    public NotificatorSetting__c notificator { get; set; }

    public NotificatorAdminPanelController() {
        notificator = NotificatorSingleton.getNotificator();
        storages = NotificatorSingleton.getStorages();
    }
    
    public Boolean getRunJobButtonActive() {
        Integer count = [Select count() FROM CronTrigger WHERE CronJobDetail.Name = :NotificatorJob.JOB_NAME LIMIT 1];
        if(count>0 || notificator.Id==null) return false;
        return true;
    }   
    
    public void runJob() {
        if(getRunJobButtonActive())    
        System.schedule(NotificatorJob.JOB_NAME, '0 '+Math.Mod(DateTime.now().minute()+1,60)+' * * * ?', new NotificatorJob());
    }
    
    public Boolean getKillJobButtonActive() {
        Integer count = [Select count() FROM CronTrigger WHERE CronJobDetail.Name = :NotificatorJob.JOB_NAME LIMIT 1];
        if(count>0) return true;
        return false;
    }
    
    public void killJob() {
        List<CronTrigger> jobs = [SELECT Id FROM CronTrigger  WHERE CronJobDetail.Name = :NotificatorJob.JOB_NAME];
        for(CronTrigger job: jobs) System.abortJob(job.id);
    }
    
    public void saveNotificator() {
        try {
            upsert notificator;
    
            List<NotificatorStorage__c> nStorages = prepareStoragesToUpsert();
            upsert nStorages;
    
        } catch(Exception ex) {
            ApexPages.addMessages(ex) ; 
        }
    }

    private List<NotificatorStorage__c> prepareStoragesToUpsert() {
        List<NotificatorStorage__c> nStorages = new List<NotificatorStorage__c>();
        for (StorageOCR storage: storages) {
            NotificatorStorage__c ns = storage.getSettings();
            if (ns.Setting__c == null) ns.Setting__c = notificator.Id;
            nStorages.add(ns);
        }
        return nStorages;
    }

}