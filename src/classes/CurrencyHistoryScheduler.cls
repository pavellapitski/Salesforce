global class CurrencyHistoryScheduler implements Schedulable, Database.AllowsCallouts {

    global CurrencyHistoryScheduler() {}

    global void execute(SchedulableContext sc) {
        CurrencyHistory.updateCurrencyRates(System.today().addDays(-1));
        System.scheduleBatch(new UpdateCurrenciesBatch(), 'Manage Currencies', 1);
    }
}