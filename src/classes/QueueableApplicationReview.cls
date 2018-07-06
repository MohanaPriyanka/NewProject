/**
 * Created by mstackhouse on 7/3/2018.
 * Description: 
 * Test: 
 */


public class QueueableApplicationReview implements Queueable {
    public static Id leadId;

    public QueueableApplicationReview(Lead queuedLead) {
        leadId = queuedLead.Id;
    }

    public void execute(QueueableContext context) {
        PCRApprovalHandler pcrApprovalHandler = new PCRApprovalHandler();
        Lead lead = pcrApprovalHandler.getLeadsForCreditAnalysis(new Set<Id>{leadId})[0];
        if (pcrApprovalHandler.leadReadyForPrequalCheck(lead)) {
            List<LASERCA__Personal_Credit_Report__c> pcrsToUpdate = new List<LASERCA__Personal_Credit_Report__c>();
            lead = pcrApprovalHandler.runCreditReviewProcess(lead, null, null);
            update lead;
            pcrsToUpdate.add(lead.Personal_Credit_Report__r);
            if (lead.Personal_Credit_Report_Co_Applicant__c != null) {
                pcrsToUpdate.add(lead.Personal_Credit_Report_Co_Applicant__r);
            }
            update pcrsToUpdate;
        } else if (!Test.isRunningTest()) {
            System.enqueueJob(new QueueableApplicationReview(lead));
        }
    }
}