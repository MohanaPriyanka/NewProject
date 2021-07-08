/**
 * Created by jeffparlin on 6/28/21.
 * @description Processes CS Leads which have entered an 'Application Complete' state, called from varying contexts
 * Tested By: CSLeadsRESTControllerV2Test
 */
public without sharing class CSApplicationFinisher {

    @TestVisible private static LeadSelector leadSelector = new LeadSelector();
    @TestVisible private static FeatureSelector featureSelector = new FeatureSelector();
    @TestVisible private static CSQualificationService qualificationService = new CSQualificationService();
    @TestVisible private static LeadService leadService = new LeadService();

    /**
     * @description Performs required actions when a CS Lead is marked as "complete" by SSF or API
     * Runs in async @future context.
     * @param leadId CS Lead record to process
     * @param setApplicationCompleteDate Set application complete date on Lead via Apex when called?
     */
    @Future
    public static void execute(Id leadId, Boolean setApplicationCompleteDate) {
        // Locate lead
        Lead lead = leadSelector.selectOne(leadId);
        if (lead == null) {
            String message = 'Unable to process CS lead application complete steps. Reprocess manually. Inputs:\nleadId: '
                + leadId + '\nsetApplicationCompleteDate: ' + setApplicationCompleteDate;
            Logger.logNow('CSApplicationFinisher', 'execute', message, Logger.ERROR);
            return;
        }

        // Perform actions on CS Lead application complete
        updateLeadOnComplete(lead, setApplicationCompleteDate);
        createAndSendCSPartnerEmail(lead);
        createQCCaseForNoMatchPCR(lead);
        UtilityDataRequestBuilder.createUDRs(new List<Id>{lead.Id});
        if (lead.No_Payment__c == false) {
            ZuoraAccountService.createAccounts(new Set<Id>{lead.Id});
        }
    }

    private static void updateLeadOnComplete(Lead lead, Boolean setApplicationCompleteDate) {
        if (setApplicationCompleteDate) {
            lead.Application_Complete_Date__c = Datetime.now();
        }
        lead.Application_Status__c = 'Application Completed';
        try {
            CSLeadsRESTControllerV2.setContinueApplicationLinks(lead, 'Application Completed');
            qualificationService.qualifyLead(lead);
            leadService.updateLead(lead);
        } catch (Exception e) {
            String message = 'Failed to update lead on application complete.\n\n' + e.getMessage() + '\n\n' + e.getStackTraceString();
            Logger.logNow('CSApplicationFinisher', 'updateLeadOnComplete', message, Logger.ERROR);
        }
    }

    /**
     * @description Method to send an email to the related Partner when the customer has completed their SSF
     * Application
     * @param Lead Lead that has completed the application
     */
    @TestVisible
    private static void createAndSendCSPartnerEmail(Lead lead) {
        System_Default__mdt systemDefault = featureSelector.getSystemDefaults();
        if (systemDefault.Application_Complete_Email_Template__c == null || lead?.Partner_Email__c == null) {
            Logger.logNow('CSLeadsService', 'createAndSendCSPartnerEmail',
                'Email was not sent to Partner for lead: ' + lead.Id + '; First confirm ' +
                    'that there is an email template found in System Default custom metadata. ' +
                    'Then confirm the lead is populated with a Partner Email.', Logger.WARN);
            return;
        }
        EmailTemplate template = MessagingService.getHtml(systemDefault.Application_Complete_Email_Template__c);
        String templateHtml = template.HtmlValue;
        templateHtml = templateHtml.replace('{{{Recipient.Name}}}', lead.Name);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setOrgWideEmailAddressId(MessagingService.getCustomerCareEmail().Id);
        mail.setSubject('Application Completed for ' + lead.Name);
        mail.setHtmlBody(templateHtml);
        mail.setToAddresses(new List<String>{lead.Partner_Email__c});
        mail.setTargetObjectId(lead.Id);
        mail.setSaveAsActivity(true);
        mail.setTreatTargetObjectAsRecipient(false);

        try {
            MessagingService.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
        } catch (Exception e) {
            Logger.logNow('CSApplicationFinisher', 'createAndSendCSPartnerEmail', e.getMessage() +
                '; ' + e.getStackTraceString());
        }
    }

    /**
    * When application is completed, if PCR is still a "No Match," we create a QC Case
    * @param lead lead that has completed the SSF Application
    */
    @TestVisible
    private static void createQCCaseForNoMatchPCR(Lead lead) {
        if (lead.Personal_Credit_Report__r.LASERCA__Credit_Score__c == '9999') {
            CaseFactory noMatchFactory  = new CaseFactory();
            noMatchFactory.setLead(lead);
            noMatchFactory.setQueueType('No FICO Match');
            System.enqueueJob(noMatchFactory);
        }
    }
}