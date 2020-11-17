global class ContractNotificationScheduler implements Schedulable {

   global void execute(SchedulableContext sc) {       
      ContractNotification.sendSalesRepNotifications();
      ContractNotification.sendCSRepNotifications();
      ContractNotification.sendCSRepPostLaunchNotifications();
   }
}