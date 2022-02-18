/**
 * Created by jeffparlin on 6/14/21.
 * Description: For flow invocable context, dispatches adverse action notice to Leads who are marked unqualified
 */
public with sharing class InvocableUnqualifiedLeadEmailer {

    @InvocableMethod(
        Label='InvocableUnqualifiedLeadEmailer'
        Description='Sends an adverse action email to a Lead given the un-qualification reason')
    public static void sendUnqualifiedLeadAdverseActionEmail(List<Lead> leads) {
        for (Lead lead : leads) {
            if (lead.Unqualified_due_to_FICO__c) {
                CSQualificationService.sendAdverseCreditNotice(lead);
            } else {
                CSQualificationService.sendGenericUnqualifiedNotice(lead);
            }
        }
    }
}