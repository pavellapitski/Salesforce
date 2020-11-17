public with sharing class ProjectHandler implements ITrigger {

    public static Set<Id> paymentsWithStartDateUpdated = new Set<Id>();
    public static Set<Id> paymentsWithEndDateUpdated = new Set<Id>();
    public static Set<Id> paymentsWithClientSpendUpdated = new Set<Id>();

    public static Set<Id> canEditClientSpendMode = new Set<Id>();

    private static String marginAPIName = Project__c.Margin__c.getDescribe().getName();
    private static String billingConditionAPIName = Project__c.BillingCondition__c.getDescribe().getName();
    private static String billingProfileAPIName = Project__c.Account_Type__c.getDescribe().getName();
    private static String paymentTypeAPIName = Project__c.Payment_Type__c.getDescribe().getName();
    private static String brandAPIName = Project__c.Brand__c.getDescribe().getName();
    private static String accountAPIName = Project__c.Account__c.getDescribe().getName();
    private static String currencyCodeAPIName = Project__c.CurrencyIsoCode.getDescribe().getName();
    private static String startDateAPIName = Project__c.Start_Date__c.getDescribe().getName();
    private static String endDateAPIName = Project__c.End_Date__c.getDescribe().getName();
    private static String clientSpendAPIName = Project__c.Client_Spend__c.getDescribe().getName();
    private static String actualRebateAPIName = Project__c.Actual_Rebate__c.getDescribe().getName();
    private static String marginTypeAPIName = Project__c.Margin_Type__c.getDescribe().getName();

    public ProjectHandler() {}

    public void bulkBefore() {}

    public void bulkAfter() {}

    public void beforeInsert(List<SObject> so) {
        System.debug('### ProjectHandler.BEFORE_INSERT :' + so);
        List<Project__c> contracts = (List<Project__c>) so;
        Map<String, Project__c> contractForBrandAccount = new Map<String, Project__c>();

        for (Project__c contract :contracts) {
            contract.CSEmailFromBrandAccount__c = contract.DefaultBrandAccountCSRepEmail__c;
            contract.WeeklyReportingSchedule__c = (String.isBlank(contract.WeeklyReportingSchedule__c)) ? 'N/A' : contract.WeeklyReportingSchedule__c;

            if (String.isBlank(contract.ClientServicesRep__c) && String.isNotBlank(contract.DefaultClientServicesRep__c)) {
                contract.ClientServicesRep__c = contract.DefaultClientServicesRep__c;
            }

            contract.Actual_Rebate__c = calculateActualRebate(contract);

            if (String.isNotBlank(contract.Brand__c) && String.isNotBlank(contract.Account__c)) {
                String brandId = ((String) contract.Brand__c ).left(15);
                String accountId = ((String) contract.Account__c).left(15);
                contractForBrandAccount.put(brandId + '-' + accountId, contract);
            }
        }

        if (!contractForBrandAccount.isEmpty()) {
            updateBrandAccount(contractForBrandAccount);
        }
        System.debug('### ProjectHandler.BEFORE_INSERT END');
    }

    public void beforeUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {
        System.debug('### ProjectHandler.BEFORE_UPDATE :' + so.values());
        Map<Id, Project__c> contracts = (Map<Id, Project__c>) so;
        Map<Id, Project__c> oldContractsMap = (Map<Id, Project__c>) oldSo;
        Set<Id> contractsWithChangedClientSpend = new Set<Id>();
        Set<Id> contractsWithXeroIdToUpdate = new Set<Id>();

        Map<String, Project__c> contractForBrandAccount = new Map<String, Project__c>();
        for (Project__c contr :contracts.values()) {
            Project__c oldContract = oldContractsMap.get(contr.Id);
            contr.CSEmailFromBrandAccount__c = contr.DefaultBrandAccountCSRepEmail__c;

            if (String.isBlank(contr.ClientServicesRep__c) && String.isNotBlank(contr.DefaultClientServicesRep__c)) {
                contr.ClientServicesRep__c = contr.DefaultClientServicesRep__c;
            }

            if (contr.Sync_With_MM__c != null && contr.PerformMMSync__c == oldContract.PerformMMSync__c) {
                contr.PerformMMSync__c = true;
            }

            Boolean isBrandChanged = (contr.Brand__c != oldContract.Brand__c && String.isNotBlank(contr.Brand__c));
            Boolean isAccountChanged = (contr.Account__c != oldContract.Account__c && String.isNotBlank(contr.Account__c));
            if (isBrandChanged || isAccountChanged) {
                String brandId = ((String) contr.Brand__c ).left(15);
                String accountId = ((String) contr.Account__c).left(15);
                contractForBrandAccount.put(brandId + '-' + accountId, contr);
            }

            if (contr.Client_Spend__c != oldContract.Client_Spend__c) {
                contractsWithChangedClientSpend.add(contr.Id);
            }

            if (String.isNotBlank(contr.BillingCondition__c) && contr.BillingConditionName__c == Contract.BILLING_CONDITION_EXTECH) {
                contr.Payment_Type__c = 'Net 45';
                if (String.isBlank(contr.Xero_Id__c)) {
                    contractsWithXeroIdToUpdate.add(contr.Id);
                }
            }

            contr.Actual_Rebate__c = calculateActualRebate(contr);
        }

        if (!contractForBrandAccount.isEmpty()) {
            updateBrandAccount(contractForBrandAccount);
        }

        if (!contractsWithChangedClientSpend.isEmpty()) {
            for (Project__c contract : [SELECT Id, (SELECT Id FROM Sub_Projects__r) FROM Project__c WHERE Id IN :contractsWithChangedClientSpend]) {
                if (contract.Sub_Projects__r.size() > 1 && !canEditClientSpendMode.contains(contract.Id)) {
                    contracts.get(contract.Id).addError(Label.ContractHasMultiplePaymentsCannotEditClientSpend);
                }
            }
        }
        if (!contractsWithXeroIdToUpdate.isEmpty()) {
            updateXeroIds(contracts, contractsWithXeroIdToUpdate);
        }

        Map<String, List<Id>> contractXeroId = new Map<String, List<Id>>();
        for (Project__c contract :contracts.values()) {
            if (String.isNotBlank(contract.Xero_Id__c) && (String.isBlank(contract.XeroObject__c) || contract.Xero_Id__c != oldContractsMap.get(contract.Id).Xero_Id__c)) {
                if (!contractXeroId.containsKey(contract.Xero_Id__c)) {
                    contractXeroId.put(contract.Xero_Id__c, new List<Id>());
                }
                contractXeroId.get(contract.Xero_Id__c).add(contract.Id);
            }
        }

        if (!contractXeroId.isEmpty()) {
            updateXeroObjects(contractXeroId, contracts);
        }
        System.debug('### ProjectHandler.BEFORE_UPDATE END');
    }

    public void beforeDelete(List<SObject> so) {}

    public void afterInsert(List<SObject> so) {
        System.debug('### ProjectHandler.AFTER_INSERT :' + so);
        List<Project__c> contracts = (List<Project__c>) so;
        Map<Id, Project__c> opportunityContracts = new Map<Id, Project__c>();
        for (Project__c contract :contracts) {
            if (String.isNotBlank(contract.Opportunity__c)) {
                opportunityContracts.put(contract.Opportunity__c, contract);
            }
        }
        if (!opportunityContracts.isEmpty()) {
            Contract.updateContractFromOpportunity(opportunityContracts);
            updateBrandOnOpportunity(opportunityContracts);
        }
        if (!contracts.isEmpty()) {
            Contract.createNewPayments(contracts);
            createSalesRepRecords(contracts);
        }
        System.debug('### ProjectHandler.AFTER_INSERT END');
    }

    private Set<Id> idsWithInvoicesPaid = new Set<Id>();
    public void afterUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {
        System.debug('### ProjectHandler.AFTER_UPDATE :' + so.values());
        Set<String> syncWithUtopsa = new Set<String>();
        Set<Id> contractIdsForPaymentsToChange = new Set<Id>();
        Map<Id, Project__c> opportunityContracts = new Map<Id, Project__c>();

        Project__c oldContract, newContract;
        for (SObject record :so.values()) {
            newContract = (Project__c) record;
            oldContract = (Project__c) oldSo.get(newContract.Id);

            if (isValueChanged(newContract, oldContract, marginAPIName) ||
                isValueChanged(newContract, oldContract, billingProfileAPIName) ||
                isValueChanged(newContract, oldContract, paymentTypeAPIName)  ||
                isValueChanged(newContract, oldContract, billingConditionAPIName) ||
                isValueChanged(newContract, oldContract, currencyCodeAPIName) ||
                isValueChanged(newContract, oldContract, actualRebateAPIName) ||
                isValueChanged(newContract, oldContract, marginTypeAPIName) ||
                isValueChanged(newContract, oldContract, startDateAPIName) ||
                isValueChanged(newContract, oldContract, endDateAPIName) ||
                isValueChanged(newContract, oldContract, clientSpendAPIName)
            ) {
                System.debug('### TEST billingConditionAPIName: ' + isValueChanged(newContract, oldContract, billingConditionAPIName));
                contractIdsForPaymentsToChange.add(newContract.Id);
            }

            if (newContract.InvoicesPaid__c && (oldContract.InvoicesPaid__c  != newContract.InvoicesPaid__c)) {
                idsWithInvoicesPaid.add(newContract.Id);
            }

            if (newContract.PerformMMSync__c && !oldContract.PerformMMSync__c) {
                syncWithUtopsa.add(newContract.Id);
            }

            Boolean isBrandChanged = isValueChanged(newContract, oldContract, brandAPIName);
            Boolean isAccountChanged = isValueChanged(newContract, oldContract, accountAPIName);
            if (String.isNotBlank(newContract.Opportunity__c) && (isAccountChanged || isBrandChanged)) {
                opportunityContracts.put(newContract.Opportunity__c, newContract);
            }
        }

        if (!contractIdsForPaymentsToChange.isEmpty()) {
            Map<Id, Sub_Project__c> paymentsToUpdate = new Map<Id, Sub_Project__c>();
            preparePaymentsAndProjectsToUpdate(contractIdsForPaymentsToChange, paymentsToUpdate, oldSo, so);

            if (!paymentsToUpdate.isEmpty()) {
                // Validation should be disabled to allow make changes regardless the error: "Sum of payment client spend must be equal to contract client spend"
                SubProjectHandler.skipUpdateValidation = true;
                // Validation should be disabled to allow make changes regardless the error: "Sum of project client spend must be equal to payment client spend"
                PaymentHandler.skipUpdateValidation = true;

                System.debug('### TEST paymentsToUpdate: ' + paymentsToUpdate);
                update paymentsToUpdate.values(); //paymentsUpdate(JSON.serialize(paymentsToUpdate.values()));
            }
        }

        if (!opportunityContracts.isEmpty()) {
            updateBrandOnOpportunity(opportunityContracts);
        }

        ConSalesRepExpCommissionCalculator.SALES_REP_EXPECTED_COMMISSIONS_RECALCULATED = false;
        ConSalesRepExpCommissionCalculator.calculateExpectedCommission(so.keySet());
        System.debug('### ProjectHandler.AFTER_UPDATE END');
    }

    public void afterDelete(List<SObject> so) {}

    public void andFinally() {
        if (!idsWithInvoicesPaid.isEmpty()) {
            updateSalesReps();
        }
    }

    private void preparePaymentsAndProjectsToUpdate(Set<Id> contractIds, Map<Id, Sub_Project__c> paymentsMap, Map<Id, SObject> oldSo, Map<Id, SObject> so) {
        List<Project__c> contracts = [
            SELECT Id, Project_ID__c, Account_Type__c, Margin__c, Payment_Type__c, CurrencyIsoCode,
                (SELECT Id, End_Date__c, Start_Date__c, Project__c, Name, Account_Type__c, Margin__c, CurrencyIsoCode, Checked__c FROM Sub_Projects__r ORDER BY End_Date__c ASC)/*,
                (SELECT Id, End_Date__c, Start_Date__c, Project__c, Payment_Type__c, Name, Account_Type__c, Margin__c, CurrencyIsoCode FROM Payments__r ORDER BY End_Date__c ASC)*/
            FROM Project__c
            WHERE Id IN: contractIds
        ];

        Project__c newContract, oldContract;
        for (Project__c contract :contracts) {
            newContract = (Project__c) so.get(contract.Id);
            oldContract = (Project__c) oldSo.get(newContract.Id);

            Boolean isMarginChanged = isValueChanged(newContract, oldContract, marginAPIName),
                    isBillingProfileChanged = isValueChanged(newContract, oldContract, billingProfileAPIName),
                    isPaymentTypeChanged = isValueChanged(newContract, oldContract, paymentTypeAPIName),
                    isBillingConditionChanged = isValueChanged(newContract, oldContract, billingConditionAPIName),
                    isCurrencyCodeChanged = isValueChanged(newContract, oldContract, currencyCodeAPIName),
                    //isActualRebateChanged = isValueChanged(newContract, oldContract, actualRebateAPIName),
                    isDateChanged = isValueChanged(newContract, oldContract, startDateAPIName) || isValueChanged(newContract, oldContract, endDateAPIName),
                    isClientSpendChanged = isValueChanged(newContract, oldContract, clientSpendAPIName),
                    isMarginTypeChanged = isValueChanged(newContract, oldContract, marginTypeAPIName);

            if (contract.Sub_Projects__r.size() > 0) {
                Boolean contractHasOnePayment = contract.Sub_Projects__r.size() == 1;
                Sub_Project__c paymentToUpdate, firstPaymentRecord, lastPaymentRecord;

                for (Sub_Project__c payment :contract.Sub_Projects__r) {
                    if (isDateChanged) {
                        if (firstPaymentRecord == null || (payment.Start_Date__c < firstPaymentRecord.Start_Date__c)) {
                            firstPaymentRecord = payment;
                        }
                        if (lastPaymentRecord == null || (payment.End_Date__c > lastPaymentRecord.End_Date__c)) {
                            lastPaymentRecord = payment;
                        }
                    }

                    Boolean updatePayment = false;
                    // create a new instance for payment(Sub_Project__c) to avoid unnecessary(old) values in record for async update
                    paymentToUpdate = new Sub_Project__c(Id = payment.Id);
                    if (isClientSpendChanged && contractHasOnePayment) {
                        // if ClientSpend on contract is updated and Contract has only one record,
                        paymentsWithClientSpendUpdated.add(payment.Id);
                        paymentToUpdate.Client_Spend__c = newContract.Client_Spend__c;
                        updatePayment = true;
                    }
                    if (isMarginChanged) {
                        paymentToUpdate.Margin__c = newContract.Margin__c;
                        updatePayment = true;
                    }
                    if (isBillingProfileChanged) {
                        paymentToUpdate.Account_Type__c = newContract.Account_Type__c;
                        updatePayment = true;
                    }
                    if (isPaymentTypeChanged) {
                        paymentToUpdate.Payment_Type__c = newContract.Payment_Type__c;
                        updatePayment = true;
                    }
                    if (isCurrencyCodeChanged) {
                        paymentToUpdate.CurrencyIsoCode = newContract.CurrencyIsoCode;
                        updatePayment = true;
                    }
                    if (/*payment.Checked__c = false &&*/ isBillingConditionChanged) { // TODO: check THAT ????
                        updatePayment = true;
                    }
                    if (isMarginTypeChanged) {
                        paymentToUpdate.Margin_Type__c = newContract.Margin_Type__c;
                        updatePayment = true;
                    }
                    // add record to collection to be updated
                    if (updatePayment && !paymentsMap.containsKey(paymentToUpdate.Id)) {
                        paymentsMap.put(paymentToUpdate.Id, paymentToUpdate);
                    }
                }

                if (firstPaymentRecord != null) {
                    // TODO: move to a method
                    if (firstPaymentRecord.Start_Date__c != newContract.Start_Date__c) {
                        Date newStartDate = newContract.Start_Date__c;
                        if (firstPaymentRecord.End_Date__c >= newStartDate || contractHasOnePayment) {
                            paymentsWithStartDateUpdated.add(firstPaymentRecord.Id);

                            // create a new instance for payment(Sub_Project__c) to avoid unnecessary(old) values in record for update
                            paymentToUpdate = new Sub_Project__c(Id = firstPaymentRecord.Id);
                            if (!paymentsMap.containsKey(paymentToUpdate.Id)) {
                                paymentsMap.put(paymentToUpdate.Id, paymentToUpdate);
                            }
                            paymentsMap.get(paymentToUpdate.Id).Start_Date__c = newStartDate;
                        } else {
                            newContract.Start_Date__c.addError(Label.ContractStartDateBiggerThanFirstPaymentEndDate);
                        }
                    }
                }
                if (lastPaymentRecord != null) {
                    // TODO: move to a method
                    if (lastPaymentRecord.End_Date__c != newContract.Start_Date__c) {
                        Date newEndDate = newContract.End_Date__c;
                        if (lastPaymentRecord.Start_Date__c <= newEndDate || contractHasOnePayment) {
                            paymentsWithEndDateUpdated.add(lastPaymentRecord.Id);

                            // create a new instance for payment(Sub_Project__c) to avoid unnecessary(old) values in record for update
                            paymentToUpdate = new Sub_Project__c(Id = lastPaymentRecord.Id);
                            if (!paymentsMap.containsKey(paymentToUpdate.Id)) {
                                paymentsMap.put(paymentToUpdate.Id, paymentToUpdate);
                            }
                            paymentsMap.get(paymentToUpdate.Id).End_Date__c = newEndDate;
                        } else {
                            newContract.End_Date__c.addError(Label.ContractEndDateLowerThanLastPaymenStartDate);
                        }
                    }
                }
            }
        }
    }

    private Decimal calculateActualRebate(Project__c contract) {
        Decimal result = 0;
        if (contract.Contract_Ended__c) {
            Decimal strikeMargin = contract.Strike_Final_Margin__c/100, // Billing Condition data: = DefaultMargin - RebateRate
                actualGrossProfit = contract.Actual_Gross_Profit__c,
                clientSpend = contract.Client_Spend__c,
                mediaSpend = contract.AdWords_Spend__c;

            String marginType = contract.Margin_Type__c,
                billingCondition = contract.BillingConditionName__c;

            if (billingCondition.contains('Instant Rebate')) {
                result = actualGrossProfit * contract.BC_Rebate__c/100 / (1 - contract.BC_Rebate__c/100);
                System.debug('### ACTUAL_REBATE 1: ' + result);
            } else {
                if (strikeMargin > 0 && clientSpend > 0) {
                    if (strikeMargin <= (clientSpend - mediaSpend)/clientSpend) {
                        Decimal mediaOrClientSpend = (marginType == '% of Media') ? mediaSpend : clientSpend;
                        // might be negative value
                        result = actualGrossProfit - strikeMargin * mediaOrClientSpend;
                        System.debug('### ACTUAL_REBATE 2 : ' + result);
                    } else {
                        System.debug('### ACTUAL_REBATE 3 : ' + result);
                        result = actualGrossProfit * (1 - strikeMargin);
                    }
                } else if (strikeMargin == 0 && clientSpend > 0) {
                    // corner case for Make Good campaigns, Margin is 0%
                    result = clientSpend * contract.BC_Rebate__c/100;
                    System.debug('### ACTUAL_REBATE 4: ' + result);
                }
            }

            /*Decimal strikeFinalMarginFromBC = contract.BC_Strike_Final_Margin__c/100, // Assuming that SFM is the same that Strike Margin
            if (strikeMargin > 0 && clientSpend > 0) {
                if (strikeMargin <= (clientSpend - mediaSpend)/clientSpend) {
                    Decimal mediaOrClientSpend = (marginType == '% of Media') ? mediaSpend : clientSpend;
                    // might be negative value
                    result = actualGrossProfit - strikeMargin * mediaOrClientSpend;
                    System.debug('### ACTUAL REBATE 1: ' + result);
                }
            } else {
                if (billingCondition.contains('Instant Rebate') || billingCondition.contains('Extech')) {
                    Decimal instantRebate = contract.BC_Instant_Rebate__c / 100; // Billing Condition data: Instant Rebate
                    result = actualGrossProfit * instantRebate / (1 - instantRebate);
                    System.debug('### 2.Actual Rebate: ' + result);
                } else if (billingCondition.contains('Rebate 1/3') || billingCondition.contains('Margin Split 2:1')) {
                    // for campaigns of 2016 year  = 'Rebate 1/3'
                    // not used on Production
                    result = actualGrossProfit * 1/3;
                    System.debug('### 3.Actual Rebate: ' + result);
                } else if (strikeFinalMarginFromBC != null && strikeFinalMarginFromBC > 0) {
                    result = actualGrossProfit * (1 - strikeFinalMarginFromBC);
                    System.debug('### 4.Actual Rebate: ' + result);
                } else if (strikeMargin == 0 && clientSpend != 0) {
                    // corner case: for Make Good campaigns, Margin is 0%
                    result = clientSpend * strikeRebateFromBC;
                    System.debug('### 5.Actual Rebate: ' + result);
                }
            }*/
        } else {
            result = contract.ExpectedRebate__c;
        }
        return (result < 0) ? 0 : result;
    }

    private Boolean isValueChanged(Project__c recordNew, Project__c recordOld, String fieldAPIName) {
        return Utility.isValueChanged(recordNew, recordOld, fieldAPIName);
    }

    public void updateBrandAccount(Map<String, Project__c> contractForBrandAccount) {
        Set<String> accountIds = new Set<String>();
        Set<String> brandIds = new Set<String>();
        for (Project__c prj :contractForBrandAccount.values()) {
            accountIds.add(prj.Account__c);
            brandIds.add(prj.Brand__c);
        }

        Map<String,String> brandIdToName = new Map<String,String>();
        for (Brand__c brand :[SELECT Id, Name FROM Brand__c WHERE Id IN :brandIds]) {
            brandIdToName.put(brand.Id, brand.Name);
        }
        Map<String, String> accIdToName = new Map<String, String>();
        Map<String, Brand_Account__c> brandIdAccountIdKeys_existing = new Map<String, Brand_Account__c>();
        for (Account acc :[SELECT Id, Name, (SELECT Brand__c, Id FROM Brand_Accounts__r) FROM Account WHERE Id IN :accountIds]) {
            accIdToName.put(acc.Id, acc.Name);

            for (Brand_Account__c ba :acc.Brand_Accounts__r) {
                brandIdAccountIdKeys_existing.put(((String)ba.Brand__c).left(15) + '-' + ((String)acc.Id).left(15), ba);
            }
        }

        System.debug('### brandIdAccountIdKeys_existing: ' + brandIdAccountIdKeys_existing);

        Map<String, Brand_Account__c> newBrandAccounts = new Map<String,Brand_Account__c>();
        for (String key :contractForBrandAccount.keySet()) {
            if (brandIdAccountIdKeys_existing.containsKey(key)) {
                contractForBrandAccount.get(key).BrandAccount__c = brandIdAccountIdKeys_existing.get(key).Id;
            } else {
                //create new brand/account record based on new account and new brand
                String accId = contractForBrandAccount.get(key).Account__c;
                String brandId = contractForBrandAccount.get(key).Brand__c;
                String accName = accIdToName.get(accId);
                String brandName = brandIdToName.get(brandId);

                newBrandAccounts.put(key, new Brand_Account__c(Accounts__c = accId, Brand__c = brandId, Name = brandName + ' / ' + accName));
            }
        }
        insert newBrandAccounts.values();

        for (String key :contractForBrandAccount.keySet()) {
            if (!newBrandAccounts.containsKey(key)) {
                continue;
            }
            contractForBrandAccount.get(key).BrandAccount__c = newBrandAccounts.get(key).Id;
        }
    }

    public void updateBrandOnOpportunity(Map<Id, Project__c> oppIdToContracts) {
        // get related opportunities
        List<Opportunity> relatedOpps = [SELECT Brand__c, AccountId FROM Opportunity WHERE Id IN :oppIdToContracts.keySet()];
        // check if contract.Brand__c is different from opportunity.Brand__c
        List<Opportunity> oppToUpdate = new List<Opportunity>();
        for (Opportunity opp :relatedOpps) {
            Project__c contract = oppIdToContracts.get(opp.Id);
            if (opp.Brand__c == contract.Brand__c && opp.AccountId == contract.Account__c) {
                continue;
            }
            if (opp.Brand__c != contract.Brand__c) {
                opp.Brand__c = contract.Brand__c;
            }
            if (opp.AccountId != contract.Account__c) {
                opp.AccountId = contract.Account__c;
            }
            oppToUpdate.add(opp);
        }
        // update opportunity.Brand_Account
        update oppToUpdate;
    }

    private void createSalesRepRecords(List<Project__c> insertedContracts) {
        Set<Id> userIds = new Set<Id>();
        Map<Id, Commission_Profile__c> userCommissionProfile = new Map<Id, Commission_Profile__c>();

        // get information from inserted records
        List<Project__c> contracts = [
            SELECT Id, CurrencyIsoCode, Gross_Profit__c, Opportunity__r.OwnerId, Opportunity__r.Additional_Rep__c, Opportunity__r.InsideSalesRep__c, Opportunity__r.Non_Salesforce_Rep__c
            FROM Project__c
            WHERE Id IN: insertedContracts
        ];

        for (Project__c contract : contracts) {
            userIds.add(contract.Opportunity__r.OwnerId);

            if (contract.Opportunity__r.Additional_Rep__c != null) {
                userIds.add(contract.Opportunity__r.Additional_Rep__c);
            }
            if (contract.Opportunity__r.InsideSalesRep__c != null) {
                userIds.add(contract.Opportunity__r.InsideSalesRep__c);
            }
        }

        for (Commission_Profile__c commissionProfile : [SELECT Id, Salesforce_User__c FROM Commission_Profile__c  WHERE Salesforce_User__c IN : userIds]) {
            userCommissionProfile.put(commissionProfile.Salesforce_User__c, commissionProfile);
        }

        if (!userCommissionProfile.isEmpty()) {
            // list of Contract_Sales_Rep__c records to insert
            List<Contract_Sales_Rep__c> salesRepList = new List<Contract_Sales_Rep__c>();

            for (Project__c p : contracts) {
                salesRepList.add(new Contract_Sales_Rep__c(
                        Contract__c   = p.Id,
                        CurrencyIsoCode = p.CurrencyIsoCode,
                        Commission_Profile__c = (userCommissionProfile.get(p.Opportunity__r.OwnerId)!=null)?userCommissionProfile.get(p.Opportunity__r.OwnerId).Id:null
                ));

                if (p.Opportunity__r.Additional_Rep__c != null) {
                    salesRepList.add(new Contract_Sales_Rep__c(
                            Contract__c   = p.Id,
                            CurrencyIsoCode = p.CurrencyIsoCode,
                            Commission_Profile__c = (userCommissionProfile.get(p.Opportunity__r.Additional_Rep__c)!=null)?userCommissionProfile.get(p.Opportunity__r.Additional_Rep__c).Id:null
                    ));
                }

                if (p.Opportunity__r.InsideSalesRep__c != null) {
                    salesRepList.add(new Contract_Sales_Rep__c(
                            Contract__c   = p.Id,
                            CurrencyIsoCode = p.CurrencyIsoCode,
                            Commission_Profile__c = (userCommissionProfile.get(p.Opportunity__r.InsideSalesRep__c)!=null)?userCommissionProfile.get(p.Opportunity__r.InsideSalesRep__c).Id:null
                    ));
                }
                if (p.Opportunity__r.Non_Salesforce_Rep__c != null) {
                    salesRepList.add(new Contract_Sales_Rep__c(
                            Contract__c   = p.Id,
                            CurrencyIsoCode = p.CurrencyIsoCode,
                            Commission_Profile__c = p.Opportunity__r.Non_Salesforce_Rep__c
                    ));
                }

            }

            if (!salesRepList.isEmpty()) {
                insert salesRepList;
            }
        }
    }

    private void updateSalesReps() {
        List<Contract_Sales_Rep__c> salesReps = [
            SELECT Commission__c, Expected_commission__c, ExpectedCommission__c, GrossProfitperRep__c, Expected_Gross_Profit_per_Rep__c, CurrencyIsoCode,
                    Contract__r.CurrencyIsoCode, Contract__r.Id
            FROM Contract_Sales_Rep__c
            WHERE Contract__c IN :idsWithInvoicesPaid
                AND Commission__c = NULL
                AND (Contract__r.Payment_Type__c != '100% Upfront' OR (Contract__r.Payment_Type__c = '100% Upfront' AND Contract__r.InvoicesPaid__c = TRUE AND
                Contract__r.Contract_Ended__c = TRUE))
        ];
        copySalesRepCommissions(salesReps);
        update salesReps;
    }

    public static void copySalesRepCommissions(List<Contract_Sales_Rep__c> salesRepsList) {
        for (Contract_Sales_Rep__c salesRep :salesRepsList) {
            if (salesRep.Commission__c == null) {
                salesRep.Commission__c = salesRep.Expected_commission__c;
            }
            salesRep.GrossProfitPerRep__c = salesRep.Expected_Gross_Profit_Per_Rep__c;
        }
    }

    private static void updateXeroIds(Map<Id, Project__c> contracts, Set<Id> contractsWithXeroIdToUpdate) {
        List<XeroContact__c> xeroContacts = [
                SELECT XeroId__c, XeroSettings__c, XeroSettings__r.Region__c
                FROM XeroContact__c
                WHERE BillingCondition__c = :Contract.BILLING_CONDITION_EXTECH
        ];

        if (!xeroContacts.isEmpty()) {
            for (Id contractId : contractsWithXeroIdToUpdate) {
                Project__c contract = contracts.get(contractId);
                contract.Xero_Id__c = xeroContacts[0].XeroId__c;
                contract.Xero_Entity__c = xeroContacts[0].XeroSettings__c;
            }
        }
    }

    private static void updateXeroObjects(Map<String, List<Id>> contractXeroId, Map<Id, Project__c> contracts) {
        for (XeroEntity__c xeroObject : [SELECT Id, XeroId__c FROM XeroEntity__c WHERE XeroId__c IN : contractXeroId.keySet()]) {
            for (Id contractId : contractXeroId.get(xeroObject.XeroId__c)) {
                contracts.get(contractId).XeroObject__c = xeroObject.Id;
            }
        }
    }
}