global with sharing class XeroWrappers {
    public XeroWrappers() {}

    global abstract class XeroObject {
        @AuraEnabled public List<String> validationErrors;
    }

    global class XeroAccount extends XeroObject{
        public String accountID { get;set; }
        public String code { get;set; }
        public String name { get;set; }
        public String accountType { get;set; }
        public String status { get;set; }
        public String description { get;set; }
        public String taxType { get;set; }
        public Boolean enablePaymentsToAccount { get;set; }
        public Boolean showInExpenseClaims { get;set; }
        public String accountClass { get;set; }
        public String systemAccount { get;set; }
        public String bankAccountNumber { get;set; }
        public String bankAccountType { get;set; }
        public String currencyCode { get;set; }
        public String reportingCode { get;set; }
        public String reportingCodeName { get;set; }
        public Boolean hasAttachments { get;set; }

        global XeroAccount() {}
        global XeroAccount(Map<String, Object> params) {
            for (String key : params.keySet()) {
                if (key == 'AccountID') {
                    this.accountID = String.valueOf(params.get(key));
                } else if (key == 'Code') {
                    this.code = String.valueOf(params.get(key));
                } else if (key == 'Name') {
                    this.name = String.valueOf(params.get(key));
                } else if (key == 'Status') {
                    this.status = String.valueOf(params.get(key));
                } else if (key == 'Type') {
                    this.accountType = String.valueOf(params.get(key));
                } else if (key == 'TaxType') {
                    this.taxType = String.valueOf(params.get(key));
                } else if (key == 'Description') {
                    this.description = String.valueOf(params.get(key));
                } else if (key == 'Class') {
                    this.accountClass = String.valueOf(params.get(key));
                } else if (key == 'SystemAccount') {
                    this.systemAccount = String.valueOf(params.get(key));
                } else if (key == 'EnablePaymentsToAccount') {
                    this.enablePaymentsToAccount = Boolean.valueOf(params.get(key));
                } else if (key == 'ShowInExpenseClaims') {
                    this.showInExpenseClaims = Boolean.valueOf(params.get(key));
                } else if (key == 'BankAccountType') {
                    this.bankAccountType = String.valueOf(params.get(key));
                } else if (key == 'ReportingCode') {
                    this.reportingCode = String.valueOf(params.get(key));
                } else if (key == 'BankAccountNumber') {
                    this.bankAccountNumber = String.valueOf(params.get(key));
                } else if (key == 'CurrencyCode') {
                    this.currencyCode = String.valueOf(params.get(key));
                } else if (key == 'ReportingCodeName') {
                    this.reportingCodeName = String.valueOf(params.get(key));
                } else if (key == 'HasAttachments') {
                    this.hasAttachments = Boolean.valueOf(params.get(key));
                }
            }
        }
    }

    /**************** CONTACT ****************/
    global class XeroContact extends XeroObject {
        @AuraEnabled public String contactID { get;set; }
        @AuraEnabled public String contactNumber { get;set; }
        @AuraEnabled public String accountNumber { get;set; }
        @AuraEnabled public XeroContactStatus contactStatus { get;set; }
        @AuraEnabled public String name { get;set; }
        @AuraEnabled public String firstName { get;set; }
        @AuraEnabled public String lastName { get;set; }
        @AuraEnabled public String emailAddress { get;set; }
        @AuraEnabled public String skypeUserName { get;set; }
        @AuraEnabled public String bankAccountDetails { get;set; }
        @AuraEnabled public String taxNumber { get;set; }
        @AuraEnabled public String accountsReceivableTaxType { get;set; }
        @AuraEnabled public String accountsPayableTaxType { get;set; }
        @AuraEnabled public Boolean isSupplier { get;set; }
        @AuraEnabled public Boolean isCustomer { get;set; }
        @AuraEnabled public String defaultCurrency { get;set; }
        @AuraEnabled public List<XeroAddress> addresses { get;set; }
        @AuraEnabled public List<XeroPhone> phones { get;set; }
        @AuraEnabled public List<XeroContactPerson> contactPersons { get;set; }

        // optional for PUT/POST
        @AuraEnabled public String xeroNetworkKey { get;set; }
        @AuraEnabled public String salesDefaultAccountCode { get;set; }
        @AuraEnabled public String purchasesDefaultAccountCode { get;set; }
        @AuraEnabled public List<XeroTrackingCategory> salesTrackingCategories { get;set; }
        @AuraEnabled public List<XeroTrackingCategory> purchasesTrackingCategory { get;set; }
        @AuraEnabled public XeroPaymentTerms paymentTerms { get;set; }

        // only for GET
        @AuraEnabled public List<XeroContactGroup> contactGroups { get;set; }
        @AuraEnabled public String website { get;set; }
        @AuraEnabled public XeroBrandingTheme brandingTheme { get;set; }
        @AuraEnabled public XeroBatchPayment batchPayments { get;set; }
        @AuraEnabled public Decimal discount { get;set; }
        @AuraEnabled public XeroBalances balances { get;set; }
        @AuraEnabled public Boolean hasAttachments { get;set; }
        @AuraEnabled public Boolean hasErrors { get {
            if (hasErrors == null) {
                hasErrors = false;
            }
            return hasErrors;
        } set; }

        // only for POST/PUT
        @AuraEnabled public List<XeroMessage> warnings { get;set; }

        global XeroContact() {}

        global XeroContact(String contactId) {
            this.contactID = contactId;
        }

        global XeroContact(Map<String, Object> params) {
            purchasesTrackingCategory = new List<XeroTrackingCategory>();
            salesTrackingCategories = new List<XeroTrackingCategory>();
            contactPersons = new List<XeroContactPerson>();
            phones = new List<XeroPhone>();
            addresses = new List<XeroAddress>();
            contactGroups = new List<XeroContactGroup>();

            for (String key :params.keySet()) {
                if (String.isBlank(key) || params.get(key) == null) {
                    continue;
                }

                if (key == 'ContactID') {
                    this.contactID = String.valueOf(params.get(key));
                } else if (key == 'ContactNumber') {
                    this.contactNumber = String.valueOf(params.get(key));
                } else if (key == 'AccountNumber') {
                    this.accountNumber = String.valueOf(params.get(key));
                } else if (key == 'ContactStatus') {
                    this.contactStatus = (XeroWrappers.XeroContactStatus) XeroWrappers.getEnumValue('ContactStatus', String.valueOf(params.get(key)));
                } else if (key == 'Name') {
                    this.name = String.valueOf(params.get(key));
                } else if (key == 'FirstName') {
                    this.firstName = String.valueOf(params.get(key));
                } else if (key == 'Lastname') {
                    this.lastName = String.valueOf(params.get(key));
                } else if (key== 'EmailAddress') {
                    this.emailAddress = String.valueOf(params.get(key));
                } else if (key == 'SkypeUserName') {
                    this.skypeUserName = String.valueOf(params.get(key));
                } else if (key == 'BankAccountDetails') {
                    this.bankAccountDetails = String.valueOf(params.get(key));
                } else if (key == 'TaxNumer') {
                    this.taxNumber = String.valueOf(params.get(key));
                } else if (key == 'AccountsReceivableTaxType') {
                    this.accountsReceivableTaxType = String.valueOf(params.get(key));
                } else if (key == 'AccountsPayableTaxType') {
                    this.accountsPayableTaxType = String.valueOf(params.get(key));
                } else if (key == 'IsSupplier') {
                    this.isSupplier = Boolean.valueOf(params.get(key));
                } else if (key == 'IsCustomer') {
                    this.isCustomer = Boolean.valueOf(params.get(key));
                } else if (key == 'DefaultCurrency') {
                    this.defaultCurrency = String.valueOf(params.get(key));
                } else if (key == 'Discount') {
                    this.discount = Decimal.valueOf(String.valueOf(params.get(key)));
                } else if (key == 'Website') {
                    this.website = String.valueOf(params.get(key));
                } else if (key == 'Addresses') {
                    for (Object address :(List<Object>) params.get(key)) {
                        this.addresses.add(new XeroAddress((Map<String,Object>) address));
                    }
                } else if (key == 'Phones') {
                    for (Object phone :(List<Object>) params.get(key)) {
                        this.phones.add(new XeroPhone((Map<String,Object>)phone));
                    }
                } else if (key == 'BatchPayments') {
                    this.batchPayments = new XeroBatchPayment((Map<String,Object>)params.get(key));
                } else if (key == 'ContactPersons') {
                    for (Object p :(List<Object>) params.get(key)) {
                        this.contactPersons.add(new XeroContactPerson((Map<String,Object>)p));
                    }
                } else if (key == 'XeroNetworkKey') {
                    this.xeroNetworkKey = String.valueOf(params.get(key));
                } else if (key == 'SalesDefaultAccountCode') {
                    this.salesDefaultAccountCode = String.valueOf(params.get(key));
                } else if (key == 'PurchasesDefaultAccountCode') {
                    this.purchasesDefaultAccountCode = String.valueOf(params.get(key));
                } else if (key == 'SalesTrackingCategories') {
                    for (Object cat :(List<Object>) params.get(key)) {
                        this.salesTrackingCategories.add(new XeroTrackingCategory((Map<String,Object>)cat));
                    }
                } else if (key == 'PurchasesTrackingCategories') {
                    for (Object cat :(List<Object>)params.get(key)) {
                        this.purchasesTrackingCategory.add(new XeroTrackingCategory((Map<String,Object>)cat));
                    }
                } else if (key == 'PaymentTerms') {
                    this.paymentTerms = new XeroPaymentTerms((Map<String,Object>)params.get(key));
                } else if (key == 'BrandingTheme') {
                    this.brandingTheme = new XeroBrandingTheme((Map<String,Object>)params.get(key));
                } else if (key == 'HasAttachments') {
                    this.hasAttachments = Boolean.valueOf(params.get(key));
                } else if (key == 'ContactGroups') {
                    for (Object xcg :(List<Object>) params.get(key)) {
                        this.contactGroups.add(new XeroContactGroup((Map<String,Object>)xcg));
                    }
                } if (key == 'Balances') {
                    this.balances = new XeroBalances((Map<String,Object>)params.get(key));
                } else if (key == 'Warnings') {
                    this.warnings = new List<XeroMessage>();
                    for (Object obj :(List<Object>) params.get(key)) {
                        this.warnings.add(new XeroMessage((Map<String,Object>)obj));
                    }
                } else if (key == 'HasValidationErrors') {
                    this.hasErrors = Boolean.valueOf(params.get(key));
                } else if (key == 'ValidationErrors') {
                    this.validationErrors = new List<String>();
                    for (Object obj :(List<Object>) params.get(key)) {
                        this.validationErrors.add(String.valueOf(((Map<String,Object>)obj).get('Message')));
                    }
                }
            }
        }
    }

    global class XeroLineItem extends XeroObject {
        // required to create & recommended for PUT/POST
        public String description { get;set; }

        // recommended for PUT/POST
        public Decimal quantity { get;set; }
        public Decimal unitAmount { get;set; }
        public String itemCode { get;set; }
        public String accountCode { get;set; }

        // recommended for POST
        public String lineItemID { get;set; }

        // optional for PUT/POST
        public String taxType { get;set; }
        public Decimal taxAmount { get;set; }
        public Decimal lineAmount { get;set; }
        public List<XeroTrackingCategory> tracking { get;set; }
        public Decimal discountRate { get;set; }

        // only for POST/PUT
        public List<XeroMessage> warnings { get;set; }

        global XeroLineItem() {
            tracking = new List<XeroTrackingCategory>();
        }

        global XeroLineItem(Map<String, Object> params) {
            tracking = new List<XeroTrackingCategory>();
            for (String key : params.keySet()) {
                if (String.isBlank(key) == true || params.get(key) == null) {
                    continue;
                }

                if (key == 'Description') {
                    this.description = String.valueOf(params.get(key));
                } else if (key == 'Quantity') {
                    this.quantity = Decimal.valueOf(String.valueOf(params.get(key)));
                } else if (key == 'UnitAmount') {
                    this.unitAmount = Decimal.valueOf(String.valueOf(params.get(key)));
                } else if (key == 'ItemCode') {
                    this.itemCode = String.valueOf(params.get(key));
                } else if (key == 'AccountCode') {
                    this.accountCode = String.valueOf(params.get(key));
                } else if (key == 'LineItemID') {
                    this.lineItemID = String.valueOf(params.get(key));
                } else if (key == 'TaxType') {
                    this.taxType = String.valueOf(params.get(key));
                } else if (key == 'TaxAmount') {
                    this.taxAmount = Decimal.valueOf(String.valueOf(params.get(key)));
                } else if (key == 'LineAmount') {
                    this.lineAmount = Decimal.valueOf(String.valueOf(params.get(key)));
                } else if (key == 'Tracking') {
                    for (Object tracking :(List<Object>) params.get(key)) {
                        this.tracking.add(new XeroTrackingCategory((Map<String,Object>) tracking));
                    }
                } else if (key == 'DiscountRate') {
                    this.discountRate = Decimal.valueOf(String.valueOf(params.get(key)));
                } else if (key == 'Warnings') {
                    this.warnings = new List<XeroMessage>();
                    for (Object obj :(List<Object>) params.get(key)) {
                        this.warnings.add(new XeroMessage((Map<String,Object>) obj));
                    }
                }
            }
        }
    }

    global class XeroInvoice extends XeroObject {
        // required
        public XeroInvoiceType type { get;set; }
        public XeroContact contact { get;set; }
        public List<XeroLineItem> lineItems { get; set; }
        // recommended for PUT/POST
        public Date invoiceDate { get;set; }    // in response - Date
        public String dateString { get;set; }
        public Date dueDate { get;set; }
        public String dueDateString { get;set; }
        public XeroLineAmount lineAmount { get;set; }
        // optional for PUT/POST
        public String invoiceNumber { get;set; }
        public String reference { get;set; }
        public String brandingThemeID { get;set; }
        public String url { get;set; }
        public String currencyCode { get;set; }
        public Decimal currencyRate { get;set; }
        public XeroInvoiceStatus status { get;set; }
        public Boolean sentToContact { get;set; }
        public Date expectedPaymentDate { get;set; }
        public Date plannedPaymentDate { get;set; }
        // GET vars
        public Decimal subTotal { get;set; }
        public Decimal totalTax { get;set; }
        public Decimal total { get;set; }
        public Decimal totalDiscount { get;set; }
        public String invoiceID { get;set; }
        public Boolean hasAttachments { get;set; }
        public Decimal amountDue { get;set; }
        public Decimal amountPaid { get;set; }
        public Date fullyPaidOnDate { get;set; }
        public Decimal amountCredited { get;set; }
        public Date updatedDateUTC { get;set; }

        // only for POST/PUT response
        public List<XeroMessage> warnings { get;set; }
        public Boolean hasErrors { get;set; }

        global XeroInvoice() {
            this.lineItems = new List<XeroLineItem>();
        }

        global XeroInvoice(Map<String,Object> params) {
            this.lineItems = new List<XeroLineItem>();
            for (String key : params.keySet()) {
                // skip if no param
                if (String.isBlank(key) == true || params.get(key) == null) {
                    continue;
                }

                if (key == 'Type') {
                    this.type = (XeroInvoiceType) XeroWrappers.getEnumValue('InvoiceType', (String.valueOf(params.get(key))));
                } else if (key == 'Contact') {
                    this.contact = new XeroContact((Map<String,Object>)params.get(key));
                } else if (key == 'LineItems') {
                    this.lineItems = new List<XeroLineItem>();
                    for (Object xli :(List<Object>) params.get(key)) {
                        this.lineItems.add(new XeroLineItem((Map<String,Object>)xli));
                    }
                } else if (key == 'DateString') {
                    this.dateString  = String.valueOf(params.get(key));
                    this.invoiceDate = Date.valueOf(this.dateString);
                } else if (key == 'DueDateString') {
                    this.dueDate = Date.valueOf(String.valueOf(params.get(key)));
                } else if (key == 'LineAmount') {
                    this.lineAmount = (XeroLineAmount) XeroWrappers.getEnumValue('LineAmount', String.valueOf(params.get(key)));
                } else if (key == 'InvoiceNumber') {
                    this.invoiceNumber = String.valueOf(params.get(key));
                } else if (key == 'Reference') {
                    this.reference = String.valueOf(params.get(key));
                } else if (key == 'Url') {
                    this.url = String.valueOf(params.get(key));
                } else if (key == 'CurrencyCode') {
                    this.currencyCode = String.valueOf(params.get(key));
                } else if (key == 'CurrencyRate') {
                    this.currencyRate = Decimal.valueOf(String.valueOf(params.get(key)));
                } else if (key == 'Status') {
                    this.status = (XeroInvoiceStatus)XeroWrappers.getEnumValue('InvoiceStatus', String.valueOf(params.get(key)));
                } else if (key == 'SentToContact') {
                    this.sentToContact = Boolean.valueOf(params.get(key));
                } else if (key == 'ExpectedPaymentDateString') {
                    this.expectedPaymentDate = Date.valueOf(String.valueOf(params.get(key)));
                } else if (key == 'PlannedPaymentDateString') {
                    this.plannedPaymentDate = Date.valueOf(String.valueOf(params.get(key)));
                } else if (key == 'SubTotal') {
                    this.subTotal = Decimal.valueOf(String.valueOf(params.get(key)));
                } else if (key == 'TotalTax') {
                    this.totalTax = Decimal.valueOf(String.valueOf(params.get(key)));
                } else if (key == 'Total') {
                    this.total = Decimal.valueOf(String.valueOf(params.get(key)));
                } else if (key == 'TotalDiscount') {
                    this.totalDiscount = Decimal.valueOf(String.valueOf(params.get(key)));
                } else if (key == 'InvoiceID') {
                    this.invoiceID = String.valueOf(params.get(key));
                } else if (key == 'HasAttachments') {
                    this.hasAttachments = Boolean.valueOf(params.get(key));
                } else if (key == 'Warnings') {
                    this.warnings = new List<XeroMessage>();
                    for (Object obj :(List<Object>) params.get(key)) {
                        this.warnings.add(new XeroMessage((Map<String,Object>)obj));
                    }
                } else if (key == 'BrandingThemeID') {
                    this.brandingThemeID = String.valueOf(params.get(key));
                } else if (key == 'AmountDue') {
                    this.amountDue = Decimal.valueOf(String.valueOf(params.get(key)));
                } else if (key == 'AmountPaid') {
                    this.amountPaid = Decimal.valueOf(String.valueOf(params.get(key)));
                } else if (key == 'FullyPaidOnDate') {
                    String fullyPaid = String.valueOf(params.get(key));
                    if (String.isNotBlank(fullyPaid)) {
                        fullyPaid = fullyPaid.substring(fullyPaid.indexOf('(') + 1, fullyPaid.indexOf(')'));

                        List<String> positiveOffset = fullyPaid.split('\\+');
                        List<String> negativeOffset = fullyPaid.split('\\-');

                        Long milliseconds;
                        Integer offset;
                        if (negativeOffset.size() == 2) {
                            milliseconds = Long.valueOf(negativeOffset[0]);
                            offset = Integer.valueOf('-' + negativeOffset[1].left(2));
                        } else if (positiveOffset.size() == 2) {
                            milliseconds = Long.valueOf(positiveOffset[0]);
                            offset = Integer.valueOf(positiveOffset[1].left(2));
                        }
                        this.fullyPaidOnDate = Datetime.newInstance(milliseconds).addHours(offset).dateGmt();
                    }
                } else if (key == 'AmountCredited') {
                    this.amountCredited = Decimal.valueOf(String.valueOf(params.get(key)));
                } else if (key == 'UpdatedDateUTCString') {
                    this.updatedDateUTC = Date.valueOf(String.valueOf(params.get(key)));
                } else if (key == 'HasErrors') {
                    this.hasErrors = Boolean.valueOf(params.get(key));
                } else if (key == 'ValidationErrors') {
                    this.validationErrors = new List<String>();
                    for (Object obj :(List<Object>) params.get(key)) {
                        this.validationErrors.add(String.valueOf(((Map<String,Object>)obj).get('Message')));
                    }
                }
            }
        }
    }

    global class XeroCreditNote extends XeroObject {
        public List<XeroLineItem> lineItems { get; set; }
        public XeroCreditNoteStatus status { get; set; }
        public XeroCreditNoteType type { get;set; }
        public XeroContact contact { get;set; }
        public Date creditNoteDate {get; set;}
        public String creditNoteId {get; set;}
        public String creditNoteNumber {get; set;}
        public String currencyCode {get; set;}
        public String Reference {get; set;}

        global XeroCreditNote(CreditNote__c creditNote) {
            Sub_Project__c payment = SubProjectRepository.getInvoiceForXeroSubmission(creditNote.Payment__c)[0];

            this.lineItems = new List<XeroLineItem>();
            this.currencyCode = creditNote.Payment__r.CurrencyIsoCode;
            this.type = XeroCreditNoteType.ACCRECCREDIT;
            this.status = XeroCreditNoteStatus.SUBMITTED;

	        String customName = payment.Project__r.Custom_Xero_Campaign_Name__c!=null?payment.Project__r.Custom_Xero_Campaign_Name__c : payment.Project__r.Name;
            this.Reference = payment.Invoice__c + ' - ' + customName + ' - ' + payment.ProjectID__c;

            Integer nextMonth = payment.End_Date__c.addMonths(1).month();
            if ((System.today().month() == payment.End_Date__c.month() || System.today().month() == nextMonth) && System.today().day() <= 14) {
                this.creditNoteDate = payment.End_Date__c;
            } else {
                this.creditNoteDate = System.today();
            }

            String contactId;
            if (!String.isBlank(creditNote.Payment__r.Project__r.Xero_ID__c) && !String.isBlank(creditNote.Payment__r.Project__r.Xero_Entity__c)) {
                contactId = creditNote.Payment__r.Project__r.Xero_ID__c;
            } else {
                contactId = creditNote.Payment__r.Account__r.Xero_Id__c;
            }
            this.contact = new XeroWrappers.XeroContact(contactId);

            XeroWrappers.XeroLineItem lineItem = new XeroWrappers.XeroLineItem();
            lineItem.description = XeroUtils.prepareLineItemDescription(payment);
            lineItem.quantity = 1;
            lineItem.accountCode = creditNote.Payment__r.Project__r.Xero_Entity__r.AccountCode__c !=null ? creditNote.Payment__r.Project__r.Xero_Entity__r.AccountCode__c : '1100';
            lineItem.lineAmount  = creditNote.XeroAmount__c;
            this.lineItems = new List<XeroWrappers.XeroLineItem>{lineItem};
        }

        global XeroCreditNote(Map<String,Object> params) {
            this.lineItems = new List<XeroLineItem>();
            this.validationErrors = new List<String>();

            for (String key : params.keySet()) {
                if (String.isBlank(key) == true || params.get(key) == null) {
                    continue;
                }

                if (key == 'CreditNoteID') {
                    this.creditNoteId = String.valueOf(params.get(key));
                }
                if (key == 'CreditNoteNumber') {
                    this.creditNoteNumber = String.valueOf(params.get(key));
                }
                if (key == 'Reference') {
                    this.Reference = String.valueOf(params.get(key));
                }
                if (key == 'Status') {
                    this.status = (XeroCreditNoteStatus)XeroWrappers.getEnumValue('CreditNoteStatus', String.valueOf(params.get(key)));
                }
                if (key == 'ValidationErrors') {
                    for (Object obj :(List<Object>) params.get(key)) {
                        this.validationErrors.add(String.valueOf(((Map<String,Object>)obj).get('Message')));
                    }
                }
            }
        }
    }

    global class XeroCreditNoteAllocation extends XeroObject {
        public XeroInvoice Invoice {get; set;}
        public String AppliedAmount {get; set;}

        /*global XeroCreditNoteAllocation(CreditNote__c creditNote) {
            this.Invoice = new XeroInvoice();
            this.Invoice.invoiceID = creditNote.Payment__r.Xero_ID__c;
            this.AppliedAmount = String.valueOf(creditNote.Amount__c);
        }*/

        global XeroCreditNoteAllocation(Map<String,Object> params) {
            this.validationErrors = new List<String>();
            for (String key : params.keySet()) {
                if (String.isBlank(key) == true || params.get(key) == null) {
                    continue;
                }
                if (key == 'ValidationErrors') {
                    List<Object> objList = (List<Object>)params.get(key);
                    for (Object obj : objList) {
                        this.validationErrors.add(String.valueOf(((Map<String,Object>)obj).get('Message')));
                    }
                }
            }
        }
    }

    /**************** PAYMENT ****************/
    global class XeroPayment extends XeroObject {
        public String invoiceID { get;set; }
        public String creditNoteID { get;set; }
        public String prepaymentID { get;set; }
        public String overpaymentID { get;set; }
        public String invoiceNumber { get;set; }
        /*public String CreditNoteNumber { get;set; }*/

        public String accountID { get;set; }
        public String code { get;set; }
        public Date paymentDate { get;set; }
        public Decimal currencyRate { get;set; }
        public Decimal amount { get;set; }
        public String reference { get;set; }
        public Boolean isReconciled { get;set; }

        // only for method GET
        public XeroPaymentStatus status { get;set; }
        public XeroPaymentType paymentType { get;set; }
        public Date updatedDateUTC { get;set; }

        global XeroPayment() {}

        global XeroPayment(Map<String,Object> params){
            for (String key :params.keySet()) {
                if (String.isBlank(key) == true || params.get(key) == null) {
                    continue;
                }

                if (key == 'InvoiceID') {
                    this.invoiceID = String.valueOf(params.get(key));
                } else if (key == 'CreditNoteID') {
                    this.creditNoteID = String.valueOf(params.get(key));
                } else if (key == 'PrepaymentID') {
                    this.prepaymentID = String.valueOf(params.get(key));
                } else if (key == 'OverpaymentID') {
                    this.overpaymentID = String.valueOf(params.get(key));
                } else if (key == 'InvoiceNumber') {
                    this.invoiceNumber = String.valueOf(params.get(key));
                } else if (key == 'InvoiceID') {
                    this.invoiceID = String.valueOf(params.get(key));
                } else if (key == 'AccountID') {
                    this.accountID = String.valueOf(params.get(key));
                } else if (key == 'Code') {
                    this.code = String.valueOf(params.get(key));
                } else if (key == 'DateString') {
                    this.paymentDate = Date.valueOf(String.valueOf(params.get(key)));
                } else if (key == 'CurrencyRate') {
                    this.currencyRate = Decimal.valueOf(String.valueOf(params.get(key)));
                } else if (key == 'Amount') {
                    this.amount = Decimal.valueOf(String.valueOf(params.get(key)));
                } else if (key == 'Reference') {
                    this.reference = String.valueOf(params.get(key));
                } else if (key == 'IsReconciled') {
                    this.isReconciled = Boolean.valueOf(params.get(key));
                } else if (key == 'Status') {
                    this.status = (XeroPaymentStatus)getEnumValue('PaymentStatus', String.valueOf(params.get(key)));
                } else if (key == 'Status') {
                    this.paymentType = (XeroPaymentType)getEnumValue('PaymentType', String.valueOf(params.get(key)));
                } else if (key == 'UpdatedDateUTC') {
                    this.updatedDateUTC = convertToDate(String.valueOf(params.get(key)));
                }
            }
        }
    }

    /**************** PHONE ****************/
    global class XeroPhone extends XeroObject{
        @AuraEnabled public XeroPhoneType phoneType { get;set; }
        @AuraEnabled public String phoneNumber { get;set; }
        @AuraEnabled public String phoneAreaCode { get;set; }
        @AuraEnabled public String phoneCountryCode { get;set; }

        global XeroPhone() {}

        global XeroPhone(Map<String, Object> params) {
            for (String key : params.keySet()) {
                if (String.isBlank(key) == true && params.get(key) == null) {
                    continue;
                }

                if (key == 'PhoneType') {
                    this.phoneType = (XeroPhoneType)XeroWrappers.getEnumValue('PhoneType', String.valueOf(params.get(key)));
                } else if (key == 'PhoneNumber') {
                    this.phoneNumber = String.valueOf(params.get(key));
                } else if (key == 'PhoneAreaCode') {
                    this.phoneAreaCode = String.valueOf(params.get(key));
                } else if (key == 'PhoneCountryCode') {
                    this.phoneCountryCode = String.valueOf(params.get(key));
                }
            }
        }
    }

    /**************** ADDRESS ****************/
    global class XeroAddress extends XeroObject {
        @AuraEnabled public XeroAddressType AddressType { get;set; }
        @AuraEnabled public String AddressLine1 { get;set; }
        @AuraEnabled public String AddressLine2 { get;set; }
        @AuraEnabled public String AddressLine3 { get;set; }
        @AuraEnabled public String AddressLine4 { get;set; }
        @AuraEnabled public String City { get;set; }
        @AuraEnabled public String Region { get;set; }
        @AuraEnabled public String PostalCode { get;set; }
        @AuraEnabled public String Country { get;set; }
        @AuraEnabled public String AttentionTo { get;set; }

        global XeroAddress() {}

        global XeroAddress(Map<String, Object> params) {
            for (String key : params.keySet()) {
                if (String.isBlank(key) == true && params.get(key) == null) {
                    continue;
                }

                if (key == 'AddressType') {
                    this.AddressType = (XeroAddressType)XeroWrappers.getEnumValue('AddressType', String.valueOf(params.get(key)));
                } else if (key == 'AddressLine1') {
                    this.AddressLine1 = String.valueOf(params.get(key));
                } else if (key == 'AddressLine2') {
                    this.AddressLine2 = String.valueOf(params.get(key));
                } else if (key == 'AddressLine3') {
                    this.AddressLine3 = String.valueOf(params.get(key));
                } else if (key == 'AddressLine4') {
                    this.AddressLine4 = String.valueOf(params.get(key));
                } else if (key == 'City') {
                    this.City = String.valueOf(params.get(key));
                } else if (key == 'PostalCode') {
                    this.PostalCode = String.valueOf(params.get(key));
                } else if (key == 'Region') {
                    this.Region = String.valueOf(params.get(key));
                } else if (key == 'Country') {
                    this.Country = String.valueOf(params.get(key));
                } else if (key == 'AttentionTo') {
                    this.AttentionTo = String.valueOf(params.get(key));
                }
            }
        }
    }

    /**************** BATCH PAYMENT ****************/
    global class XeroBatchPayment extends XeroObject {
        public String BankAccountNumber { get;set; }
        public String BankAccountName { get;set; }
        public String Details { get;set; }
        public String Code { get;set; }
        public String Reference { get;set; }

        global XeroBatchPayment() {}
        global XeroBatchPayment(Map<String,Object> params) {
            for (String key : params.keySet()) {
                if (String.isBlank(key) == true && params.get(key) == null) {
                    continue;
                }

                if (key == 'BankAccountNumber') {
                    this.BankAccountNumber = String.valueOf(params.get(key));
                } else if (key == 'BankAccountName') {
                    this.BankAccountName = String.valueOf(params.get(key));
                } else if (key == 'Details') {
                    this.Details = String.valueOf(params.get(key));
                } else if (key == 'Code') {
                    this.Code = String.valueOf(params.get(key));
                } else if (key == 'Reference') {
                    this.Reference = String.valueOf(params.get(key));
                }
            }
        }
    }

    /**************** CONTACT PERSON ****************/
    global class XeroContactPerson extends XeroObject {
        @AuraEnabled public String ContactPersonId { get;set; }
        @AuraEnabled public String FirstName { get;set; }
        @AuraEnabled public String LastName { get;set; }
        @AuraEnabled public String EmailAddress { get;set; }
        @AuraEnabled public Boolean IncludeInEmails { get;set; }

        global XeroContactPerson() {}
        global XeroContactPerson(Map<String,Object> params) {
            for (String key : params.keySet()) {
                if (String.isBlank(key) == true && params.get(key) == null) {
                    continue;
                }

                if (key == 'ContactPersonId') {
                    this.ContactPersonId = String.valueOf(params.get(key));
                } else if (key == 'FirstName') {
                    this.FirstName = String.valueOf(params.get(key));
                } else if (key == 'LastName') {
                    this.LastName = String.valueOf(params.get(key));
                } else if (key == 'EmailAddress') {
                    this.EmailAddress = String.valueOf(params.get(key));
                } else if (key == 'IncludeInEmails') {
                    this.IncludeInEmails = Boolean.valueOf(params.get(key));
                }
            }
        }
    }

    // CONTACT GROUP
    global class XeroContactGroup extends XeroObject {
        @AuraEnabled String ContactGroupID { get;set; }
        @AuraEnabled String Name { get;set; }
        @AuraEnabled String Status { get;set; }
        List<XeroContact> Contacts { get;set; }

        /*global XeroContactGroup() {
            Contacts = new List<XeroContact>();
        }*/

        global XeroContactGroup(Map<String, Object> params) {
            Contacts = new List<XeroContact>();
            for (String key : params.keySet()) {
                if (String.isBlank(key) == true && params.get(key) == null) {
                    continue;
                }

                if (key == 'ContactGroupID') {
                    this.ContactGroupID = String.valueOf(params.get(key));
                } else if (key == 'Name') {
                    this.Name = String.valueOf(params.get(key));
                } else if (key == 'Status') {
                    this.Status = String.valueOf(params.get(key));
                } else if (key == 'Contacts') {
                    List<Object> contacts = (List<Object>)params.get(key);
                    for (Object o : contacts) {
                        this.Contacts.add(new XeroWrappers.XeroContact((Map<String,Object>)o));
                    }
                }
            }
        }
    }

    // TERMS
    global class XeroTerms extends XeroObject {
        @AuraEnabled public Integer Day { get;set; }
        @AuraEnabled public XeroPaymentTermType Type { get;set; }

        /*global XeroTerms() {}*/

        global XeroTerms(Map<String, Object> params) {
            if (params.containsKey('Day') && params.get('Day') != null) {
                this.Day = Integer.valueOf(params.get('Day'));
            }
            if (params.containsKey('Type') && params.get('Type') != null) {
                this.Type = (XeroPaymentTermType)getEnumValue('PaymentType', String.valueOf(params.get('Type')));
            }
        }
    }

    // PAYMENT TERMS
    global class XeroPaymentTerms extends XeroObject {
        @AuraEnabled public XeroTerms Bills { get;set; }
        @AuraEnabled public XeroTerms Sales { get;set; }

        global XeroPaymentTerms() {}
        global XeroPaymentTerms(Map<String, Object> params) {
            if (params.containsKey('Bills') && params.get('Bills') != null) {
                this.Bills = new XeroTerms((Map<String,Object>)params.get('Bills'));
            }

            if (params.containsKey('Sales') && params.get('Sales') != null) {
                this.Sales = new XeroTerms((Map<String,Object>)params.get('Sales'));
            }
        }
    }

    // TRACKING OPTION
    global class XeroTrackingOption extends XeroObject {
        @AuraEnabled public String TrackingCategoryID { get;set; }
        @AuraEnabled public String Name { get;set; }
        @AuraEnabled public XeroTrackingStatus Status { get;set; }

        /*global XeroTrackingOption() {}*/
        global XeroTrackingOption(Map<String,Object> params) {
            if (params.containsKey('TrackingCategoryID') == true && params.get('TrackingCategoryID') != null) {
                this.TrackingCategoryID = String.valueOf(params.get('TrackingCategoryID'));
            }
            if (params.containsKey('Name') == true && params.get('Name') != null) {
                this.Name               = String.valueOf(params.get('Name'));
            }
            if (params.containsKey('Status') == true && params.get('Status') != null) {
                this.Status             = (XeroTrackingStatus)getEnumValue('TrackingStatus', String.valueOf(params.get('Status')));
            }
        }
    }

    // TRACKING CATEGORY
    global class XeroTrackingCategory extends XeroObject {
        @AuraEnabled public String Name { get;set; }
        @AuraEnabled public XeroTrackingStatus Status { get;set; }
        @AuraEnabled public List<XeroTrackingOption> Options { get;set; }

        /*global XeroTrackingCategory() {
            Options = new List<XeroTrackingOption>();
        }*/

        global XeroTrackingCategory(Map<String,Object> params) {
            Options = new List<XeroTrackingOption>();

            if (params.containsKey('Name') == true && params.get('Name') != null) {
                this.Name = String.valueOf(params.get('Name'));
            }
            if (params.containsKey('Status') == true && params.get('Status') != null) {
                this.Status = (XeroTrackingStatus)getEnumValue('TrackingStatus', String.valueOf(params.get('Status')));
            }
            if (params.containsKey('Options') == true && params.get('Options') != null) {
                for (Object o :(List<Object>) params.get('Options')) {
                    this.Options.add(new XeroTrackingOption((Map<String,Object>)o));
                }
            }
        }
    }

    // BALANCE
    global class XeroBalance extends XeroObject {
        @AuraEnabled public Decimal outstanding { get;set; }
        @AuraEnabled public Decimal overdue { get;set; }

        global XeroBalance() {}

        global XeroBalance(Map<String,Object> params) {
            if (params.containsKey('Outstanding') == true && params.get('Outstanding') != null) {
                this.outstanding = Decimal.valueOf(String.valueOf(params.get('Outstanding')));
            }
            if (params.containsKey('Overdue') == true && params.get('Overdue') != null) {
                this.overdue = Decimal.valueOf(String.valueOf(params.get('Overdue')));
            }
        }
    }

    // BALANCES
    global class XeroBalances extends XeroObject {
        @AuraEnabled public XeroBalance accountsReceivable { get;set; }
        @AuraEnabled public XeroBalance accountsPayable { get;set; }

        global XeroBalances() {}
        global XeroBalances(Map<String,Object> params) {
            if (params.containsKey('AccountsReceivable') == true && params.get('AccountsReceivable') != null) {
                this.accountsReceivable = new XeroBalance((Map<String,Object>)params.get('AccountsReceivable'));
            }
            if (params.containsKey('AccountsPayable') == true && params.get('AccountsPayable') != null) {
                this.accountsPayable = new XeroBalance((Map<String,Object>)params.get('AccountsPayable'));
            }
        }
    }

    // BRANDING THEME
    global class XeroBrandingTheme extends XeroObject {
        @AuraEnabled public String BrandingThemeID { get;set; }
        @AuraEnabled public String Name { get;set; }
        @AuraEnabled public Integer SortOrder { get;set; }
        @AuraEnabled public Date CreatedDateUTC { get;set; }

        /*global XeroBrandingTheme() {}*/

        global XeroBrandingTheme(Map<String,Object> params) {
            for (String key : params.keySet()) {
                if (String.isBlank(key) == true && params.get(key) == null) {
                    continue;
                }

                if (key == 'BrandingThemeID') {
                    this.BrandingThemeID = String.valueOf(params.get(key));
                } else if (key == 'Name') {
                    this.Name = String.valueOf(params.get(key));
                } else if (key == 'SortOrder') {
                    this.SortOrder = Integer.valueOf(params.get(key));
                }
            }
        }
    }

    // WARNING MESSAGE
    global class XeroMessage {
        @AuraEnabled public String Message { get;set; }

        global XeroMessage(){}
        global XeroMessage(String message){
            this.Message = message;
        }
        global XeroMessage(Map<String,Object> message){
            if (message.containsKey('Message') == true && message.get('Message') != null) {
                this.Message = String.valueOf(message.get('Message'));
            }
        }
    }

    global enum XeroCreditNoteType { ACCPAYCREDIT, ACCRECCREDIT }
    global enum XeroInvoiceType { ACCPAY, ACCREC }
    global enum XeroLineAmount { Exclusive, Inclusive, NoTax }
    global enum XeroCreditNoteStatus { SUBMITTED, AUTHORISED, PAID }
    global enum XeroInvoiceStatus { DRAFT, SUBMITTED, AUTHORISED, PAID }
    global enum XeroContactStatus { ACTIVE, ARCHIVED }
    global enum XeroAddressType { POBOX, STREET, DELIVERY}
    global enum XeroPhoneType { XDEFAULT, DDI, MOBILE, FAX }
    global enum XeroPaymentTermType { DAYSAFTERBILLDATE, DAYSAFTERBILLMONTH, OFCURRENTMONTH, OFFOLLOWINGMONTH }
    global enum XeroPaymentType { ACCRECPAYMENT, ACCPAYPAYMENT, ARCREDITPAYMENT, APCREDITPAYMENT,
        AROVERPAYMENTPAYMENT, ARPREPAYMENTPAYMENT, APPREPAYMENTPAYMENT, APOVERPAYMENTPAYMENT }
    global enum XeroPaymentStatus { AUTHORISED, DELETED }
    global enum XeroTrackingStatus { ACTIVE, ARCHIVE, DELETED}

    public static Object getEnumValue(String type, String value) {
        if (type == 'ContactStatus') {
            for (XeroContactStatus v :XeroContactStatus.values()) {
                if (v.name() == value) {
                    return v;
                }
            }
        } else if (type == 'AddressType') {
            for (XeroAddressType v :XeroAddressType.values()) {
                if (v.name() == value) {
                    return v;
                }
            }
        } else if (type == 'CreditNoteStatus') {
            for (XeroCreditNoteStatus v :XeroCreditNoteStatus.values()) {
                if (v.name() == value) {
                    return v;
                }
            }
        } else if (type == 'PhoneType') {
            for (XeroPhoneType v :XeroPhoneType.values()) {
                if (v.name() == value || (value == 'DEFAULT' && v.name() == 'XDEFAULT')) {
                    return v;
                }
            }
        } else if (type == 'InvoiceType') {
            for (XeroInvoiceType v :XeroInvoiceType.values()) {
                if (v.name() == value) {
                    return v;
                }
            }
        } else if (type == 'LineAmount') {
            for (XeroLineAmount v :XeroLineAmount.values()) {
                if (v.name() == value) {
                    return v;
                }
            }
        } else if (type == 'InvoiceStatus') {
            for (XeroInvoiceStatus v :XeroInvoiceStatus.values()) {
                if (v.name() == value) {
                    return v;
                }
            }
        } else if (type == 'PaymentTermType') {
            for (XeroPaymentTermType v :XeroPaymentTermType.values()) {
                if (v.name() == value) {
                    return v;
                }
            }
        } else if (type == 'TrackingStatus') {
            for (XeroTrackingStatus v :XeroTrackingStatus.values()) {
                if(v.name() == value) {
                    return v;
                }
            }
        } else if (type == 'PaymentType') {
            for (XeroPaymentType v :XeroPaymentType.values()) {
                if (v.name() == value) {
                    return v;
                }
            }
        }
        return null;
    }

    public static Date convertToDate(String dtString) {
        if (String.isBlank(dtString) == true) {
            return null;
        }

        List<String> listOfDates = dtString.split('\\+');
        Long timestampDt = Long.valueOf(listOfDates[0]);
        Datetime dt = Datetime.newInstance(timestampDt);

        if (listOfDates.size() > 1) {
            Integer seconds = Integer.valueOf(listOfDates[1].replace(')',''));
            dt.addSeconds(seconds);
        }

        Date result = Date.newInstance(dt.year(), dt.month(), dt.day());
        return result;
    }

    global virtual class XeroResponse {
        @AuraEnabled public String id { get;set; }
        @AuraEnabled public String status { get;set; }
        @AuraEnabled public String providerName { get;set; }
        @AuraEnabled public String dateTimeUTC { get;set; }
        @AuraEnabled public String jsonResponse { get;set; }
        @AuraEnabled public List<XeroObject> xeroObjects {get;set;}
        @AuraEnabled public Integer statusCode { get;set; }

        global XeroResponse() {
            xeroObjects = new List<XeroObject>();
        }

        global XeroResponse(String jsonRes) {
            Map<String,Object> response = (Map<String,Object>)JSON.deserializeUntyped(jsonRes);
            this.id = String.valueOf(response.get('Id'));
            this.status = String.valueOf(response.get('Status'));
            this.dateTimeUTC = String.valueOf(response.get('DateTimeUTC'));
            this.providerName = String.valueOf(response.get('ProviderName'));
            this.jsonResponse = jsonRes;
            this.statusCode = 200;
        }

        global XeroResponse(String status, Integer code) {
            this.statusCode = code;
            this.status = status;
        }

        global XeroResponse(String status, Integer code, String jsonRes) {
            this.statusCode = code;
            this.status = status;
            this.jsonResponse = jsonRes;
        }
    }

    global class XeroCreditNoteResponse extends XeroResponse {
        public List<XeroCreditNote> xeroCreditNotes;

        global XeroCreditNoteResponse(String jsonRes) {
            super(jsonRes);

            Map<String,Object> response = (Map<String,Object>)JSON.deserializeUntyped(jsonRes);
            List<Object> obj = (List<Object>) response.get('CreditNotes');
            xeroCreditNotes = new List<XeroCreditNote>();

            for (Object o :obj) {
                xeroCreditNotes.add(new XeroWrappers.XeroCreditNote((Map<String,Object>)o));
            }
        }

        global XeroCreditNoteResponse(String status, Integer code) {
            super(status,code);
        }

        global XeroCreditNoteResponse(String status, Integer code, String jsonRes) {
            super(status,code, jsonRes);
        }
    }

    /*global class XeroCreditNoteAllocationResponse extends XeroResponse {
        public List<XeroCreditNoteAllocation> xeroCreditNoteAllocations;

        global XeroCreditNoteAllocationResponse(String jsonRes) {
            super(jsonRes);

            Map<String,Object> response = (Map<String,Object>)JSON.deserializeUntyped(jsonRes);
            List<Object> obj = (List<Object>) response.get('Allocations');
            xeroCreditNoteAllocations = new List<XeroCreditNoteAllocation>();

            for (Object o : obj) {
                xeroCreditNoteAllocations.add(new XeroWrappers.XeroCreditNoteAllocation((Map<String,Object>)o));
            }
        }

        global XeroCreditNoteAllocationResponse(String status, Integer code) {
            super(status,code);
        }

        global XeroCreditNoteAllocationResponse(String status, Integer code, String jsonRes) {
            super(status,code, jsonRes);

            Map<String,Object> params = (Map<String,Object>)JSON.deserializeUntyped(jsonRes);
        }
    }*/

    global class XeroInvoiceResponse extends XeroResponse {
        public List<XeroInvoice> Elements;
        global XeroInvoiceResponse(String jsonRes) {
            super(jsonRes);

            Map<String,Object> response = (Map<String,Object>)JSON.deserializeUntyped(jsonRes);
            List<Object> obj = (List<Object>) response.get('Invoices');
            xeroObjects = new List<XeroWrappers.XeroInvoice>();

            for (Object o :obj) {
                xeroObjects.add(new XeroWrappers.XeroInvoice((Map<String,Object>)o));
            }
        }

        global XeroInvoiceResponse(String status, Integer code) {
            super(status,code);
        }

        global XeroInvoiceResponse(String status, Integer code, String jsonRes) {
            super(status,code, jsonRes);

            Map<String,Object> params = (Map<String,Object>)JSON.deserializeUntyped(jsonRes);
            this.Elements = new List<XeroInvoice>();
        }
    }

    global class XeroContactResponse extends XeroResponse {
        /*global XeroContactResponse() {
            super();
        }*/

        global XeroContactResponse(String jsonRes) {
            super(jsonRes);

            Map<String,Object> response = (Map<String,Object>)JSON.deserializeUntyped(jsonRes);
            List<Object> obj = (List<Object>) response.get('Contacts');
            xeroObjects = new List<XeroWrappers.XeroContact>();

            for (Object o :obj) {
                xeroObjects.add(new XeroWrappers.XeroContact((Map<String,Object>)o));
            }
        }

        global XeroContactResponse(String status, Integer code) {
            super(status,code);
        }
    }

    global class XeroBrandingResponse extends XeroResponse {
        /*global XeroBrandingResponse() {
            super();
        }*/

        global XeroBrandingResponse(String jsonRes) {
            super(jsonRes);

            Map<String,Object> response = (Map<String,Object>)JSON.deserializeUntyped(jsonRes);
            List<Object> obj = (List<Object>) response.get('BrandingThemes');
            xeroObjects = new List<XeroWrappers.XeroBrandingTheme>();

            for (Object o :obj) {
                xeroObjects.add(new XeroWrappers.XeroBrandingTheme((Map<String,Object>)o));
            }
        }

        global XeroBrandingResponse(String status, Integer code) {
            super(status,code);
        }
    }
}