/**
 * @description Created by Jordan Pentaleri 1/2/20. Handles Partner Commissions.
 * Tested by: PartnerCommissionServiceTest, UtilityAccountSubscriptionHandlerTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class PartnerCommissionService {

    @TestVisible private static UASSelector utilityaccountSelector = new UASSelector();
    @TestVisible private static CommissionPaymentSelector commissionPaySelector = new CommissionPaymentSelector();
    @TestVisible private static PartnerInvoiceSelector partnerInvoiceSelector = new PartnerInvoiceSelector();

    private Map<Id, Decimal> oppToUASSummaryMap = new Map<Id, Decimal>();
    private Map<Id, Commission_Payment__c> oppToExistingContractExecutionPaymentMap = new Map<Id, Commission_Payment__c>();
    private Map<String, Invoice__c> partnerToOldestOpenInvoiceMap = new Map<String, Invoice__c>();

    public enum CommissionType {
        CONTRACTEXECUTION, FIRSTBILLSENT, FIRSTBILLPAID
    }
    private Map<CommissionType, String> commissionTypeEnumToString = new Map<CommissionType, String>{
        CommissionType.CONTRACTEXECUTION => 'Contract Execution',
        CommissionType.FIRSTBILLSENT => 'First Bill Sent',
        CommissionType.FIRSTBILLPAID => 'First Bill Paid'
    };

    public class PendingCommission {
        public List<Opportunity> opportunitiesToRun;
        public CommissionType typeOfCommission;
    }

    public void createCommissionRecords(PendingCommission pendingCommission) {
        try {
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
                new List<SObjectType>{
                    Opportunity.SObjectType,
                    Commission_Payment__c.SObjectType,
                    Case.SObjectType
                }
            );
            calculateCommissionRecords(pendingCommission, uow);
            Util.commitWorkWithRetry(uow, 10);
        } catch (Exception e) {
            Logger.logNow('PartnerCommissionService', 'createCommissionRecords', e.getStackTraceString() + '\n' + e.getMessage(), 'ERROR');
        }
        // Flush error logs together to limit number of error logs created / DML calls (no callouts).
        // Most logs are marked as 'info' if we need to dig into it farther, but real notification is via Case to Ops
        Logger.flushLogs();
    }

    /**
     * @description We only set opp fields CS_Capacity_Allocated__c & Commission_Structure__c
     * when Opportunity is set to Complete and we calculate the contract execution commission.
     * They should not change after the contract execution commission record has been created as those fields
     * will be used to calculate other commission types (first bill, first pay, etc)
     * @param pendingCommission Wrapper object for all Opportunities that either need Commission Payments created or
     * updated AND the type of Commission (Contract Execution, First Bill Sent, or First Bill Paid)
     * @param unitOfWork uow to use for the transaction
     **/
    public void calculateCommissionRecords(PendingCommission pendingCommission, fflib_SObjectUnitOfWork unitOfWork) {
        if (pendingCommission.typeOfCommission == CommissionType.CONTRACTEXECUTION) {
            populateContractExecutionMaps(pendingCommission.opportunitiesToRun);
            setOpportunityFields(pendingCommission.opportunitiesToRun, unitOfWork);
        }
        getAndCreatePartnerInvoices(pendingCommission.opportunitiesToRun);
        calculateCommissionPayments(pendingCommission, unitOfWork);
    }

    private void calculateCommissionPayments(PendingCommission pendingCommission, fflib_SObjectUnitOfWork unitOfWork) {
        Date dueDate = getDueDate();
        Date dueToAccountingDate = Date.newInstance(dueDate.year(), dueDate.month(), 3);
        String commissionPaymentType = commissionTypeEnumToString.get(pendingCommission.typeOfCommission);

        for (Opportunity opp : pendingCommission.opportunitiesToRun) {
            if (missingRequiredFields(opp)) {
                continue;
            }
            Decimal commissionAmount = getCommissionAmount(opp, pendingCommission.typeOfCommission);
            Invoice__c partnerInvoice = partnerToOldestOpenInvoiceMap.get(opp.Partner_tag_lookup__c);
            if (partnerInvoice == null) {
                Logger.logLater(
                    'PartnerCommissionService',
                    'calculateCommissionPayment',
                    'Could not find a partner invoice for ' + String.valueOf(opp.Partner_tag_lookup__c));
                continue;
            }
            Commission_Payment__c payment = new Commission_Payment__c(
                Amount_Due__c = commissionAmount.setScale(2, RoundingMode.HALF_UP),
                Commission_Structure__c = opp.Commission_Structure__c,
                Due_Date__c = dueDate,
                Due_to_Accounting__c = dueToAccountingDate,
                Invoice__c = partnerInvoice.Id,
                Name = (opp.Partner_tag_lookup__r.Name + ' - ' + opp.Name + ' - ' + commissionPaymentType).left(80),
                Opportunity__c = opp.Id,
                Status__c = 'Pending Approval',
                Commission_Type__c = commissionPaymentType
            );
            upsertCommissionPayments(payment, pendingCommission.typeOfCommission, unitOfWork);
        }
    }

    /**
     * @description Ensures that we only update and insert Commission Payments that register a change
     * @param payment Commission Payment that will either be inserted as new payment or update a Pending payment
     * @param type Commission Payment type
     * @param unitOfWork uow
     **/
    private void upsertCommissionPayments(Commission_Payment__c payment, CommissionType type, fflib_SObjectUnitOfWork unitOfWork) {
        Commission_Payment__c existingContractExecutionPayment;
        if (type == CommissionType.CONTRACTEXECUTION) {
            existingContractExecutionPayment = oppToExistingContractExecutionPaymentMap.get(payment.Opportunity__c);
        }
        if (existingContractExecutionPayment == null) {
            unitOfWork.registerNew(payment);
        } else if (existingContractExecutionPayment != null
            && (existingContractExecutionPayment.Amount_Due__c != payment.Amount_Due__c
            || existingContractExecutionPayment.Commission_Structure__c != payment.Commission_Structure__c)) {
            payment.Id = existingContractExecutionPayment.Id;
            unitOfWork.registerDirty(payment);
        }
        // otherwise, update not required because commission amount and structure is the same
    }

    private Boolean missingRequiredFields(Opportunity opp) {
        return (
            opp.CS_Capacity_Allocated__c == null || opp.Commission_Structure__c == null || opp.Partner_tag_lookup__c == null
        );
    }

    private Decimal getCommissionAmount(Opportunity opp, CommissionType enumValue) {
        switch on enumValue {
            when CONTRACTEXECUTION {
                Decimal commissionRate = Util.nullToZero(opp.Commission_Structure__r.Cents_kW_DC_Up_Front__c);
                return opp.CS_Capacity_Allocated__c * commissionRate * 1000;
            } when FIRSTBILLSENT {
                Decimal commissionRate = Util.nullToZero(opp.Commission_Structure__r.Cents_kW_DC_First_Bill__c);
                return opp.CS_Capacity_Allocated__c * commissionRate * 1000;
            } when FIRSTBILLPAID {
                Decimal commissionRate = Util.nullToZero(opp.Commission_Structure__r.Cents_kW_DC_First_Bill_Paid__c);
                return opp.CS_Capacity_Allocated__c * commissionRate * 1000;
            } when else {
                return 0;
            }
        }
    }

    private void populateContractExecutionMaps(List<Opportunity> opportunities) {
        Set<Id> oppIds = CollectionUtil.getIdSet(opportunities);
        oppToUASSummaryMap = utilityaccountSelector.getUASSummaryByOpportunity(oppIds);
        populateExistingPaymentsMap(oppIds);
    }

    private void populateExistingPaymentsMap(Set<Id> oppIds) {
        String contractExecutionType = commissionTypeEnumToString.get(CommissionType.CONTRACTEXECUTION);
        List<Commission_Payment__c> payments;
        payments = commissionPaySelector.getPendingCommissionPayments(oppIds, contractExecutionType);
        for (Commission_Payment__c payment : payments) {
            if (oppToExistingContractExecutionPaymentMap.containsKey(payment.Opportunity__c)) {
                Logger.logLater('PartnerCommissionService',
                    'populateExistingPaymentsMap',
                    'More than one Contract Execution payment found for opp: ' + String.valueOf(payment.Opportunity__c),
                    'INFO'
                );
            }
            oppToExistingContractExecutionPaymentMap.put(payment.Opportunity__c, payment);
        }
    }

    private void getAndCreatePartnerInvoices(List<Opportunity> opportunities) {
        Set<Id> partnerIds = new Set<Id>();
        Map<Id, String> partnerIdToNameMap = new Map<Id, String>();
        Map<Id, Id> partnerAccountMap = new Map<Id, Id>();
        for (Opportunity opportunity : opportunities) {
            partnerIds.add(opportunity.Partner_tag_lookup__c);
            partnerIdToNameMap.put(opportunity.Partner_tag_lookup__c, opportunity.Partner_tag_lookup__r.Name);
            partnerAccountMap.put(opportunity.Partner_tag_lookup__c, opportunity.Partner_tag_lookup__r.Account__c);
        }
        List<Invoice__c> invoices = partnerInvoiceSelector.getPendingPartnerInvoices(partnerIds, getDueDate());
        for (Invoice__c invoice : invoices) {
            partnerToOldestOpenInvoiceMap.put(invoice.Partner__c, invoice);
        }

        List<Invoice__c> invoicesToInsert = new List<Invoice__c>();
        for (Id partnerId : partnerIds) {
            if (!partnerToOldestOpenInvoiceMap.containsKey(partnerId)) {
                invoicesToInsert.add(createPartnerInvoice(partnerId, partnerIdToNameMap.get(partnerId), partnerAccountMap.get(partnerId)));
            }
        }
        insert invoicesToInsert;
        for (Invoice__c invoice : invoicesToInsert) {
            partnerToOldestOpenInvoiceMap.put(invoice.Partner__c, invoice);
        }
    }

    private void setOpportunityFields(List<Opportunity> opportunities, fflib_SObjectUnitOfWork unitOfWork) {
        for (Opportunity opportunity : opportunities) {
            setUASSummary(opportunity, unitOfWork);
            if (opportunity.Commission_Structure__c == null) {
                createNoCommissionStructureFoundCase(opportunity, unitOfWork);
            }
        }
    }

    private void createNoCommissionStructureFoundCase(Opportunity opp, fflib_SObjectUnitOfWork unitOfWork) {
        CaseFactory caseFactory = new CaseFactory();
        Case newCase;
        newCase = caseFactory.getCase('Partner_Care_Case');
        newCase.Subject = 'Issue with Creation of Commission Payment';
        newCase.Priority = 'Medium';
        newCase.Product_Line__c = 'Community Solar';
        newCase.Related_Opportunity__c = opp.Id;
        newCase.Description = 'During creation of contract execution commission payment record, ' +
            'could not find Commission Structure on opportunity: ' +
            String.valueOf(opp.Id) + ' (' + String.valueOf(opp.Name) + '). ' +
            'Please locate and apply the correct Commission Structure for this deal.';
        newCase.Origin = 'Other';
        newCase.Case_Type__c = 'Perch';
        newCase.Disable_Followup_Email__c = true;
        unitOfWork.registerNew(newCase);
    }

    private void setUASSummary(Opportunity opp, fflib_SObjectUnitOfWork unitOfWork) {
        Decimal uasSummary = oppToUASSummaryMap.get(opp.Id);
        if (uasSummary == null) {
            Logger.logLater(
                'PartnerCommissionService',
                'setUASSummary',
                'Could not get UAS summmary for opp: ' + String.valueOf(opp.Id) + 'and map: ' + JSON.serialize(oppToUASSummaryMap),
                'INFO'
            );
            return;
        }
        Boolean currentCapacityNeedsUpdate = opp.CS_Capacity_Allocated__c != uasSummary &&
            (opp.CS_Capacity_Allocated__c == null || opp.CS_Capacity_Allocated__c == 0);
        if (currentCapacityNeedsUpdate) {
            opp.CS_Capacity_Allocated__c = uasSummary;
            unitOfWork.registerDirty(opp, new List<SObjectField>{
                Opportunity.CS_Capacity_Allocated__c
            });
        }
    }

    @TestVisible
    private Invoice__c createPartnerInvoice(Id partnerId, String partnerName, Id accountId) {
        Date dueDate = getDueDate();
        Id recordTypeId = SObjectType.Invoice__c.getRecordTypeInfosByDeveloperName().get('Partner_Invoice').getRecordTypeId();
        Date dueToAccountingDate = Date.newInstance(dueDate.year(), dueDate.month(), 3);
        Datetime dueDatetime = Datetime.newInstance(dueDate.year(), dueDate.month(), dueDate.day());
        String monthName = dueDatetime.format('MMMMM');

        Invoice__c invoiceToCreate = new Invoice__c(
            Name = (partnerName + ' ' + monthName + ' ' + String.valueOf(dueDate.year())).left(80),
            Due_Date__c = dueDate,
            Due_to_Accounting__c = dueToAccountingDate,
            Invoice_Type__c = 'Direct',
            Partner__c = partnerId,
            Product_Line__c = 'Community Solar',
            Status__c = 'Received >> QC',
            RecordTypeId = recordTypeId,
            Account__c = accountId
        );
        return invoiceToCreate;
    }

    private Date getDueDate() {
        Date monthFromToday = System.today().addMonths(1);
        return Date.newInstance(monthFromToday.year(), monthFromToday.month(), 15);
    }
}