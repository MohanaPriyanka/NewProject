/**
 * @description Created by SarahRenfro on 5/22/2019.
 * Tested by: CSQualificationTestclass
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CSQualificationService {

    private static SharedSolarSystemsSelector systemsSelector = new SharedSolarSystemsSelector();
    private static CreditReportSelector creditReportSelector = new CreditReportSelector();
    private static Map<Id, Lead> leadMap = new Map<Id, Lead>();

    @TestVisible private fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<Schema.SObjectType>{
            LASERCA__Personal_Credit_Report__c.SObjectType,
            LASERCA__Credit_Report_Log__c.SObjectType,
            Lead.SObjectType
        }
    );

    /**
     * @description Runs a CS Qualification check for an input Lead, and sets the Lead Status accordingly
     * @param lead Lead record
     */
    public void qualifyLead(Lead lead) {
        String leadStatus;
        SharedSolarSystems qualifier = new SharedSolarSystems(systemsSelector.getSharedSolarSystemsForEnrollment());
        leadStatus = qualifier.checkCSQualification(lead, lead.LASER_Credit_Score__c);
        lead.Status = leadStatus != null ? leadStatus : lead.Status;
    }

    /**
     * @description Run from CreditReportLogTrigger on LASERCA__Credit_Report_Log__c generation to auto-qualify lead
     * @param triggerNewMap LASERCA__Credit_Report_Log__c Trigger.NEW
     */
    public void checkCreditReportLog(Map<Id, LASERCA__Credit_Report_Log__c> triggerNewMap) {
        SharedSolarSystemQualifier.ignoreLoadZones(); // Set to ignore load zones for qualification check (in case of split LZ)
        Set<Id> pcrIds = new Set<Id>();
        List<LASERCA__Credit_Report_Log__c> errorCRLs = new List<LASERCA__Credit_Report_Log__c>();
        List<String> leadIds = new List<String>();
        for (LASERCA__Credit_Report_Log__c crl : triggerNewMap.values()) {
            leadIds.add(crl.LASERCA__Lead__c);
            if (isErrorCRL(crl)) {
                errorCRLs.add(crl);
            } else {
                pcrIds.add(crl.LASERCA__Personal_Credit_Report__c);
            }
        }
        leadMap = new LeadSelector().getLeadMap(leadIds);
        handleErrorCRL(errorCRLs);
        List<LASERCA__Personal_Credit_Report__c> completedPCRs = creditReportSelector.getCompletedPCRs(pcrIds);
        underwriteLeadWithFICO(completedPCRs);

        try {
            // We want to prevent the CRLTrigger from running again and entering an infinite loop (since uow could be
            // updating an error CRL with a No Match PCR.
            Util.disableTrigger('Disable_CreditReportLogTrigger__c');
            uow.commitWork();
        } catch (Exception e) {
            Logger.logNow(
                'CSQualificationService',
                'checkCreditReportLog',
                e.getMessage() + '\n' + e.getStackTraceString()
            );
        } finally {
            Util.enableTrigger('Disable_CreditReportLogTrigger__c');
        }
    }

    private Boolean isErrorCRL(LASERCA__Credit_Report_Log__c crl) {
        Boolean errorWithNoPCR = crl.LASERCA__Status__c == 'Error' && crl.LASERCA__Personal_Credit_Report__c == null;
        Boolean pcrNotScored = crl.LASERCA__Personal_Credit_Report__c != null && crl.File_Not_Scored__c;
        return errorWithNoPCR || pcrNotScored;
    }

    /**
     * @description If a Credit Report is returned with Status = ERROR, we create a blank PCR to be used in
     * underwriting. The blank PCR will be populated with a score of "null", resulting in a case to resolve
     * @param errorCRLs CRLs with Status = Error
     */
    private void handleErrorCRL(List<LASERCA__Credit_Report_Log__c> errorCRLs) {
        List<LASERCA__Personal_Credit_Report__c> noMatchPCRs = new List<LASERCA__Personal_Credit_Report__c>();
        for (LASERCA__Credit_Report_Log__c errorCRL : errorCRLs) {
            LASERCA__Personal_Credit_Report__c pcr;
            if (errorCRL.LASERCA__Personal_Credit_Report__c == null) {
                pcr = new LASERCA__Personal_Credit_Report__c(
                    Name = 'NO MATCH for Lead: ',
                    LASERCA__Lead__c = errorCRL.LASERCA__Lead__c,
                    LASERCA__Credit_Score__c = null
                );
                uow.registerNew(pcr);
                LASERCA__Credit_Report_Log__c crl = new LASERCA__Credit_Report_Log__c(
                    Id = errorCRL.Id,
                    LASERCA__Personal_Credit_Report__c = pcr.Id
                );
                uow.registerDirty(crl, LASERCA__Credit_Report_Log__c.LASERCA__Personal_Credit_Report__c, pcr);
            } else {
                pcr = new LASERCA__Personal_Credit_Report__c(
                    Id = errorCRL.LASERCA__Personal_Credit_Report__c,
                    LASERCA__Lead__c = errorCRL.LASERCA__Lead__c,
                    LASERCA__Credit_Score__c = null
                );
                uow.registerDirty(pcr);
            }
            noMatchPCRs.add(pcr);
            Lead pcrLead = leadMap.get(errorCRL.LASERCA__Lead__c);
            pcrLead.Personal_Credit_Report__c = pcr.Id;
            uow.registerDirty(pcrLead, Lead.Personal_Credit_Report__c, pcr);
            if (pcrLead.Application_Complete_Date__c != null) {
                createNoMatchFICOCase(pcrLead);
            }
        }
        underwriteLeadWithFICO(noMatchPCRs);
    }

    /**
     * @description Reads the PCR for a lead and runs qualification logic based off credit score.
     * If credit score is a real score, close all related FICO Cases.
     * @param pcrRecords Personal Credit Reports to be evaluated
     */
    private void underwriteLeadWithFICO(List<LASERCA__Personal_Credit_Report__c> pcrRecords) {
        SharedSolarSystems sharedSolarSystems = new SharedSolarSystems(systemsSelector.getSharedSolarSystemsForEnrollment());
        for (LASERCA__Personal_Credit_Report__c creditReport : pcrRecords) {
            Lead lead = leadMap.get(creditReport.LASERCA__Lead__c);
            if (creditReport.LASERCA__Credit_Score__c != null) {
                closeReportMissingCases(lead);
            }
            String newLeadStatus = sharedSolarSystems.checkCSQualification(lead, creditReport.LASERCA__Credit_Score__c);
            lead.Status = newLeadStatus;
            uow.registerDirty(lead);
        }
    }

    private void createNoMatchFICOCase(Lead lead) {
        CaseFactory noMatchFactory = new CaseFactory();
        noMatchFactory.setLead(lead);
        noMatchFactory.setQueueType('No FICO Match');
        System.enqueueJob(noMatchFactory);
    }

    /**
     * @description If after running qualification logic (SharedSolarSystems) the lead's credit score does not meet
     * any of the open project's credit minimum, the Lead should be flagged as "Unqualified due to FICO" and have an
     * Adverse Credit Notice email sent automatically
     * @param lead Lead that is unqualified due to FICO
     */
    public static void handleLeadUnqualifiedDueToFICO(Lead lead) {
        if (!lead.Unqualified_due_to_FICO__c) {
            lead.Unqualified_due_to_FICO__c = true;
            sendAdverseCreditNotice(lead);
        }
    }

    public static void sendAdverseCreditNotice(Lead lead) {
        MessagingService.EmailEnvelope ee = new MessagingService.EmailEnvelope();
        ee.emailTemplateName = 'CS_Customer_Credit_Denied';
        ee.orgWideEmail = MessagingService.getCustomerCareEmail().Address;
        ee.addressList = new List<String>{
            lead.Email
        };
        ee.subjectLine = 'Your {!$Label.Company_Name} Community Solar Application Has Been Denied';
        ee.sobjectId = lead.Id;
        MessagingService.ReplacementText leadName = new MessagingService.ReplacementText(
            '{!Lead.FirstName}', lead.Name
        );
        MessagingService.ReplacementText creditDate = new MessagingService.ReplacementText(
            '{!Lead.Date_of_Credit_Report__c}', lead.Date_of_Credit_Report__c.format()
        );
        MessagingService.ReplacementText creditScore = new MessagingService.ReplacementText(
            '{!Lead.LASER_Credit_Score__c}', lead.LASER_Credit_Score__c == null ? 'N/A' : lead.LASER_Credit_Score__c
        );
        MessagingService.ReplacementText detail1 = new MessagingService.ReplacementText(
            '{!Lead.Credit_Report_Detail_1__c}', lead.Credit_Report_Detail_1__c
        );
        MessagingService.ReplacementText detail2 = new MessagingService.ReplacementText(
            '{!Lead.Credit_Report_Detail_2__c}', lead.Credit_Report_Detail_2__c
        );
        MessagingService.ReplacementText detail3 = new MessagingService.ReplacementText(
            '{!Lead.Credit_Report_Detail_3__c}', lead.Credit_Report_Detail_3__c
        );
        MessagingService.ReplacementText detail4 = new MessagingService.ReplacementText(
            '{!Lead.Credit_Report_Detail_4__c}', lead.Credit_Report_Detail_4__c
        );
        MessagingService.ReplacementText creditprovider = new MessagingService.ReplacementText(
            '{!Lead.Credit_Provider__c}', lead.Credit_Provider__c
        );
        MessagingService.ReplacementText creditprovideraddress = new MessagingService.ReplacementText(
            '{!Lead.Credit_Provider_Address__c}', lead.Credit_Provider_Address__c
        );
        ee.replacementTexts = new List<MessagingService.ReplacementText>{
            leadName, creditDate, creditScore, detail1, detail2, detail3, detail4, creditprovider, creditprovideraddress
        };
        MessagingService.sendEmailTemplate(ee);
    }

    /**
     * @description Sends the lead the "unable to approve your application" email if the lead's status is not already
     * Unqualified. Assumes the caller will then set the lead's status to unqualified
     * @param lead The lead to get the email
     */
    public static void sendGenericUnqualifiedNotice(Lead lead) {
        MessagingService.EmailEnvelope ee = new MessagingService.EmailEnvelope();
        ee.emailTemplateName = 'Credit Denied - No FICO product';
        ee.orgWideEmail = MessagingService.getCustomerCareEmail().Address;
        ee.addressList = new List<String>{
            lead.Email
        };
        ee.subjectLine = 'Sorry, we were unable to approve your application';
        ee.sobjectId = lead.Id;
        MessagingService.ReplacementText leadName = new MessagingService.ReplacementText(
            '{!Lead.FirstName}', lead.FirstName
        );
        ee.replacementTexts = new List<MessagingService.ReplacementText>{
            leadName
        };
        MessagingService.sendEmailTemplate(ee);
    }

    public static void closeReportMissingCases(Lead lead) {
        CaseSelector caseSelector = new CaseSelector();
        List<Case> cases = caseSelector.selectOpenNoMatchCasesFromLead(lead);
        cases.addAll(caseSelector.selectOpenLowMatchCasesFromLead(lead));
        for (Case c : cases) {
            c.Status = 'Closed';
        }
        update cases;
    }
}