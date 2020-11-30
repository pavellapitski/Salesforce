/**
 * Created by pavel on 2020-10-23.
 */

@IsTest
private class InvoiceHelperTest {

    @IsTest
    static void invoiceSchedulerTestSuccess() {
        TestHelper.createAppSettings();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new InvoiceHelper.ResponseMockSuccess());
        System.schedule('Test Scheduler', '0 0 23 * * ?', new InvoiceScheduler());
        Test.stopTest();

        List<EventLog__c> logs = [SELECT Id, Info__c, Status__c FROM EventLog__c WHERE Type__c = :EventLog.STRIKE_DATA_CALLOUT AND Status__c = :EventLog.STATUS_ERROR];
        System.assertEquals(logs.size(), 0, 'No Errors Should Be');
    }

    @IsTest
    static void calloutInvoicesTestSuccess() {
        TestHelper.createAppSettings();
        InvoiceHelper.ResponseMockSuccess mockClass = new InvoiceHelper.ResponseMockSuccess();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mockClass);
        InvoiceScheduler.calloutInvoices();
        Test.stopTest();

        List<EventLog__c> logs = [SELECT Id, Info__c, Status__c FROM EventLog__c WHERE Type__c = :EventLog.STRIKE_DATA_CALLOUT AND Status__c = :EventLog.STATUS_ERROR];
        System.assertEquals(logs.size(), 0, 'No Errors Should Be');

        List<Invoice__c> invoices = [SELECT Id FROM Invoice__c];
        System.assertEquals(mockClass.invoice_amount, invoices.size());
    }

    @IsTest
    static void sendInvoiceTest() {
        String region = 'EMEA';
        Integer invoices_amount = 1;

        XeroSettings__c xs = TestHelper.createXeroEntityByRegion(region, true);
        List<Invoice__c> invoices = new List<Invoice__c>();
        for (Integer i = 1; i <= invoices_amount; i++) {
            invoices.add(TestHelper.createInvoice(100*i, xs.Id, region, false));
        }
        insert invoices;

        List<Invoice__c> invoicesSelected = [SELECT Xero_Invoice_Id__c, Xero_Invoice_Name__c, Xero_Id__c FROM Invoice__c WHERE Id IN :invoices];
        for (Invoice__c invoice :invoicesSelected) {
            System.assertEquals(null, invoice.Xero_Invoice_Id__c, 'Id should be equal to null');
            System.assertEquals(null, invoice.Xero_Invoice_Name__c, 'Id should be equal to null');
            System.assertNotEquals(null, invoice.Xero_Id__c, 'Xero Contract Id should be defined to create Invoice record in Xero');
        }

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new XeroMockUpResponseGenerator());
        for (Invoice__c invoice :invoices) {
            InvoiceHelper.sendInvoice(invoice);
        }
        Test.stopTest();

        invoicesSelected = [SELECT Xero_Invoice_Id__c, Xero_Invoice_Name__c FROM Invoice__c WHERE Id IN :invoices];
        for (Invoice__c invoice :invoicesSelected) {
            System.assertNotEquals(null, invoice.Xero_Invoice_Id__c, 'Id should be assigned');
            System.assertNotEquals(null, invoice.Xero_Invoice_Name__c, 'Id should be assigned');
        }
    }

    @IsTest
    static void calloutInvoicesTestSuccessDuplicationCheck1() {
        TestHelper.createAppSettings();
        InvoiceHelper.ResponseMockSuccess mockClass = new InvoiceHelper.ResponseMockSuccess();

        Test.startTest();
        // create duplicate records
        List<Invoice__c> invoicesToInsert = new List<Invoice__c>();
        for (InvoiceHelper.InvoiceData invoice :mockClass.getBodyFor5Records()) {
            invoicesToInsert.add(InvoiceHelper.setInvoice(invoice));
        }
        // change the date, decreasing the month by 1
        for (Invoice__c invoice :invoicesToInsert) {
            invoice.Start_Date__c = invoice.Start_Date__c.addMonths(-1);
            invoice.End_Date__c = invoice.End_Date__c.addMonths(-1);
        }
        Integer existingInvoiceAmount = invoicesToInsert.size();
        insert invoicesToInsert;

        Test.setMock(HttpCalloutMock.class, mockClass);
        InvoiceScheduler.calloutInvoices();
        Test.stopTest();

        List<EventLog__c> logs = [SELECT Id, Info__c, Status__c FROM EventLog__c WHERE Type__c = :EventLog.STRIKE_DATA_CALLOUT AND Status__c = :EventLog.STATUS_ERROR];
        System.assertEquals(logs.size(), 0, 'No Errors Should Be');

        List<Invoice__c> invoices = [SELECT Id FROM Invoice__c];
        System.assertEquals(existingInvoiceAmount * 2, invoices.size(), 'Old records stay unchanged, new records have been added');
    }

    @IsTest
    static void calloutInvoicesTestSuccessDuplicationCheck2() {
        Decimal initialInvoiceAmount = 100;
        TestHelper.createAppSettings();
        InvoiceHelper.ResponseMockSuccess mockClass = new InvoiceHelper.ResponseMockSuccess();

        Test.startTest();
        // create duplicate records
        List<Invoice__c> invoicesToInsert = new List<Invoice__c>();
        for (InvoiceHelper.InvoiceData invoice :mockClass.getBodyFor5Records()) {
            invoice.invoice_amount = initialInvoiceAmount; // set up Invoice Amount to check the value is updated further
            invoicesToInsert.add(InvoiceHelper.setInvoice(invoice));
        }
        insert invoicesToInsert;

        Test.setMock(HttpCalloutMock.class, mockClass);
        InvoiceScheduler.calloutInvoices();
        Test.stopTest();

        List<EventLog__c> logs = [SELECT Id, Info__c, Status__c FROM EventLog__c WHERE Type__c = :EventLog.STRIKE_DATA_CALLOUT AND Status__c = :EventLog.STATUS_ERROR];
        System.assertEquals(logs.size(), 0, 'No Errors Should Be');

        List<Invoice__c> invoices = [SELECT Id, Invoice_Amount__c FROM Invoice__c];
        System.assertEquals(mockClass.invoice_amount, invoices.size(), 'Old records have been replaced by new ones');
        for (Invoice__c invoice :invoices) {
            System.assertNotEquals(initialInvoiceAmount, invoice.Invoice_Amount__c, 'Invoice Amount should be updated');
        }
    }

    @IsTest
    static void updateInvoiceFromXeroSyncScheduler() { // XeroSync.updateInvoice()

    }

    /*@IsTest
    static void invoiceBatchTestError() {
        TestHelper.createAppSettings();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new InvoiceHelper.ResponseMockError());
        System.schedule('Test Scheduler 1', '0 0 22 * * ?', new InvoiceScheduler());
        Test.stopTest();

        List<EventLog__c> logs = [SELECT Id, Info__c, Status__c FROM EventLog__c WHERE Type__c = :EventLog.STRIKE_DATA_CALLOUT AND Status__c = :EventLog.STATUS_ERROR];
        System.assertEquals(1, logs.size());
        System.assert((logs[0].Info__c).startsWith('CALLOUT ERROR. STATUS: '));
    }*/


}