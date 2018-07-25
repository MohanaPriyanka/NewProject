/**
 * Created by mstackhouse on 7/3/2018.
 * Description: Called from PCRApprovalHandler to queue a lead for a credit check. This is used because of a race condition
 * that occurs when joint applications have their credit pulled. In some cases, if the timing of the PCRs coming back from 
 * Transunion overlaps, then the lead won't be analyzed. This ensures that the credit application gets reviewed
 * 
 *
 * Test: CAPControllerTest & PCRApprovalHandlerTest
 */


public class QueueableApplicationReview implements Queueable {
    public Id leadId;

    public QueueableApplicationReview(Lead queuedLead) {
        this.leadId = queuedLead.Id;
    }

    public void execute(QueueableContext context) {
        PCRApprovalHandler pcrApprovalHandler = new PCRApprovalHandler();
        Lead lead = pcrApprovalHandler.getLeadsForCreditAnalysis(new Set<Id>{this.leadId})[0];
        if (pcrApprovalHandler.leadReadyForPrequalCheck(lead)) {
            List<LASERCA__Personal_Credit_Report__c> pcrsToUpdate = new List<LASERCA__Personal_Credit_Report__c>();
            lead = pcrApprovalHandler.runCreditReviewProcess(lead, null, null);
            update lead;
            checkAvidiaStatus(lead, lead.Personal_Credit_Report__r);
            pcrsToUpdate.add(lead.Personal_Credit_Report__r);
            if (lead.Personal_Credit_Report_Co_Applicant__c != null) {
                pcrsToUpdate.add(lead.Personal_Credit_Report_Co_Applicant__r);
            }
            update pcrsToUpdate;
        } else if (!Test.isRunningTest()) {
            System.enqueueJob(new QueueableApplicationReview(lead));
        }
    }

    private void checkAvidiaStatus(Lead lead, LASERCA__Personal_Credit_Report__c pcr) {
        if(pcr.Avidia_Review_Status__c == 'Reviewed - Declined') {
            Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Lead__c = :lead.Id];
            opp.StageName = 'Voided';
            update opp;
        }
    }

}
