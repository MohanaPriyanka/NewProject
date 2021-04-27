/**
 * Created by SarahRenfro on 5/22/2019.
 * Tested by: CSQualificationTestclass
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CSQualificationService {
    private static SharedSolarSystemsSelector systemsSelector = new SharedSolarSystemsSelector();
    private static CreditReportSelector creditReportSelector = new CreditReportSelector();
    private static Map<Id, Lead> leadMap = new Map<Id, Lead>();

    @TestVisible private  fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<Schema.SObjectType> {
            LASERCA__Personal_Credit_Report__c.SObjectType,
            Lead.SObjectType
        }
    );

    /**
     * @description Sets the qualification Status for a Lead generated on the SSF platform when the application
     * is marked as 'Complete'.
     * <br><br>
     * NOTE: Qualification for Leads with FICO underwriting is processed by the CreditReportLogTrigger and not
     * handled in this method. See CSQualificationService.underwriteLeadWithFICO()
     * @param lead Lead record
     */
    public void qualifyLead(Lead lead) {
        String leadStatus;
        switch on lead.Underwriting_Criteria__c {
            when 'Financial Review' {
                leadStatus = underwriteWithFinancialReview(lead);
            }
            when 'None' {
                SharedSolarSystems qualDomain = new SharedSolarSystems(systemsSelector.getSharedSolarSystemsForEnrollment());
                leadStatus = qualDomain.checkCSQualification(lead, null);
            }
        }
        lead.Status = leadStatus != null ? leadStatus : lead.Status;
    }

    /**
     * @description Run from CreditReportLogTrigger on LASERCA__Credit_Report_Log__c generation to auto-qualify lead
     * @param triggerNewMap LASERCA__Credit_Report_Log__c Trigger.NEW
     * @param triggerOldMap LASERCA__Credit_Report_Log__c Trigger.OLD
     */
    public void checkCreditReportLog(Map<Id,LASERCA__Credit_Report_Log__c> triggerNewMap, Map<Id,LASERCA__Credit_Report_Log__c> triggerOldMap) {
        Set<Id> pcrIds = new Set<Id>();
        List<LASERCA__Credit_Report_Log__c> errorCRLs = new List<LASERCA__Credit_Report_Log__c>();
        List<String> leadIds = new List<String>();
        for (LASERCA__Credit_Report_Log__c crl : triggerNewMap.values()) {
            leadIds.add(crl.LASERCA__Lead__c);
            if (crl.LASERCA__Status__c == 'ERROR') {
                errorCRLs.add(crl);
            } else {
                pcrIds.add(crl.LASERCA__Personal_Credit_Report__c);
            }
        }
        leadMap = new LeadSelector().getLeadMap(leadIds);
        if (errorCRLs.size() > 0 ) {
            handleErrorCRL(errorCRLs[0]);
        }
        List<LASERCA__Personal_Credit_Report__c> completedPCRs = creditReportSelector.getCompletedPCRs(pcrIds);
        underwriteLeadWithFICO(completedPCRs);

        try {
            uow.commitWork();
        } catch (Exception e) {
            Logger.logLater(
                'CSQualificationService',
                'checkCreditReportLog',
                e.getMessage() + '\n' + e.getStackTraceString()
            );
        }
    }

    /**
     * @description If a Credit Report is returned with Status = ERROR, we create a blank PCR to be used in
     * underwriting. The blank PCR will be populated with a score of 9999, resulting in a case to resolve
     *
     * @param errorCRL CRL with Status = Error
     */
    private void handleErrorCRL(LASERCA__Credit_Report_Log__c errorCRL) {
        LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c();
        pcr.Name = 'NO MATCH for Lead: ';
        pcr.LASERCA__Lead__c = errorCRL.LASERCA__Lead__c;
        insert pcr;

        Lead lead = leadMap.get(errorCRL.LASERCA__Lead__c);
        lead.Personal_Credit_Report__c = pcr.Id;
        uow.registerDirty(lead);
        underwriteLeadWithFICO(new List<LASERCA__Personal_Credit_Report__c>{pcr});
    }

    /**
     * @description Reads the PCR for a lead and runs qualification logic based off credit score.
     * If credit score is a real score, close all related FICO Cases.
     *
     * @param pcrs Personal Credit Reports to be evaluated
     */
    private void underwriteLeadWithFICO(List<LASERCA__Personal_Credit_Report__c> pcrs) {
        SharedSolarSystems sharedSolarSystems = new SharedSolarSystems(systemsSelector.getSharedSolarSystemsForEnrollment());
        for (LASERCA__Personal_Credit_Report__c creditReport : pcrs) {
            Lead lead = leadMap.get(creditReport.LASERCA__Lead__c);
            Decimal creditScore = 0;
            if (creditReport.LASERCA__Credit_Score__c == null) {
                creditScore = 9999;
                handleNoMatchCreditPull(creditReport, lead);
            } else if (creditReport.LASERCA__Credit_Score__c != '9999') {
                creditScore = Decimal.valueOf(creditReport.LASERCA__Credit_Score__c);
                closeReportMissingCases(lead);
            }
            lead.Status = sharedSolarSystems.checkCSQualification(lead, creditScore);
            uow.registerDirty(lead);
        }
    }

    /**
     * @description Returns the qualification status for a Lead which utilizes Financial Review underwriting
     * @param lead Lead record
     * @return String
     */
    private String underwriteWithFinancialReview(Lead lead) {
        Set<Id> financialUnderwritingIds = new Set<Id>();
        if (lead == null) {
            return null;
        }
        if (lead.Underwrite_Financial_Documents__r != null) {
            for (Financial_Underwriting_Document__c fud : lead.Underwrite_Financial_Documents__r) {
                financialUnderwritingIds.add(fud.Id);
            }
        }

        // Verify that we have financial documents to review
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

    /**
     * @description If score is missing, populates PCR with 9999 to be resolved later. Creates a case to resolve
     * missing credit score for completed applications.
     *
     * @param noMatchPCR Personal Credit Report missing a credit score
     * @param lead Lead related to the PCR
     */
    private void handleNoMatchCreditPull(LASERCA__Personal_Credit_Report__c noMatchPCR, Lead lead) {
        noMatchPCR.LASERCA__Credit_Score_TransUnion__c = '9999';
        noMatchPCR.LASERCA__Credit_Score__c = '9999';
        uow.registerDirty(noMatchPCR);
        if (lead.LeadSource == 'CSAP' || lead.Application_Complete_Date__c != null) {
            createNoMatchFICOCase(lead);
        }
    }

    private void createNoMatchFICOCase(Lead lead) {
        CaseFactory noMatchFactory  = new CaseFactory();
        noMatchFactory.setLead(lead);
        noMatchFactory.setQueueType('No FICO Match');
        System.enqueueJob(noMatchFactory);
    }

    /**
     * @description If after running qualification logic (SharedSolarSystems) the lead's credit score does not meet
     * any of the open project's credit minimum, the Lead should be flagged as "Unqualified due to FICO" and have an
     * Adverse Credit Notice email sent automatically
     *
     * @param lead Lead that is unqualified due to FICO
     */
    public static void handleLeadUnqualifiedDueToFICO(Lead lead) {
        if (!lead.Unqualified_due_to_FICO__c){
            lead.Unqualified_due_to_FICO__c = true;
            sendAdverseCreditNotice(lead);
        }
    }

    private static void sendAdverseCreditNotice(Lead lead) {
        MessagingService.EmailEnvelope ee = new MessagingService.EmailEnvelope();
        ee.emailTemplateName = 'CS_Customer_Credit_Denied';
        ee.orgWideEmail =  MessagingService.getCustomerCareEmail().Address;
        ee.addressList = new List<String>{lead.Email};
        ee.subjectLine = 'Your BlueWave Community Solar Application Has Been Denied';
        ee.sobjectId = lead.Id;
        MessagingService.ReplacementText leadName = new MessagingService.ReplacementText('{!Lead.FirstName}', lead.Name);
        MessagingService.ReplacementText creditDate = new MessagingService.ReplacementText('{!Lead.Date_of_Credit_Report__c}', lead.Date_of_Credit_Report__c.format());
        MessagingService.ReplacementText creditScore = new MessagingService.ReplacementText('{!Lead.LASER_Credit_Score__c}', lead.LASER_Credit_Score__c);
        MessagingService.ReplacementText detail1 = new MessagingService.ReplacementText('{!Lead.Credit_Report_Detail_1__c}', lead.Credit_Report_Detail_1__c);
        MessagingService.ReplacementText detail2 = new MessagingService.ReplacementText('{!Lead.Credit_Report_Detail_2__c}', lead.Credit_Report_Detail_2__c);
        MessagingService.ReplacementText detail3 = new MessagingService.ReplacementText('{!Lead.Credit_Report_Detail_3__c}', lead.Credit_Report_Detail_3__c);
        MessagingService.ReplacementText detail4 = new MessagingService.ReplacementText('{!Lead.Credit_Report_Detail_4__c}', lead.Credit_Report_Detail_4__c);
        ee.replacementTexts = new List<MessagingService.ReplacementText>{leadName, creditDate, creditScore, detail1, detail2, detail3, detail4 };
        MessagingService.sendEmailTemplate(ee);
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
            List<ZipCode_Utility_Junction__c> zipCodeUtilityJunctions = ZipcodeUtilitiesSelector.selectZipcodeUtilitiesAndLoadzones(zipcode);
            for (ZipCode_Utility_Junction__c junction : zipCodeUtilityJunctions) {
                this.utilityIds.add(junction.Utility__c);
            }
            this.loadZone = zipCodeUtilityJunctions[0].Load_Zone_Utility__r.LZ__c;
        }

        /**
         * @description Evaluates qualifying attributes for each pairing of Lead to SSS. Creates a list
         * of boolean maps (match Results)  that are used in the CSQualificationTable LWC.
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
        CaseSelector caseSelector = new CaseSelector();
        List<Case> cases = caseSelector.selectOpenNoMatchCasesFromLead(lead);
        cases.addAll(caseSelector.selectOpenLowMatchCasesFromLead(lead));
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