/**
 * Created by aingram on 9/3/21.
 * @description Selects all leads with a EmailBouncedDate from today and creates a case for the lead if one doesn't already exist.
 */

public with sharing class BouncedEmailCaseCreationScheduler implements Schedulable {

    private CaseFactory caseFactory = new CaseFactory();
    private List<Lead> leadsNeedingCases = new List<Lead>();

    public void execute(SchedulableContext ctx) {
        try {
            List<Lead> bouncedLeads = getLeadsWithBouncedEmails();
            processLeads(bouncedLeads);

        } catch (Exception e) {
            Logger.logLater('BouncedEmailCaseCreationScheduler', 'execute', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        } finally {
            Logger.flushLogs();
        }

    }

    private List<Lead> getLeadsWithBouncedEmails() {
        return [
            SELECT Id, Status, FirstName, LastName, Email, Partner_Account__c, Partner_Contact__c, (
                SELECT Id, Description FROM Cases__r WHERE Subject = '- Other' AND Product_Line__c = 'Community Solar' AND IsClosed = FALSE
            )
            FROM Lead
            WHERE EmailBouncedDate != null AND EmailBouncedDate = TODAY 
        ];
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