public with sharing class PaymentCtrl {

    public Sub_Project__c payment { get;set; }
    private ApexPages.StandardController stdController;

    public List<Utility.FieldSetDefinition> fsList {get;set;}
    public Boolean showEditPopUpMessage { get;set; }
    public Boolean saveAndNew { get;set; }

    public Boolean savedSuccessfully { get;set; }

    private Decimal baseClientSpend;

    public PaymentCtrl(ApexPages.StandardController stdController) {
        this.payment = (Sub_Project__c) stdController.getRecord();
        this.stdController = stdController;
    }

    public void onEditReady() {
        this.payment = [SELECT Account__c, Account_Type__c, AdWordsSpend__c, AdWords_Spend_report__c, Ad_Serving_Costs__c,
                Billing_Conditions__c, Billing_Profile__c, Campaign_Status__c, Checked__c, Client_Spend__c,
                Client_Spend_Defined_on_IO__c, CreatedById, CreatedDate, CurrencyIsoCode, Days_running__c,
                Discount_Violation__c, Discount_Terms__c, End_Date__c, ExpectedRebate__c, Final_Margin__c, IsDeleted,
                Expected_Gross_Profit__c ,Gross_Profit__c, Gross_Profit_report__c, Id, Invoice__c, Invoice_Amount__c,
                LastActivityDate, LastModifiedById, LastModifiedDate, LastReferencedDate, LastViewedDate,
                Margin__c, Margin_Type__c, Media_Order__c, Name, Opportunity__c, Paid__c,
                Payment_Date__c, PaymentType__c, Project__c, ProjectID__c, RecordTypeId, RecordType.Name,
                Start_Date__c, Synced_with_Xero__c, SystemModstamp, Total_Revenue__c, Total_Revenue_report__c,
                Suggested_Client_Spend__c, Xero_ID__c, Xero_Invoice__c ,  XeroStatus__c,
                (SELECT CreatedById, CreatedDate, Field, Id, IsDeleted, NewValue, OldValue, ParentId FROM Histories ORDER BY CreatedDate DESC LIMIT 10)
            FROM Sub_Project__c
            WHERE Id =: this.payment.Id
        ];

        String paymentType = this.payment.RecordType.Name;
        Map<String,Schema.FieldSet> fsMap = Utility.getObjectFieldSetsMap('Sub_Project__c');
        fsList = new List<Utility.FieldSetDefinition>();
        for (Schema.FieldSet fs :fsMap.values()) {
            if (!fs.getName().contains('Editfields')) {
                continue;
            }
            fsList.add(new Utility.FieldSetDefinition(fs));
        }

        showEditPopUpMessage = false;
        saveAndNew = false;
        baseClientSpend = this.payment.Client_Spend__c;
    }

    public PageReference submitClientSpend() {
        showEditPopUpMessage = false;
        savedSuccessfully = true;

        try {
            update this.payment;
        } catch (DmlException e) {
            ApexPages.Message msg = new apexPages.Message(Apexpages.Severity.ERROR, e.getDmlMessage(0));
            ApexPages.addMessage(msg);
            savedSuccessfully = false;
            return null;
        }

        if (saveAndNew) {
            ApexPages.currentPage().setRedirect(true);
            return new PageReference('/' + stdController.getRecord().getSObjectType().getDescribe().getKeyPrefix() + '/e');
        }
        return new PageReference('/' + this.payment.Id);
    }

    public PageReference save() {
        if (payment.Client_Spend_Defined_on_IO__c == true && payment.Client_Spend__c != baseClientSpend) {
            showEditPopUpMessage = true;
            return null;
        }

        savedSuccessfully = true;
        try {
            update payment;
        } catch (DmlException e) {
            ApexPages.Message msg = new apexPages.Message(Apexpages.Severity.ERROR, e.getDmlMessage(0));
            ApexPages.addMessage(msg);
            savedSuccessfully = false;
            return null;
        }

        if (saveAndNew) {
            ApexPages.currentPage().setRedirect(true);
            return new PageReference('/' + stdController.getRecord().getSObjectType().getDescribe().getKeyPrefix() + '/e');
        }
        return new PageReference('/' + this.payment.Id);
    }


    public PageReference cancelUpdate() {
        showEditPopUpMessage = false;
        return new PageReference('/' + this.payment.Id);
    }
}