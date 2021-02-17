global class XeroSyncScheduler implements Schedulable {

   /*
   String CRON_EXP = '0 ' + Datetime.now().addMinutes(1).minute() + ' ' +
           Datetime.now().hour() + ' ' +
           System.today().day() + ' ' +
           System.today().month() + ' ? ' + System.today().year();

   System.schedule('Xero Sync Daily', CRON_EXP, new XeroSyncScheduler());

   System.schedule('Xero Sync Daily', '0 55 14 * * ?', new XeroSyncScheduler());
   */

   global void execute(SchedulableContext sc) {
      XeroSync.handleInvoicesFromXero();
      //XeroSync.updateCreditNotesFromXero();

      XeroSync.updateInvoiceFromXero();
   }


}