@SuppressWarnings('ApexUnresolvableReference')
public with sharing class PlanComponentCtrl {

    public Integer paymentRow { get; set; }
    public Integer projectRow { get; set; }
    public String projectId { get; set; }
    public String paymentId { get; set; }
    public String contractId { get; set; }
    public Boolean errorOccurred { get; set; }

    @TestVisible private List<Sub_Project__c> payments { get {
        if (payments == null){
            payments = new List<Sub_Project__c>();
        }
        return payments;
    } set; }

    @TestVisible private List<SelectOption> platforms { get {
        if (platforms == null) {
            platforms = new List<SelectOption>();
        }
        return platforms;
    } set; }

    /*public Boolean isContractDateGreaterToday { get {
        return project.Start_Date__c < System.today();
    }}*/

    public List<Sub_Project__c> newPayments { get; set; }
    public Map<Id, List<ProjectWrapper>> expandedProjectsByPaymentId { get; set; }
    public String expandedPayments { get; set; }
    public Map<String, Boolean> deleteProjectsMap { get; set; }
    public Map<Id, Platform__c> platformsMap { get; set; }

    public String paymentToInvoice { get; set; }
    public Project__c project { get; set; } // TODO: should be renamed to contract

    public List<SubProject.PaymentWrapper> paymentWrappers { get; set; }
    public Set<String> expandedPaymentIds { get; set; }

    public Map<String, Integer> paymentToProjectsNumberMap { get; set; }
    public Map<String, Boolean> isStartDateCorrect { get; set; }
    public Map<String, Boolean> isEndDateCorrect { get; set; }
    public String recIdWithChangedClientSpend { get; set; }

    @TestVisible private Set<String> recordsWithInvoiceAmountUpdate = new Set<String>();
    /*@TestVisible private Boolean preventRecreationOfProjects = true;*/
    @TestVisible private String objType = SubProjectRepository.API_NAME; // TODO: should be changed to final static

    public PlanComponentCtrl() {
        deleteProjectsMap = new Map<String, Boolean>();
        isStartDateCorrect = new Map<String, Boolean>();
        isEndDateCorrect = new Map<String, Boolean>();
        expandedProjectsByPaymentId = new Map<Id, List<ProjectWrapper>>();
        newPayments = new List<Sub_Project__c>();
        expandedPayments = '';
        expandedPaymentIds = new Set<String>();
        paymentWrappers = new List<SubProject.PaymentWrapper>();
        platformsMap = new Map<Id, Platform__c>(PlatformRepository.getAvailablePlatforms());
    }

    public List<SubProject.PaymentWrapper> getPaymentsList() {
        if (payments.isEmpty()) {
            resetContract();
        }
        return paymentWrappers;
    }

    private void validateDates(List<Sub_Project__c> paymentsToDelete, List<Sub_Project__c> insertPayments, List<Sub_Project__c> updatePayments) {
        List<Sub_Project__c> upsertPayments = new List<Sub_Project__c>(insertPayments);
        upsertPayments.addAll(updatePayments);

        if (!paymentsToDelete.isEmpty() && !paymentsToDelete[0].Project__r.Gaps_Exist_Between_Projects__c) {
            for (Sub_Project__c payment :paymentsToDelete) {
                Boolean projectStartDateWithinContractDates = (payment.Start_Date__c >= project.Start_Date__c) && (payment.Start_Date__c <= project.End_Date__c);
                Boolean projectEndDateWithinContractDates = (payment.End_Date__c >= project.Start_Date__c) && (payment.End_Date__c <= project.End_Date__c);
                if ((projectStartDateWithinContractDates || projectEndDateWithinContractDates) && !SubProject.isPaymentContained(payment, upsertPayments)) {
                    payment.addError(Label.PaymentCannotBeRemoved);
                    errorOccurred = true;
                }
            }
        }
    }

    private void validateNumberOfProjectsForPayments() {
        Map<Id, Boolean> paymentHasProjects = new Map<Id, Boolean>();
        for (Id paymentId :expandedProjectsByPaymentId.keySet()) {
            Boolean paymentContainsProject = false;
            for (ProjectWrapper wProject :expandedProjectsByPaymentId.get(paymentId)) {
                if (!deleteProjectsMap.containsKey(wProject.project.Id) || !deleteProjectsMap.get(wProject.project.Id)) {
                    paymentContainsProject = true;
                }
            }
            paymentHasProjects.put(paymentId, paymentContainsProject);
        }

        for (Boolean paymentContainsProject :paymentHasProjects.values()) {
            if (paymentContainsProject = false) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'At least one project is required for payment'));
                errorOccurred = true;
            }
        }
    }

    private void validateCostStructure(List<Sub_Project__c> insertPayments, List<Sub_Project__c> updatePayments, List<Payment__c> updateProjects) {
        // Selects also old projects that may be updated (outdated)
        List<Sub_Project__c> paymentsWithProjects = SubProjectRepository.getPaymentsWithProjects(updatePayments);
        paymentsWithProjects.addAll(insertPayments);

        Map<String, String> platformIdToCostStructure = new Map<String, String>();
        Set<String> platformsWithDifferentCostStructure = new Set<String>();
        Map<Id, Payment__c> updateProjectsMap = new Map<Id, Payment__c>(updateProjects);
        for (Sub_Project__c payment :paymentsWithProjects) {
            for (Payment__c project :payment.Projects__r) {
                project = (updateProjectsMap.containsKey(project.Id)) ? updateProjectsMap.get(project.Id) : project;


                String platform = project.OpportunityPlatform__r.Platform__r.Name,
                        key = platform + '_' + project.StrikeId__c;
                System.debug('### project: ' + project);
                System.debug('### key: ' + key + ' platform: ' + platform + '  cc: ' + project.CostStructure__c);
                if (!platformIdToCostStructure.containsKey(key)) {
                    platformIdToCostStructure.put(key, project.CostStructure__c);
                } else {
                    // other iterations
                    String costStructure = platformIdToCostStructure.get(key);
                    if (project.CostStructure__c != costStructure) {
                        platformsWithDifferentCostStructure.add(project.OpportunityPlatform__r.Platform__r.Name);
                    }
                }
            }
        }
        System.debug('### platformIdToCostStructure: ' + platformIdToCostStructure);
        System.debug('### platformsWithDifferentCostStructure: ' + platformsWithDifferentCostStructure);
        if (!platformsWithDifferentCostStructure.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Cost Structure should be the same for projects with platforms: ' +
                     String.join(new List<String>(platformsWithDifferentCostStructure), ',')));
            errorOccurred = true;
        }
   }

    public PageReference saveObjects() {
        errorOccurred = false;

        List<Sub_Project__c> paymentsToInsert = new List<Sub_Project__c>(), paymentsToUpdate = new List<Sub_Project__c>(), paymentsToDelete = new List<Sub_Project__c>();
        for (SubProject.PaymentWrapper wPayment :paymentWrappers) {
            if (wPayment.deletePayment) {
                paymentsToDelete.add(wPayment.payment);
                continue;
            }
            // if payment record is being inserted/updated
            if (String.isBlank(wPayment.payment.Id)) {
                paymentsToInsert.add(wPayment.payment);
            } else {
                paymentsToUpdate.add(wPayment.payment);
            }
        }

        List<Payment__c> projectsToInsert = new List<Payment__c>(), projectsToUpdate = new List<Payment__c>(), projectsToDelete = new List<Payment__c>();
        for (Id paymentId :expandedProjectsByPaymentId.keySet()) {
            for (ProjectWrapper wProject :expandedProjectsByPaymentId.get(paymentId)) {
                if (!deleteProjectsMap.containsKey(wProject.project.Id) || !deleteProjectsMap.get(wProject.project.Id)) {
                    if (String.isBlank(wProject.project.Id)) {
                        projectsToInsert.add(wProject.project);
                    } else {
                        projectsToUpdate.add(wProject.project);

                    }
                } else {
                    projectsToDelete.add(wProject.project);
                }
            }
            // TODO: check that logic
            if (!projectsToInsert.isEmpty() || !projectsToUpdate.isEmpty() || !projectsToDelete.isEmpty()) {
                SubProjectHandler.canEditClientSpendMode.add(paymentId);
            }
        }

        // IF ERROR: "Payment cannot be removed, unless every date is included in another payment or gaps between projects are allowed."
        validateDates(paymentsToDelete, paymentsToInsert, paymentsToUpdate);

        // IF ERROR: "At least one project is required for payment."
        validateNumberOfProjectsForPayments();

        // IF ERROR: "Cost Structure should be the same for projects: "
        validateCostStructure(paymentsToInsert, paymentsToUpdate, projectsToUpdate);

        if (errorOccurred) return null;

        List<ProjectToCreatives__c> p2csToInsert = new List<ProjectToCreatives__c>(), p2csToDelete = new List<ProjectToCreatives__c>();
        for (Id paymentId :expandedProjectsByPaymentId.keySet()) {
            for (ProjectWrapper wProject :expandedProjectsByPaymentId.get(paymentId)) {
                if (!deleteProjectsMap.containsKey(wProject.project.Id) || !deleteProjectsMap.get(wProject.project.Id)) {
                    if (String.isBlank(wProject.project.Id)) {
                        // the following list of p2cToInsert doesn't have project Id, because project is not inserted
                        // creatives should appear when project is saved - business logic
                        continue;
                    }
                    if (wProject.creativesOptions.isEmpty()) {
                        continue;
                    }

                    // if it's an existing Project AND at least one option exists
                    for (Creative creativeOption :wProject.creativesOptions) {
                        if (!creativeOption.isSelected && String.isNotBlank(creativeOption.p2cId)) {
                            p2csToDelete.add(new ProjectToCreatives__c(Id = creativeOption.p2cId));
                        }
                        if (creativeOption.isSelected && String.isBlank(creativeOption.p2cId) && String.isNotBlank(wProject.project.Id)) {
                            p2csToInsert.add(new ProjectToCreatives__c(Creative__c = creativeOption.creativeId, Project__c = wProject.project.Id));
                        }
                        if (creativeOption.isSelected && String.isBlank(creativeOption.p2cId) && String.isBlank(wProject.project.Id)) {
                            p2csToInsert.add(new ProjectToCreatives__c(Creative__c = creativeOption.creativeId, Project__c = null));
                        }
                    }
                }
            }
         }

        Set<Id> updatedPaymentIds = new Set<Id>();
        updatedPaymentIds.addAll(ProjectHandler.paymentsWithStartDateUpdated);
        updatedPaymentIds.addAll(ProjectHandler.paymentsWithEndDateUpdated);
        updatedPaymentIds.addAll(ProjectHandler.paymentsWithClientSpendUpdated);
        if (!updatedPaymentIds.isEmpty() && paymentsToInsert.isEmpty()) {
            paymentsToUpdate = readPaymentsChangedFromContract(paymentsToUpdate, updatedPaymentIds);
        }

        Set<Id> updatedProjectIds = new Set<Id>();
        updatedProjectIds.addAll(SubProjectHandler.projectsWithStartDateUpdated);
        updatedProjectIds.addAll(SubProjectHandler.projectsWithEndDateUpdated);
        updatedProjectIds.addAll(SubProjectHandler.projectsWithClientSpendUpdated);
        if (!updatedProjectIds.isEmpty() && projectsToInsert.isEmpty()) {
            projectsToUpdate = readProjectsChangedFromPayment(projectsToUpdate, updatedProjectIds);
        }

        Savepoint sp = Database.setSavepoint();
        try {
            // delete payments if necessary
            SubProjectHandler.skipDeleteValidation = true;
            delete paymentsToDelete;
            SubProjectHandler.skipDeleteValidation = false;

            // delete projects if necessary
            PaymentHandler.skipDeleteValidation = true;
            delete projectsToDelete;
            PaymentHandler.skipDeleteValidation = false;

            // update Contract skipping validation
            SubProjectHandler.skipUpdateValidation = true;
            PaymentHandler.skipUpdateValidation = true;
            ProjectHandler.canEditClientSpendMode.add(project.Id);
            project.PerformMMSync__c = true;
            project.LastModifiedBy__c = UserInfo.getUserId();
            //project.Gaps_Exist_Between_Projects__c = doesGapExistBetweenProjects(projectsToInsert, projectsToUpdate);
            update project;
            SubProjectHandler.skipUpdateValidation = false;
            PaymentHandler.skipUpdateValidation = false;

            // update Payments (Sub_Project__c)
            PaymentHandler.skipUpdateValidation = true;
            if (!paymentsToInsert.isEmpty()) {
                SubProjectHandler.skipUpdateValidation = true;
                update paymentsToUpdate;
                SubProjectHandler.skipUpdateValidation = false;

                insert paymentsToInsert;
            } else {
                update paymentsToUpdate;
            }

            PaymentHandler.skipUpdateValidation = false;
            // update Projects (Payment__c)
            if (!projectsToInsert.isEmpty()) {
                PaymentHandler.skipUpdateValidation = true;
                update projectsToUpdate;

                PaymentHandler.calculateIsOverlapping = true;
                insert projectsToInsert;
                PaymentHandler.skipUpdateValidation = false;
                PaymentHandler.calculateIsOverlapping = false;

                //PaymentHandler.calculateIsOverlapping = true;
                //update projectsToInsert;
            } else {
                upsert projectsToUpdate;
            }

            delete p2csToDelete;
            insert p2csToInsert;

            reloadRecords((new Map<Id, Payment__c>(projectsToUpdate)).keySet(), (new Map<Id, Payment__c>(projectsToInsert)).keySet());
            ApexPages.addMessage(new ApexPages.Message(Apexpages.Severity.CONFIRM, 'Saved successfully'));
        } catch (DmlException ex) {
            System.debug('### PlanComponentCtrl.saveObjects: ' + ex);
            System.debug('### PlanComponentCtrl.saveObjects: ' + ex.getStackTraceString());
            for (Sub_Project__c payment :paymentsToInsert) {
                payment = payment.clone(false);
            }
            for (Payment__c project :projectsToInsert) {
                project = project.clone(false);
            }
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(Apexpages.Severity.ERROR, ex.getDmlMessage(0)));
            errorOccurred = true;
        }
        return null;
    }

    private void reloadRecords(Set<Id> updatedProjectIds, Set<Id> insertedProjectIds) {
        resetContract();
        resetProjects(updatedProjectIds, insertedProjectIds);
    }

    private void resetProjects(Set<Id> updatedProjectIds, Set<Id> insertedProjectIds) {
        Set<Id> upsertProjectIds = new Set<Id>(updatedProjectIds);
        upsertProjectIds.addAll(insertedProjectIds);

        Map<Id, Payment__c> changedProjects = new Map<Id, Payment__c>(PaymentRepository.getPaymentsByIdsSortedByStartDateAndStrikeID(upsertProjectIds));
        Map<Id, List<Payment__c>> paymentIdToProjects = new Map<Id, List<Payment__c>>();
        for (Payment__c project : changedProjects.values()) {
            if (!paymentIdToProjects.containsKey(project.Payment__c)) {
                paymentIdToProjects.put(project.Payment__c, new List<Payment__c>());
            }
            paymentIdToProjects.get(project.Payment__c).add(project);
        }

        expandedProjectsByPaymentId = new Map<Id, List<ProjectWrapper>>();
        newPayments = new List<Sub_Project__c>();
        List<VideoUrl__c> creativesForContract = VideoUrlRepository.getVideosForContract(project.Id);
        for (Id paymentId : paymentIdToProjects.keySet()) {
            expandedProjectsByPaymentId.put(paymentId, wrapProjects(paymentIdToProjects.get(paymentId), creativesForContract));
            for (Payment__c project : paymentIdToProjects.get(paymentId)) {
                deleteProjectsMap.put(project.Id, false);
            }
        }
    }

    public void sendInvoice() {
        List<XeroSync.InvoiceWrapper> responses = XeroSync.sendInvoice(paymentToInvoice);
        for (XeroSync.InvoiceWrapper response :responses) {
            if (response.status.equals(XeroSync.STATUS_SUCCESS)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, response.message));
                resetContract();
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, response.message));
            }
        }
    }

    public void addNewPayment() {
        Sub_Project__c newPayment = Utility.copyContractDataToPayment(project.Id);
        newPayment.Start_Date__c = null;
        newPayment.End_Date__c = null;
        newPayment.Client_Spend__c = 0;

        newPayments.add(newPayment);
        paymentWrappers.add(new SubProject.PaymentWrapper(newPayment, true));
    }

    public PageReference addNewProject() {
        Sub_Project__c payment;
        for (Sub_Project__c paymentRecord :project.Sub_Projects__r) {
            if (paymentRecord.Id == paymentId) {
                payment = paymentRecord;
            }
        }
        Payment__c newProject = Utility.copyContractDataToProject(project);
        newProject.Project__c = project.Id;
        newProject.Payment__c = paymentId;
        newProject.OpportunityPlatform__c = platforms[0].getValue();
        newProject.Start_Date__c = payment.Start_Date__c;
        newProject.End_Date__c = payment.End_Date__c;

        assignOpportunityPlatform(newProject);
        expandedProjectsByPaymentId.get(newProject.Payment__c).add(new ProjectWrapper(newProject));
        System.debug('### expandedProjectsByPaymentId: ' + expandedProjectsByPaymentId.get(newProject.Payment__c));
        return null;
    }

    public void cancelNewPayment() {
        Integer newIndex = paymentRow - payments.size();
        if (newPayments.size() > newIndex) {
            newPayments.remove(newIndex);
        }
        if (paymentWrappers.size() > paymentRow) {
            paymentWrappers.remove(paymentRow);
        }
    }

    public void cancelNewProject() {
        try {
            expandedProjectsByPaymentId.get(paymentId).remove(projectRow);
        } catch (DmlException ex) {
            ApexPages.addMessage(new ApexPages.Message(Apexpages.Severity.ERROR, ex.getDmlMessage(0)));
        }
    }

    public List<SelectOption> getAvailablePlatforms() {
        if (String.isNotBlank(contractId) && platforms.isEmpty()) {
            List<OpportunityPlatform__c> relatedPlatforms = PlatformRepository.getPlatformsForContracts(new Set<Id>{contractId}).get(contractId);
            for (OpportunityPlatform__c platform :relatedPlatforms) {
                platforms.add(new SelectOption(platform.Id, platform.Platform__r.Name));
            }
        }
        Utility.sortSelectOptionsByLabel(platforms);
        return platforms;
    }

    public void showProjectsForPayment() {
        expandedPaymentIds.add(paymentId);
        if (!expandedProjectsByPaymentId.containsKey(paymentId)) {
            List<Payment__c> projects = PaymentRepository.getProjectsForPayment(paymentId);
            storeExpandedProjectsInfo(projects);
        }
        expandedPayments = String.join(new List<String>(expandedPaymentIds), ',');
    }

    public void showProjectsForAllPayments() {
        Set<String> paymentIds = new Set<String>();
        for (SubProject.PaymentWrapper payWrap : paymentWrappers) {
            paymentIds.add(payWrap.payment.Id);
        }

        expandedPaymentIds.addAll(paymentIds);
        if (!paymentIds.isEmpty()) {
            for (List<Payment__c> projects : PaymentRepository.getProjectsForPayments(paymentIds).values()) {
                storeExpandedProjectsInfo(projects);
            }
        }
        expandedPayments = String.join(new List<String>(expandedPaymentIds), ',');
    }

    public void hideProjectsForPayment() {
        expandedPaymentIds.remove(paymentId);
        expandedPayments = String.join(new List<String>(expandedPaymentIds), ',');
    }

    private List<Payment__c> readProjectsChangedFromPayment(List<Payment__c> projectsToUpdate, Set<Id> updatedProjectIds) {
        Map<Id, Payment__c> projectsUpdatedFromPayment = new Map<Id, Payment__c>(PaymentRepository.getPaymentsByIDs(updatedProjectIds));

        for (Payment__c project : projectsToUpdate) {
            if (projectsUpdatedFromPayment.containsKey(project.Id)) {
                project.Name = projectsUpdatedFromPayment.get(project.Id).Name;

                if (SubProjectHandler.projectsWithStartDateUpdated.contains(project.Id)) {
                    project.Start_Date__c = projectsUpdatedFromPayment.get(project.Id).Start_Date__c;
                }
                if (SubProjectHandler.projectsWithEndDateUpdated.contains(project.Id)) {
                    project.End_Date__c = projectsUpdatedFromPayment.get(project.Id).End_Date__c;
                }
                if (SubProjectHandler.projectsWithClientSpendUpdated.contains(project.Id)) {
                    project.Client_Spend__c = projectsUpdatedFromPayment.get(project.Id).Client_Spend__c;
                }
            }
        }
        return projectsToUpdate;
    }

    private List<Sub_Project__c> readPaymentsChangedFromContract(List<Sub_Project__c> paymentsToUpdate, Set<Id> updatedPaymentIds) {
        Map<Id, Sub_Project__c> paymentsUpdatedFromContract = new Map<Id, Sub_Project__c>(SubProjectRepository.getSubProjectsByIDs(updatedPaymentIds));

        for (Sub_Project__c payment : paymentsToUpdate) {
            if (paymentsUpdatedFromContract.containsKey(payment.Id)) {
                payment.Name = paymentsUpdatedFromContract.get(payment.Id).Name;

                if (ProjectHandler.paymentsWithStartDateUpdated.contains(payment.Id)) {
                    payment.Start_Date__c = paymentsUpdatedFromContract.get(payment.Id).Start_Date__c;
                }
                if (ProjectHandler.paymentsWithEndDateUpdated.contains(payment.Id)) {
                    payment.End_Date__c = paymentsUpdatedFromContract.get(payment.Id).End_Date__c;
                }
                if (ProjectHandler.paymentsWithClientSpendUpdated.contains(payment.Id)) {
                    payment.Client_Spend__c = paymentsUpdatedFromContract.get(payment.Id).Client_Spend__c;
                }
            }
        }
        return paymentsToUpdate;
    }

    public PageReference recreateSobjects() {
        try {
            SubProjectHandler.skipDeleteValidation = true;
            delete payments;
            SubProjectHandler.skipDeleteValidation = false;

            payments.clear();
            Contract.createNewPayments(new List<Project__c>{project});
        } catch (DmlException ex) {
            ApexPages.addMessage(new ApexPages.Message(Apexpages.Severity.ERROR, ex.getDmlMessage(0)));
        }
        return null;
    }

    private Map<Id, Boolean> paymentIdsToInconsistentSpendsStatus() {
        List<Payment__c> projects = PaymentRepository.getProjectsWithSpendsByContractId(project.Id);
        Map<Id, Boolean> paymentsWithStatus = new Map<Id, Boolean>();
        for (Payment__c project :projects) {
            Id paymentId = project.Payment__c;
            // by default payment doesn't have related projects with inconsistent spends
            if (!paymentsWithStatus.containsKey(paymentId)) {
                paymentsWithStatus.put(paymentId, false);
            }

            Boolean areSpendsInconsistent = paymentsWithStatus.get(paymentId);
            Set<Date> dates = new Set<Date>();
            for (Project_Media_Spend__c cSpend :project.ContractMediaSpends__r) {
                // 1. duplicate spend record (i.e. spends having the same date in one project) counts as inconsistent
                // 2. spends that are not sync (i.e. were created manually) count as Inconsistent
                if (dates.contains(cSpend.Date__c) || !cSpend.Is_Sync__c) {
                    areSpendsInconsistent |= true;
                } else {
                    dates.add(cSpend.Date__c);
                }
            }
            paymentsWithStatus.put(paymentId, areSpendsInconsistent);
        }
        return paymentsWithStatus;
    }

    private void resetContract() {
        String query = 'SELECT Id, Account__r.Xero_Id__c, Account__c, Account_Type__c, AdWords_Spend__c, Client_Spend_Defined_on_IO__c, ' +
                'Client_IO__c, Client_Spend__c, CurrencyIsoCode, Discount_Terms__c, End_Date__c, Gaps_Exist_Between_Projects__c, Geo__c, ' +
                'Invoice_Amount_Roll_Up__c, InvoicingType__c, MinPaymentStartDate__c, Margin__c, Margin_Type__c, More_Info__c, Name, Opportunity__c, ' +
                'Opportunity__r.NumberOfPlatforms__c, Payment_Type__c, Project_ID__c, SpendRefreshDate__c, Start_Date__c, Sync_With_MM__c, Total_Revenue__c, ' +
                'Verticals__c, Video_Length__c, Xero_Id__c ';

        String subQuery = ', (SELECT Id, Margin__c, Margin_Type__c, Name, Start_Date__c, End_Date__c, Project__c, Client_Spend__c, Media_Order__c ';
            subQuery += ', Ad_Serving_Costs__c, BillingConditionDiscountTerms__c, AdWordsSpend__c, Checked__c, Discount_Terms__c, Discount_Violation__c,';
            subQuery += ' HasPendingCreditNotes__c, Invoice_Amount__c, InvoicingLocked__c, LockedUntil__c, MediaSpendAssigned__c, OverlapsContractDates__c, ';
            subQuery += ' Paid__c, Payment_Type__c, PaymentType__c, Project__r.MinPaymentStartDate__c, Project__r.Client_Spend__c, ';
            subQuery += ' Project__r.Gaps_Exist_Between_Projects__c, Suggested_Client_Spend__c, Xero_ID__c, Xero_Invoice__c, XeroStatus__c';
            subQuery += ' FROM Sub_Projects__r ORDER BY End_Date__c ASC)';

        query += subQuery + ' FROM Project__c WHERE Id =: contractId';

        System.debug('### query: ' + query);

        List<Project__c> contracts = Database.query(query);
        payments = new List<SObject>();
        paymentToProjectsNumberMap = new Map<String, Integer>();
        paymentWrappers = new List<SubProject.PaymentWrapper>();

        if (!contracts.isEmpty()) {
            project = contracts[0];
            payments.addAll(project.Sub_Projects__r);

            Map<Id, Boolean> paymentIdsToInconsistentSpendsStatus = paymentIdsToInconsistentSpendsStatus();

            Set<Id> paymentIdSet = new Set<Id>();
            for (Integer i = 0; i < project.Sub_Projects__r.size(); i++) {
                Sub_Project__c payment = project.Sub_Projects__r[i];

                paymentIdSet.add(payment.Id);
                paymentToProjectsNumberMap.put(payment.Id, 0);
                paymentWrappers.add(new SubProject.PaymentWrapper(payment, paymentIdsToInconsistentSpendsStatus.get(payment.Id)));

                if (i == 0) {
                    isStartDateCorrect.put(payment.Id, true);
                } else if (payment.Start_Date__c <= project.Sub_Projects__r[i - 1].End_Date__c) {
                    isStartDateCorrect.put(payment.Id, false);
                } else {
                    isStartDateCorrect.put(payment.Id, true);
                }
            }

            for (Integer i = 0; i < project.Sub_Projects__r.size() - 1; i++) {
                if (project.Sub_Projects__r[i].End_Date__c >= project.Sub_Projects__r[i + 1].Start_Date__c) {
                    isEndDateCorrect.put(project.Sub_Projects__r[i].Id, false);
                } else {
                    isEndDateCorrect.put(project.Sub_Projects__r[i].Id, true);
                }
            }

            if (!project.Sub_Projects__r.isEmpty()) {
                List<Payment__c> projList = PaymentRepository.getPaymentsBySubProjectIDs(paymentIdSet);
                Integer counter;
                for (Payment__c p : projList) {
                    if (!paymentToProjectsNumberMap.containsKey(p.Payment__c)) {
                        paymentToProjectsNumberMap.put(p.Payment__c, 1);
                    } else {
                        counter = paymentToProjectsNumberMap.get(p.Payment__c);
                        paymentToProjectsNumberMap.put(p.Payment__c, ++counter);
                    }
                }
                isEndDateCorrect.put(project.Sub_Projects__r[project.Sub_Projects__r.size() - 1].Id, true);
            }
        }
    }

    public void onClientSpendChange() {
        recordsWithInvoiceAmountUpdate.add(recIdWithChangedClientSpend);
    }

    private String getCostStructureForSameProjectsInContract(Id contractId, String strikeId, Id exceptProjectId, String platform) {
        String costStructure = '';
        for (Payment__c project :[SELECT CostStructure__c, OpportunityPlatform__r.Platform__r.Name FROM Payment__c WHERE StrikeId__c = :strikeId AND Project__c = :contractId AND Id != :exceptProjectId]) {
            // if changed project has different cost structure, no message should appear
            if (platform != project.OpportunityPlatform__r.Platform__r.Name) {
                continue;
            }
            costStructure = project.CostStructure__c;
        }
        return costStructure;
    }

    public void projectCostStructureUpdated() {
        List<ProjectWrapper> wProject = expandedProjectsByPaymentId.get(paymentId);
        Payment__c project = unWrapProjects(wProject)[projectRow];

        String costStructure = getCostStructureForSameProjectsInContract(project.Project__c, project.StrikeId__c, project.Id, project.OpportunityPlatform__r.Platform__r.Name);
        if (String.isNotBlank(costStructure) && project.CostStructure__c != costStructure) {
            ApexPages.addMessage(new ApexPages.Message(Apexpages.Severity.WARNING, 'Cost Structure for ' + project.Name + ' is different from ' + costStructure
                    +'. Please create a new Project or revert your changes.'));
        }

        OpportunityPlatform__c oppPlatform = project.OpportunityPlatform__r;
        if (String.isNotBlank(project.CostStructure__c) && oppPlatform.NoCostStructure__c == false) {
            project.VariableUnitCost__c = Boolean.valueOf(oppPlatform.get('Variable' + project.CostStructure__c + '__c'));
            project.UnitCost__c = (Decimal) oppPlatform.get(project.CostStructure__c + '__c');
        }
    }

    public void projectPlatformUpdated() {
        List<ProjectWrapper> wrappedProjects = expandedProjectsByPaymentId.get(paymentId);
        Payment__c projectRecord = unWrapProjects(wrappedProjects)[projectRow];

        assignOpportunityPlatform(projectRecord);
        if (String.isNotBlank(projectRecord.Id)) {
            wrappedProjects[projectRow] = new ProjectWrapper(projectRecord, VideoUrlRepository.getVideosForContract(projectRecord.Project__c));
        } else {
            // creative options should appear after project is inserted
            wrappedProjects[projectRow] = new ProjectWrapper(projectRecord);
        }
    }

    public void paymentDeleteChanged() {
        for (SubProject.PaymentWrapper payWrap : paymentWrappers) {
            if (payWrap.payment.Id == paymentId) {
                payWrap.deletePayment = !payWrap.deletePayment;
            }
        }
    }

    public void projectDeleteChanged() {
        Boolean isProjectDeleted = deleteProjectsMap.get(projectId);
        deleteProjectsMap.put(projectId, !isProjectDeleted);
    }

    private Boolean doesGapExistBetweenProjects(List<Payment__c> insertProjects, List<Payment__c> updateProjects) {
        // Checks if Gap Between Project Dates actually exists
        List<Payment__c> projects = new List<Payment__c>();
        projects.addAll(insertProjects);
        projects.addAll(updateProjects);

        Map<Date, List<Date>> startToEndDatesMap = new Map<Date, List<Date>>();
        for (Payment__c project :projects) {
            if (!startToEndDatesMap.containsKey(project.Start_Date__c)) {
                startToEndDatesMap.put(project.Start_Date__c, new List<Date>());
            }
            startToEndDatesMap.get(project.Start_Date__c).add(project.End_Date__c);
        }

        Boolean gapExists = false;
        List<Date> startDates = new List<Date>(startToEndDatesMap.keySet());
        startDates.sort();
        if (!startDates.isEmpty() && startDates[0] > project.Start_Date__c) {
            gapExists = true;
        } else {
            List<Date> endDates;
            Date lastEndDate;
            for (Integer i = 0; i < startDates.size() - 1; i++) {
                endDates = startToEndDatesMap.get(startDates[i]);
                endDates.sort();
                lastEndDate = endDates.get(endDates.size() - 1);
                if (lastEndDate < startDates[i + 1] - 1) {
                    gapExists = true;
                    break;
                }
            }
        }
        return gapExists;
    }

    private Platform__c assignOpportunityPlatform(Payment__c projectRecord) {
        if (String.isNotBlank(projectRecord.OpportunityPlatform__c)) {
            // re-select Opportunity Platform to have CostStructures values
            OpportunityPlatform__c oppPlatform = OpportunityPlatformRepository.getByIDs(new Set<Id>{projectRecord.OpportunityPlatform__c})[0];
            Platform__c platform = platformsMap.get(oppPlatform.Platform__c);

            projectRecord.OpportunityPlatform__r = oppPlatform;
            projectRecord.UnitCost__c = null;
            projectRecord.CostStructure__c = oppPlatform.CostStructure__c;
            if (!oppPlatform.NoCostStructure__c) {
                if (!projectRecord.CostStructure__c.contains(';')) {
                    projectRecord.VariableUnitCost__c = Boolean.valueOf(oppPlatform.get('Variable' + projectRecord.CostStructure__c + '__c'));
                }
                if (!projectRecord.VariableUnitCost__c && projectRecord.CostStructure__c != null && !projectRecord.CostStructure__c.contains(';')) {
                    projectRecord.UnitCost__c = (Decimal) oppPlatform.get(projectRecord.CostStructure__c + '__c');
                }
            }
            return platform;
        }
        return null;
    }

    @TestVisible private void storeExpandedProjectsInfo(List<Payment__c> projects) {
        List<VideoUrl__c> creativesForContract = VideoUrlRepository.getVideosForContract(project.Id);
        expandedProjectsByPaymentId.put(projects[0].Payment__c, wrapProjects(projects, creativesForContract));
        for (Payment__c project : projects) {
            deleteProjectsMap.put(project.Id, false);
        }
    }

    @TestVisible private List<Payment__c> unWrapProjects(List<ProjectWrapper> projectWrappers) {
        List<Payment__c> projects = new List<Payment__c>();
        for (ProjectWrapper wrappedProject : projectWrappers) {
            projects.add(wrappedProject.project);
        }
        return projects;
    }

    @TestVisible private List<ProjectWrapper> wrapProjects(List<Payment__c> projects, List<VideoUrl__c> creatives) {
        List<ProjectWrapper> projectWrappers = new List<ProjectWrapper>();
        for (Payment__c projectRecord : projects) {
            projectWrappers.add(new ProjectWrapper(projectRecord, creatives));
        }
        return projectWrappers;
    }

    @TestVisible class ProjectWrapper {
        public Payment__c project { get; set; }
        public List<ProjectToCreatives__c> existingP2Cs { get; set; }

        public List<SelectOption> availableCostStructures {
            get {
                if (availableCostStructures == null) {
                    availableCostStructures = new List<SelectOption>();
                }
                return availableCostStructures;
            }
            set;
        }

        public List<Creative> creativesOptions {
            get {
                if (creativesOptions == null) {
                    creativesOptions = new List<Creative>();
                }
                return creativesOptions;
            }
            set;
        }

        public ProjectWrapper(Payment__c project) {
            this.project = project;
            fillInCostStructures();
        }

        public ProjectWrapper(Payment__c project, List<VideoUrl__c> creatives) {
            this.project = project;
            fillInCostStructures();
            fillInCreatives(creatives);
        }

        private void fillInCostStructures() {
            if (String.isNotBlank(project.OpportunityPlatform__r.CostStructure__c)) {
                if (project.OpportunityPlatform__r.CostStructure__c.split(';').size() > 1) {
                    availableCostStructures.add(new SelectOption('', ''));
                }
                for (String costStructure : project.OpportunityPlatform__r.CostStructure__c.split(';')) {
                    availableCostStructures.add(new SelectOption(costStructure, costStructure));
                }
            }
        }

        private void fillInCreatives(List<VideoUrl__c> creatives) {
            this.creativesOptions.clear();
            // existing p2c records represent the relation(junction object) between project and creative.
            // if record exists - the relation is established
            this.existingP2Cs = [
                    SELECT Project__c, Creative__c, Creative__r.Name
                    FROM ProjectToCreatives__c
                    WHERE Project__c = :project.Id AND Creative__c != NULL
            ];
            // add selected options to available options if allowed and mark it SELECTED
            for (ProjectToCreatives__c existingP2C : existingP2Cs) {
                this.creativesOptions.add(new Creative(existingP2C.Project__c, existingP2C.Creative__c, true, existingP2C.Creative__r.Name, existingP2C.Id));
            }

            for (VideoUrl__c creative : creatives) {
                Boolean doesNotOverlapDates = project.Start_Date__c <= creative.EndDate__c && project.End_Date__c >= creative.StartDate__c;
                Boolean samePlatform = (project.OpportunityPlatform__r != null && project.OpportunityPlatform__r.Platform__r.Name == creative.Platform__c);
                Boolean wasAdded = false;
                for (Creative creativesOption : this.creativesOptions) {
                    if (creativesOption.name == creative.Name) {
                        wasAdded = true;
                    }
                }
                if (!wasAdded && samePlatform && doesNotOverlapDates) {
                    this.creativesOptions.add(new Creative(project.Id, creative.Id, false, creative.Name, null));
                }
            }
        }
    }

    public class Creative {
        public Id projectId { get; set; }
        public Id creativeId { get; set; }
        public Boolean isSelected { get; set; }
        public String name { get; set; }
        public Id p2cId { get; set; }

        public Creative(Id projectId, Id creativeId, Boolean isSelected, String name, Id p2cId) {
            this.projectId = projectId;
            this.creativeId = creativeId;
            this.isSelected = isSelected;
            this.name = name;
            this.p2cId = p2cId;
        }
    }
}