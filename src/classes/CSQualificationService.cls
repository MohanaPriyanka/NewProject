/**
 * Created by SarahRenfro on 5/22/2019.
 *
 * Test: CSQualificationTestclass
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CSQualificationService {
    private static SharedSolarSystemsSelector systemsSelector = new SharedSolarSystemsSelector();
    private static CreditReportSelector creditReportSelector = new CreditReportSelector();
    private static Map<Id, Lead> leadMap = new Map<Id, Lead>();

    public static void checkCreditReportLog(
        Map<Id, LASERCA__Credit_Report_Log__c> triggerNewMap,
        Map<Id, LASERCA__Credit_Report_Log__c> triggerOldMap) {
        Set<Id> pcrIds = new Set<Id>();
        List<LASERCA__Credit_Report_Log__c> errorLogs = new List<LASERCA__Credit_Report_Log__c>();

        List<String> leadIds = new List<String>();
        for (LASERCA__Credit_Report_Log__c crl : triggerNewMap.values()) {
            leadIds.add(crl.LASERCA__Lead__c);
        }

        leadMap = LeadSelector.getLeadMap(leadIds);
        if (leadMap.values().size()== 0 ) {
            return;
        }

        if (triggerOldMap == null) {
            for (LASERCA__Credit_Report_Log__c crl : triggerNewMap.values()) {
                switch on crl.LASERCA__Status__c {
                    when 'Completed' {
                        pcrIds.add(crl.LASERCA__Personal_Credit_Report__c);
                    } when 'Error' {
                        errorLogs.add(crl);
                    }
                }
            }
        } else {
            for (Id oldId : triggerOldMap.keySet()) {
                if (triggerNewMap.get(oldId).LASERCA__Status__c == 'Completed' &&
                        triggerOldMap.get(oldId).LASERCA__Status__c != 'Completed') {
                    pcrIds.add(triggerNewMap.get(oldId).LASERCA__Personal_Credit_Report__c);
                }
            }
        }

        List<LASERCA__Personal_Credit_Report__c> completedPCRs = creditReportSelector.getCompletedPCRs(pcrIds);
        List<Lead> updateLeads = new List<Lead>();
        updateLeads = underwriteLeadWithFICO(completedPCRs);
        if (errorLogs.size() > 0 ) {
           updateLeads.addAll(handleNoMatchCreditPull(errorLogs));
        }

        update updateLeads;
    }
    public static List<Lead> underwriteLeadWithFICO(List<LASERCA__Personal_Credit_Report__c> pcrs) {
        SharedSolarSystems sharedSolarSystems = new SharedSolarSystems(systemsSelector.getSharedSolarSystemsForEnrollment());
        List<Lead> leadsToUpdate = new List<Lead>();
        for (LASERCA__Personal_Credit_Report__c creditReport : pcrs) {
            Lead lead = leadMap.get(creditReport.LASERCA__Lead__c);
            Decimal creditScore = 0;
            if (creditReport.LASERCA__Credit_Score__c != null){
                creditScore = Decimal.valueOf(creditReport.LASERCA__Credit_Score__c);
                closeReportMissingCases(lead);
            }
            if (creditReport.Approval_Status__c =='Declined') {
                CaseFactory lowMatchFactory = new CaseFactory();
                lowMatchFactory.setLead(lead);
                lowMatchFactory.setQueueType('Low FICO Match');
                System.enqueueJob(lowMatchFactory);
            }
            lead.Status = sharedSolarSystems.checkCSQualification(lead, creditScore);
            leadsToUpdate.add(lead);
        }
        return leadsToUpdate;
    }

    public static List<Lead> handleNoMatchCreditPull(List<LASERCA__Credit_Report_Log__c> creditReportLogs) {
        List<Lead> leadsToUpdate = new List<Lead>();
        SharedSolarSystems sharedSolarSystems = new SharedSolarSystems(systemsSelector.getSharedSolarSystemsForEnrollment());
        List<LASERCA__Personal_Credit_Report__c> updatePCRs = new List<LASERCA__Personal_Credit_Report__c>();
        for (LASERCA__Credit_Report_Log__c crl : creditReportLogs) {
            Lead lead = leadMap.get(crl.LASERCA__Lead__c);
            lead.Status = 'Unqualified';
            //TODO: Once we decide how to handle change in PCRs being returned by LASERCA, we can just remove this block
            if (crl.LASERCA__Personal_Credit_Report__c != null) {
                LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c(
                    Id = crl.LASERCA__Personal_Credit_Report__c,
                    LASERCA__Credit_Score_TransUnion__c = '9999',
                    LASERCA__Credit_Score__c = '9999');

                updatePCRs.add(pcr);
                lead.Status = sharedSolarSystems.checkCSQualification(lead, 9999);
            }
            update updatePCRs;

            if (lead.LeadSource == 'CSAP' || lead.Application_Complete_Date__c != null) {
                CaseFactory noMatchFactory  = new CaseFactory();
                noMatchFactory.setLead(lead);
                noMatchFactory.setQueueType('No FICO Match');
                leadsToUpdate.add(lead);
                System.enqueueJob(noMatchFactory);
            }
        }
        return leadsToUpdate;
    }

    public String underwriteWithFinancialReview(Lead lead){
        if( lead == null) {
            return null;
        }

        Set<Id> financialUnderwritingIds = new Set<Id>();
        if (lead.Underwrite_Financial_Documents__r != null) {
            for(Financial_Underwriting_Document__c fud : lead.Underwrite_Financial_Documents__r) {
                financialUnderwritingIds.add(fud.Id);
            }
        }

        List<ContentDocumentLink> contentDocLinks = new List<ContentDocumentLink>();
        if (!financialUnderwritingIds.isEmpty()) {
            contentDocLinks = [SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :financialUnderwritingIds];
        }
        SharedSolarSystems sharedSolarSystems = new SharedSolarSystems(systemsSelector.getSharedSolarSystemsForEnrollment());

        String result = 'Unqualified';
        if (!contentDocLinks.isEmpty()) {
            result = sharedSolarSystems.checkCSQualification(lead, null);
        }
        return result;
    }

    public virtual class QualificationMatch {
        @AuraEnabled
        public Shared_Solar_System__c sss;
        @AuraEnabled
        public Boolean completeMatch = false;
        @AuraEnabled
        public Boolean isOpen = false;
        @AuraEnabled
        public Boolean hasCapacity = false;
        @AuraEnabled
        public Boolean hasLZ = false;
        @AuraEnabled
        public Boolean hasPartner = false;
        @AuraEnabled
        public Boolean isUnderwritten = false;
        @AuraEnabled
        public String eligiblePartners;
        @AuraEnabled
        public String underwritingOptions;
    }

    public class QualificationInput {
        public  List<QualificationMatch> qualificationMatches = new List<QualificationMatch>();
        private List<Id> utilityIds = new List<Id>();
        private Lead lead;
        private String loadZone;
        private Id productId;
        private String partnerId;
        private Integer fico;
        private String underwriting;

        public QualificationInput(Id leadId, Id productId, Id partnerId, String zipCode, String underwriting) {
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

            if (fico != null) {
                this.fico = Integer.valueOf(fico);
            } else if (this.lead != null) {
                this.fico = (this.lead.LASER_Credit_Score__c == null ? 0 : Integer.valueOf(this.lead.LASER_Credit_Score__c));
            } else {
                this.fico = 999;
            }
        }

        private void assignUtilityAndLoadZones(String zipcode) {
            List<ZipCode_Utility_Junction__c> zipCodeUtilityJunctions = ZipcodeUtilitiesSelector.selectZipcodeUtilitiesAndLoadzones(zipCode);
            for (ZipCode_Utility_Junction__c junction : zipCodeUtilityJunctions) {
                this.utilityIds.add(junction.Utility__c);
            }
            this.loadZone = zipCodeUtilityJunctions[0].Load_Zone_Utility__r.LZ__c;
        }

        /**
         * @description Evaluates qualifying attributes for each pairing of Lead to SSS. Creates a list
          * of boolean maps (match Results)  that are used in the CSQualificationTable LWC.
         *
         */
        public void createQualificationList() {
            SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
            List<Shared_Solar_System__c> sssList = sssSelector.selectSharedSolarSystemsForQualificationCheck(this.productId, this.utilityIds);

            for (Shared_Solar_System__c sss : sssList) {
                QualificationMatch matchResult = new QualificationMatch();
                matchResult.sss = sss;
                if (sss.Open__c) {
                    matchResult.isOpen = true;
                }
                if (sss.Capacity_Available_to_be_Reserved__c > 0) {
                    matchResult.hasCapacity = true;
                }

                matchResult.hasLZ = SharedSolarSystems.loadZoneInServiceTerritory(this.loadZone, sss);
                matchResult.hasPartner = SharedSolarSystems.isPartnerEligible(partnerId, sss);
                matchResult.eligiblePartners = summarizeEligiblePartners(sss.Partner_Shared_Solar_System_Accesses__r);
                matchResult.underwritingOptions = summarizeUnderwritingOptions(sss);

                Boolean meetsPaymentCriteria = (this.lead == null ? true : SharedSolarSystems.meetsPaymentCriteria(this.lead, sss));
                Boolean meetsUnderwritingCriteria;

                switch on (this.underwriting) {
                    when 'FICO' {
                        meetsUnderwritingCriteria= sss.Available_SMB_Underwriting_Method_FICO__c && this.fico >= sss.Credit_Score_Requirement__c;
                    } when 'Financial Review' {
                        meetsUnderwritingCriteria = sss.Available_SMB_Underwriting_Method_Docs__c;
                    } when else {
                        meetsUnderwritingCriteria = true;
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
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    @AuraEnabled
    public static List<QualificationMatch> getQualificationMatches(String leadId, String product, String partner, String zipCode, String underwriting) {
        QualificationInput input = new QualificationInput(leadId, product, partner, zipCode, underwriting);
        input.createQualificationList();
        return input.qualificationMatches;
    }

    public static void closeReportMissingCases(Lead lead) {
        List<Case> cases = new CaseSelector().selectOpenNoMatchCasesFromLead(lead);
        if (cases.size() > 0) {
            for (Case c : cases) {
                c.Status = 'Closed';
            }
            update cases;
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

}