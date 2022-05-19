/**
 * @description Created by jeffparlin on 5/16/22. Emails Partner contacts if Lead is unable to be converted onto the
 * project specified by the partner during enrollment
 * Tested By: CSLeadsConverterTest
 */
public without sharing class PartnerSystemSelectionNotifier {

    public static void assessLeadPostConversion(Lead lead) {
        if (lead.SSS_Selected_by_Partner__c == null) {
            return;
        }
        for (Utility_Account_Subscription__c uas : new UASSelector().getByLeadId(lead.Id)) {
            if (uas.Shared_Solar_System__c == lead.SSS_Selected_by_Partner__c) {
                return;
            }
        }
        notifyPartnerSelectedSystemUnavailable(lead.Id);
    }

    public static void notifyPartnerSelectedSystemUnavailable(Id leadId) {
        List<Opportunity> opportunities = new OpportunitiesSelector().getOppsByLead(leadId);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        try {
            Map<String,String> emailMergeFields = new Map<String,String>{
                '{!Lead.Partner_Name__c}' => opportunities[0].Lead__r.Partner_Account__r.Name,
                '{!Lead.Name}' => opportunities[0].Lead__r.Name,
                '{!Partner_Selected_Project}' => new SharedSolarSystemsSelector()
                    .selectOne(opportunities[0].Lead__r.SSS_Selected_by_Partner__c).Name
            };
            String emailBody = MessagingService.getHtmlWithReplacements(
                'CS_Partner_Partner_Selected_System_Not_Used', emailMergeFields
            );
            mail.htmlBody = emailBody;
            mail.setSubject('Perch Energy Change of Project Notification Regarding a Customer Enrollment in SSF');
            mail.setOrgWideEmailAddressId(MessagingService.getCustomerCareEmail().Id);
            mail.toAddresses = new AccountsSelector()
                .getPartnerAccountAdminContactEmails(opportunities[0].Lead__r.Partner_Account__c);
            MessagingService.sendEmail(new List<Messaging.Email>{mail});
        } catch (Exception e) {
            String message = 'Unable to notify partner that the selected system for ' + leadId + ' is unavailable';
            message += '\n\n' + e.getMessage() + '\n\n' + e.getStackTraceString();
            Logger.postLog('PartnerSystemSelectionNotifier', 'notifyPartnerUnavailableSelectedSystem (Queueable)',
                message, Datetime.now(), Logger.ERROR
            );
        }
    }
}