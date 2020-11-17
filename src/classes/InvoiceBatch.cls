/**
 * Created by pavel on 2020-10-13.
 */

public with sharing class InvoiceBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id FROM Invoice__c WHERE Status__c = NULL]);
    }

    public void execute(Database.BatchableContext BC, List<Invoice__c> unpaidInvoices) {

    }

    public void finish(Database.BatchableContext BC) {}




}