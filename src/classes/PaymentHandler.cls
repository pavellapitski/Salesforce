public with sharing class PaymentHandler implements ITrigger {

    @TestVisible private static final String VARIABLE_KEYWORD = 'Variable';
    @TestVisible public static Map<String, BillingCondition__c> billingConditions { get {
        if (billingConditions == null) {
            billingConditions = new Map<String, BillingCondition__c>();
            for (BillingCondition__c bc :[SELECT Id, Name, RecordType.Name, Rebate_Rate__c, Rebate_Type__c, Strike_Profit__c FROM BillingCondition__c]) {
                billingConditions.put(bc.Name, bc);
            }
        }
        return billingConditions;
    } set; }

    public static Boolean skipUpdateValidation = false;
    public static Boolean skipInsertValidation = false;
    public static Boolean skipDeleteValidation = false;
    public static Boolean calculateIsOverlapping = true;

    public PaymentHandler() {}

    public void bulkBefore() {}

    public void bulkAfter() {}

    public void beforeInsert(List<SObject> so) {
        System.debug('### PaymentHandler.beforeInsert: ' + so);
        List<Payment__c> projects = (List<Payment__c>) so;
        updateStrikeIds(projects);

        Map<Id, List<Payment__c>> projectsForPayments = new Map<Id, List<Payment__c>>();
        Map<Id, List<Payment__c>> projectsForPlatforms = new Map<Id, List<Payment__c>>();
        for (Payment__c project :projects) {
            project.Platform_Type__c = project.Platform_Type_Formula__c;
            project.Platform_Prefix__c = project.PlatformPrefix__c;

            if (!projectsForPayments.containsKey(project.Payment__c)) {
                projectsForPayments.put(project.Payment__c, new List<Payment__c>());
            }
            projectsForPayments.get(project.Payment__c).add(project);

            if (!projectsForPlatforms.containsKey(project.OpportunityPlatform__c)) {
                projectsForPlatforms.put(project.OpportunityPlatform__c, new List<Payment__c>());
            }
            projectsForPlatforms.get(project.OpportunityPlatform__c).add(project);

            // the order of calculations matters
            project.InvoiceAmount__c = calculateInvoiceAmount(project);
            project.Expected_Gross_Profit_New__c = calculateExpectedGrossProfit(project);
            project.Actual_Rebate__c = calculateActualRebate(project);
            project.Actual_Gross_Profit_New__c = calculateActualGrossProfit(project);
        }

        Map<Id, OpportunityPlatform__c> oppPlatformsMap = new Map<Id, OpportunityPlatform__c>(OpportunityPlatformRepository.getByIDs(projectsForPlatforms.keySet()));

        copyFieldsFromOppPlatformToProject(projects, oppPlatformsMap);
        setVariableUnitCost(projectsForPlatforms, oppPlatformsMap);
        if (calculateIsOverlapping) {
            setIsOverlapping(projectsForPayments, new Map<Id, Payment__c>());
        }
        renameProjects(projects);
        System.debug('### PaymentHandler.beforeInsert END');
    }

    public void beforeUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {
        System.debug('### PaymentHandler.beforeUpdate NEW: ' + so.values());
        System.debug('### PaymentHandler.beforeUpdate OLD: ' + oldSo.values());
        Map<Id, Payment__c> projectsMap = new Map<Id, Payment__c>();
        for (SObject record :so.values()) {
            projectsMap.put(record.Id, (Payment__c) record);
        }

        Map<Id, List<Payment__c>> projectsForPayments = new Map<Id, List<Payment__c>>();
        Map<Id, List<Payment__c>> projectsForPlatforms = new Map<Id, List<Payment__c>>();
        Payment__c oldProject, newProject;
        for (Id idKey :projectsMap.keySet()) {
            oldProject = (Payment__c) oldSo.get(idKey);
            newProject = projectsMap.get(idKey);

            if (!projectsForPayments.containsKey(newProject.Payment__c)) {
                projectsForPayments.put(newProject.Payment__c, new List<Payment__c>());
            }
            projectsForPayments.get(newProject.Payment__c).add(newProject);

            if (!projectsForPlatforms.containsKey(newProject.OpportunityPlatform__c)) {
                projectsForPlatforms.put(newProject.OpportunityPlatform__c, new List<Payment__c>());
            }
            projectsForPlatforms.get(newProject.OpportunityPlatform__c).add(newProject);

            if (!newProject.PaymentChecked__c) {
                newProject.InvoiceAmount__c = calculateInvoiceAmount(newProject);
            }
            newProject.Platform_Prefix__c = oldProject.PlatformPrefix__c;

            // the order of calculations matters
            newProject.Expected_Gross_Profit_New__c = calculateExpectedGrossProfit(newProject);
            newProject.Actual_Rebate__c = calculateActualRebate(newProject);
            newProject.Actual_Gross_Profit_New__c = calculateActualGrossProfit(newProject);
        }

        updateStrikeIds(projectsMap.values());
        if (calculateIsOverlapping) {
            setIsOverlapping(projectsForPayments, projectsMap);
        }
        renameProjects(projectsMap.values());

        Map<Id,OpportunityPlatform__c> oppPlatforms = new Map<Id, OpportunityPlatform__c>(OpportunityPlatformRepository.getByIDs(projectsForPlatforms.keySet()));
        setVariableUnitCost(projectsForPlatforms, oppPlatforms);
        setMetrics(projectsMap.values(), oppPlatforms);
        System.debug('### PaymentHandler.beforeUpdate END');
    }

    private Decimal calculateInvoiceAmount(Payment__c project) {
        BillingCondition__c billingCondition = PaymentHandler.billingConditions.get(project.BillingCondition__c);
        Boolean isNormalBillingCondition = billingCondition.RecordType.Name == 'Normal',
                isRebateBillingCondition = billingCondition.RecordType.Name == 'Rebate',
                isInstantRebate = billingCondition.Rebate_Type__c == 'Instant'; //billingCondition.Name.contains('Instant Rebate');*/

        Decimal strikeProfit = (isRebateBillingCondition) ? billingCondition.Strike_Profit__c/100 : null,
                maxCPA = (project.CostStructure__c != null && project.CostStructure__c.contains('CPM') && project.UnitCost__c != null) ? project.UnitCost__c/1000 : project.UnitCost__c;

        return calculateInvoiceAmount(
            project.Account_Type__c,
            project.Margin_Type__c,
            isNormalBillingCondition,
            isRebateBillingCondition,
            isInstantRebate,
            project.Quantity__c,
            project.AmountDelivered__c,
            project.Media_Order__c,
            project.AdWordsSpend__c,
            maxCPA,
            project.Client_Spend__c,
            project.Margin__c/100,
            strikeProfit
        );
    }

    private static Decimal calculateInvoiceAmount(
            String billingProfile,  // "Strike" or "Client"
            String marginType,      // "% of Budget" or "% of Media"
            Boolean isNormalBillingCondition,
            Boolean isRebateBillingCondition,
            Boolean isInstantRebate,
            Decimal ordered,
            Decimal delivered,
            Decimal mediaOrder,
            Decimal mediaSpend,
            Decimal maxCPA,
            Decimal clientSpend,
            Decimal margin,
            Decimal strikeProfit
    ) {
        Decimal invoiceAmount = 0, marginTypeCoefficient = 1;
        if (marginType == '% of Budget') {
            marginTypeCoefficient = 1/(1 - margin);
        } else if (marginType == '% of Media') {
            marginTypeCoefficient = (1 + margin);
        }

        System.debug('### INV_AMOUNT / strikeProfit: ' + strikeProfit +
                + ' / mType: ' + marginType + ' / maxCPA: ' + maxCPA + ' / clientSpend: ' + clientSpend + ' / mediaOrder: ' + mediaOrder
                + ' / mediaSpend:' + mediaSpend + ' / delivered: ' + delivered + ' / ordered: ' + ordered + ' / marginTypeCoefficient: ' + marginTypeCoefficient);

        clientSpend = (clientSpend == null) ? 0 : clientSpend; // for new project client spend can be zero

        if (billingProfile == Utility.BILLING_PROFILES.Strike.name()) {
            if (isNormalBillingCondition) {
                if (maxCPA != null) {
                    if (delivered >= ordered) {
                        System.debug('### SCENARIO 1');
                        invoiceAmount = clientSpend;
                    } else {
                        System.debug('### SCENARIO 2');
                        invoiceAmount = delivered * maxCPA;
                    }
                } else {
                    System.debug('### SCENARIO 3 / 4');
                    invoiceAmount = mediaSpend * marginTypeCoefficient;
                }
            } else if (isRebateBillingCondition) {
                if (maxCPA != null) {
                    if (delivered >= ordered && mediaSpend >= mediaOrder || isInstantRebate) {
                        System.debug('### SCENARIO 5');
                        invoiceAmount = (clientSpend - mediaSpend) * strikeProfit + mediaSpend;
                    } else {
                        if (marginType == '% of Budget') {
                            if (delivered >= ordered && mediaSpend < mediaOrder) {
                                System.debug('### SCENARIO 6');
                                invoiceAmount = mediaSpend * margin * marginTypeCoefficient * strikeProfit + mediaSpend;
                            } else if (delivered < ordered && mediaSpend * marginTypeCoefficient >= (delivered * maxCPA)) {
                                System.debug('### SCENARIO 7');
                                invoiceAmount = (clientSpend * (delivered/ordered) - mediaSpend) * strikeProfit + mediaSpend;
                            } else if (delivered < ordered && mediaSpend * marginTypeCoefficient < (delivered * maxCPA)) {
                                System.debug('### SCENARIO 8');
                                invoiceAmount = mediaSpend * margin * marginTypeCoefficient * strikeProfit + mediaSpend;
                            }
                        } else if (marginType == '% of Media') {
                            if (delivered >= ordered && mediaSpend < mediaOrder) {
                                System.debug('### SCENARIO 9');
                                invoiceAmount = mediaSpend * margin * strikeProfit + mediaSpend;
                            } else if (delivered < ordered && mediaSpend * marginTypeCoefficient >= (delivered * maxCPA)) {
                                System.debug('### SCENARIO 10');
                                invoiceAmount = (clientSpend * (delivered/ordered) - mediaSpend) * strikeProfit + mediaSpend;
                            } else if (delivered < ordered && mediaSpend * marginTypeCoefficient < (delivered * maxCPA)) {
                                System.debug('### SCENARIO 11');
                                invoiceAmount = mediaSpend * margin * strikeProfit + mediaSpend;
                            }
                        }
                    }
                } else {
                    if (mediaSpend >= mediaOrder || isInstantRebate) {
                        System.debug('### SCENARIO 12');
                        invoiceAmount = (clientSpend - mediaSpend) * strikeProfit + mediaSpend;
                    } else {
                        if (marginType == '% of Budget') {
                            System.debug('### SCENARIO 13');
                            invoiceAmount = mediaSpend * margin * marginTypeCoefficient * strikeProfit + mediaSpend;
                        } else if (marginType == '% of Media') {
                            System.debug('### SCENARIO 14');
                            invoiceAmount = mediaSpend * margin * strikeProfit + mediaSpend;
                        }
                    }
                }
            }
        } else if (billingProfile == Utility.BILLING_PROFILES.Client.name()) {
            if (isNormalBillingCondition) {
                if (maxCPA != null) {
                    if (delivered >= ordered && mediaSpend >= mediaOrder) {
                        System.debug('### SCENARIO 15');
                        invoiceAmount = clientSpend - mediaSpend;
                    }
                    if (marginType == '% of Budget') {
                        if (delivered >= ordered && mediaSpend < mediaOrder) {
                            System.debug('### SCENARIO 16');
                            invoiceAmount = mediaSpend * margin * marginTypeCoefficient;
                        } else if (delivered < ordered && mediaSpend * marginTypeCoefficient >= (delivered * maxCPA)) {
                            System.debug('### SCENARIO 17');
                            invoiceAmount = clientSpend * (delivered/ordered) - mediaSpend;
                        } else if (delivered < ordered && mediaSpend * marginTypeCoefficient < (delivered * maxCPA)) {
                            System.debug('### SCENARIO 18');
                            invoiceAmount = mediaSpend * margin * marginTypeCoefficient;
                        }
                    } else if (marginType == '% of Media') {
                        if (delivered >= ordered && mediaSpend < mediaOrder) {
                            System.debug('### SCENARIO 19');
                            invoiceAmount = mediaSpend * margin;
                        } else if (delivered < ordered && mediaSpend * marginTypeCoefficient >= (delivered * maxCPA)) {
                            System.debug('### SCENARIO 20');
                            invoiceAmount = clientSpend * (delivered/ordered) - mediaSpend;
                        } else if (delivered < ordered && mediaSpend * marginTypeCoefficient < (delivered * maxCPA)) {
                            System.debug('### SCENARIO 21');
                            invoiceAmount = mediaSpend * margin * marginTypeCoefficient;
                        }
                    }
                } else {
                    if (mediaSpend >= mediaOrder) {
                        System.debug('### SCENARIO 22');
                        invoiceAmount = clientSpend - mediaSpend;
                    } else {
                        if (marginType == '% of Budget') {
                            System.debug('### SCENARIO 23');
                            invoiceAmount = mediaSpend * margin * marginTypeCoefficient;
                        } else if (marginType == '% of Media') {
                            System.debug('### SCENARIO 24');
                            invoiceAmount = mediaSpend * margin;
                        }
                    }
                }
            } else if (isRebateBillingCondition) {
                if (maxCPA != null) {
                    if (delivered >= ordered && mediaSpend >= mediaOrder || isInstantRebate) {
                        System.debug('### SCENARIO 25');
                        invoiceAmount = (clientSpend - mediaSpend) * strikeProfit;
                    } else {
                        if (marginType == '% of Budget') {
                            if (delivered >= ordered && mediaSpend < mediaOrder) {
                                System.debug('### SCENARIO 26');
                                invoiceAmount = mediaOrder * margin * marginTypeCoefficient * strikeProfit;
                            } else if (delivered < ordered && mediaSpend * marginTypeCoefficient >= (delivered * maxCPA)) {
                                System.debug('### SCENARIO 27');
                                invoiceAmount = (clientSpend * (delivered/ordered) - mediaSpend) * strikeProfit;
                            } else if (delivered < ordered && mediaSpend * marginTypeCoefficient < (delivered * maxCPA)) {
                                System.debug('### SCENARIO 28');
                                invoiceAmount = mediaSpend * margin * marginTypeCoefficient * strikeProfit;
                            }
                        } else if (marginType == '% of Media') {
                            if (delivered >= ordered && mediaSpend < mediaOrder) {
                                System.debug('### SCENARIO 29');
                                invoiceAmount = mediaOrder * margin * strikeProfit;
                            } else if (delivered < ordered && mediaSpend * marginTypeCoefficient >= (delivered * maxCPA)) {
                                System.debug('### SCENARIO 30');
                                invoiceAmount = (clientSpend * (delivered/ordered) - mediaSpend) * strikeProfit;
                            } else if (delivered < ordered && mediaSpend * marginTypeCoefficient < (delivered * maxCPA)) {
                                System.debug('### SCENARIO 31');
                                invoiceAmount = mediaSpend * margin * strikeProfit;
                            }
                        }
                    }
                } else {
                    if (mediaSpend >= mediaOrder /*|| isInstantRebate*/) {
                        System.debug('### SCENARIO 35');
                        invoiceAmount = (clientSpend - mediaSpend) * strikeProfit;
                    } else {
                        if (marginType == '% of Budget') {
                            System.debug('### SCENARIO 33');
                            invoiceAmount = mediaSpend * margin * marginTypeCoefficient * strikeProfit;
                        } else if (marginType == '% of Media') {
                            System.debug('### SCENARIO 34');
                            invoiceAmount = mediaSpend * margin * strikeProfit;
                        }
                    }
                }
            }
        }
        return invoiceAmount;
    }

    private Decimal calculateExpectedGrossProfit(Payment__c project) {
        String billingCondition = project.BillingCondition__c,
                marginType = project.Margin_Type__c;
        Decimal expectedGrossProfit = 0,
                clientSpend = (project.Client_Spend__c == null) ? 0 : project.Client_Spend__c,
                mediaOrder = project.Media_Order__c,
                rebateRate = project.Rebate_Rate__c/100,
                strikeProfit = project.Strike_Profit__c/100;

        if (billingCondition.contains('Instant Rebate')) {
            expectedGrossProfit = (clientSpend - mediaOrder) * (1 - strikeProfit);
        } else {
            if (marginType == '% of Media') {
                expectedGrossProfit = (clientSpend - mediaOrder) -  (mediaOrder * rebateRate);
            } else {
                expectedGrossProfit = (clientSpend - mediaOrder) -  (clientSpend * rebateRate);
            }
        }
        return expectedGrossProfit;
    }

    private Decimal calculateActualRebate(Payment__c project) {
        Decimal clientSpend = (project.Client_Spend__c == null) ? 0 : project.Client_Spend__c,
                mediaSpend = project.AdWordsSpend__c,
                invoiceAmount = project.InvoiceAmount__c,
                margin = project.Margin__c/100,
                strikeProfit = project.Strike_Profit__c/100,
                rebateRate = project.Rebate_Rate__c/100,
                actualRebate = 0;

        String billingCondition = project.BillingCondition__c,
                marginType = project.Margin_Type__c,
                billingProfile = project.Account_Type__c;

        if (billingCondition.startsWith('Instant Rebate')) {
            actualRebate = (clientSpend - mediaSpend) * (1 - strikeProfit);
        } else if (billingCondition.startsWith('Margin Split')) {
            if (billingProfile == Utility.BILLING_PROFILES.Client.name()) {
                actualRebate = invoiceAmount * (1 - strikeProfit);
            } else if (billingProfile == Utility.BILLING_PROFILES.Strike.name()) {
                actualRebate = (invoiceAmount - mediaSpend) * (1 - strikeProfit);
            }
        } else if (billingCondition.startsWith('Rebate')) {
            if (marginType == '% of Budget') {
                if (billingProfile == Utility.BILLING_PROFILES.Client.name()) {
                    actualRebate = (invoiceAmount / margin) * rebateRate;
                } else if (billingProfile == Utility.BILLING_PROFILES.Strike.name()) {
                    actualRebate = clientSpend * rebateRate;
                }
            } else if (marginType == '% of Media') {
                if (billingProfile == Utility.BILLING_PROFILES.Client.name()) {
                    actualRebate = (mediaSpend  + invoiceAmount) * rebateRate;
                } else if (billingProfile == Utility.BILLING_PROFILES.Strike.name()) {
                    actualRebate = (mediaSpend + mediaSpend * margin) * rebateRate;
                }
            }
        }
        return actualRebate;
    }

    private Decimal calculateActualGrossProfit(Payment__c project) {
        String billingCondition = project.BillingCondition__c,
                marginType = project.Margin_Type__c,
                billingProfile = project.Account_Type__c;

        Decimal actualGrossProfit = 0,
                clientSpend = (project.Client_Spend__c == null) ? 0 : project.Client_Spend__c,
                mediaSpend = project.AdWordsSpend__c,
                rebateRate = project.Rebate_Rate__c/100,
                discount = project.Discount__c,
                strikeProfit = project.Strike_Profit__c/100,
                invoiceAmount = project.InvoiceAmount__c,
                actualRebate = project.Actual_Rebate__c;
                // strikeFinalMargin = project.Strike_Final_Margin__c/100,
                // contractClientSpend = project.C_ClientSpend__c,

        if ((project.P_SyncedWithXero__c || project.P_Checked__c) && Date.today() >= project.End_Date__c) {
            if (billingCondition.startsWith('Instant Rebate')) {
                // for  "Instant Rebate" billing condition
                actualGrossProfit = (clientSpend - mediaSpend) * (1 - strikeProfit);
            } else if (billingCondition.startsWith('Margin Split')) {
                // for all "Margin Split" billing conditions
                if (billingProfile == 'Client') {
                    actualGrossProfit = invoiceAmount * strikeProfit;
                } else if (billingProfile == 'Strike') {
                    actualGrossProfit = (clientSpend - mediaSpend ) * strikeProfit;
                }
            } else if (billingCondition.startsWith('Rebate')) {
                // for all "Rebate" billing conditions
                if (billingProfile == 'Client') {
                    actualGrossProfit = invoiceAmount - actualRebate;
                } else if (billingProfile == 'Strike') {
                    actualGrossProfit = invoiceAmount - mediaSpend - actualRebate;
                }
            } else {
                // for  "Normal" billing condition
                if (marginType == '% of Media') {
                    if (billingProfile == 'Client') {
                        actualGrossProfit = invoiceAmount;
                    } else if (billingProfile == 'Strike') {
                        // TODO: ask if formula correct?
                        actualGrossProfit = (clientSpend - mediaSpend) - (mediaSpend * rebateRate);
                    }
                } else if (marginType == '% of Budget') {
                    if (billingProfile == 'Client') {
                        // TODO: ask if formula correct?
                        actualGrossProfit = (clientSpend - mediaSpend) - (clientSpend * rebateRate);
                    } else if (billingProfile == 'Strike') {
                        actualGrossProfit = invoiceAmount - mediaSpend;
                    }
                }
            }
        } else {
            actualGrossProfit = project.Expected_Gross_Profit_New__c;
        }
        return actualGrossProfit - discount;
    }

    public void beforeDelete(List<SObject> so) {
        List<Payment__c> projects = (List<Payment__c>) so;
        for (Payment__c project :projects) {
            if (!skipDeleteValidation && project.Start_Date__c != null && project.Start_Date__c <= System.today()) {
                project.addError(Label.CannotRemoveStartedProject);
            }
        }
    }

    public void afterInsert(List<SObject> so) {
        System.debug('### PaymentHandler.afterInsert :' + so);
        List<Payment__c> projects = (List<Payment__c>) so;
        if (!skipInsertValidation) {
            validateProjects(new Map<Id, Payment__c> (projects));
        }
        reassignSpends(projects);
        markForMMSync(projects);

        MonthlyDistribution.createMonthlyDistribution(projects);
        System.debug('### PaymentHandler.afterInsert END');
    }

    public void afterUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {
        System.debug('### PaymentHandler.afterUpdate :' + so.values());
        List<Payment__c> updatedProjects = new List<Payment__c>();
        if (!skipUpdateValidation) {
            validateProjects((Map<Id, Payment__c>)so);
        }

        List<Payment__c> newDatesForSubProjects = new List<Payment__c>();
        for (Id id :so.keySet()) {
            Payment__c oldProject = (Payment__c) oldSo.get(id);
            Payment__c newProject = (Payment__c) so.get(id);

            if (oldProject.Start_Date__c != newProject.Start_Date__c || oldProject.End_Date__c != newProject.End_Date__c) {
                newDatesForSubProjects.add(newProject);
            }
            if (newProject.ShouldSyncWithMM__c && (oldProject.Client_Spend__c != newProject.Client_Spend__c ||
                oldProject.End_Date__c != newProject.End_Date__c ||
                oldProject.Start_Date__c != newProject.Start_Date__c ||
                oldProject.Payment__c != newProject.Payment__c ||
                oldProject.Project__c != newProject.Project__c ||
                oldProject.ProjectID__c != newProject.ProjectID__c ||
                oldProject.StrikeId__c != newProject.StrikeId__c ||
                oldProject.IsOverlapping__c != newProject.IsOverlapping__c))
            {
                updatedProjects.add(newProject);
            }
        }

        if (!updatedProjects.isEmpty()) {
            markForMMSync(updatedProjects);
        }

        if (!newDatesForSubProjects.isEmpty()) {
            reassignSpends(newDatesForSubProjects);
        }

        MonthlyDistribution.createMonthlyDistribution(((Map<Id,Payment__c>) so).values());
        System.debug('### PaymentHandler.afterUpdate END');
    }

    public void afterDelete(List<SObject> so) {
        List<Payment__c> projects = (List<Payment__c>)so;
        if (!skipDeleteValidation) {
            validateOnDelete(projects);
        }
    }

    public void andFinally() {}

    private static void markForMMSync(List<Payment__c> projects) {
        Map<Id, Project__c> contractsToSyncWithMM = new Map<Id, Project__c>();
        for (Payment__c project :projects) {
            if (project.ShouldSyncWithMM__c) {
                contractsToSyncWithMM.put(project.ContractId__c, new Project__c(Id = project.ContractId__c, PerformMMSync__c = true));
            }
        }
        System.debug('### markForMMSync : ' + contractsToSyncWithMM);
        update contractsToSyncWithMM.values();
    }

    private void renameProjects(List<Payment__c> projects) {
        Set<Id> paymentIdSet = new Set<Id>();
        for (Payment__c project : projects) {
            if (String.isNotBlank(project.Payment__c)) {
                paymentIdSet.add(project.Payment__c);
            }
        }
        Map<Id, Sub_Project__c> idToPaymentMap = new Map<Id, Sub_Project__c>([SELECT Id, Project__r.Project_ID__c FROM Sub_Project__c WHERE Id IN: paymentIdSet]);
        String startDate, endDate, newName;
        for (Payment__c project : projects) {
            if (idToPaymentMap.containsKey(project.Payment__c)) {
                String strikeId = project.ApplyStrikeIdSuffix__c ? project.StrikeId__c : project.ProjectID__c;

                startDate = String.isNotBlank(String.valueOf(project.Start_Date__c)) ? String.valueOf(project.Start_Date__c).replaceAll('-', '.') : '';
                endDate   = String.isNotBlank(String.valueOf(project.End_Date__c)) ? String.valueOf(project.End_Date__c).replaceAll('-', '.') : '';
                newName   = '[' + strikeId + ' - ' + startDate + ' - ' + endDate + ']';
                project.Name = newName;
            }
        }
    }

    private void validateProjects(Map<Id, Payment__c> projects) {
        Set<Id> paymentIds = new Set<Id>();
        for (Payment__c project :projects.values()) {
            if (!String.isBlank(project.Payment__c)) {
                paymentIds.add(project.Payment__c);
            }
        }

        List<Sub_Project__c> payments = SubProjectRepository.getPaymentsByIDsWithProjects(paymentIds);
        for (Sub_Project__c payment :payments) {
            Payment__c projectWithEarliestStartDate = null;
            Payment__c projectWithLatestEndDate = null;
            Decimal projectsClientSpend = 0;
            List<Date> sortedStartDates = new List<Date>();
            Map<Date, List<Payment__c>> projectsByStartDate = new Map<Date, List<Payment__c>>();

            for (Payment__c project : payment.Projects__r) {
                projectsClientSpend += project.Client_Spend__c;
                sortedStartDates.add(project.Start_Date__c);

                if (!projectsByStartDate.containsKey(project.Start_Date__c)) {
                    projectsByStartDate.put(project.Start_Date__c, new List<Payment__c> {project});
                } else {
                    projectsByStartDate.get(project.Start_Date__c).add(project);
                }

                if (projectWithEarliestStartDate == null) {
                    projectWithEarliestStartDate = project;
                } else if (project.Start_Date__c < projectWithEarliestStartDate.Start_Date__c) {
                    projectWithEarliestStartDate = project;
                }

                if (projectWithLatestEndDate == null) {
                    projectWithLatestEndDate = project;
                } else if (project.End_Date__c > projectWithLatestEndDate.End_Date__c) {
                    projectWithLatestEndDate = project;
                }
            }

            if (sortedStartDates.size() > 1) {
                validateProjectDateRanges(payment, projects, sortedStartDates, projectsByStartDate);
            }

            if (projects.containsKey(projectWithEarliestStartDate.Id) && (projectWithEarliestStartDate.Start_Date__c != payment.Start_Date__c)) {
                projects.get(projectWithEarliestStartDate.Id).Start_Date__c.addError(Label.EarliestProjectStartDateNotEqualPaymentStartDate);
            }

            if (projects.containsKey(projectWithLatestEndDate.Id) && (projectWithLatestEndDate.End_Date__c != payment.End_Date__c)) {
                projects.get(projectWithLatestEndDate.Id).End_Date__c.addError(Label.LatestProjectEndDateNotEqualPaymentEndDate);
            }

            if (projectsClientSpend != payment.Client_Spend__c) {
                String errorMessage = Label.SumProjectClientSpendNotEqualPaymentClientSpend;
                errorMessage += ' Payment Client Spend: ' + payment.Client_Spend__c;
                errorMessage += '. Sum of Projects Client Spends: ' + projectsClientSpend;
                projects.values()[0].addError(errorMessage);
            }
        }
    }

    private void validateProjectDateRanges(Sub_Project__c payment, Map<Id, Payment__c> projects, List<Date> sortedStartDates, Map<Date, List<Payment__c>> projectsByStartDate) {
        sortedStartDates.sort();

        for (Integer i = 0; i < sortedStartDates.size() - 1; i++) {
            List<Payment__c> currentProjects = projectsByStartDate.get(sortedStartDates[i]);
            List<Payment__c> nextProjects = projectsByStartDate.get(sortedStartDates[i + 1]);

            Payment__c currentProject = currentProjects[0];
            Payment__c nextProject = nextProjects[0];

            if (!payment.Project__r.Gaps_Exist_Between_Projects__c && (currentProject.End_Date__c.addDays(1) < nextProjects[0].Start_Date__c)) {
                if (projects.containsKey(currentProject.Id)) {
                    projects.get(currentProject.Id).End_Date__c.addError(Label.ProjectGaps);
                }
                if (projects.containsKey(nextProject.Id)) {
                    projects.get(nextProject.Id).Start_Date__c.addError(Label.ProjectGaps);
                }
            }
        }
    }

    private static void updateStrikeIds(List<Payment__c> projects) {
        Map<String, List<Payment__c>> projectsForPayment = new Map<String, List<Payment__c>>();

        Map<String, Map<Date, List<Payment__c>>> projectsByPlatformAndStartDate = new Map<String, Map<Date, List<Payment__c>>>();
        Map<String, List<Date>> sortedStartDates = new Map<String, List<Date>>();
        Set<String> currentProjects = new Set<String>();

        List<String> alphabet = new List<String> {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'};

        for (Payment__c project : projects) {
            if (String.isBlank(project.StrikeId__c) || (!String.isBlank(project.PlatformPrefix__c) && !project.StrikeId__c.startsWith(project.PlatformPrefix__c))) {
                if (!projectsForPayment.containsKey(project.Payment__c)) {
                    projectsForPayment.put(project.Payment__c, new List<Payment__c> {project});
                } else {
                    projectsForPayment.get(project.Payment__c).add(project);
                }

                if (!String.isBlank(project.Id)) {
                    currentProjects.add(project.Id);
                }

                if (!projectsByPlatformAndStartDate.containsKey(project.PlatformId__c)) {
                    projectsByPlatformAndStartDate.put(project.PlatformId__c, new Map<Date, List<Payment__c>> {project.Start_Date__c => new List<Payment__c> {project}});
                    sortedStartDates.put(project.PlatformId__c, new List<Date> {project.Start_Date__c});
                } else {
                    Map<Date, List<Payment__c>> projectsByStartDate = projectsByPlatformAndStartDate.get(project.PlatformId__c);
                    if (!projectsByStartDate.containsKey(project.Start_Date__c)) {
                        projectsByStartDate.put(project.Start_Date__c, new List<Payment__c> {project});
                        sortedStartDates.get(project.PlatformId__c).add(project.Start_Date__c);
                    } else {
                        projectsByStartDate.get(project.Start_Date__c).add(project);
                    }
                }
            }
        }

        for (List<Date> startDates : sortedStartDates.values()) {
            startDates.sort();
        }

        List<Payment__c> payments = [
            SELECT Payment__c, ProjectID__c, StrikeId__c, PlatformId__c
            FROM Payment__c
            WHERE Payment__c IN :projectsForPayment.keySet() AND Id NOT IN :currentProjects
            ORDER BY Start_Date__c
        ];

        Map<String, Map<String, Map<String, Payment__c>>> projectsByPlatformAndStrikeIdSuffix = new Map<String, Map<String, Map<String, Payment__c>>>();
        for (Payment__c project :payments) {
            if (!String.isBlank(project.StrikeId__c) && project.StrikeId__c.length() > project.ProjectID__c.length()) {
                String suffix = project.StrikeId__c.substringAfter(project.ProjectID__c);
                if (!projectsByPlatformAndStrikeIdSuffix.containsKey(project.PlatformId__c)) {
                    projectsByPlatformAndStrikeIdSuffix.put(project.PlatformId__c, new Map<String, Map<String, Payment__c>> {project.Payment__c => new Map<String, Payment__c> { suffix => project }});
                } else {
                    Map<String, Map<String, Payment__c>> projectsByStrikeIdSuffix = projectsByPlatformAndStrikeIdSuffix.get(project.PlatformId__c);

                    if (!projectsByStrikeIdSuffix.containsKey(project.Payment__c)) {
                        projectsByStrikeIdSuffix.put(project.Payment__c, new Map<String, Payment__c> {suffix => project});
                    } else {
                        projectsByStrikeIdSuffix.get(project.Payment__c).put(suffix, project);
                    }
                }
            }
        }

        for (String platformId : sortedStartDates.keySet()) {
            List<Date> startDates = sortedStartDates.get(platformId);
            Map<Date, List<Payment__c>> projectsByStartdate = projectsByPlatformAndStartDate.get(platformId);
            Map<String, Map<String, Payment__c>> projectsByStrikeIdSuffix = new Map<String, Map<String, Payment__c>>();

            if (projectsByPlatformAndStrikeIdSuffix.containsKey(platformId)) {
                projectsByStrikeIdSuffix = projectsByPlatformAndStrikeIdSuffix.get(platformId);
            } else {
                projectsByPlatformAndStrikeIdSuffix.put(platformId, projectsByStrikeIdSuffix);
            }

            for (Date startDate : startDates) {
                for (Payment__c project : projectsByStartdate.get(startDate)) {
                    if (projectsByStrikeIdSuffix.containsKey(project.Payment__c)) {
                        Map<String, Payment__c> existingProjects = projectsByStrikeIdSuffix.get(project.Payment__c);
                        for (String letter : alphabet) {
                            if (!existingProjects.containsKey(letter)) {
                                project.StrikeId__c = project.ProjectID__c + letter;
                                break;
                            }
                        }

                        projectsByStrikeIdSuffix.get(project.Payment__c).put(project.StrikeId__c.substringAfter(project.ProjectID__c), project);
                    } else {
                        project.StrikeId__c = project.ProjectID__c + 'A';
                        projectsByStrikeIdSuffix.put(project.Payment__c, new Map<String, Payment__c> { 'A' => project });
                    }
                }
            }
        }
    }

    private void reassignSpends(List<Payment__c> projects) {
        Set<String> contractIds = new Set<String>();
        for (Payment__c project :projects) {
            contractIds.add(project.Project__c);
        }

        MMSpendingsHandler.skipProjectMediaSpendCreation = true;
        delete [SELECT Id FROM Project_Media_Spend__c WHERE Project__c IN :projects];
        MMSpendingsHandler.skipProjectMediaSpendCreation = false;

        List<Project_Media_Spend__c> pmsToInsert = new List<Project_Media_Spend__c>();
        List<MM_Spendings__c> relatedMMs = [SELECT Date__c, Delivered__c, Media_Spend__c, CurrencyIsoCode, Strike_ID__c, StrikeId__c, Id FROM MM_Spendings__c WHERE Contract__c IN :contractIds];
        for (Payment__c project : projects) {
            for (MM_Spendings__c mediaSpend :relatedMMs) {
                Boolean strikeIdMatched = false;

                if (!String.isBlank(mediaSpend.StrikeId__c)) {
                    strikeIdMatched = project.StrikeId__c.contains(mediaSpend.StrikeId__c);
                } else if (project.StrikeId__c.contains(mediaSpend.Strike_ID__c)) {
                    strikeIdMatched = true;
                }

                if (strikeIdMatched && mediaSpend.Date__c >= project.Start_Date__c && mediaSpend.Date__c <= project.End_Date__c) {
                    pmsToInsert.add(new Project_Media_Spend__c (
                        Project__c  = project.Id,
                        Date__c = mediaSpend.Date__c,
                        Delivered__c  = mediaSpend.Delivered__c,
                        Amount__c  = mediaSpend.Media_Spend__c,
                        CurrencyIsoCode = mediaSpend.CurrencyIsoCode,
                        MMSpending__c = mediaSpend.Id
                    ));
                }
            }
        }
        insert pmsToInsert;
    }

    private static void validateOnDelete(List<Payment__c> projects) {
        Map<Id, List<Payment__c>> projectsForPayment = new Map<Id, List<Payment__c>>();

        for (Payment__c project : projects) {
            if (!projectsForPayment.containsKey(project.Payment__c)) {
                projectsForPayment.put(project.Payment__c, new List<Payment__c> {project});
            } else {
                projectsForPayment.get(project.Payment__c).add(project);
            }
        }

        List<Sub_Project__c> subProjects = [SELECT Id, (SELECT Id FROM Projects__r) FROM Sub_Project__c WHERE Id IN :projectsForPayment.keySet()];
        for (Sub_Project__c payment : subProjects) {
            if (payment.Projects__r.isEmpty()) {
                for (Payment__c project : projectsForPayment.get(payment.Id)) {
                    project.addError(Label.CannotRemoveLastProject);
                }
            }
        }
    }

    private void setIsOverlapping(Map<Id, List<Payment__c>> projectsForPayments, Map<Id, Payment__c> newMap) {
        List<Payment__c> projectsToUpdate = new List<Payment__c>();

        List<Payment__c> payments = [
            SELECT Id, Start_Date__c, End_Date__c, IsOverlapping__c, Payment__c, OpportunityPlatform__c, PlatformPrefix__c
            FROM Payment__c
            WHERE Payment__c IN :projectsForPayments.keySet() AND Id NOT IN :newMap.keySet()
        ];

        for (Payment__c proj :payments) {
            projectsForPayments.get(proj.Payment__c).add(proj);
        }

        for (Id paymentId : projectsForPayments.keySet()) {
            for (Payment__c project : projectsForPayments.get(paymentId)) {
                Boolean initialIsOverlapping = project.IsOverlapping__c;
                Boolean isOverlapping = false;

                for (Payment__c otherProject : projectsForPayments.get(paymentId)) {
                    Boolean isDifferent = (project.Id != otherProject.Id);
                    Boolean isPrefixEqual = (project.OpportunityPlatform__c == null || project.PlatformPrefix__c == otherProject.PlatformPrefix__c);
                    Boolean overlapCondition1 = (project.Start_Date__c >= otherProject.Start_Date__c && project.Start_Date__c <= otherProject.End_Date__c);
                    Boolean overlapCondition2 = (project.End_Date__c >= otherProject.Start_Date__c && project.End_Date__c <= otherProject.End_Date__c);
                    Boolean overlapCondition3 = (otherProject.Start_Date__c >= project.Start_Date__c && otherProject.Start_Date__c <= project.End_Date__c);
                    Boolean overlapCondition4 = (otherProject.End_Date__c >= project.Start_Date__c && otherProject.End_Date__c <= project.End_Date__c);

                    if (isDifferent && isPrefixEqual &&  (overlapCondition1 || overlapCondition2 || overlapCondition3 || overlapCondition4)) {
                        isOverlapping = true;
                        project.IsOverlapping__c = true;
                    }
                }
                if (!isOverlapping) {
                    project.IsOverlapping__c = false;
                }
                if (String.isNotBlank(project.Id) && !newMap.containsKey(project.Id) && isOverlapping != initialIsOverlapping) {
                    projectsToUpdate.add(project);
                }
            }
        }
        calculateIsOverlapping = false;
        update projectsToUpdate;
    }

    private static void setVariableUnitCost(Map<Id,List<Payment__c>> projectsForPlatforms, Map<Id,OpportunityPlatform__c> oppPlatforms) {
        for (OpportunityPlatform__c oppPlatform :oppPlatforms.values()) {
            List<Payment__c> projects = projectsForPlatforms.get(oppPlatform.Id);
            for (Payment__c project :projects) {
                if (String.isNotBlank(project.CostStructure__c)) {
                    project.VariableUnitCost__c = Boolean.valueOf(oppPlatform.get(VARIABLE_KEYWORD + project.CostStructure__c + '__c'));
                }
            }
        }
    }

    private void copyFieldsFromOppPlatformToProject(List<Payment__c> projects, Map<Id,OpportunityPlatform__c> oppPlatforms) {
        for (Payment__c project :projects) {
            OpportunityPlatform__c oppPlatform = oppPlatforms.get(project.OpportunityPlatform__c);
            if (oppPlatform == null) continue;

            if (oppPlatform.KPI__c != null) project.KPI__c = oppPlatform.KPI__c;
            if (oppPlatform.CTA_Overlay_Text__c != null) project.CTA_Overlay_Text__c = oppPlatform.CTA_Overlay_Text__c;
            if (oppPlatform.Pixel_Tracking__c != null) project.Pixel_Tracking__c = oppPlatform.Pixel_Tracking__c;
            if (oppPlatform.Companion_Banner__c != null) project.Companion_Banner__c = oppPlatform.Companion_Banner__c;
            if (oppPlatform.Opportunity__c != null) project.Opportunity__c = oppPlatform.Opportunity__c;
            if (oppPlatform.Age__c != null) project.Age__c = oppPlatform.Age__c;
            if (oppPlatform.Age_max__c != null) project.Age_Max__c = oppPlatform.Age_max__c;
            if (oppPlatform.Age_min__c != null) project.Age_Min__c = oppPlatform.Age_min__c;
            if (oppPlatform.Gender__c != null) project.Gender__c = oppPlatform.Gender__c;
            if (oppPlatform.Facebook_page__c != null) project.Facebook_Page__c = oppPlatform.Facebook_page__c;
            if (oppPlatform.Objectives__c != null) project.Objectives__c = oppPlatform.Objectives__c;
            if (oppPlatform.Opportunity_Ad_Placement__c != null) project.Opportunity_Ad_Placement__c = oppPlatform.Opportunity_Ad_Placement__c;
            if (String.isNotBlank(oppPlatform.Cost_Structure_Metrics__c) && String.isNotBlank(project.CostStructure__c)) {
                List<String> allMetrics = oppPlatform.Cost_Structure_Metrics__c.split(PlatformWrapper.CC_METRIC_SEPARATOR);
                for (String selectedMetric :allMetrics) {
                    String ccName = Platform.metricsToCCNames.containsKey(selectedMetric) ? Platform.metricsToCCNames.get(selectedMetric) : '';
                    if (project.CostStructure__c == ccName) {
                        project.Metric__c = selectedMetric;
                    }
                }
            }
        }
    }

    private void setMetrics(List<Payment__c> projects, Map<Id,OpportunityPlatform__c> oppPlatforms) {
        for (Payment__c project :projects) {
            OpportunityPlatform__c oppPlatform = oppPlatforms.get(project.OpportunityPlatform__c);
            if (oppPlatform == null) continue;

            if (String.isNotBlank(oppPlatform.Cost_Structure_Metrics__c) && String.isNotBlank(project.CostStructure__c)) {
                List<String> allMetrics = oppPlatform.Cost_Structure_Metrics__c.split(PlatformWrapper.CC_METRIC_SEPARATOR);
                for (String selectedMetric :allMetrics) {
                    String ccName = Platform.metricsToCCNames.containsKey(selectedMetric) ? Platform.metricsToCCNames.get(selectedMetric) : '';
                    if (project.CostStructure__c == ccName) {
                        project.Metric__c = selectedMetric;
                    }
                }
            }
        }
    }

    /*private Decimal calculateInvoiceAmount(Payment__c project) {
        String billingProfile,  billingCondition, paymentType, marginType;
        Double mediaOrder, clientSpend, invoiceAmount, conditionRebate, helperValue, ordered, delivered;
        Decimal margin, adWordsSpend, profile, condition, instantRebate;
        Id projectId = project.Id;

        billingProfile = project.Account_Type__c;
        billingCondition = project.BillingCondition__c;
        margin = project.Margin__c;
        marginType = project.Margin_Type__c;
        adWordsSpend = (project.AdWordsSpend__c == null) ? 0 : project.AdWordsSpend__c;
        mediaOrder = project.Media_Order__c;
        clientSpend = (project.Client_Spend__c == null) ? 0 : project.Client_Spend__c;
        conditionRebate = project.ConditionRebateFormula__c;
        paymentType = project.PaymentType__c;
        ordered  = project.Quantity__c;
        delivered = project.AmountDelivered__c;

        helperValue = (project.CostStructure__c != null && project.CostStructure__c.contains('CPM') && project.UnitCost__c != null) ? project.UnitCost__c/1000 : project.UnitCost__c;
        profile = (billingProfile == 'Strike') ? adWordsSpend : 0;

        instantRebate = (project.Instant_Rebate__c == NULL) ? 0 : project.Instant_Rebate__c;
        condition = 1 - instantRebate/100;

        System.debug('### clientSpend: ' + clientSpend + ' ### condition: ' + condition);

        if (margin == 100 || paymentType == '100% Upfront') {
            System.debug('### projectId: ' + projectId + '  === 1 invAmount: ' + invoiceAmount);
            invoiceAmount = clientSpend;
        } else if (billingCondition.contains('Instant Rebate')) {
            invoiceAmount = (clientSpend - adWordsSpend) * condition + profile;
            System.debug('### Instant Rebate, invAmount = ' + invoiceAmount);
        } else {
            if (billingProfile == 'Strike' && (billingCondition == 'Normal' || (conditionRebate != null && condition == 1))) {
                if (helperValue != null && delivered >= ordered) {
                    invoiceAmount = clientSpend;
                    System.debug('### projectId: ' + projectId + '  === 2 invAmount: ' + invoiceAmount);
                } else if (helperValue != null && delivered < ordered) {
                    invoiceAmount = delivered * helperValue;
                    System.debug('### projectId: ' + projectId + '  === 3 invAmount: ' + invoiceAmount);
                } else if (helperValue == null && margin != null) {
                    invoiceAmount = adWordsSpend / (1 - margin/100);
                    System.debug('### projectId: ' + projectId + '  === 4 invAmount: ' + invoiceAmount);
                    if (marginType == '% of Media') {
                        invoiceAmount = adWordsSpend * (1 + margin/100);
                        System.debug('### projectId: ' + projectId + '  === 5 invAmount: ' + invoiceAmount);
                    }
                }
            } else if ((margin != null && helperValue != null && delivered >= ordered && adWordsSpend >= mediaOrder) ||
                    (margin != null && helperValue == null  && adWordsSpend >= mediaOrder)) {
                invoiceAmount = (clientSpend - adWordsSpend) * condition + profile;
                System.debug('### projectId: ' + projectId + '  === 6 invAmount: ' + invoiceAmount);
            } else if ((margin != null && helperValue != null && adWordsSpend < mediaOrder && delivered >= ordered) ||
                    (margin != null && helperValue == null && adWordsSpend < mediaOrder)) {
                invoiceAmount = adWordsSpend * ((margin/100)/(1-margin/100)) * condition + profile;
                System.debug('### projectId: ' + projectId + '  === 7 invAmount: ' + invoiceAmount);
                if (marginType == '% of Media') {
                    invoiceAmount = adWordsSpend * (margin/100)* condition + profile;
                    System.debug('### projectId: ' + projectId + '  === 8 invAmount: ' + invoiceAmount);
                }
            } else if (marginType == '% of Media' && margin != null && helperValue != null && delivered < ordered && adWordsSpend*(1+margin/100) >= delivered * helperValue) {
                invoiceAmount = (clientSpend * delivered / ordered - adWordsSpend) * condition + profile;
                System.debug('### projectId: ' + projectId + '  === 9 invAmount: ' + invoiceAmount);
            } else if (marginType != '% of Media' && margin != null && helperValue != null && delivered < ordered && adWordsSpend/(1-margin/100) >= delivered * helperValue) {
                invoiceAmount = (clientSpend * delivered / ordered - adWordsSpend) * condition + profile;
                System.debug('### projectId: ' + projectId + '  === 10 invAmount: ' + invoiceAmount);
            } else if (marginType == '% of Media' && margin != null && helperValue != null && delivered < ordered && adWordsSpend*(1+margin/100) < delivered * helperValue) {
                invoiceAmount = (adWordsSpend * (margin/100)) * condition + profile;
                System.debug('### projectId: ' + projectId + '  === 11 invAmount: ' + invoiceAmount);
            } else if (margin != null && helperValue != null && delivered < ordered && adWordsSpend/(1-margin/100) < delivered * helperValue) {
                invoiceAmount = (adWordsSpend * (margin/100)/(1-margin/100)) * condition + profile;
                System.debug('### projectId: ' + projectId + '  === 12 invAmount: ' + invoiceAmount);
            }
        }
        if ((billingProfile == 'Client' && adWordsSpend >= clientSpend) || invoiceAmount < 0) {
            System.debug('### projectId: ' + projectId + '  === 13 invAmount: ' + invoiceAmount);
            invoiceAmount = 0;
        }
        return invoiceAmount;
    }*/
}