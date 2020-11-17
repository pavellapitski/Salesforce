public without sharing class Utility {

    public enum BILLING_PROFILES {Strike, Client}


    public static final String TRIGGER_ON = 'ON';
    public static final String EMPTY_PLATFORM_ACCOUNT_EXCEPTION = 'Platform Account is empty on {0} platforms.';

    private static Boolean isSandbox = null;

    public static List<SelectOption> sortSelectOptionsByLabel(List<SelectOption> sortingList) {
        for (Integer i = 0; i < sortingList.size(); i++) {
            for (Integer j = i; j > 0; j--) {
                if (sortingList[j - 1].getLabel() > sortingList[j].getLabel() && sortingList[j - 1].getLabel() != '--None--') {
                    SelectOption tempOption = sortingList[j];
                    sortingList[j] = sortingList[j - 1];
                    sortingList[j - 1] = tempOption;
                }
            }
        }
        return sortingList;
    }

    public static Sub_Project__c copyContractDataToPayment(String contractId) {
        return copyContractDataToPayment([
            SELECT Id, CurrencyIsoCode, Account__c, Account_Type__c, Client_Spend__c, End_Date__c, Margin__c, Margin_Type__c, Opportunity__c, Payment_Type__c, Start_Date__c, Total_Revenue__c
            FROM Project__c
            WHERE Id = :contractId
            LIMIT 1
        ]);
    }

    public static Sub_Project__c copyContractDataToPayment(Project__c contract) {
        Sub_Project__c payment = new Sub_Project__c(Project__c = contract.Id);
        payment.Account__c = contract.Account__c;
        payment.Account_Type__c = contract.Account_Type__c;
        payment.Margin__c = contract.Margin__c;
        payment.Margin_Type__c = contract.Margin_Type__c;
        payment.Opportunity__c = contract.Opportunity__c;
        payment.CurrencyIsoCode = contract.CurrencyIsoCode;
        return payment;
    }

    public static Payment__c copyContractDataToProject(Project__c contract) {
        Payment__c payment  = new Payment__c(Project__c = contract.Id);
        if (payment.Account__c == null) payment.Account__c = contract.Account__c;
        if (payment.Margin__c == null) payment.Margin__c = contract.Margin__c;
        if (payment.Margin_Type__c == null) payment.Margin_Type__c = contract.Margin_Type__c;
        if (payment.Opportunity__c == null) payment.Opportunity__c = contract.Opportunity__c;
        if (payment.CurrencyIsoCode == null) payment.CurrencyIsoCode = contract.CurrencyIsoCode;
        return payment;
    }

    public static List<Payment__c> copyPaymentDataToProject(Sub_Project__c payment,  Map<Id, List<OpportunityPlatform__c>> contractPlatforms) {
        List<Payment__c> payments = new List<Payment__c>();
        if (contractPlatforms.containsKey(payment.Project__c)) {
            Integer index = 1, numberOfProjects = 0;
            Decimal total = 0;

            for (OpportunityPlatform__c contractPlatform :contractPlatforms.get(payment.Project__c)) {
                numberOfProjects += contractPlatform.NoCostStructure__c ? 1 : contractPlatform.CostStructure__c.split(';').size();
            }

            for (OpportunityPlatform__c contractPlatform :contractPlatforms.get(payment.Project__c)) {
                if (!contractPlatform.NoCostStructure__c && String.isNotBlank(contractPlatform.CostStructure__c)) {
                    for (String costStructure :contractPlatform.CostStructure__c.split(';')) {
                        Payment__c project = createProjectFromPayment(payment, contractPlatform.Id, numberOfProjects, index, total);
                        project.UnitCost__c = (Decimal)contractPlatform.get(costStructure + '__c');
                        project.CostStructure__c = costStructure;

                        total += project.Client_Spend__c;
                        index++;

                        payments.add(project);
                    }
                } else {
                    Payment__c project = createProjectFromPayment(payment, contractPlatform.Id, numberOfProjects, index, total);
                    total += project.Client_Spend__c;
                    index++;

                    payments.add(project);
                }
            }
        }
        return payments;
    }

    public static Project__c copyOpportunityDataToContract(Opportunity opp) {
        return new Project__c(
            Account_Type__c = opp.Account_Type__c,
            Account__c = opp.AccountId,
            BillingCondition__c = opp.BillingCondition__c,
            Brand__c = opp.Brand__c,
            BrandAccount__c = opp.BrandAccount__c,
            Client_IO__c = opp.IO__c,
            ClientServicesRep__c = opp.ClientServicesRep__c,
            Client_Spend__c = opp.Amount,
            CurrencyIsoCode = opp.CurrencyIsoCode,
            End_Date__c = opp.Flight_End__c,
            Geo__c = opp.Geo__c,
            Language__c = opp.Language__c,
            Margin__c = opp.Percent_Margin__c,
            Margin_Type__c = opp.Margin_Type__c,
            More_Info__c = opp.More_Info__c,
            Name = opp.Name,
            Order_Type__c = opp.Order_Type__c,
            Opportunity__c = opp.Id,
            OwnerId = opp.OwnerId,
            Payment_Type__c = opp.Payment_Type__c,
            Start_Date__c = opp.Flight_Start__c,
            Strike_ID__c = opp.Strike_ID__c,
            Targeting__c = opp.Targeting__c,
            Verticals__c = opp.Verticals__c,
            Video_Length__c = opp.Video_Length__c,
            Custom_Xero_Campaign_Name__c = opp.CustomXeroCampaignName__c
        );
    }

    public static XeroWrappers.XeroInvoice mapPaymentToInvoice(Sub_Project__c payment, String contactId, String xeroEntityId) {
        String xeroItemQuery = ' SELECT ItemCode__c FROM XeroItem__c WHERE XeroSettings__c = :xeroEntityId AND ';
        xeroItemQuery += ' BillingProfile__c INCLUDES (\'' + payment.Project__r.Account_Type__c + '\')';

        List<XeroItem__c> xeroItems = Database.query(xeroItemQuery);
        XeroSettings__c xeroSettings = [SELECT AccountCode__c FROM XeroSettings__c WHERE Id = :xeroEntityId];

        XeroWrappers.XeroInvoice invoice = new XeroWrappers.XeroInvoice();
        XeroWrappers.XeroContact contact = new XeroWrappers.XeroContact(contactId);
        invoice.Contact = contact;
        invoice.CurrencyCode = payment.CurrencyIsoCode;
        invoice.InvoiceDate = payment.End_Date__c;
        invoice.DueDate = payment.End_Date__c.addDays(30);

        if (String.isNotBlank(payment.PaymentType__c)) {
            if (payment.PaymentType__c.startsWith('Net')) {
                List<String> splitType = payment.PaymentType__c.split(' ');
                if (splitType.size() == 2) {
                    invoice.DueDate = payment.End_Date__c.addDays(Integer.valueOf(splitType[1]));
                }
            }
        }

        List<XeroWrappers.XeroLineItem> lineItems = new List<XeroWrappers.XeroLineItem>();
        if (String.isNotBlank(payment.Project__r.Account__r.InvoiceLayout__c) && payment.Project__r.Account__r.InvoiceLayout__c == 'Media/Strike Fee' && payment.Project__r.Account_Type__c != 'Client') {
            lineItems.add(createXeroLineItem(payment, xeroSettings, 'Media Cost', payment.AdWordsSpend__c));
            lineItems.add(createXeroLineItem(payment, xeroSettings, '111', payment.Invoice_Amount__c - payment.AdWordsSpend__c));
        } else {
            String itemCode = !xeroItems.isEmpty() ? xeroItems[0].ItemCode__c : '';
            lineItems.add(createXeroLineItem(payment, xeroSettings, itemCode, payment.Invoice_Amount__c));
        }

        invoice.LineItems = lineItems;
        invoice.Type = XeroWrappers.XeroInvoiceType.ACCREC;
        invoice.Status = XeroWrappers.XeroInvoiceStatus.SUBMITTED;

        Datetime endDateTime = Datetime.newInstance(payment.End_Date__c.year(), payment.End_Date__c.month(), payment.End_Date__c.day());
        String customName = (payment.Project__r.Custom_Xero_Campaign_Name__c != null) ?
                payment.Project__r.Custom_Xero_Campaign_Name__c : payment.Project__r.Name;

        invoice.Reference = endDateTime.formatGmt('MMM') + ' - ' + customName + ' - ' + payment.ProjectID__c;
        return invoice;
    }

    public static String formatDate(Date dt) {
        Datetime dtime = Datetime.newInstance(dt, Time.newInstance(0, 0, 0, 0));
        return dtime.format('dd/MM/yyyy');
    }

    /*********************/
    public class FieldDef {
        public String label { get;set; }
        public String type { get;set; }
        public String name { get;set; }
        public Boolean required { get;set; }
        public Boolean hidden = false;

        public FieldDef(Schema.FieldSetMember field) {
            name = field.getFieldPath();
            label = field.getLabel();
            type = String.valueOf(field.getType());
            required = field.getRequired();
        }
    }

    public class FieldSetDefinition {
        public String name { get;set; }
        public String label { get;set; }
        public String description { get;set; }
        public List<FieldDef> fields { get;set; }

        public FieldSetDefinition(Schema.FieldSet fieldSet) {
            name = fieldSet.getName();
            label = fieldSet.getLabel();
            description = fieldSet.getDescription();
            fields = new List<FieldDef>();

            for (Schema.FieldSetMember fsm :fieldSet.getFields()) {
                fields.add(new FieldDef(fsm));
            }
        }
    }

    public static Map<String, Schema.FieldSet> getObjectFieldSetsMap(String objectName) {
        Schema.DescribeSObjectResult describeSObjectResultObj = getObjectDescribe(objectName);
        Map<String, Schema.FieldSet> fieldSetMap = describeSObjectResultObj.fieldSets.getMap();
        return fieldSetMap;
    }

    public static Map<String, Schema.SObjectField> getObjectFieldsMap(String objectName) {
        Schema.DescribeSObjectResult describeSObjectResultObj = getObjectDescribe(objectName);
        Map<String, Schema.SObjectField> fieldsMap = describeSObjectResultObj.fields.getMap();
        return fieldsMap;
    }

    public static Schema.DescribeSObjectResult getObjectDescribe(String objectName) {
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType SObjectTypeObj = globalDescribeMap.get(objectName);
        return SObjectTypeObj.getDescribe();
    }

    private static XeroWrappers.XeroLineItem createXeroLineItem(Sub_Project__c payment, XeroSettings__c xeroSettings, String itemCode, Decimal amount) {
        XeroWrappers.XeroLineItem lineItem = new XeroWrappers.XeroLineItem();
        lineItem.Description = XeroUtils.prepareLineItemDescription(payment);
        lineItem.Quantity = 1;
        lineItem.AccountCode = xeroSettings.AccountCode__c;
        lineItem.LineAmount = amount;
        lineItem.UnitAmount = lineItem.LineAmount;
        if (String.isNotBlank(itemCode)) {
            lineItem.ItemCode = itemCode;
        }
        return lineItem;
    }

    private static Payment__c createProjectFromPayment(Sub_Project__c payment, Id contractPlatformId, Integer numberOfProjects, Integer index, Decimal total) {
        Payment__c project = new Payment__c();
        if (project.Account__c == null) project.Account__c = payment.Account__c;
        if (project.Client_Spend__c == null) project.Client_Spend__c = (index == numberOfProjects) ? payment.Client_Spend__c - total : Math.round(payment.Client_Spend__c / numberOfProjects * 100)/100;
        if (project.Margin__c == null) project.Margin__c = payment.Margin__c;
        if (project.Margin_Type__c == null) project.Margin_Type__c = payment.Margin_Type__c;
        if (project.Opportunity__c == null) project.Opportunity__c = payment.Opportunity__c;
        if (project.CurrencyIsoCode == null) project.CurrencyIsoCode = payment.CurrencyIsoCode;
        if (project.Name == null) project.Name = payment.Name;
        if (project.Start_Date__c == null) project.Start_Date__c = payment.Start_Date__c;
        if (project.End_Date__c == null) project.End_Date__c = payment.End_Date__c;
        if (project.Payment__c == null) project.Payment__c = payment.Id;
        if (project.Project__c == null) project.Project__c = payment.Project__c;
        if (project.OpportunityPlatform__c == null) project.OpportunityPlatform__c = contractPlatformId;
        return project;
    }

    public static Boolean getIsSandbox() {
        if (isSandbox == null) {
            isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        }
        return isSandbox;
    }

    public static Boolean getIsProduction() {
        if (isSandbox == null) {
            isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        }
        return !isSandbox;
    }

    public static String findFBAccountName(Project__c contract) {
        String accountName = '';
        for (OpportunityPlatform__c contractPlatform : contract.ContractPlatforms__r) {
            if ((contractPlatform.Platform__r.Name == 'Instagram' || contractPlatform.Platform__r.Name == 'Facebook') && accountName == '') {
                accountName = (String.isNotBlank(contractPlatform.PlatformAccount__c)) ? contractPlatform.PlatformAccount__c : '';
            }
        }
        return accountName;
    }

    public static String findDBMAccountName(Project__c contract) {
        String accountName = '';
        for (OpportunityPlatform__c contractPlatform : contract.ContractPlatforms__r) {
            if ((contractPlatform.Platform__r.Name == 'DBM TrueView' || contractPlatform.Platform__r.Name == 'DBM RTB') && accountName == '') {
                accountName = (String.isNotBlank(contractPlatform.PlatformAccount__c)) ? contractPlatform.PlatformAccount__c : '';
            }
        }
        return accountName;
    }

    public static String findAdWordsAccountName(Project__c contract) {
        String accountName = '';
        for (OpportunityPlatform__c contractPlatform : contract.ContractPlatforms__r) {
            if ((contractPlatform.Platform__r.Name == 'AdWords CPM'
                    || contractPlatform.Platform__r.Name == 'TrueView'
                    || contractPlatform.Platform__r.Name == 'Google Search'
                    || contractPlatform.Platform__r.Name == 'Google Display Network'
                ) && accountName == '') {
                accountName = (String.isNotBlank(contractPlatform.PlatformAccount__c)) ? contractPlatform.PlatformAccount__c : '';
            }
        }
        return accountName;
    }

    // MediaManager
    public class APIException extends Exception {
        public APIException(MMSpendType type) {
            if (type == MMSpendType.DBM) {
                this.setMessage(String.format(EMPTY_PLATFORM_ACCOUNT_EXCEPTION, new List<String>{'DBM TrueView/DBM RTB'}));
            } else if (type == MMSpendType.FACEBOOK) {
                this.setMessage(String.format(EMPTY_PLATFORM_ACCOUNT_EXCEPTION, new List<String>{'Instagram/Facebook'}));
            } else if (type == MMSpendType.ADWORDS) {
                this.setMessage(String.format(EMPTY_PLATFORM_ACCOUNT_EXCEPTION, new List<String>{'AdWords CPM/TrueView/Google Search'}));
            }
        }
    }

    public enum MMSpendType { FACEBOOK, ADWORDS, DBM }

    public class SpendAssignResult {
        public Boolean isValid {get; set;}
        public String message {get; set;}

        public SpendAssignResult() {
            this.isValid = false;
            this.message = '';
        }

        public void setFailure(String msg) {
            this.message = msg;
            this.isValid = false;
        }

        public void setSuccess() {
            this.message = 'Spends Imported Successfully.';
            this.isValid = true;
        }

    }

    public static String getSpendCurrencyErrorMsg(Project__c contract, String strikeId, String spendCurrency) {
        return 'Contract Name: ' + contract.Name + '\n' +
                '\tStrike Id: ' + strikeId + '\n' +
                '\tContract Currency: ' + contract.CurrencyIsoCode + '\n' +
                '\tMedia Manager Currency: ' + spendCurrency + '\n' +
                '\tPlease find more details here: ' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + contract.Id + '\n';
    }

    public static String getSpendContractNotFoundErrorMsg(String strikeId, String spendDate) {
        return strikeId + ' (' + spendDate + ')';
        //return '\tContract with given Project Id (Strike Id) couldn\'t be found: ' + strikeId + ' (' + spendDate + ')';
    }

    public static String getSpendAccountErrorMsg(Project__c contract, MMSpendType type, String strikeId, String accountId) {
        String accountName = '', accountType = '';
        if (type == MMSpendType.FACEBOOK) {
            accountName = findFBAccountName(contract);
            accountType = MMSpendType.FACEBOOK.name();
        } else if (type == MMSpendType.DBM) {
            accountName = findDBMAccountName(contract);
            accountType = MMSpendType.DBM.name();
        } else if (type == MMSpendType.ADWORDS) {
            accountName = findAdWordsAccountName(contract);
            accountType =  MMSpendType.ADWORDS.name();
        }
        accountName = (String.isBlank(accountName)) ? 'NULL' : accountName;

        String retVal = '\tClient Services Rep: ';
        retVal += String.isBlank(contract.ClientServicesRep__r.Name) ? 'Not Assigned' : contract.ClientServicesRep__r.Name;
        retVal += ',\n\n' + '\tContract Name: ' + contract.Name + ',\n\n' +
                '\tStrike Id: ' + strikeId + ',\n\n' +
                '\tContract ' + accountType + ' Account: ' + accountName;
        retVal += ',\n\n' + '\tMedia Manager ' + accountType + ' Account: ' + accountId + '\n\n';
        return retVal;
    }

    public static String getSpendAccountShortErrorMsg(Project__c contract, MMSpendType type, String accountId) {
        String accountName = '', accountType = '';
        if (type == MMSpendType.FACEBOOK) {
            accountName = findFBAccountName(contract);
            accountType = MMSpendType.FACEBOOK.name();
        } else if (type == MMSpendType.DBM) {
            accountName = findDBMAccountName(contract);
            accountType = MMSpendType.DBM.name();
        } else if (type == MMSpendType.ADWORDS) {
            accountName = findAdWordsAccountName(contract);
            accountType = MMSpendType.ADWORDS.name();
        }
        accountName = (String.isBlank(accountName)) ? 'NULL' : accountName;
        return 'Expected ' + accountType + ' Account: ' + accountId + '. Actual: ' + accountName + '.\n\n';
    }

    public static String fetchName(Date sDate, Date eDate, String projectID) {
        String startDate, endDate, newName;
        startDate = String.isNotBlank(String.valueOf(sDate)) ? String.valueOf(sDate).replaceAll('-', '.') : '';
        endDate   = String.isNotBlank(String.valueOf(eDate)) ? String.valueOf(eDate).replaceAll('-', '.') : '';
        newName   = '[' + projectID + ' - ' + startDate + ' - ' + endDate + ']';
        return newName;
    }

    public static Boolean isValueChanged(SObject recordNew, SObject recordOld, String fieldAPIName) {
        return (recordNew.get(fieldAPIName) != null && (recordOld.get(fieldAPIName) == null || recordNew.get(fieldAPIName) != recordOld.get(fieldAPIName)));
    }
}