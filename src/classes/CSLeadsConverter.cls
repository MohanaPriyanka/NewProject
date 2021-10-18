/**
 * @description Created by jeffparlin on 9/23/21. Validates and converts leads input by caller. Leveraged by apex and
 *      Lead Qualification/Conversion flow.
 * Tested By: CSLeadsConverterTest
 */
public without sharing class CSLeadsConverter {

    public static final String CONVERSION_FAILURE = 'Conversion Failure';
    public static final String INCOMPLETE_UALS = 'Incomplete UALs';
    public static final String PRODUCT_MISMATCH = 'System Product Mismatch';

    @TestVisible private static LeadSelector leadSelector = new LeadSelector();
    @TestVisible private static SharedSolarSystemsSelector systemsSelector = new SharedSolarSystemsSelector();
    @TestVisible private static UtilitySelector utilitySelector = new UtilitySelector();

    private Map<Id, LeadConvertDetail> conversions = new Map<Id, LeadConvertDetail>();
    private List<Database.LeadConvert> conversionsReady = new List<Database.LeadConvert>();

    public CSLeadsConverter(List<LeadConvertDetail> details) {
        for (LeadConvertDetail detail : details) {
            this.conversions.put(detail.leadId, detail);
        }
    }

    @InvocableMethod(Label='Invocable Lead Converter' Description='Converts CS Leads')
    public static List<LeadConvertDetail> invocableConvertLead(List<LeadConvertDetail> details) {
        CSLeadsConverter converter = new CSLeadsConverter(details);
        converter.execute(true);
        return details;
    }

    public void execute(Boolean flowInvocation) {
        if (flowInvocation) {
            retrieveDependencies(conversions.values()[0]);
        }
        validateInputs();
        updateLeadsWithInputs();
        constructConversionData();
        commitConversion();
    }

    /**
     * @description Retrieves dependencies needed for processing Lead Conversion when this class is executed from a
     *      Flow context
     * @param detail LeadConvertDetail object housing required Lead conversion data (inputs & outputs)
     */
    @TestVisible
    private void retrieveDependencies(LeadConvertDetail detail) {
        Lead lead = leadSelector.getLeadForLeadConversion(detail.leadId);
        Map<Id,Shared_Solar_System__c> sharedSolarSystemMap = new Map<Id, Shared_Solar_System__c>(
            systemsSelector.getSharedSolarSystemsForEnrollment()
        );
        Map<Id,Utility__c> utilitiesByIds = utilitySelector.getAllUtilitiesMap();

        detail.utilityAccountLogs = lead.Utility_Account_Logs__r;
        detail.utility = utilitiesByIds.get(lead.Utility_relationship__c);
        for (Id systemId : detail.selectedSystemIds) {
            detail.selectedSystems.add(sharedSolarSystemMap.get(systemId));
        }
    }

    @TestVisible
    private void validateInputs() {
        for (LeadConvertDetail detail : conversions.values()) {
            new CSLeadConversionValidator(detail).validate();
        }
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private void updateLeadsWithInputs() {
        List<Lead> leadsToUpdateWithInputs = new List<Lead>();
        for (LeadConvertDetail detail : conversions.values()) {
            if (detail.selectedSystems != null && detail.error != PRODUCT_MISMATCH) {
                Lead lead = new Lead(
                    Id = detail.leadId,
                    Selected_SSS_For_Conversion__c = getSelectedSystemIds(detail),
                    Product__c = detail.selectedProductId
                );
                leadsToUpdateWithInputs.add(lead);
            }
        }
        update leadsToUpdateWithInputs;
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

    private void commitConversion() {
        if (conversionsReady.isEmpty()) {
            return;
        }
        List<Database.LeadConvertResult> results = Database.convertLead(conversionsReady, false);
        for (Database.LeadConvertResult result : results) {
            if (!result.isSuccess()) {
                LeadConvertDetail detail = conversions.get(result.getLeadId());
                detail.error = CONVERSION_FAILURE;
                detail.errorsEncountered.add(CONVERSION_FAILURE);
                detail.errorMessage = result.getErrors().toString();
            }
        }
    }
}