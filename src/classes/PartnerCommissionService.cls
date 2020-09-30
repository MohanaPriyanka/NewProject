/**
 * Test: PartnerCommissionServiceTest, UtilityAccountSubscriptionHandlerTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class PartnerCommissionService{
    @TestVisible
    private static UASSelector utilityaccountSelector = new UASSelector();
    @TestVisible
    private static CommissionStructureSelector commissionStructureSelector = new CommissionStructureSelector();
    @TestVisible
    private static CommissionPaymentSelector commissionPaySelector = new CommissionPaymentSelector();
    @TestVisible
    private static PartnerInvoiceSelector partnerInvoiceSelector = new PartnerInvoiceSelector();

    private Map<Id,Decimal> oppToUASSummaryMap = new Map<Id,Decimal>();
    private Map<String,Commission_Structure__c> partnerProductKeyToCommissionMap = new Map<String,Commission_Structure__c>();
    private Map<Id,Commission_Payment__c> oppToExistingContractExecutionPaymentMap = new Map<Id,Commission_Payment__c>();
    private Map<String,Invoice__c> partnerToOldestOpenInvoiceMap = new Map<String,Invoice__c>();
    private Date dueDate;

    public enum CommissionType {CONTRACTEXECUTION, FIRSTBILLSENT, FIRSTBILLPAID}

    public class PendingCommission {
        public List<Opportunity> opportunitiesToRun;
        public CommissionType typeOfCommission;
    }

    public fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<SObjectType> {
            Opportunity.SObjectType,
            Commission_Payment__c.SObjectType,
            Case.SObjectType
        }
    );

    public void createCommissionRecords(PendingCommission pendingCommission){
        try {
            calculateCommissionRecords(pendingCommission);
            Util.commitWorkWithRetry(uow,10);
        } catch (Exception excep){
            Logger.logNow('PartnerCommissionService','createCommissionRecords', excep.getStackTraceString() + ' ' + excep.getMessage(),'ERROR');
        }
        // Flush error logs together to limit number of error logs created / DML calls (no callouts).
        // Most logs are marked as 'info' if we need to dig into it farther, but real notification is via Case to Ops
        Logger.flushLogs();
    }

    /**
        We only set opportunity fields CS_Capacity_Allocated__c & Commission_Structure__c
        when Opportunity is set to Complete and we calculate the contract execution commission.
        They should not change after the contract execution commission record has been created as those fields
        will be used to calculate other commission types (first bill, first pay, etc)

        @param PendingCommission Wrapper object for all Opportunities that either need Commission Payments created or
        updated AND the type of Commission (Contract Execution, First Bill Sent, or First Bill Paid)
    **/
    @TestVisible
    private void calculateCommissionRecords(PendingCommission pendingCommission){

        if (pendingCommission.typeOfCommission == CommissionType.CONTRACTEXECUTION){
            populateContractExecutionMaps(pendingCommission.opportunitiesToRun);
            setOpportunityFields(pendingCommission.opportunitiesToRun);
        }
        getAndCreatePartnerInvoices(pendingCommission.opportunitiesToRun);
        calculateCommissionPayments(pendingCommission);
    }

    private void calculateCommissionPayments(PendingCommission pendingCommission){
        Date dueDate = getDueDate();
        Date dueToAccountingDate = Date.newInstance(dueDate.Year(),dueDate.month(),3);
        String commissionPaymentType = convertCommissionTypeEnumToPicklist(pendingCommission.typeOfCommission);

        for (Opportunity opp : pendingCommission.opportunitiesToRun){
            if (missingRequiredFields(opp)){
                continue;
            }
            Decimal commissionAmount = getCommissionAmount(opp, pendingCommission.typeOfCommission);
            Invoice__c partnerInvoice = partnerToOldestOpenInvoiceMap.get(opp.Partner_tag_lookup__c);
            if (partnerInvoice == null){
                Logger.logLater(
                    'PartnerCommissionService',
                    'calculateCommissionPayment',
                    'Could not find a partner invoice for ' + String.valueOf(opp.Partner_tag_lookup__c));
                continue;
            }
            Commission_Payment__c payment = new Commission_Payment__c(
                Amount_Due__c = commissionAmount.setScale(2,RoundingMode.HALF_UP),
                Commission_Structure__c = opp.Commission_Structure__c,
                Due_Date__c = dueDate,
                Due_to_Accounting__c = dueToAccountingDate,
                Invoice__c = partnerInvoice.Id,
                Name = (opp.Partner_tag_lookup__r.Name + ' - ' + opp.Name + ' - ' + commissionPaymentType).LEFT(80),
                Opportunity__c = opp.Id,
                Status__c = 'Pending Approval',
                Commission_Type__c = commissionPaymentType
            );
            upsertCommissionPayments(payment, pendingCommission.typeOfCommission);
        }
    }

    /**
        Ensures that we only update and insert Commission Payments that register a change
        @param payment Commission Payment that will either be inserted as new payment or update a Pending payment
        @param type Commission Payment type
    **/
    private void upsertCommissionPayments(Commission_Payment__c payment, CommissionType type){
        Commission_Payment__c existingContractExecutionPayment;
        if (type == CommissionType.CONTRACTEXECUTION) {
            existingContractExecutionPayment = oppToExistingContractExecutionPaymentMap.get(payment.Opportunity__c);
        }
        if (existingContractExecutionPayment == null){
            uow.registerNew(payment);
        } else if (existingContractExecutionPayment != null
            && (existingContractExecutionPayment.Amount_Due__c != payment.Amount_Due__c
            || existingContractExecutionPayment.Commission_Structure__c != payment.Commission_Structure__c)){
            payment.Id = existingContractExecutionPayment.Id;
            uow.registerDirty(payment);
        } else {
            // update not required because commission amount and structure is the same
        }
    }

    private Boolean missingRequiredFields(Opportunity opp){
        return (
            opp.CS_Capacity_Allocated__c == null ||
                opp.Commission_Structure__c == null ||
                opp.Partner_tag_lookup__c == null
        );
    }

    private String convertCommissionTypeEnumToPicklist(CommissionType enumValue){
        if (enumValue == CommissionType.CONTRACTEXECUTION){
            return 'Contract Execution';
        } else if (enumValue == CommissionType.FIRSTBILLSENT){
            return 'First Bill Sent';
        } else if (enumValue == CommissionType.FIRSTBILLPAID){
            return 'First Bill Paid';
        } else {
            return null;
        }
    }

    private Decimal getCommissionAmount(Opportunity opp, CommissionType enumValue){
        if (enumValue == CommissionType.CONTRACTEXECUTION){
            return opp.CS_Capacity_Allocated__c*opp.Commission_Structure__r.Cents_kW_DC_Up_Front__c *1000;
        } else if (enumValue == CommissionType.FIRSTBILLSENT){
            return opp.CS_Capacity_Allocated__c*opp.Commission_Structure__r.Cents_kW_DC_First_Bill__c*1000;
        } else if (enumValue == CommissionType.FIRSTBILLPAID){
            return opp.CS_Capacity_Allocated__c*opp.Commission_Structure__r.Cents_kW_DC_First_Bill_Paid__c *1000;
        } else {
            return 0;
        }
    }

    private void populateContractExecutionMaps(List<Opportunity> opportunities){
        Set<Id> oppIds = CollectionUtil.getIdSet(opportunities);
        populateUASMap(oppIds);
        populateCommissionStructureMap(opportunities);
        populateExistingPaymentsMap(oppIds);
    }

    private void populateUASMap(Set<Id> oppIds){
        oppToUASSummaryMap = utilityaccountSelector.getUASSummaryByOpportunity(oppIds);
    }

    private void populateCommissionStructureMap(List<Opportunity> opportunities){
        Set<Id> partnerIds = new Set<Id>();
        for (Opportunity opportunity : opportunities){
            partnerIds.add(opportunity.Partner_tag_lookup__c);
        }
        List<Commission_Structure__c> activeCommissionStructures = commissionStructureSelector.getActiveCommissionStructures(partnerIds);
        for (Commission_Structure__c structure : activeCommissionStructures){
            String partnerProductKey = String.valueOf(structure.Partner__c) + String.valueOf(structure.Product__c);
            if (partnerProductKeyToCommissionMap.containsKey(partnerProductKey)){
                Logger.logLater('PartnerCommissionService','populateCommissionStructureMap',
                    'More than one active commission structure record was found for ' +
                        'partner: ' + structure.Partner__c + ' and product: ' + structure.Product__c,
                    'INFO');
                continue;
            }
            partnerProductKeyToCommissionMap.put(partnerProductKey,structure);
        }
    }

    private void populateExistingPaymentsMap(Set<Id> oppIds){
        String contractExecutionType = convertCommissionTypeEnumToPicklist(CommissionType.CONTRACTEXECUTION);
        List<Commission_Payment__c> payments;
        payments = commissionPaySelector.getPendingCommissionPayments(oppIds, contractExecutionType);
        for (Commission_Payment__c payment : payments){
            if (oppToExistingContractExecutionPaymentMap.containsKey(payment.Opportunity__c)){
                Logger.logLater('PartnerCommissionService',
                    'populateExistingPaymentsMap',
                    'More than one Contract Execution payment found for opp: ' + String.valueOf(payment.Opportunity__c),
                    'INFO'
                );
            }
            oppToExistingContractExecutionPaymentMap.put(payment.Opportunity__c, payment);
        }
    }

    private void getAndCreatePartnerInvoices(List<Opportunity> opportunities){
        Set<Id> partnerIds = new Set<Id>();
        Map<Id, String> partnerIdToNameMap = new Map<Id, String>();
        for (Opportunity opportunity : opportunities){
            partnerIds.add(opportunity.Partner_tag_lookup__c);
            partnerIdToNameMap.put(opportunity.Partner_tag_lookup__c, opportunity.Partner_tag_lookup__r.Name);
        }
        List<Invoice__c> invoices = partnerInvoiceSelector.getPendingPartnerInvoices(partnerIds, getDueDate());
        for (Invoice__c invoice : invoices){
            partnerToOldestOpenInvoiceMap.put(invoice.Partner__c, invoice);
        }

        List<Invoice__c> invoicesToInsert = new List<Invoice__c>();
        for (Id partnerId : partnerIds){
            if (!partnerToOldestOpenInvoiceMap.containsKey(partnerId)){
                invoicesToInsert.add(createPartnerInvoice(partnerId, partnerIdToNameMap.get(partnerId)));
            }
        }
        insert invoicesToInsert;
        for (Invoice__c invoice : invoicesToInsert){
            partnerToOldestOpenInvoiceMap.put(invoice.Partner__c, invoice);
        }
    }

    private void setOpportunityFields(List<Opportunity> opportunities){
        for (Opportunity opportunity : opportunities){
            setUASSummary(opportunity);
            setActiveCommissionStructure(opportunity);
        }
    }

    private void setUASSummary(Opportunity opportunity){
        Decimal uasSummary = oppToUASSummaryMap.get(opportunity.Id);
        if (uasSummary == null ){
            Logger.logLater(
                'PartnerCommissionService',
                'setUASSummary',
                'Could not get UAS summmary for opp: ' + String.valueOf(opportunity.Id) + 'and map: ' + JSON.serialize(oppToUASSummaryMap),
                'INFO'
            );
            return;
        }

        if ((opportunity.CS_Capacity_Allocated__c == null || opportunity.CS_Capacity_Allocated__c == 0) &&
            opportunity.CS_Capacity_Allocated__c != uasSummary){
            opportunity.CS_Capacity_Allocated__c = uasSummary;
            uow.registerDirty(opportunity);
        }
    }

    private void setActiveCommissionStructure(Opportunity opportunity){
        if (opportunity.Commission_Structure__c == null){
            String partnerProductKey = String.valueOf(opportunity.Partner_tag_lookup__c) + String.valueOf(opportunity.Product__c);
            Commission_Structure__c structure = partnerProductKeyToCommissionMap.get(partnerProductKey);
            if (structure == null){
                createCaseForSupportFollowUp('During creation of contract execution commission payment record, ' +
                    'could not find active commission structure for partner: ' +
                    String.valueOf(opportunity.Partner_tag_lookup__c) + 'and product: ' +
                    String.valueOf(opportunity.Product__c) + 'on opportunity: ' +
                    String.valueOf(opportunity.Id) + ' (' + String.valueOf(opportunity.Name) + '). ' +
                    'There are either no matches or too many matches for that partner and product pair',
                    opportunity.Id
                );
            } else {
                opportunity.Commission_Structure__c = structure.Id;
                opportunity.Commission_Structure__r = structure;
                uow.registerDirty(opportunity);
            }
        }
    }

    private void createCaseForSupportFollowUp(String description, Id opportunityId){
        CaseFactory caseFactory = new CaseFactory();
        Case newCase;
        newCase = caseFactory.getCase('Customer_Care');
        newCase.Subject = 'Issue with Creation of Commission Payment';
        newCase.Priority = 'Medium';
        newCase.Product_Line__c = 'Community Solar';
        newCase.Related_Opportunity__c = opportunityId;
        newCase.Description = description;
        newCase.Origin = 'Other';
        newCase.Case_Type__c = 'BlueWave';
        newCase.Disable_Followup_Email__c = true;
        uow.registerNew(newCase);
    }

    @TestVisible
    private Invoice__c createPartnerInvoice(Id partnerId, String partnerName){
        Date dueDate = getDueDate();
        Id recordTypeId = Schema.SObjectType.Invoice__c.getRecordTypeInfosByDeveloperName().get('Partner_Invoice').getRecordTypeId();
        Date dueToAccountingDate = Date.newInstance(dueDate.Year(),dueDate.month(),3);
        Datetime dueDatetime = Datetime.newInstance(dueDate.year(), dueDate.month(),dueDate.day());
        String monthName = dueDatetime.format('MMMMM');

        Invoice__c invoiceToCreate = new Invoice__c(
            Name = (partnerName + ' ' + monthName + ' ' + String.valueOf(dueDate.Year())).LEFT(80),
            Due_Date__c = dueDate,
            Due_to_Accounting__c = dueToAccountingDate,
            Invoice_Type__c = 'Direct',
            Partner__c = partnerId,
            Product_Line__c = 'Community Solar',
            Status__c = 'Received >> QC',
            RecordTypeId = recordTypeId
        );
        return invoiceToCreate;
    }

    private Date getDueDate(){
        if (dueDate == null){
            Date monthFromToday = System.today().addMonths(1);
            dueDate = Date.newInstance(monthFromToday.year(),monthFromToday.month(),15);
        }
        return dueDate;
    }
}