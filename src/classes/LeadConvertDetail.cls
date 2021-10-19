/**
 * @description Created by jeffparlin on 9/23/21. Class structure utilized in the Lead Qualification/Conversion flow and
 *     CSLeadsConverter to cache all information needed relating to Lead conversion
 * Tested by: CSLeadsConverterTest
 */
public without sharing class LeadConvertDetail {
    @InvocableVariable(Description='Lead Id to process Lead Conversion for' Required=true)
    public Id leadId;

    @InvocableVariable(Description='Lead Id to process Lead Conversion for' Required=true)
    public Id selectedProductId;

    @InvocableVariable(Description='Lead Id to process Lead Conversion for' Required=true)
    public List<Id> selectedSystemIds = new List<Id>();

    @InvocableVariable(Description='Error code, if encountered, from Lead Conversion attempt' Required=false)
    public String error;

    @InvocableVariable(Description='Error message, if encountered, from Lead Conversion attempt' Required=false)
    public String errorMessage;

    public Boolean autoConversion = false;
    public Lead lead;
    public List<Shared_Solar_System__c> selectedSystems = new List<Shared_Solar_System__c>();
    public List<Utility_Account_Log__c> utilityAccountLogs = new List<Utility_Account_Log__c>();
    public Set<String> errorsEncountered = new Set<String>();
    public Utility__c utility;
}