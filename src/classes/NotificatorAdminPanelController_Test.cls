@isTest
private class NotificatorAdminPanelController_Test {

    static testMethod void save_WhenNoNotificator_CreateNotificator() {
        Integer countBefore = [SELECT count() FROM NotificatorSetting__c];
        System.assertEquals(0, countBefore);

        NotificatorAdminPanelController controller = new NotificatorAdminPanelController();
        controller.notificator.recipient__c = 'test@notificator.com';
        controller.saveNotificator();

        Integer countAfter = [SELECT count() FROM NotificatorSetting__c];
        System.assertEquals(1, countAfter);
    }

    static testMethod void save_WhenNotificatorExist_updateNotificator() {
        NotificatorTestUtils.prepareTestNotificator();
        Integer countBefore = [SELECT count() FROM NotificatorSetting__c];
        System.assertEquals(1, countBefore);

        NotificatorAdminPanelController controller = new NotificatorAdminPanelController();
        controller.notificator.recipient__c = 'updated@notificator.com';
        controller.saveNotificator();

        Integer countAfter = [SELECT count() FROM NotificatorSetting__c];
        System.assertEquals(1, countAfter);
        System.assertEquals('updated@notificator.com', [SELECT recipient__c FROM NotificatorSetting__c].recipient__c);
    }

    
    static testMethod void getRunJobButtonActive_whenNoNotificator_returnFalse() {
        NotificatorAdminPanelController controller = new NotificatorAdminPanelController(); 
        
        System.assertEquals(false, controller.getRunJobButtonActive());         
    }

    static testMethod void getRunJobButtonActive_whenJobIsRunning_returnFalse() {
        NotificatorTestUtils.prepareTestNotificator();        
        NotificatorAdminPanelController controller = new NotificatorAdminPanelController(); 

        Test.startTest();
		System.schedule('Notificator_Test',
                        '0 0 0 15 3 ? 2022', 
                        new NotificatorJob());        
        Test.stopTest();        
        
        System.assertEquals(false, controller.getRunJobButtonActive());         
    }
    
    static testMethod void getRunJobButtonActive_whenNotificatorExistAndNoRunningJob_returnTrue() {
        NotificatorTestUtils.prepareTestNotificator();        
        NotificatorAdminPanelController controller = new NotificatorAdminPanelController(); 

        System.assertEquals(true, controller.getRunJobButtonActive());         
    }    
    
    static testMethod void runJob_whenItsPossible_run() {
        NotificatorTestUtils.prepareTestNotificator();        
        NotificatorAdminPanelController controller = new NotificatorAdminPanelController(); 
        
        Test.startTest();        
        controller.runJob();
        Test.stopTest();          

		Integer count = [Select count() FROM CronTrigger WHERE CronJobDetail.Name = 'Notificator_Test' LIMIT 1];        
        System.assertEquals(1,count);           
    }   

    static testMethod void runJob_whenItsNotPossible_notRun() { 
        NotificatorAdminPanelController controller = new NotificatorAdminPanelController(); 
        
        Test.startTest();        
        controller.runJob();
        Test.stopTest();          

		Integer count = [Select count() FROM CronTrigger WHERE CronJobDetail.Name = 'Notificator_Test' LIMIT 1];        
        System.assertEquals(0,count);           
    }      

    static testMethod void getKillJobButtonActive_whenJobIsRunning_returnTrue() {
        NotificatorTestUtils.prepareTestNotificator();        
        NotificatorAdminPanelController controller = new NotificatorAdminPanelController(); 
        
        Test.startTest();        
        controller.runJob();
        Test.stopTest();  

        System.assertEquals(true,controller.getKillJobButtonActive());           
    }      
    
    static testMethod void getKillJobButtonActive_whenJobIsNotRunning_returnFalse() {
        NotificatorTestUtils.prepareTestNotificator();        
        NotificatorAdminPanelController controller = new NotificatorAdminPanelController(); 

        System.assertEquals(false,controller.getKillJobButtonActive());           
    }     
    
    static testMethod void killJob() {
        NotificatorTestUtils.prepareTestNotificator();        
        NotificatorAdminPanelController controller = new NotificatorAdminPanelController(); 
        
        Test.startTest();        
        controller.runJob();
        Test.stopTest();  
		controller.killJob();        

		Integer count = [Select count() FROM CronTrigger WHERE CronJobDetail.Name = 'Notificator_Test' LIMIT 1];        
        System.assertEquals(0,count);            
    }    
    
}