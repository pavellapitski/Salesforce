public with sharing class SubProjectHandler implements ITrigger{

    public static Boolean skipUpdateValidation = false;
    public static Boolean skipDeleteValidation = false;
    public static Set<Id> canEditClientSpendMode = new Set<Id>();

    public static Set<Id> projectsWithStartDateUpdated = new Set<Id>();
    public static Set<Id> projectsWithEndDateUpdated = new Set<Id>();
    public static Set<Id> projectsWithClientSpendUpdated = new Set<Id>();

    private static Set<Id> paymentIdsToForceProjectUpdate = new Set<Id>();

    public SubProjectHandler() {}

    public void bulkBefore() {}

    public void bulkAfter() {}

    public void beforeInsert(List<SObject> so) {
        System.debug('### SubProjectHandler.BEFORE_INSERT :' + so);
        List<Sub_Project__c> payments = (List<Sub_Project__c>) so;
        Map<Id, Project__c> contractsMap = new Map<Id, Project__c>(getContractsByIds(getContractIDs(payments)));

        for (Sub_Project__c payment :payments) {
            Project__c parentContract = contractsMap.get(payment.Project__c);
            if (String.isNotBlank(payment.DefaultClientServicesRepEmail__c)) {
                payment.CSEmail__c = payment.DefaultClientServicesRepEmail__c;
            }
            // we assign values from formula to text fields to avoid
            // "Unable to use this formula containing derived values because the field is included in the following roll-up summary field"
            payment.Rebate__c = payment.BillingConditionRebate__c; // assign BC's rebateRate taken from formula
            payment.Billing_Condition__c = payment.Billing_Conditions__c; // assign BC's name taken from formula
            payment.Discount_Terms__c = payment.BillingConditionDiscountTerms__c; // assign BC's discount terms taken from formula
            payment.Name = Utility.fetchName(payment.Start_Date__c, payment.End_Date__c, parentContract.Project_ID__c);

            // changes in the following values are responsible for updating related Payment__c records
            payment.Contract_Actual_Rebate__c = parentContract.Actual_Rebate__c;
            payment.Contract_Billing_Condition_Id__c = String.valueOf(parentContract.BillingCondition__c);
        }
        System.debug('### SubProjectHandler.BEFORE_INSERT END ');
    }

    public void beforeUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {
        System.debug('### SubProjectHandler.BEFORE_UPDATE :' + so.values());
        System.debug('### SubProjectHandler.BEFORE_UPDATE OLD :' + oldSo.values());
        Map<Id, Sub_Project__c> newPaymentsMap = (Map<Id, Sub_Project__c>) so;
        Map<Id, Project__c> contractsMap = new Map<Id, Project__c>(getContractsByIds(getContractIDs(newPaymentsMap.values())));

        Sub_Project__c oldPayment, newPayment;
        Set<Id> paymentsWithChangedClientSpend = new Set<Id>();
        for (Id paymentId :newPaymentsMap.keySet()) {
            oldPayment = (Sub_Project__c) oldSo.get(paymentId);
            newPayment = (Sub_Project__c) so.get(paymentId);
            Project__c parentContract = contractsMap.get(newPayment.Project__c);


            if (newPayment.XeroStatus__c == 'Authorised' && oldPayment.XeroStatus__c != 'Authorised') {
                newPayment.AuthorizationDate__c = Date.today();
            }

            if (oldPayment.Client_Spend__c != newPayment.Client_Spend__c) {
                paymentsWithChangedClientSpend.add(newPayment.Id);
            }

            if (oldPayment.Start_Date__c != newPayment.Start_Date__c || oldPayment.End_Date__c != newPayment.End_Date__c) {
                newPayment.Name = Utility.fetchName(newPayment.Start_Date__c, newPayment.End_Date__c, parentContract.Project_ID__c);
            }

            if (String.isNotBlank(newPayment.DefaultClientServicesRepEmail__c)) {
                newPayment.CSEmail__c = newPayment.DefaultClientServicesRepEmail__c;
            }
            newPayment.Invoice_Amount__c = (newPayment.RevisedAmount__c != null) ? newPayment.RevisedAmount__c : newPayment.InvoiceAmountRollUp__c;

            // we assign values from formula to text fields to avoid
            // "Unable to use this formula containing derived values because the field is included in the following roll-up summary field"
            newPayment.Rebate__c = newPayment.BillingConditionRebate__c; // assign BC's discount terms taken from formula
            newPayment.Discount_Terms__c = newPayment.BillingConditionDiscountTerms__c; // assign BC's discount terms taken from formula
            newPayment.Billing_Condition__c = newPayment.Billing_Conditions__c; // assign BC's name taken from formula

            // values below depends on Contract values
            Boolean isContractActualRebateChanged = oldPayment.Contract_Actual_Rebate__c != parentContract.Actual_Rebate__c;
            Boolean isContractBillingConditionChanged = oldPayment.Contract_Billing_Condition_Id__c != String.valueOf(parentContract.BillingCondition__c);
            if (isContractActualRebateChanged || isContractBillingConditionChanged) {
                newPayment.Contract_Actual_Rebate__c = parentContract.Actual_Rebate__c;
                newPayment.Contract_Billing_Condition_Id__c = String.valueOf(parentContract.BillingCondition__c);
                paymentIdsToForceProjectUpdate.add(paymentId);
            }
        }

        if (!paymentsWithChangedClientSpend.isEmpty()){
            for (Sub_Project__c payment :[SELECT Id, (SELECT Id FROM Projects__r) FROM Sub_Project__c WHERE Id IN :paymentsWithChangedClientSpend]) {
                if (payment.Projects__r.size() > 1 && !canEditClientSpendMode.contains(payment.Id)) {
                    newPaymentsMap.get(payment.Id).addError(Label.PaymentHasMultipleProjectsCannotEditClientSpend);
                }
            }
        }
        System.debug('### SubProjectHandler.BEFORE_UPDATE END.');
    }

    public void beforeDelete(List<SObject> so) {
        if (!skipDeleteValidation) {
            validateOnDelete(so);
        }
    }

    public void afterInsert(List<SObject> so) {
        System.debug('### SubProjectHandler.AFTER_INSERT :' + so);
        List<Sub_Project__c> payments = (List<Sub_Project__c>) so;
        validatePayments(new Map<Id, Sub_Project__c>(payments));

        Set<Id> contractIds = new Set<Id>();
        for (Sub_Project__c payment :payments) {
            contractIds.add(payment.Project__c);
        }

        Map<Id, List<OpportunityPlatform__c>> contractPlatforms = PlatformRepository.getPlatformsForContracts(contractIds);
        List<Payment__c> projectsToInsert = new List<Payment__c>();
        for (Sub_Project__c payment :payments) {
            projectsToInsert.addAll(Utility.copyPaymentDataToProject(payment, contractPlatforms));
        }
        insert projectsToInsert;
        System.debug('### SubProjectHandler.AFTER_INSERT END.');
    }

    public void afterUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {
        System.debug('### SubProjectHandler.AFTER_UPDATE :' + so.values());
        System.debug('### SubProjectHandler.AFTER_UPDATE OLD:' + so.values());
        Boolean isStartDateChanged, isEndDateChanged, isClientSpendChanged, isSyncWithXero, isPaymentTypeChanged,
                isBillingProfileChanged, isCurrencyCodeChanged, isMarginChanged, isCheckedStatusChanged, isMarginTypeChanged;
        if (!skipUpdateValidation) {
            validatePayments((Map<Id, Sub_Project__c>) so);
        }

        Sub_Project__c oldPayment, newPayment;
        Set<Id> paymentIDsToUpdateProjects = new Set<Id>();
        for (Id paymentId :so.keySet()) {
            oldPayment = (Sub_Project__c) oldSo.get(paymentId);
            newPayment = (Sub_Project__c) so.get(paymentId);

            isStartDateChanged = oldPayment.Start_Date__c != newPayment.Start_Date__c;
            isEndDateChanged = oldPayment.End_Date__c != newPayment.End_Date__c;
            isClientSpendChanged = oldPayment.Client_Spend__c != newPayment.Client_Spend__c;
            isCheckedStatusChanged = oldPayment.Checked__c != newPayment.Checked__c;
            isSyncWithXero = oldPayment.Synced_with_Xero__c != newPayment.Synced_with_Xero__c ;
            isMarginTypeChanged = oldPayment.Margin_Type__c != newPayment.Margin_Type__c;
            isPaymentTypeChanged = oldPayment.Payment_Type__c != newPayment.Payment_Type__c;
            isBillingProfileChanged = oldPayment.Account_Type__c != newPayment.Account_Type__c;
            isMarginChanged = oldPayment.Margin__c != newPayment.Margin__c;
            isCurrencyCodeChanged = oldPayment.CurrencyIsoCode != newPayment.CurrencyIsoCode;

            // changes in the following values should force updating related Payment__c records
            if (isStartDateChanged || isEndDateChanged || isClientSpendChanged || isCheckedStatusChanged || isSyncWithXero || isMarginTypeChanged ||
                    isPaymentTypeChanged || isBillingProfileChanged || isMarginChanged || isCurrencyCodeChanged) {
                paymentIDsToUpdateProjects.add(paymentId);
            }
        }

        if (!paymentIdsToForceProjectUpdate.isEmpty()) {
            paymentIDsToUpdateProjects.addAll(paymentIdsToForceProjectUpdate);
            paymentIdsToForceProjectUpdate.clear(); // clean a static variable, to make sure no subsequent trigger loops will keep the value
        }

        if (!paymentIDsToUpdateProjects.isEmpty()) {
            Map<Id, Payment__c> projectsToUpdate = new Map<Id, Payment__c>();

            updateProjectsFromPayment(paymentIDsToUpdateProjects, (Map<Id, Sub_Project__c>) so, (Map<Id, Sub_Project__c>) oldSo, projectsToUpdate);
            update projectsToUpdate.values();
        }
        System.debug('### SubProjectHandler.AFTER_UPDATE END.');
    }

    public void afterDelete(List<SObject> so) {}

    public void andFinally() {}

    private List<Project__c> getContractsByIds(Set<Id> contractIds) {
        return [
            SELECT Id, Project_ID__c, Margin__c, Actual_Rebate__c, BillingCondition__c, Account_Type__c, Payment_Type__c
            FROM Project__c
            WHERE Id IN :contractIds
        ];
    }

    private Set<Id> getContractIDs(List<Sub_Project__c> payments) {
        Set<Id> contractIDs = new Set<Id>();
        for (Sub_Project__c payment :payments) {
            contractIDs.add(payment.Project__c);
        }
        return contractIDs;
    }

    private void validateOnDelete(List<SObject> so) {
        Map<Id, Sub_Project__c> deletedPaymentsMap = new Map<Id, Sub_Project__c>((List<Sub_Project__c>) so);

        Set<Id> contractIds = getContractIDs(deletedPaymentsMap.values());
        Map<Id, Sub_Project__c> paymentsWithGapsInProjectsMap = new Map<Id, Sub_Project__c>([
            SELECT OverlapsContractDates__c, Project__r.Start_Date__c, Project__r.End_Date__c, Start_Date__c, End_Date__c
            FROM Sub_Project__c
            WHERE Project__c IN :contractIds AND Project__r.Gaps_Exist_Between_Projects__c = FALSE
        ]);

        Map<Id, List<Sub_Project__c>> paymentsForContract = new Map<Id, List<Sub_Project__c>>();
        for (Sub_Project__c payment :paymentsWithGapsInProjectsMap.values()) {
            if (!paymentsForContract.containsKey(payment.Project__c)) {
                paymentsForContract.put(payment.Project__c, new List<Sub_Project__c>());
            }
            paymentsForContract.get(payment.Project__c).add(payment);
        }

        for (Sub_Project__c payment :deletedPaymentsMap.values()) {
            if (paymentsWithGapsInProjectsMap.containsKey(payment.Id)) {
                payment = paymentsWithGapsInProjectsMap.get(payment.Id);
                if (payment.OverlapsContractDates__c) {
                    if (!SubProject.isPaymentContained(payment, paymentsForContract.get(payment.Project__c))) {
                        deletedPaymentsMap.get(payment.Id).addError(Label.PaymentCannotBeRemoved);
                    }
                }
            }
        }
    }

    private void validatePayments(Map<Id, Sub_Project__c> payments) {
        Set<Id> contractIds = getContractIDs(payments.values());

        Sub_Project__c paymentWithEarliestStartDate, paymentWithLatestEndDate;
        Decimal paymentsClientSpend;
        for (Project__c contract :[SELECT End_Date__c, Start_Date__c, Client_Spend__c, (SELECT Start_Date__c, End_Date__c, Client_Spend__c FROM Sub_Projects__r) FROM Project__c WHERE Id IN :contractIds] ) {
            paymentWithEarliestStartDate = null;
            paymentWithLatestEndDate = null;
            paymentsClientSpend = 0;

            List<Date> sortedStartDates = new List<Date>();
            Map<Date, List<Sub_Project__c>> paymentsByStartDate = new Map<Date, List<Sub_Project__c>>();

            for (Sub_Project__c payment :contract.Sub_Projects__r) {
                paymentsClientSpend += payment.Client_Spend__c;
                sortedStartDates.add(payment.Start_Date__c);

                if (!paymentsByStartDate.containsKey(payment.Start_Date__c)) {
                    paymentsByStartDate.put(payment.Start_Date__c, new List<Sub_Project__c>());
                }
                paymentsByStartDate.get(payment.Start_Date__c).add(payment);

                if (paymentWithEarliestStartDate == null) {
                    paymentWithEarliestStartDate = payment;
                } else if (payment.Start_Date__c < paymentWithEarliestStartDate.Start_Date__c) {
                    paymentWithEarliestStartDate = payment;
                }

                if (paymentWithLatestEndDate == null) {
                    paymentWithLatestEndDate = payment;
                } else if (payment.End_Date__c > paymentWithLatestEndDate.End_Date__c) {
                    paymentWithLatestEndDate = payment;
                }
            }

            if (sortedStartDates.size() > 1) {
                validatePaymentDateRanges(payments, sortedStartDates, paymentsByStartDate);
            }

            if (payments.containsKey(paymentWithEarliestStartDate.Id) && (paymentWithEarliestStartDate.Start_Date__c != contract.Start_Date__c)) {
                payments.get(paymentWithEarliestStartDate.Id).Start_Date__c.addError(Label.EarliestPaymentStartDateNotEqualContractStartDate);
            }

            if (payments.containsKey(paymentWithLatestEndDate.Id) && (paymentWithLatestEndDate.End_Date__c != contract.End_Date__c)) {
                payments.get(paymentWithLatestEndDate.Id).End_Date__c.addError(Label.LatestPaymentEndDateNotEqualContractEndDate);
            }

            if (paymentsClientSpend != contract.Client_Spend__c) {
                String errorMessage = Label.SumPaymentClientSpendNotEqualContractClientSpend;
                errorMessage += ' Contract Client Spend: ' + contract.Client_Spend__c;
                errorMessage += '. Sum of Payment Client Spends: ' + paymentsClientSpend;

                payments.values()[0].addError(errorMessage);
            }
        }
    }

    private void validatePaymentDateRanges(Map<Id, Sub_Project__c> payments, List<Date> sortedStartDates, Map<Date, List<Sub_Project__c>> paymentsByStartDate) {
        sortedStartDates.sort();

        for (Integer i = 0; i < sortedStartDates.size() - 1; i++) {
            List<Sub_Project__c> currentPayments = paymentsByStartDate.get(sortedStartDates[i]);
            List<Sub_Project__c> nextPayments = paymentsByStartDate.get(sortedStartDates[i + 1]);

            if (currentPayments.size() > 1) {
                for (Sub_Project__c payment : currentPayments) {
                    if (payments.containsKey(payment.Id)) {
                        payments.get(payment.Id).addError(Label.PaymentsOverlapping);
                    }
                }
            } else {
                Sub_Project__c currentPayment = currentPayments[0];
                Sub_Project__c nextPayment = nextPayments[0];

                if (currentPayment.End_Date__c >= nextPayment.Start_Date__c) {
                    if (payments.containsKey(currentPayment.Id)) {
                        payments.get(currentPayment.Id).End_Date__c.addError(Label.PaymentsOverlapping);
                    }
                    if (payments.containsKey(nextPayment.Id)) {
                        payments.get(nextPayment.Id).Start_Date__c.addError(Label.PaymentsOverlapping);
                    }
                }
            }
        }
    }

    private void updateProjectsFromPayment(Set<Id> paymentIDs, Map<Id, Sub_Project__c> payments, Map<Id, Sub_Project__c> oldPayments, Map<Id, Payment__c> projectsToUpdate) {
        Map<Id, Payment__c> projects = new Map<Id, Payment__c> ([
            SELECT Client_Spend__c, Start_Date__c, End_Date__c, Payment__r.Client_Spend__c, Payment__r.Start_Date__c, Payment__r.End_Date__c, Payment__c,
                    Margin_Type__c
            FROM Payment__c
            WHERE Payment__c IN :paymentIDs
        ]);

        Map<Id, List<Payment__c>> firstProjectsOnPayment = new Map<Id, List<Payment__c>>();
        Map<Id, List<Payment__c>> lastProjectsOnPayment = new Map<Id, List<Payment__c>>();
        Map<Id, Set<Id>> projectsForPayment = new Map<Id, Set<Id>>();
        for (Payment__c project :projects.values()) {
            Id paymentId = project.Payment__c;
            if (project.Start_Date__c < payments.get(paymentId).Start_Date__c || project.Start_Date__c == oldPayments.get(paymentId).Start_Date__c) {
                if (!firstProjectsOnPayment.containsKey(paymentId)) {
                    firstProjectsOnPayment.put(paymentId, new List<Payment__c>());
                }
                firstProjectsOnPayment.get(paymentId).add(project);
            }

            if (project.End_Date__c > payments.get(paymentId).End_Date__c || project.End_Date__c == oldPayments.get(paymentId).End_Date__c) {
                if (!lastProjectsOnPayment.containsKey(paymentId)) {
                    lastProjectsOnPayment.put(paymentId, new List<Payment__c>());
                }
                lastProjectsOnPayment.get(paymentId).add(project);
            }

            if (!projectsForPayment.containsKey(paymentId)) {
                projectsForPayment.put(paymentId, new Set<Id>());
            }
            projectsForPayment.get(paymentId).add(project.Id);
        }


        for (Id paymentId :paymentIDs) {
            if (firstProjectsOnPayment.containsKey(paymentId)) {
                updateFirstProjects(firstProjectsOnPayment.get(paymentId), projectsToUpdate, payments);
            }

            if (lastProjectsOnPayment.containsKey(paymentId)) {
                updateLastProjects(lastProjectsOnPayment.get(paymentId), projectsToUpdate, payments);
            }

            if (projectsForPayment.containsKey(paymentId)) {
                Sub_Project__c payment = payments.get(paymentId);
                Integer projectsUnderPaymentAmount = projectsForPayment.get(paymentId).size();
                for (Id projectId : projectsForPayment.get(paymentId)) {
                    Payment__c project;
                    // project could be changed before, check if it's true
                    if (projectsToUpdate.containsKey(projectId)) {
                        project = projectsToUpdate.get(projectId);
                    } else {
                        project = new Payment__c(Id = projectId);
                    }

                    if (String.isNotBlank(String.valueOf(payment.Margin__c))) {
                        project.Margin__c = payment.Margin__c;
                    }
                    if (String.isNotBlank(payment.Payment_Type__c)) {
                        project.Payment_Type__c = payment.Payment_Type__c;
                    }
                    if (String.isNotBlank(payment.CurrencyIsoCode)) {
                        project.CurrencyIsoCode = payment.CurrencyIsoCode;
                    }
                    if (project.Margin_Type__c != payment.Margin_Type__c) {
                        project.Margin_Type__c = payment.Margin_Type__c;
                    }
                    if (projectsUnderPaymentAmount == 1) {
                        if (project.Client_Spend__c != payments.get(paymentId).Client_Spend__c) {
                            project.Client_Spend__c = payments.get(paymentId).Client_Spend__c;
                            projectsWithClientSpendUpdated.add(project.Id);
                        }
                    }
                    projectsToUpdate.put(projectId, project);
                }
            }
        }
    }

    private void updateFirstProjects(List<Payment__c> projects, Map<Id, Payment__c> projectsToUpdate, Map<Id, Sub_Project__c> payments) {
        for (Payment__c project : projects) {
            Date newStartDate = project.Payment__r.Start_Date__c;
            if (project.End_Date__c >= newStartDate) {
                project.Start_Date__c = newStartDate;
                projectsWithStartDateUpdated.add(project.Id);

                if (!projectsToUpdate.containsKey(project.Id)) {
                    projectsToUpdate.put(project.Id, project);
                }
            } else {
                payments.get(project.Payment__c).Start_Date__c.addError(Label.PaymentStartDateBiggerThanFirstProjectEndDate);
            }
        }
    }

    private void updateLastProjects(List<Payment__c> projects, Map<Id, Payment__c> projectsToUpdate, Map<Id, Sub_Project__c> payments) {
        for (Payment__c project : projects) {
            Date newEndDate = project.Payment__r.End_Date__c;
            if (project.Start_Date__c <= newEndDate) {
                project.End_Date__c = project.Payment__r.End_Date__c;
                projectsWithEndDateUpdated.add(project.Id);

                if (!projectsToUpdate.containsKey(project.Id)) {
                    projectsToUpdate.put(project.Id, project);
                }
            } else {
                payments.get(project.Payment__c).End_Date__c.addError(Label.PaymentEndDateLowerThanLastProjectStartDate);
            }
        }
    }

}