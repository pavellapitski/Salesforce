global class OpportunityNotificationScheduler implements Schedulable {

   global void execute(SchedulableContext sc) {       
      OpportunityNotification.sendSalesRepNotifications('OpportunitySalesRepReminder12Days', 12);
      OpportunityNotification.sendSalesRepNotifications('OpportunitySalesRepReminder30Days', 30);
      OpportunityNotification.sendCSRepNotifications('OpportunityClientServiceReminder12Days', 12);
      OpportunityNotification.sendCSRepNotifications('OpportunityClientServiceReminder30Days', 30);
   }
}