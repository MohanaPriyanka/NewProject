/**
 * @description Created by jeffparlin on 9/23/21. Validates and converts leads input by caller. Leveraged by apex and
 *      Lead Qualification/Conversion flow. This class uses a bulkified design pattern which can support multiple
 *      Leads passing through per instance.
 * Tested By: CSLeadsConverterTest
 */
public without sharing class CSLeadsConverter implements Queueable {

    @TestVisible private static Integer queueableBatchSize = (Integer)
        System_Properties__c.getValues('System')?.CS_Auto_Lead_Conversion_Batch_Size__c;
    @TestVisible private static LeadSelector leadSelector = new LeadSelector();
    @TestVisible private static SharedSolarSystemsSelector systemsSelector = new SharedSolarSystemsSelector();
    @TestVisible private static UtilitySelector utilitySelector = new UtilitySelector();

    private Boolean isAutoConversionContext = false;
    private Map<Id, LeadConvertDetail> conversions = new Map<Id, LeadConvertDetail>();
    private List<Database.LeadConvert> conversionsReady;
    private Set<Id> autoConvertLeads = new Set<Id>();
    private Map<Id, Shared_Solar_System__c> systemsForEnrollment;

    /**
     * @description Constructor used by Flow to run Lead conversion for specified LeadConvertDetail objects
     * @param details List of LeadConvertDetail wrapper objects housing Lead Conversion information
     */
    public CSLeadsConverter(List<LeadConvertDetail> details) {
        systemsForEnrollment = new Map<Id, Shared_Solar_System__c>(systemsSelector.getSharedSolarSystemsForEnrollment());
        mapConversions(details);
    }

    /**
     * @description Constructor used by Queueable Apex/Auto Lead Qualification & Conversion
     * @param leadIdsForAutoConversion Set of Lead Ids to run lead conversion for
     */
    public CSLeadsConverter(Set<Id> leadIdsForAutoConversion) {
        this.autoConvertLeads = leadIdsForAutoConversion;
    }

    /**
     * @description Flow invocation of CS Lead conversion (synchronous)
     * @param details LeadConvertDetail objects which house conversion information
     *      Due to this running in a Flow context, the array size of details wil always be 1
     * @return Return version of the LeadConvertDetail complete with errors and error messages, if encountered
     */
    @InvocableMethod(Label='Invocable Lead Converter' Description='Converts CS Leads')
    public static List<LeadConvertDetail> invocableConvertLead(List<LeadConvertDetail> details) {
        CSLeadsConverter converter = new CSLeadsConverter(details);
        converter.convert();
        return details;
    }

    /**
     * @description Queueable invocation of CS Lead Conversion (asynchronous), see UtilityAccountLogTriggerHandler
     *      Handles job chaining in the event of a large bolus of incoming conversions --
     *      The Lead conversion process is CPU Time extensive as of this impl, so restrict batches to smaller chunks
     * @param ctx Queueable context
     */
    public void execute(QueueableContext ctx) {
        isAutoConversionContext = true;
        List<Id> leadIdsToProcess = new List<Id>(autoConvertLeads);
        try {
            Set<Id> leadsForNextBatch = new Set<Id>();
            for (Integer i = leadIdsToProcess.size()-1; i >= queueableBatchSize; i--) {
                Id currentLeadId = leadIdsToProcess[i];
                leadIdsToProcess.remove(i);
                leadsForNextBatch.add(currentLeadId);
            }

            autoConvertLeads = new Set<Id>(leadIdsToProcess);
            List<LeadConvertDetail> details = constructDetailsByLeads();
            mapConversions(details);
            convert();

            if (!leadsForNextBatch.isEmpty() && !Test.isRunningTest()) {
                System.enqueueJob(new CSLeadsConverter(leadsForNextBatch));
            }
        } catch (Exception e) {
            String message = 'Error encountered while running CSLeadsConverter in Queueable context. Leads impacted: '
                + autoConvertLeads + '\n\n' + e.getMessage() + ' ' + e.getStackTraceString();
            Logger.logNow('CSLeadsConverter', 'execute (queueable)', message, Logger.ERROR);
        }
    }

    /**
     * @description Primary execution chain here
     */
    private void convert() {
        retrieveDependencies();
        validateInputs();
        modifyLeadsWithInputs();
        constructConversionData();
        commitConversion();
        updateLeadsWithConversionResults();
    }

    /**
     * @description Maps Lead Id to LeadConvertDetail object for reference if needed
     * @param details List of LeadConvertDetail objects
     */
    private void mapConversions(List<LeadConvertDetail> details) {
        for (LeadConvertDetail detail : details) {
            this.conversions.put(detail.leadId, detail);
        }
    }

    /**
     * @description Constructs LeadConvertDetail objects for passed-in Lead Ids, intended for Lead Auto Conversion context
     * @return List of LeadConvertDetail objects to be used by remainder of class
     */
    private List<LeadConvertDetail> constructDetailsByLeads() {
        List<LeadConvertDetail> details = new List<LeadConvertDetail>();
        systemsForEnrollment = new Map<Id, Shared_Solar_System__c>(systemsSelector.getSharedSolarSystemsForEnrollment());
        SharedSolarSystems systemsHelper = new SharedSolarSystems(systemsForEnrollment.values());
        List<Lead> leads = leadSelector.selectAll(autoConvertLeads);
        for (Lead lead : leads) {
            LeadConvertDetail detail = new LeadConvertDetail();
            List<Shared_Solar_System__c> qualifiedSystemsForLead = systemsHelper.getQualifiedForLead(lead);
            detail.leadId = lead.Id;
            detail.selectedProductId = lead.Product__c;
            detail.selectedSystemIds = CollectionUtil.getIds(qualifiedSystemsForLead);
            detail.autoConversion = isAutoConversionContext;
            details.add(detail);
        }
        return details;
    }

    /**
     * @description Retrieves dependencies needed for processing Lead Conversion and caches in LeadConvertDetail object
     */
    @TestVisible
    private void retrieveDependencies() {
        Map<Id, Utility__c> utilityMap = utilitySelector.getAllUtilitiesMap();
        Map<Id, Lead> leadMap = leadSelector.getLeadsForConversion(conversions.keySet());

        for (LeadConvertDetail detail : conversions.values()) {
            detail.lead = leadMap.get(detail.leadId);
            detail.utilityAccountLogs = detail.lead.Utility_Account_Logs__r;
            detail.utility = utilityMap.get(detail.lead.Utility_relationship__c);
            for (Id systemId : detail.selectedSystemIds) {
                detail.selectedSystems.add(systemsForEnrollment.get(systemId));
            }
        }
    }

    /**
     * @description Runs validation check on each LeadConvertDetail before continuing down the Lead Conversion path
     */
    @TestVisible
    private void validateInputs() {
        for (LeadConvertDetail detail : conversions.values()) {
            new CSLeadConversionValidator(detail).validate();
        }
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private void modifyLeadsWithInputs() {
        List<Lead> leadsToUpdate = new List<Lead>();
        for (LeadConvertDetail detail : conversions.values()) {
            Lead lead = new Lead(Id = detail.leadId);
            lead.Status = !detail.selectedSystems.isEmpty() ? 'Qualified' : lead.Status;
            lead.Selected_SSS_For_Conversion__c = getSelectedSystemIds(detail);
            lead.Product__c = detail.selectedProductId;
            leadsToUpdate.add(lead);
        }
        updateLeads(leadsToUpdate, true);
    }

    @TestVisible
    private void updateLeads(List<Lead> leadsToUpdate, Boolean preConversion) {
        try {
            update leadsToUpdate;
        } catch (Exception e) {
            Boolean isUnableToLockRowError = e.getMessage().contains('UNABLE_TO_LOCK_ROW');
            if (isUnableToLockRowError && !isAutoConversionContext) {
                throw new Util.BWException(e.getMessage());
            }
            Logger.logNow('CSLeadsConverter', 'updateLeads ' + (preConversion ? '(pre-Convert)' : '(post-Convert)'),
                e.getMessage(), Logger.ERROR);
        }
    }

    @TestVisible
    private String getSelectedSystemIds(LeadConvertDetail detail) {
        String selectedSystems = '';
        for (Shared_Solar_System__c sss : detail.selectedSystems) {
            selectedSystems += sss.Id + '/';
        }
        return selectedSystems;
    }

    @TestVisible
    private void constructConversionData() {
        conversionsReady = new List<Database.LeadConvert>();
        for (LeadConvertDetail detail : conversions.values()) {
            if (detail.error == null) {
                Database.LeadConvert conversion = new Database.LeadConvert();
                conversion.setLeadId(detail.leadId);
                conversion.setOwnerId(System.UserInfo.getUserId());
                conversion.setConvertedStatus('Qualified');
                conversion.setDoNotCreateOpportunity(true);
                conversionsReady.add(conversion);
            }
        }
    }

    @TestVisible
    private void commitConversion() {
        if (conversionsReady.isEmpty()) {
            return;
        }
        List<Database.LeadConvertResult> results = Database.convertLead(conversionsReady, false);
        for (Database.LeadConvertResult result : results) {
            if (!result.isSuccess()) {
                LeadConvertDetail detail = conversions.get(result.getLeadId());
                detail.error = CSLeadConversionValidator.CONVERSION_FAILURE;
                detail.errorsEncountered.add(CSLeadConversionValidator.CONVERSION_FAILURE);
                detail.errorMessage = result.getErrors().toString();
            }
        }
    }

    /**
     * @description Updates Leads with results of Auto-Conversions only
     */
    private void updateLeadsWithConversionResults() {
        List<Lead> leadsToUpdate = new List<Lead>();
        for (LeadConvertDetail detail : conversions.values()) {
            Lead lead = new Lead(Id = detail.leadId);
            lead.Auto_QC_Last_Runtime__c = System.now();
            lead.Auto_QC_Failure_Reason__c = detail.errorsEncountered.size() > 1 ? CSLeadConversionValidator.MULTIPLE_ISSUES : detail.error;
            lead.Auto_QC_Failure_Details__c = String.join(new List<String>(detail.errorsEncountered), ', ');
            lead.Auto_QC_Error_Debug__c = detail.errorMessage;
            leadsToUpdate.add(lead);
        }
        updateLeads(leadsToUpdate, false);
    }
}