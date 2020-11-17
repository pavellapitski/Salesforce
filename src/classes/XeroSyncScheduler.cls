global class XeroSyncScheduler implements Schedulable {

   global void execute(SchedulableContext sc) {
      XeroSync.handleInvoicesFromXero();
      XeroSync.updateCreditNotesFromXero();

      //XeroSync.updateInvoiceFromXero();
   }
}