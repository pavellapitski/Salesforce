global class SubProjectNotificationScheduler implements Schedulable 
{
    global void execute(SchedulableContext sc) {
      SubProjectNotification.sendPaymentsNotification();
      SubProjectNotification.sendCreditNotesNotification();
   } 
}