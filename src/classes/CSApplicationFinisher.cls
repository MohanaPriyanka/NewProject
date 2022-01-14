/**
 * @description Processes a CS Lead which has entered an 'Application Complete' state, called typically from the API
 * Tested By: CSLeadsRESTControllerV2Test
 */
public without sharing class CSApplicationFinisher implements Queueable, Database.AllowsCallouts {

    @TestVisible private static LeadSelector leadSelector = new LeadSelector();
    @TestVisible private static FeatureSelector featureSelector = new FeatureSelector();
    @TestVisible private static CSQualificationService qualificationService = new CSQualificationService();
    @TestVisible private static LeadService leadService = new LeadService();
    @TestVisible private static Boolean triggerErrorInTest = false;
    private Datetime applicationCompleteDate;
    private Id leadId;

    /**
     * @description Constructor for class
     * @param leadId CS Lead record to process
     * @param appCompleteDate Application complete date, if provided by UI (SSF), otherwise, if null, fill date in this class
     */
    public CSApplicationFinisher(Id leadId, Datetime appCompleteDate) {
        this.leadId = leadId;
        this.applicationCompleteDate = appCompleteDate;
    }

    /**
     * @description Performs required actions when a CS Lead is marked as "complete" by SSF or API
     * Runs in async @future context.
     * @param ctx Queueable context
     **/
    public void execute(System.QueueableContext ctx) {
        Lead lead = leadSelector.selectOne(leadId);
        if (lead == null) {
            logError(null, 'execute', 'Unable to locate lead');
            return;
        }
        try {
            updateLeadOnComplete(lead);
            if (Test.isRunningTest() && triggerErrorInTest) {
                throw new Util.BWException('Test error encountered');
            }
        } catch (Exception e) {
            logError(e, 'execute', 'Failed to update lead');
            return; // Do not continue if lead update fails
        }
        performAdditionalActions(lead);
    }

    /**
     * @description Updates CS Lead with changes necessary when the Lead is ready to be marked "Application Complete"
     * @param lead CS Lead
     */
    public void updateLeadOnComplete(Lead lead) {
        lead.Application_Complete_Date__c = applicationCompleteDate == null ? lead.Application_Complete_Date__c : applicationCompleteDate ;
        lead.Application_Status__c = 'Application Completed';
        CSLeadsRESTControllerV2.setContinueApplicationLinks(lead, 'Application Completed');
        SharedSolarSystemQualifier.ignoreLoadZones(); // Set to ignore load zones for qualification check (in case of split LZ)
        qualifyLeadIfNoUnderwritingRequired(lead);
        leadService.updateLead(lead);
    }

    /**
     * @description Method to send an email to the related Partner when the customer has completed their SSF Application
     * @param lead Lead that has completed the application
     */
    public void createAndSendCSPartnerEmail(Lead lead) {
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
            logError(e, 'createAndSendCSPartnerEmail', 'Failed to send CS Partner email on application completion');
        }
    }

    /**
     * @description When application is completed, if PCR is still a "No Match," we create a QC Case
     * @param lead lead that has completed the SSF Application
     */
    public void createQCCaseForNoMatchPCR(Lead lead) {
        try {
            if (lead.Underwriting_Criteria__c == 'FICO' && lead.Personal_Credit_Report__r.LASERCA__Credit_Score__c == null) {
                CaseFactory noMatchFactory = new CaseFactory();
                noMatchFactory.setLead(lead);
                noMatchFactory.setQueueType('No FICO Match');
                noMatchFactory.insertNoMatchCreditReportCase();
            }
        } catch (Exception e) {
            logError(e, 'createQCCaseForNoMatchPCR', 'Failed to create FICO: No Match Case for Lead');
        }
    }

    /**
     * @description Creates UDR if relevant to this lead (EDI or Glynt utility data mechanism)
     * @param lead CS Lead
     */
    public void createUtilityDataRequest(Lead lead) {
        try {
            UtilityDataRequestBuilder.createUDRs(new List<Id>{
                lead.Id
            });
        } catch (Exception e) {
            logError(e, 'createUtilityDataRequest', 'Failed to create UDR for Lead');
        }
    }

    /**
     * @description Creates Zuora account if relevant to this lead (No_Payment__c flag on Lead needs to be FALSE)
     * @param lead CS Lead
     */
    public void postCreateZuoraAccountEvent(Lead lead) {
        if (!lead.No_Payment__c) {
            Zuora_Account_Create_Event__e zuoraAccountCreateEvent = new Zuora_Account_Create_Event__e(
                Lead_Id__c = lead.Id
            );
            Database.SaveResult sr = EventBus.publish(zuoraAccountCreateEvent);
            if (!sr.isSuccess()) {
                logError(null, 'postCreateZuoraAccountEvent', 'Failed to post Zuora Acc create platform event');
            }
        }
    }

    /**
     * @description Perform actions on CS Lead application complete
     * NOTE: Each method called here works independently and should have its own try/catch exception handling/logging
     * @param lead CS Lead record to process
     */
    private void performAdditionalActions(Lead lead) {
        createAndSendCSPartnerEmail(lead);
        createQCCaseForNoMatchPCR(lead);
        createUtilityDataRequest(lead);
        postCreateZuoraAccountEvent(lead);
    }

    private void logError(Exception caughtException, String method, String messagePrefix) {
        String message = messagePrefix + '. Please reprocess manually. Class inputs:\nleadId: ' + leadId +
            '\napplicationCompleteDate: ' + applicationCompleteDate;
        if (caughtException != null) {
            message += '\n\n ' + caughtException.getMessage() + '\n\n' + caughtException.getStackTraceString();
        }
        Logger.logNow('CSApplicationFinisher', method, message, Logger.ERROR);
    }

    /**
     * @description Runs a Qualification check on the Lead if (and ONLY if) it has no Underwriting requirement set.
     * For other underwriting cases, e.g. FICO, Financial Documents, qualification check is handled elsewhere.
     * @param lead Lead to assess Qualification needs
     */
    private void qualifyLeadIfNoUnderwritingRequired(Lead lead) {
        if (lead.Underwriting_Criteria__c == 'None') {
            qualificationService.qualifyLead(lead);
        }
    }
}