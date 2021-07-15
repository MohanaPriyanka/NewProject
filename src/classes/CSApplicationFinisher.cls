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
        Lead lead = leadSelector.selectOne(leadId);
        if (lead == null) {
            logError(leadId, setApplicationCompleteDate, 'Unable to locate lead');
            return;
        }
        try {
            performSteps(lead, setApplicationCompleteDate);
        } catch (Exception e) {
            String errorMessage = 'Unexpected error occurred: ' + e.getMessage() + '\n\n' + e.getStackTraceString() + '\n\n';
            logError(leadId, setApplicationCompleteDate, errorMessage);
            return;
        }
    }

    private static void logError(Id leadId, Boolean setApplicationCompleteDate, String messagePrefix) {
        String message = messagePrefix +  '. Please reprocess manually. Inputs:\nleadId: ' + leadId +
            '\nsetApplicationCompleteDate: ' + setApplicationCompleteDate;
        Logger.logNow('CSApplicationFinisher', 'execute', message, Logger.ERROR);
    }

    /**
     * @description Perform actions on CS Lead application complete
     * @param lead CS Lead record to process
     * @param setApplicationCompleteDate Set application complete date on Lead via Apex when called?
     */
    private static void performSteps(Lead lead, Boolean setApplicationCompleteDate) {
        updateLeadOnComplete(lead, setApplicationCompleteDate);
        createAndSendCSPartnerEmail(lead);
        createQCCaseForNoMatchPCR(lead);
        UtilityDataRequestBuilder.createUDRs(new List<Id>{lead.Id});
        if (lead.No_Payment__c == false) {
            ZuoraAccountService.createAccounts(new Set<Id>{lead.Id});
        }
    }

    public static void updateLeadOnComplete(Lead lead, Boolean setApplicationCompleteDate) {
        lead.Application_Complete_Date__c = setApplicationCompleteDate ? Datetime.now() : lead.Application_Complete_Date__c;
        lead.Application_Status__c = 'Application Completed';
        CSLeadsRESTControllerV2.setContinueApplicationLinks(lead, 'Application Completed');
        qualificationService.qualifyLead(lead);
        leadService.updateLead(lead);
    }

    /**
     * @description Method to send an email to the related Partner when the customer has completed their SSF Application
     * @param Lead Lead that has completed the application
     */
    public static void createAndSendCSPartnerEmail(Lead lead) {
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
        MessagingService.sendEmail(new List<Messaging.Email>{mail});
    }

    /**
    * @description When application is completed, if PCR is still a "No Match," we create a QC Case
    * @param lead lead that has completed the SSF Application
    */
    public static void createQCCaseForNoMatchPCR(Lead lead) {
        if (lead.Personal_Credit_Report__r.LASERCA__Credit_Score__c == '9999') {
            CaseFactory noMatchFactory  = new CaseFactory();
            noMatchFactory.setLead(lead);
            noMatchFactory.setQueueType('No FICO Match');
            System.enqueueJob(noMatchFactory);
        }
    }
}