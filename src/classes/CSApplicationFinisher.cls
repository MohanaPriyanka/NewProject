/**
 * @description Processes a CS Lead which has entered an 'Application Complete' state, called typically from the API
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
            updateLeadOnComplete(lead, setApplicationCompleteDate);
        } catch (Exception e) {
            String errorMessage = 'Failed to update lead' + e.getMessage() + '\n\n' + e.getStackTraceString() + '\n\n';
            logError(lead.Id, setApplicationCompleteDate, errorMessage);
            return; // Do not continue if lead update fails
        }
        performAdditionalActions(lead);
    }

    /**
     * @description Updates CS Lead with changes necessary when the Lead is ready to be marked "Application Complete"
     * @param lead CS Lead
     * @param setApplicationCompleteDate Indicates whether the application complete date should be set to system.now()
     */
    public static void updateLeadOnComplete(Lead lead, Boolean setApplicationCompleteDate) {
        lead.Application_Complete_Date__c = setApplicationCompleteDate ? Datetime.now() : lead.Application_Complete_Date__c;
        lead.Application_Status__c = 'Application Completed';
        CSLeadsRESTControllerV2.setContinueApplicationLinks(lead, 'Application Completed');
        qualificationService.qualifyLead(lead);
        leadService.updateLead(lead);
    }


    /**
     * @description Method to send an email to the related Partner when the customer has completed their SSF Application
     * @param lead Lead that has completed the application
     */
    public static void createAndSendCSPartnerEmail(Lead lead) {
        try {
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
            mail.setToAddresses(new List<String>{
                lead.Partner_Email__c
            });
            mail.setTargetObjectId(lead.Id);
            mail.setSaveAsActivity(true);
            mail.setTreatTargetObjectAsRecipient(false);
            MessagingService.sendEmail(new List<Messaging.Email>{
                mail
            });
        } catch (Exception e) {
            String message = 'Failed to send CS Partner email on application completion for ' + lead.Id;
            Logger.logNow('CSApplicationFinisher', 'execute', message, Logger.ERROR);
        }
    }

    /**
     * @description When application is completed, if PCR is still a "No Match," we create a QC Case
     * @param lead lead that has completed the SSF Application
     */
    public static void createQCCaseForNoMatchPCR(Lead lead) {
        if (lead.Personal_Credit_Report__r.LASERCA__Credit_Score__c == '9999') {
            CaseFactory noMatchFactory = new CaseFactory();
            noMatchFactory.setLead(lead);
            noMatchFactory.setQueueType('No FICO Match');
            System.enqueueJob(noMatchFactory);
        }
    }

    /**
     * @description Creates UDR if relevant to this lead (EDI or Glynt utility data mechanism)
     * @param lead CS Lead
     */
    public static void createUtilityDataRequest(Lead lead) {
        try {
            UtilityDataRequestBuilder.createUDRs(new List<Id>{
                lead.Id
            });
        } catch (Exception e) {
            String message = 'Failed to create UDR for Lead ' + lead.Id;
            Logger.logNow('CSApplicationFinisher', 'createUtilityDataRequest', message, Logger.ERROR);
        }
    }

    /**
     * @description Creates Zuora account if relevant to this lead (No_Payment__c flag on Lead needs to be FALSE)
     * @param lead CS Lead
     */
    public static void createZuoraAccount(Lead lead) {
        try {
            if (lead.No_Payment__c == false) {
                ZuoraAccountService.createAccounts(new Set<Id>{
                    lead.Id
                });
            }
        } catch (Exception e) {
            String message = 'Failed to create Zuora Account for Lead ' + lead.Id;
            Logger.logNow('CSApplicationFinisher', 'createZuoraAccount', message, Logger.ERROR);
        }
    }

    /**
     * @description Perform actions on CS Lead application complete
     * NOTE: Each method called here works independently and should have its own try/catch exception handling/logging
     * @param lead CS Lead record to process
     */
    private static void performAdditionalActions(Lead lead) {
        createAndSendCSPartnerEmail(lead);
        createQCCaseForNoMatchPCR(lead);
        createUtilityDataRequest(lead);
        createZuoraAccount(lead);
    }

    private static void logError(Id leadId, Boolean setApplicationCompleteDate, String messagePrefix) {
        String message = messagePrefix + '. Please reprocess manually. Inputs:\nleadId: ' + leadId +
            '\nsetApplicationCompleteDate: ' + setApplicationCompleteDate;
        Logger.logNow('CSApplicationFinisher', 'execute', message, Logger.ERROR);
    }
}