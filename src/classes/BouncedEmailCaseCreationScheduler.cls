/**
 * Created by aingram on 9/3/21.
 * @description Selects all leads with a EmailBouncedDate >= YESTERDAY and creates a case for the lead if one doesn't already exist. The case will be visible in the partner portal for
 * partners to resolve instead of Customer Care. The LeadTrigger will handle automatically closing the cases when the email address on the lead is updated. It is possible to update the
 * EmailBounced date manually for testing purposes but when the EmailBouncedDate is set by Salesforce, it doesn't fire the lead trigger which is why a scheduled job is being used.
 * Email addresses that we found bounce : adwait@invalid.com, test@gmail.com
 */

public without sharing class BouncedEmailCaseCreationScheduler implements Schedulable {

    private CaseFactory caseFactory = new CaseFactory();
    private LeadSelector leadSelector = new LeadSelector();
    private List<Lead> leadsNeedingCases = new List<Lead>();

    public void execute(SchedulableContext ctx) {
        try {
            List<Lead> bouncedLeads = leadSelector.getLeadsWithBouncedEmails();
            processLeads(bouncedLeads);

        } catch (Exception e) {
            Logger.logLater('BouncedEmailCaseCreationScheduler', 'execute', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        } finally {
            Logger.flushLogs();
        }

    }

    private void processLeads(List<Lead> bouncedLeads) {
        for (Lead l : bouncedLeads) {
            Boolean caseNeeded = isCaseNeeded(l);
            if(caseNeeded) {
                leadsNeedingCases.add(l);
            }
        }

        caseFactory.createBouncedEmailCases(leadsNeedingCases);

    }

    private Boolean isCaseNeeded(Lead l) {
        List<Case> childCases = l.Cases__r;
        for (Case c : childCases) {
            if (c.Description != null && c.Description.contains('bounced. Please provide new email address')) {
                return false;
            }
        }
        return true;
    }

}