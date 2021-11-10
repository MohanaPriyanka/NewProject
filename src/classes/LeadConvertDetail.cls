/**
 * @description Created by jeffparlin on 9/23/21. Class structure utilized in the Lead Qualification/Conversion flow and
 *     CSLeadsConverter to cache all information needed relating to Lead conversion
 * Tested by: CSLeadsConverterTest
 */
@SuppressWarnings('PMD.ExcessivePublicCount')
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
    public Integer numberOfDemandUals = 0;

    /**
     * @description Determines if Lead is a Test lead
     * @return Boolean
     */
    public Boolean isTestcaseLead() {
        return lead.LastName.toLowerCase() == 'testcase';
    }

    /**
     * @description Determines if Lead is already converted
     * @return Boolean
     */
    public Boolean isAlreadyConvertedLead() {
        return lead.IsConverted;
    }

    /**
     * @description Determines if Lead has a Split Load Zone (usually requires manual resolution)
     * @return Boolean
     */
    public Boolean hasUnresolvedSplitLoadZone() {
        return lead.LoadZone__c.contains('/');
    }

    /**
     * @description Determines if Lead has not undergone completion by applicant
     * @return Boolean
     */
    public Boolean isApplicationIncomplete() {
        return lead.Application_Complete_Date__c == null;
    }

    /**
     * @description Determines if Lead contact email has bounced
     * @return Boolean
     */
    public Boolean isEmailBounced() {
        return lead.EmailBouncedDate != null;
    }

    /**
     * @description Determines if conversion context is "Auto QC" but auto conversion is disabled on the Utility
     * @return Boolean
     */
    public Boolean isAutoConversionButAutoQCDisabled() {
        return autoConversion && !utility.Auto_Qualify_Convert_Active__c;
    }

    /**
     * @description Determines if no qualified systems were found for the lead
     * @return Boolean
     */
    public Boolean noQualifiedSystemsFound() {
        return selectedSystems.isEmpty() || selectedSystemIds.isEmpty();
    }

    /**
     * @description Determines if one or more selected systems does not match with the selected product
     *      Also accounts for Parent Product matches as is the case for the MA boilerplate/hybrid Product
     * @return Boolean
     */
    public Boolean isSystemProductMismatch() {
        for (Shared_Solar_System__c sss : selectedSystems) {
            Id parentProductId = sss.Product__r.Parent_Product__c;
            if (parentProductId == selectedProductId) {
                continue;
            }
            if (sss.Product__c != selectedProductId) {
                return true;
            }
        }
        return false;
    }

    /**
     * @description Determines if Utility Account Logs (UALs) on the Lead are not ready to process Lead Conversion
     * @return Boolean
     */
    public Boolean ualsNotReadyForConversion() {
        String subscriptionType = !selectedSystems.isEmpty() ? selectedSystems[0].Product__r?.Customer_Subscription_Type__c : null;
        for (Utility_Account_Log__c ual : utilityAccountLogs) {
            Boolean qcStatusInvalid = ual.QC_Status__c != 'Complete';
            Boolean kwhSubscriptionMissingData = subscriptionType == 'kWh' && ual.Annual_kWh__c == null;
            Boolean costSubscriptionMissingData = subscriptionType == 'Electricity Cost ($)' && ual.Annual_Cost_of_Electricity__c == null;
            Boolean missingRateClass = ual.Utility_Rate_Class__c == null;
            if (qcStatusInvalid || kwhSubscriptionMissingData || costSubscriptionMissingData || missingRateClass) {
                return true;
            }
        }
        if (utilityAccountLogs.isEmpty()) {
            return true;
        }
        return false;
    }

    /**
     * @description Determines if the Lead contains Demand UALs but there are no systems with available Demand capacity
     *      If the Lead contains Demand UALs, this also removes systems that have no Demand Capacity from the
     *      Selected Systems buckets to ensure that subscriptions are not inadvertently created on systems without demand capacity
     * @return Boolean
     */
    public Boolean noDemandCapacityAvailable() {
        if (numberOfDemandUals == 0) {
            return false;
        }
        for (Integer i = selectedSystems.size()-1; i >= 0; i--) {
            Shared_Solar_System__c sss = selectedSystems[i];
            if (sss.Available_Demand_Capacity__c <= 0) {
                selectedSystemIds.remove(i);
                selectedSystems.remove(i);
            }
        }
        return selectedSystems.size() == 0;
    }

    /**
     * @description Determines the number of Demand UALs on the Lead based on the Utility's Average Demand Threshold and
     *      each UAL's Average Demand metric, and sets the value on the respective LeadConvertDetail property
     */
    public void determineNumberOfDemandUals() {
        Decimal demandThreshold = utility.Average_Demand_Threshold__c;
        for (Utility_Account_Log__c ual : utilityAccountLogs) {
            if (demandThreshold != null && ual.Average_Demand__c != null && ual.Average_Demand__c >= demandThreshold) {
                numberOfDemandUals++;
            }
        }
    }
}