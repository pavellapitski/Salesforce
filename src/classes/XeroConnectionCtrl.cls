public with sharing class XeroConnectionCtrl {
    public String accountId { get;set; }
    public String selectedXeroContact {get; set;}
    public Account selectedAccount { get;set; }
    public Project__c selectedContract { get;set; }
    public String xeroId { get;set; }
    public String contractId { get;set; }
    public String xeroContactName { get; set; }
    public String xeroContactEmail { get; set; }

    public XeroWrappers.XeroContact selectedContact { get;set; }

    public Boolean createNewXeroContact {get; set;}
    public Boolean displayXeroEntities { get;set; }
    public Boolean displayXeroContacts { get;set; }
    public Boolean displayContactInfo { get;set; }
    public Boolean processIntegration { get;set; }
    public Boolean processNewInvoices { get;set; }
    public Boolean allowProcessingInvoices { get;set; }

    private Map<Id,XeroSettings__c> idToXeroSettingsMap = new Map<Id,XeroSettings__c>();
    private Map<String,XeroWrappers.XeroContact> idToXeroContactMap = new Map<String,XeroWrappers.XeroContact>();
    private String returnUrl { get;set; }

    public XeroConnectionCtrl() {
        createNewXeroContact = false;
        xeroContactName = '';
        xeroContactEmail = '';
        String currencyCode = '', region = '';

        Map<String,String> params = ApexPages.currentPage().getParameters();
        if (params.containsKey('contractId') == true && String.isBlank(params.get('contractId')) == false) {
            contractId = params.get('contractId');
            selectedContract = [
                SELECT Account__c, CurrencyIsoCode, Account__r.Region__c,
                    Name, Xero_Entity__c, Xero_ID__c, Account__r.Billing_Email__c, Account__r.Name,
                    Account__r.BillingStreet, Account__r.BillingCity, Account__r.BillingCountry,
                    Account__r.BillingPostalCode, Account__r.BillingState, Account__r.Phone, Account__r.Fax
                FROM Project__c
                WHERE Id = :contractId
            ];

            if (String.isNotBlank(selectedContract.Xero_Entity__c)) {
                xeroId = selectedContract.Xero_Entity__c;
            }
            xeroContactName = selectedContract.Account__r.Name;
            currencyCode = selectedContract.CurrencyIsoCode;
            //region = selectedContract.Account__r.Region__c;

            if (String.isNotBlank(selectedContract.Account__r.Billing_Email__c)) {
                xeroContactEmail = selectedContract.Account__r.Billing_Email__c;
            }
        } else if (params.containsKey('accountId') && String.isNotBlank(params.get('accountId'))) {
            accountId = params.get('accountId');

            getAccount();

            if (String.isNotBlank(selectedAccount.Xero_Entity__c)) {
                xeroId = selectedAccount.Xero_Entity__c;
            }
            xeroContactName = selectedAccount.Name;
            region = selectedAccount.Region__c;

            if (String.isNotBlank(selectedAccount.Billing_Email__c)) {
                xeroContactEmail = selectedAccount.Billing_Email__c;
            }
        }

        if (params.containsKey('retUrl')) {
            returnUrl = params.get('retUrl');
        }

        if (params.containsKey('inv') == true && params.get('inv') == 'true') {
            allowProcessingInvoices = true;
        } else {
            allowProcessingInvoices = false;
        }
        displayXeroEntities = false;
        selectedContact = null;

        String query = ' SELECT Id, Name, ConsumerKey__c, consumerSecret__c, PrivateKey__c, Currency__c FROM XeroSettings__c ';
        if (String.isNotBlank(currencyCode)) {
            query += ' WHERE Currency__c INCLUDES (\'' + currencyCode + '\')'; // OR Currency__c = \'\')
        }
        if (String.isNotBlank(region)) {
            if (query.contains(' WHERE ')) {
                query += ' AND ';
            } else {
                query += ' WHERE ';
            }
            query += ' (Region__c INCLUDES (\'' + region + '\') OR Region__c = \'\')';
        }
        idToXeroSettingsMap = new Map<Id,XeroSettings__c>((List<XeroSettings__c>) Database.query(query));
    }

    public PageReference connectWithXero() {
        displayXeroEntities = true;
        processIntegration  = true;
        displayContactInfo  = false;

        if (String.isBlank(xeroId) == true ) {
            displayXeroContacts = false;
        } else {
            displayXeroContacts = true;
            getContacts();
        }

        return null;
    }

    public void disconnect() {
        try {
            if (selectedAccount != null) {
                selectedAccount.Xero_Id__c = null;
                selectedAccount.XeroObject__c = null;
                selectedAccount.Xero_Entity__c = null;
                update selectedAccount;
            }

            if (selectedContract != null) {
                selectedContract.Xero_ID__c = null;
                selectedContract.XeroObject__c = null;
                selectedContract.Xero_Entity__c = null;

                update selectedContract;
            }
        } catch (DmlException ex) {
            ApexPages.addMessage(new ApexPages.Message(Apexpages.Severity.ERROR, ex.getDmlMessage(0)));
        }
    }

    public void createNewXeroContactChanged() {}

    public PageReference getAccount() {
        if (String.isNotBlank(accountId)) {
            selectedAccount = [
                SELECT AnnualRevenue, Billing_Contact__c, Billing_Email__c, BillingStreet, BillingCity,
                    BillingState, BillingCountry, BillingPostalCode, CurrencyIsoCode, JigsawCompanyId,
                    Description, Fax, Id, Industry, Is_Customer__c, Is_Supplier__c, IsDeleted, SystemModstamp,
                    MasterRecordId, Name, NumberOfEmployees, OwnerId, ParentId, Phone, PhotoUrl, Region__c,
                    Type, Website, Xero_Id__c, Xero_Entity__c
                FROM Account
                WHERE Id = :accountId];
        }
        return null;
    }

    public PageReference getContacts() {
        if (String.isBlank(xeroId)) {
            return null;
        }
        if (!Test.isRunningTest() || XeroSync.performSync) {
            XeroSync.syncXeroObjects(idToXeroSettingsMap.get(xeroId), XeroSync.XERO_TYPE_CONTACT);
        }
        selectedContact = null;

        if (processIntegration == true) {
            displayXeroContacts = true;
            displayContactInfo = false;
        }
        return null;
    }

    public PageReference createXeroAccount() {
        XeroWrappers.XeroContact xc = new XeroWrappers.XeroContact();
        xc.EmailAddress              = xeroContactEmail;
        xc.Name                      = xeroContactName;
        xc.ContactStatus             = XeroWrappers.XeroContactStatus.ACTIVE;

        if (selectedContract != null) {
            xc.DefaultCurrency           = selectedContract.CurrencyIsoCode;

            XeroWrappers.XeroAddress xa  = new XeroWrappers.XeroAddress();
            xa.AddressLine1              = selectedContract.Account__r.BillingStreet;
            xa.City                      = selectedContract.Account__r.BillingCity;
            xa.Country                   = selectedContract.Account__r.BillingCountry;
            xa.PostalCode                = selectedContract.Account__r.BillingPostalCode;
            xa.Region                    = selectedContract.Account__r.BillingState;
            xc.Addresses = new List<XeroWrappers.XeroAddress>{xa};

            List<XeroWrappers.XeroPhone> xpl = new List<XeroWrappers.XeroPhone>();
            if (selectedContract.Account__r.Phone != null) {
                XeroWrappers.XeroPhone xpd = new XeroWrappers.XeroPhone();
                xpd.PhoneType              = XeroWrappers.XeroPhoneType.XDEFAULT;
                xpd.PhoneNumber            = selectedContract.Account__r.Phone;
                xpl.add(xpd);
            }

            if (selectedContract.Account__r.Fax != null) {
                XeroWrappers.XeroPhone xpf = new XeroWrappers.XeroPhone();
                xpf.PhoneType              = XeroWrappers.XeroPhoneType.FAX;
                xpf.PhoneNumber            = selectedContract.Account__r.Fax;
                xpl.add(xpf);
            }
            xc.Phones = xpl;

            XeroWrappers.XeroContactResponse xcr = XeroAPI.postContact(xc, idToXeroSettingsMap.get(xeroId));
            System.debug('### xcr: ' + xcr);
            if (xcr.StatusCode == 200 || xcr.StatusCode == 201) {
                selectedContract.Xero_ID__c = ((XeroWrappers.XeroContact)xcr.xeroObjects[0]).ContactID;
                if (String.isBlank(selectedContract.Xero_Entity__c) == true || selectedContract.Xero_Entity__c != xeroId) {
                    selectedContract.Xero_Entity__c = xeroId;
                }

                Savepoint sp = Database.setSavepoint();
                try {
                    update selectedContract;

                    Account acc = new Account(Id = selectedContract.Account__c);
                    acc.Xero_Id__c = selectedContract.Xero_ID__c;
                    acc.Xero_Entity__c = selectedContract.Xero_Entity__c;
                    update acc;
                } catch (Exception ex) {
                    Database.rollback(sp);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
                }
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Contact has been successfully created in Xero'));
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Contact could not be created in Xero. Reason: ' + xcr.Status));
            }
        } else if (selectedAccount != null) {
            xc.DefaultCurrency           = selectedAccount.CurrencyIsoCode;

            XeroWrappers.XeroAddress xa  = new XeroWrappers.XeroAddress();
            xa.AddressLine1              = selectedAccount.BillingStreet;
            xa.City                      = selectedAccount.BillingCity;
            xa.Country                   = selectedAccount.BillingCountry;
            xa.PostalCode                = selectedAccount.BillingPostalCode;
            xa.Region                    = selectedAccount.BillingState;
            xc.Addresses = new List<XeroWrappers.XeroAddress>{xa};

            List<XeroWrappers.XeroPhone> xpl = new List<XeroWrappers.XeroPhone>();

            if (selectedAccount.Phone != null) {
                XeroWrappers.XeroPhone xpd = new XeroWrappers.XeroPhone();
                xpd.PhoneType              = XeroWrappers.XeroPhoneType.XDEFAULT;
                xpd.PhoneNumber            = selectedAccount.Phone;
                xpl.add(xpd);
            }

            if (selectedAccount.Fax != null) {
                XeroWrappers.XeroPhone xpf = new XeroWrappers.XeroPhone();
                xpf.PhoneType              = XeroWrappers.XeroPhoneType.FAX;
                xpf.PhoneNumber            = selectedAccount.Fax;
                xpl.add(xpf);
            }
            xc.Phones = xpl;

            XeroWrappers.XeroContactResponse xcr = XeroAPI.postContact(xc, idToXeroSettingsMap.get(xeroId));
            if (xcr.StatusCode == 200 || xcr.StatusCode == 201) {
                XeroWrappers.XeroContact contactResponse = (XeroWrappers.XeroContact)xcr.xeroObjects[0];

                if (contactResponse.HasErrors) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, String.join(contactResponse.ValidationErrors, ' ')));
                } else {
                    selectedAccount.Xero_Id__c = contactResponse.ContactID;

                    if (String.isBlank(selectedAccount.Xero_Entity__c) == true || selectedAccount.Xero_Entity__c != xeroId) {
                        selectedAccount.Xero_Entity__c = xeroId;
                    }
                    try {
                        update selectedAccount;
                    } catch (DmlException e) {
                        ApexPages.addMessages(e);
                    }
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Contact has been successfully created in Xero'));
                }
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Contact could not be created in Xero. Reason: ' + xcr.Status));
            }
        }
        return null;
    }

    public List<SelectOption> getXeroEntities() {
        List<SelectOption> entities = new List<SelectOption>();
        entities.add(new SelectOption('', '-- None --'));

        for(Id id : idToXeroSettingsMap.keySet()) {
            entities.add(new SelectOption(id, idToXeroSettingsMap.get(id).Name));
        }
        return entities;
    }

    public List<SelectOption> getContractList() {
        List<SelectOption> result = new List<SelectOption>{new SelectOption('', '-- None --')};
        for (Project__c p :[SELECT Account__c, Id, Name FROM Project__c WHERE Account__c =: accountId]) {
            result.add(new SelectOption(p.Id, p.Name));
        }
        return result;
    }

    public PageReference selectXeroContact() {
        XeroWrappers.XeroContactResponse contactResponse = XeroAPI.getContact(idToXeroSettingsMap.get(xeroId), selectedXeroContact);
        System.debug('### contactResponse: ' + contactResponse);
        if (contactResponse.Status == 'Not Found' && contactResponse.xeroObjects == null) {
            selectedXeroContact = null;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, contactResponse.StatusCode + ': ' + contactResponse.Status));
        } else {
            for (XeroWrappers.XeroObject obj :contactResponse.xeroObjects) {
                selectedContact = (XeroWrappers.XeroContact) obj;
                idToXeroContactMap.put(selectedContact.ContactID, selectedContact);
            }
            displayContactInfo = true;
        }
        return null;
    }

    public PageReference displayRelatedContact() {
        displayContactInfo = true;
        processIntegration  = false;
        displayXeroContacts = false;

        String relatedContactId;
        if (selectedAccount != null && String.isBlank(selectedAccount.Xero_Id__c) == false && String.isBlank(selectedAccount.Xero_Entity__c) == false) {
            relatedContactId = selectedAccount.Xero_Id__c;
            xeroId = selectedAccount.Xero_Entity__c;
        } else if (selectedContract != null && String.isBlank(selectedContract.Xero_ID__c) == false && String.isBlank(selectedContract.Xero_Entity__c) == false) {
            relatedContactId = selectedContract.Xero_ID__c;
            xeroId = selectedContract.Xero_Entity__c;
        }
        if (String.isBlank(xeroId) == false && String.isBlank(relatedContactId) == false) {
            XeroWrappers.XeroContactResponse xcr = XeroAPI.getContact(idToXeroSettingsMap.get(xeroId), relatedContactId);

            if (xcr.StatusCode == 200 && xcr.xeroObjects.size() > 0) {
               selectedContact = (XeroWrappers.XeroContact) xcr.xeroObjects[0];
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Could not find the contact in Xero'));
            }
        }
        return null;
    }

    public PageReference connectWithXeroContact() {
        if ((String.isBlank(accountId) == true && String.isBlank(contractId)) || selectedContact == null) {
            return null;
        }

        if (selectedAccount == null && selectedContact != null) {
            selectedContract.Xero_ID__c = selectedContact.ContactID;
            selectedContract.Xero_Entity__c = xeroId;
            try {
                update selectedContract;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Contract successfully connected with Xero Contact'));
            } catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Contract could not be connected with chosen Xero Contact. Reason: ' + e.getMessage()));
            }
        } else if (selectedAccount != null) {
            selectedAccount.Xero_Id__c = selectedContact.ContactID;
            selectedAccount.Xero_Entity__c = xeroId;
            try {
                update selectedAccount;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Account successfully connected with Xero Contact'));
            } catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Account could not be connected with chosen Xero Contact. Reason: ' + e.getMessage()));
            }
        }
        return null;
    }

    public PageReference redirectBack() {
        if (String.isBlank(returnUrl) == false) {
            return new PageReference('/apex/' + returnUrl);
        } else if (!String.isBlank(contractId)) {
            return new PageReference('/' + contractId);
        } else if (!String.isBlank(accountId)) {
            return new PageReference('/' + accountId);
        }
        return null;
    }


    // XeroConnection.cmp related part
    public static final String KEY_ACCOUNT = Schema.Account.SObjectType.getDescribe().getKeyPrefix();
    public static final String KEY_INVOICE = Schema.Invoice__c.SObjectType.getDescribe().getKeyPrefix();

    @AuraEnabled
    public static Contract fetchContract(String recordId) {
        SObject baseRecord = getRecordById(recordId);
        Contract contractRecord = new Contract(baseRecord);
        return contractRecord;
    }

    private static SObject getRecordById(String recId) {
        String idPrefix = recId.left(3);
        SObject record;
        if (KEY_ACCOUNT == idPrefix) {
            record = [SELECT Id, Xero_Id__c, Xero_Entity__c, Name, Region__c, CurrencyIsoCode FROM Account WHERE Id = :recId];
        } else if (KEY_INVOICE == idPrefix) {
            record = [SELECT Id, Name, Xero_Id__c, Xero_Entity__c, Region__c, CurrencyIsoCode FROM Invoice__c WHERE Id = :recId];
        } else {
            // TODO: APPLY TO OTHER OBJECTS
        }
        return record;
    }

    @TestVisible private class Contract {
        @TestVisible @AuraEnabled String xeroId { get; set; }
        @TestVisible @AuraEnabled String xeroEntityId { get; set; }
        @TestVisible @AuraEnabled String recordId { get; set; }
        @TestVisible @AuraEnabled String contractName { get; set; }
        @TestVisible @AuraEnabled String currencyIsoCode { get; set; }
        @TestVisible @AuraEnabled List<XeroEntity> xeroEntities { get {
            if (xeroEntities == null) {
                xeroEntities = new List<XeroEntity>();
            }
            return xeroEntities;
        } set; }
        @TestVisible String region { get; set; }

        public Contract(SObject record) {
            this.recordId = record.Id;
            try {
                setRegion(record);
                setXeroId(record);
                setXeroEntityId(record);
                setContractName(record);
                setCurrency(record);

                fetchXeroEntities();
            } catch (Exception ex) {
                throw new AuraHandledException('An error has occurred: ' + ex.getMessage());
            }
        }

        private void setCurrency(SObject record) {
            this.currencyIsoCode = (String) record.get('CurrencyIsoCode');
        }

        private void setRegion(SObject record) {
            String idPrefix = String.valueOf(record.Id).left(3);
            if (KEY_ACCOUNT == idPrefix) {
                this.region = (String) record.get(Account.Region__c.getDescribe().getName());
            } else if (KEY_INVOICE == idPrefix) {
                this.region = (String) record.get(Invoice__c.Region__c.getDescribe().getName());
            } else {
                // TODO: APPLY TO OTHER OBJECTS
            }
        }

        private void setXeroEntityId(SObject record) {
            String idPrefix = String.valueOf(record.Id).left(3);
            if (KEY_ACCOUNT == idPrefix) {
                this.xeroEntityId = (String) record.get(Account.Xero_Entity__c.getDescribe().getName());
            } else if (KEY_INVOICE == idPrefix) {
                this.xeroEntityId = (String) record.get(Invoice__c.Xero_Entity__c.getDescribe().getName());
            } else {
                // APPLY TO OTHER OBJECTS
            }
        }

        private void setContractName(SObject record) {
            String idPrefix = String.valueOf(record.Id).left(3);
            if (KEY_ACCOUNT == idPrefix) {
                this.contractName = (String) record.get(Account.Name.getDescribe().getName());
            } else if (KEY_INVOICE == idPrefix) {
                this.contractName = 'Do we need any name here?'; // TODO: what contract name should be
            } else {
                // APPLY TO OTHER OBJECTS
            }
        }

        private void setXeroId(SObject record) {
            String idPrefix = String.valueOf(record.Id).left(3);
            if (KEY_ACCOUNT == idPrefix) {
                this.xeroId = (String) record.get(Account.Xero_Id__c.getDescribe().getName());
            } else if (KEY_INVOICE == idPrefix) {
                this.xeroId = (String) record.get(Invoice__c.Xero_Id__c.getDescribe().getName());
            } else {
                // APPLY TO OTHER OBJECTS
            }
        }

        private void fetchXeroEntities() {
            String query = ' SELECT Id, Name, ConsumerKey__c, ConsumerSecret__c, PrivateKey__c, Currency__c FROM XeroSettings__c ';
            query += ' WHERE Region__c INCLUDES (\'' + region + '\')';
            if (String.isNotBlank(currencyIsoCode)) {
                query += ' AND (Currency__c INCLUDES (\'' + currencyIsoCode + '\') OR Currency__c = \'\')';
            }

            List<XeroSettings__c> xeroSettings = (List<XeroSettings__c>) Database.query(query);
            xeroEntities.add(new XeroEntity('', '-- None --'));
            for (XeroSettings__c xs :xeroSettings) {
                xeroEntities.add(new XeroEntity(xs.Id, xs.Name));
            }
        }

        public void unlinkXeroContact() {
            String idPrefix = String.valueOf(recordId).left(3);
            if (KEY_ACCOUNT == idPrefix) {
                Account acc = new Account(Id = recordId);
                acc.Xero_Entity__c = null;
                acc.Xero_Id__c = null;
                update acc;
            } else if (KEY_INVOICE == idPrefix) {
                Invoice__c inv = new Invoice__c(Id = recordId);
                inv.Xero_Entity__c = null;
                inv.Xero_Id__c = null;
                update inv;
            } else {
                // APPLY TO OTHER OBJECTS
            }
        }

        public void linkXeroContact(String xeroContactId, String xeroSettingId) {
            String idPrefix = String.valueOf(recordId).left(3);
            if (KEY_ACCOUNT == idPrefix) {
                Account acc = new Account(Id = recordId);
                acc.Xero_Entity__c = xeroSettingId;
                acc.Xero_Id__c = xeroContactId;
                update acc;
            } else if (KEY_INVOICE == idPrefix) {
                Invoice__c inv = new Invoice__c(Id = recordId);
                inv.Xero_Entity__c = xeroSettingId;
                inv.Xero_Id__c = xeroContactId;
                update inv;
            } else {
                // APPLY TO OTHER OBJECTS
            }
        }
    }

    @TestVisible private class XeroEntity {
        @TestVisible @AuraEnabled String xeroEntityId { get; set; }
        @TestVisible @AuraEnabled String xeroEntityName { get; set; }

        public XeroEntity(String xeroEntityId, String xeroEntityName) {
            this.xeroEntityId = xeroEntityId;
            this.xeroEntityName = xeroEntityName;
        }
    }

    @AuraEnabled
    public static void actualiseXeroContact(String xeroEntityId) {
        XeroSettings__c xs = [SELECT Id, Name, ConsumerKey__c, ConsumerSecret__c, PrivateKey__c FROM XeroSettings__c WHERE Id = :xeroEntityId];
        XeroSync.syncXeroObjects(xs, XeroSync.XERO_TYPE_CONTACT);
    }

    @AuraEnabled
    public static XeroWrappers.XeroContact getXeroContactInfo(String xeroSettingId, String xeroId) {
        XeroSettings__c xs = [SELECT Id, Name, ConsumerKey__c, ConsumerSecret__c, PrivateKey__c FROM XeroSettings__c WHERE Id = :xeroSettingId];
        XeroWrappers.XeroContactResponse contactResponse = XeroAPI.getContact(xs, xeroId);
        XeroWrappers.XeroContact selectedContact;
        if (contactResponse.xeroObjects != null && contactResponse.xeroObjects.size() > 0) {
            selectedContact = (XeroWrappers.XeroContact) contactResponse.xeroObjects[0];
        } else {
            throw new AuraHandledException(contactResponse.StatusCode + ': ' + contactResponse.Status);
        }
        return selectedContact;
    }

    @SuppressWarnings('ApexUnresolvableSignature')
    @AuraEnabled
    public static AuraResponse establishXeroConnection(String contractJSON, String xeroContactId, String xeroSettingId) {
        XeroConnectionCtrl.Contract contract = (XeroConnectionCtrl.Contract) JSON.deserialize(contractJSON, XeroConnectionCtrl.Contract.class);
        AuraResponse auResp = new AuraResponse();
        try {
            contract.linkXeroContact(xeroContactId, xeroSettingId);
        } catch (Exception ex) {
            auResp.errorMsg = ex.getMessage();
        }
        return (AuraResponse) auResp;
    }

    @AuraEnabled
    public static AuraResponse unlinkXeroConnection(String contractJSON) {
        XeroConnectionCtrl.Contract contract = (XeroConnectionCtrl.Contract) JSON.deserialize(contractJSON, XeroConnectionCtrl.Contract.class);
        AuraResponse auResp = new AuraResponse();
        try {
            contract.unlinkXeroContact();
        } catch (Exception ex) {
            auResp.errorMsg = ex.getMessage();
        }
        return (AuraResponse) auResp;
    }

    @AuraEnabled
    public static AuraResponse createXeroRecord(String newName, String newEmail, String contractJSON) {
        XeroConnectionCtrl.Contract contract = (XeroConnectionCtrl.Contract) JSON.deserialize(contractJSON, XeroConnectionCtrl.Contract.class);
        String idPrefix = String.valueOf(contract.recordId).left(3);

        AuraResponse auResp = new AuraResponse();

        XeroWrappers.XeroContact newXeroContact = new XeroWrappers.XeroContact();
        newXeroContact.emailAddress = newEmail;
        newXeroContact.name = newName;
        newXeroContact.contactStatus = XeroWrappers.XeroContactStatus.ACTIVE;
        newXeroContact.defaultCurrency = contract.currencyIsoCode;
        newXeroContact.addresses = new List<XeroWrappers.XeroAddress>();
        newXeroContact.phones = new List<XeroWrappers.XeroPhone>();

        XeroSettings__c xeroSettings = [SELECT Id, ConsumerKey__c, PrivateKey__c, ConsumerSecret__c FROM XeroSettings__c WHERE Id = :contract.xeroEntityId];

        if (KEY_ACCOUNT == idPrefix) {
            Account acc = [
                SELECT CurrencyIsoCode, BillingStreet, BillingCity, BillingCountry, BillingPostalCode, BillingState,
                        Phone, Fax, Xero_Id__c, Xero_Entity__c
                FROM Account
                WHERE Id = :contract.recordId
            ];

            newXeroContact.defaultCurrency = acc.CurrencyIsoCode;

            XeroWrappers.XeroAddress newXeroContactAddress = new XeroWrappers.XeroAddress();
            newXeroContactAddress.AddressLine1 = acc.BillingStreet;
            newXeroContactAddress.City = acc.BillingCity;
            newXeroContactAddress.Country = acc.BillingCountry;
            newXeroContactAddress.PostalCode = acc.BillingPostalCode;
            newXeroContactAddress.Region = acc.BillingState;

            newXeroContact.addresses.add(newXeroContactAddress);

            if (String.isNotBlank(acc.Phone)) {
                XeroWrappers.XeroPhone newXeroContactPhone = new XeroWrappers.XeroPhone();
                newXeroContactPhone.phoneType = XeroWrappers.XeroPhoneType.XDEFAULT;
                newXeroContactPhone.phoneNumber = acc.Phone;
                newXeroContact.phones.add(newXeroContactPhone);
            }
            if (String.isNotBlank(acc.Fax)) {
                XeroWrappers.XeroPhone newXeroContactFax = new XeroWrappers.XeroPhone();
                newXeroContactFax.phoneType = XeroWrappers.XeroPhoneType.FAX;
                newXeroContactFax.phoneNumber = acc.Fax;
                newXeroContact.phones.add(newXeroContactFax);
            }

            XeroWrappers.XeroContactResponse xeroResponse = XeroAPI.postContact(newXeroContact, xeroSettings);
            if (xeroResponse.statusCode == 200 || xeroResponse.statusCode == 201) {
                XeroWrappers.XeroContact contactResponse = (XeroWrappers.XeroContact) xeroResponse.xeroObjects[0];

                if (contactResponse.hasErrors) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, String.join(contactResponse.validationErrors, ' ')));
                } else {
                    acc.Xero_Id__c = contactResponse.contactID;
                    if (String.isBlank(acc.Xero_Entity__c) == true || acc.Xero_Entity__c != contract.xeroEntityId) {
                        acc.Xero_Entity__c = contract.xeroEntityId;
                    }
                    Savepoint sp = Database.setSavepoint();
                    try {
                        update acc;
                    } catch (DmlException ex) {
                        Database.rollback(sp);
                        auResp.errorMsg = ex.getMessage();
                    }
                }
            } else {
                auResp.errorMsg = 'Contact could not be created in Xero. Reason: ' + xeroResponse.status;
            }
        } else if (KEY_INVOICE == idPrefix) {
            XeroWrappers.XeroContactResponse xeroResponse = XeroAPI.postContact(newXeroContact, xeroSettings);
            if (xeroResponse.statusCode == 200 || xeroResponse.statusCode == 201) {
                XeroWrappers.XeroContact contactResponse = (XeroWrappers.XeroContact) xeroResponse.xeroObjects[0];

                if (contactResponse.hasErrors) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, String.join(contactResponse.validationErrors, ' ')));
                } else {
                    Invoice__c invoice = [SELECT Xero_Id__c, Xero_Entity__c FROM Invoice__c WHERE Id = :contract.recordId];
                    invoice.Xero_Id__c = contactResponse.contactID;
                    if (String.isBlank(invoice.Xero_Entity__c) == true || invoice.Xero_Entity__c != contract.xeroEntityId) {
                        invoice.Xero_Entity__c = contract.xeroEntityId;
                    }
                    Savepoint sp = Database.setSavepoint();
                    try {
                        update invoice;
                    } catch (DmlException ex) {
                        Database.rollback(sp);
                        auResp.errorMsg = ex.getMessage();
                    }
                }
            } else {
                auResp.errorMsg = 'Contact could not be created in Xero. Reason: ' + xeroResponse.status;
            }
        } else {
            auResp.errorMsg = '"createXeroRecord" method doesn\'t support processing the following idPrefix: ' + idPrefix;
        }
        return auResp;
    }

    public class AuraResponse {
        @AuraEnabled public String errorMsg { get; set; }
        @AuraEnabled public Boolean isSuccess { get {
            return String.isBlank(errorMsg);
        }}
    }
}