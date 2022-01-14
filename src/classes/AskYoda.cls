/**
 * @description Created by jeffparlin on 1/13/22. Moved from where it was initially built by Sarah Renfro in
 * CSQualificationService. This class serves as the basis for the data provided by the Ask Yoda Flow, which is designed
 * to showcase a list of qualified Shared Solar Systems for a Lead (either real or hypothetical Lead)
 * Tested by: CSQualificationTestclass
 */
public with sharing class AskYoda {

    public List<QualificationMatch> qualificationMatches = new List<QualificationMatch>();
    private List<Id> utilityIds = new List<Id>();
    private Lead lead;
    private String loadZone;
    private Id productId;
    private String partnerId;
    private Integer fico;
    private String underwriting;

    @SuppressWarnings('PMD.ExcessiveParameterList')
    @AuraEnabled
    public static List<QualificationMatch> getQualificationMatches(
        String leadId, String product, String partner, String zipCode, String underwriting) {
        AskYoda yoda = new AskYoda(leadId, product, partner, zipCode, underwriting);
        return yoda.qualificationMatches;
    }

    public AskYoda(Id leadId, Id productId, Id partnerId, String zipCode, String underwriting) {
        this.productId = productId;
        this.partnerId = partnerId;
        this.underwriting = underwriting;
        if (leadId != null) {
            this.lead = new LeadSelector().selectOne(leadId);
            this.utilityIds.add(this.lead.Utility_relationship__c);
            this.loadZone = this.lead.LoadZone__c;
        } else {
            assignUtilityAndLoadZones(zipCode);
        }
        this.fico = getFicoScore();
        createQualificationList();
    }

    private void assignUtilityAndLoadZones(String zipcode) {
        List<ZipCode_Utility_Junction__c> zipCodeUtilityJunctions =
            ZipcodeUtilitiesSelector.selectZipcodeUtilitiesAndLoadzones(zipcode);
        for (ZipCode_Utility_Junction__c junction : zipCodeUtilityJunctions) {
            this.utilityIds.add(junction.Utility__c);
        }
        if (!zipCodeUtilityJunctions.isEmpty()) {
            this.loadZone = zipCodeUtilityJunctions[0].Load_Zone_Utility__r.LZ__c;
        }
    }

    private Integer getFicoScore() {
        Integer creditScore;
        if (this.lead == null) {
            // Checking qualification with Partner, Product, ZIP
            // Default to a "passing" score of 700 as if an applicant meets the standard FICO requirement
            creditScore = 700;
        } else {
            // Checking qualification with an existing Lead
            creditScore = Integer.valueOf(Util.nullToZero(this.lead?.LASER_Credit_Score__c));
        }
        return Integer.valueOf(creditScore);
    }

    /**
     * @description Evaluates qualifying attributes for each pairing of Lead to SSS. Creates a list
     * of boolean maps (match Results) that are used in the CSQualificationTable LWC & Ask Yoda flow
     */
    private void createQualificationList() {
        SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
        List<Shared_Solar_System__c> sssList = sssSelector.selectSystemsForAskYoda(
            this.productId, this.utilityIds);

        for (Shared_Solar_System__c sss : sssList) {
            QualificationMatch matchResult = new QualificationMatch();
            matchResult.sss = sss;
            matchResult.isOpen = sss.Open__c;
            matchResult.hasCapacity = sss.Capacity_Available_to_be_Reserved__c > 0;
            matchResult.hasLZ = SharedSolarSystemQualifier.loadZoneInServiceTerritory(this.loadZone, sss);
            matchResult.hasPartner = SharedSolarSystemQualifier.isPartnerEligible(partnerId, sss);
            matchResult.eligiblePartners = summarizeEligiblePartners(sss.Partner_Shared_Solar_System_Accesses__r);
            matchResult.underwritingOptions = summarizeUnderwritingOptions(sss);

            Boolean meetsPaymentCriteria =
                this.lead == null ? true : SharedSolarSystemQualifier.meetsPaymentCriteria(this.lead, sss);
            Boolean meetsUnderwritingCriteria;

            switch on (this.underwriting) {
                when 'FICO' {
                    meetsUnderwritingCriteria =
                        sss.Available_SMB_Underwriting_Method_FICO__c && this.fico >= sss.Credit_Score_Requirement__c;
                } when 'Financial Review' {
                    meetsUnderwritingCriteria = sss.Available_SMB_Underwriting_Method_Docs__c;
                } when 'None' {
                    meetsUnderwritingCriteria = sss.Do_Not_Underwrite__c;
                }
            }
            matchResult.isUnderwritten = meetsUnderwritingCriteria == meetsPaymentCriteria;

            if (matchResult.isOpen &&
                matchResult.hasCapacity &&
                matchResult.hasLZ &&
                matchResult.hasPartner &&
                matchResult.isUnderwritten
                ) {
                matchResult.completeMatch = true;
            }
            this.qualificationMatches.add(matchResult);
        }
    }

    /**
     * @description Returns a semi-colon delimited list of partners from the list of Partner SSS Eligibility records
     * @param partnerEligibilities List of eligibility records to summarize
     * @return Summary
     */
    private static String summarizeEligiblePartners(List<Partner_Shared_Solar_System_Eligibility__c> partnerEligibilities) {
        String eligiblePartners = '';
        for (Partner_Shared_Solar_System_Eligibility__c eligibility : partnerEligibilities) {
            eligiblePartners += eligibility.Account__r.Name + '; ';
        }
        return eligiblePartners.removeEnd('; ');
    }

    private static String summarizeUnderwritingOptions(Shared_Solar_System__c sss) {
        String options = '';
        if (sss.Do_Not_Underwrite__c) {
            return 'No underwriting necessary';
        }
        if (sss.Available_SMB_Underwriting_Method_FICO__c) {
            options += 'FICO with ' + sss.Credit_Score_Requirement__c + ' Minimum; ';
        }
        if (sss.Available_SMB_Underwriting_Method_Docs__c) {
            options += 'Financial Review with ' + sss.RiskCalc_Minimum__c + ' Minimum; ';
        }
        if (sss.Do_Not_Ask_for_Payment_Method__c) {
            options += 'No Payment Details Required ';
        } else {
            options += 'Payment Details Required';
        }
        return options;
    }

    public virtual class QualificationMatch {
        @AuraEnabled public Shared_Solar_System__c sss;
        @AuraEnabled public Boolean completeMatch = false;
        @AuraEnabled public Boolean isOpen = false;
        @AuraEnabled public Boolean hasCapacity = false;
        @AuraEnabled public Boolean hasLZ = false;
        @AuraEnabled public Boolean hasPartner = false;
        @AuraEnabled public Boolean isUnderwritten = false;
        @AuraEnabled public String eligiblePartners;
        @AuraEnabled public String underwritingOptions;
    }
}