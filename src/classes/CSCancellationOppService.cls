/**
 * @description Handles opportunity related cancellation activity. See the Cancellation Process lucid chart for more detail:
 * https://lucid.app/lucidchart/28ddde15-529b-4b09-b858-35bba5e77e37/edit?shared=true&invitationId=inv_805406f1-b7d7-46cc-af1a-45901bb1d4e2&page=0_0#
 * Tested By: CSCancellationServiceTest
 */
public without sharing class CSCancellationOppService {
    @TestVisible private List<Opportunity> cancelledOpportunities = new List<Opportunity>();

    public String handleOpportunities(Boolean preview) {
        String outputMessage = CSCancellationScheduler.OPPORTUNITY_CANCELLATION_DESCRIPTION;
        cancelledOpportunities = getOpportunitiesToCancel();
        if (!preview) {
            outputMessage = outputMessage.replace('will get', 'got');
            cancelOpportunities(cancelledOpportunities);
        }
        for (Opportunity opportunity : cancelledOpportunities) {
            outputMessage += opportunity.Id + ', ' + opportunity.Name + '\n';
        }
        return outputMessage;
    }

    // W-008425: Called by the CSCancellationScheduler daily to mark Opportunities as cancelled if:
    // 1. Opportunity Stage is Complete AND
    // 2. All UASes are inactive and there are no SZSes for them (waitlist cancellation) OR
    // 3. We've sent System Bills, but not for 45 days (15 days after we expect to send), so we're finished billing
    //
    // Once all opportunities under a property account are cancelled (or Duplicate, Expired, or Dead), another scheduled job
    // will send a termination letter
    @TestVisible private void cancelOpportunities(List<Opportunity> oppToCancelList) {
        Opportunities opportunities = new Opportunities(oppToCancelList);
        opportunities.cancel();
    }

    @TestVisible private List<Opportunity> getOpportunitiesToCancel() {
        List<Opportunity> completeCSOpps = OpportunitiesSelector.selectAllCompleteCSWithUASesAndSystemBills();

        List<Opportunity> oppsToCancel = new List<Opportunity>();
        for (Opportunity opportunity : completeCSOpps) {
            if (Opportunities.shouldCancel(opportunity)) {
                oppsToCancel.add(opportunity);
            }
        }

        return oppsToCancel;
    }

    // W-008426: Called by the OpportunityTrigger to check to see if all CS opportunities are Cancelled, Expired, Duplicate,
    // or Dead. If so, we update the Account Status__c field and send the final termination letter email.
    public static List<Account> getAccountsToClose(Map<Id, Opportunity> newOppMap, Map<Id, Opportunity> oldOppMap) {
        //get all accounts where opportunities are either Cancelled, DUPLICATE, Expired or Dead
        Set<Id> accountIds = new Set<Id>();
        List<Account> accountsToClose = new List<Account>();
        for (Opportunity opp : newOppMap.values()) {
            if (opp.Product_Line__c == 'Community Solar' &&
                Opportunities.isActive(oldOppMap.get(opp.Id).StageName) && !Opportunities.isActive(opp.StageName)) {
                accountIds.add(opp.AccountId);
            }
        }

        List<Account> acctsToCheck = AccountsSelector.selectNotClosed(accountIds);
        for (Account acct : acctsToCheck) {
            if (new Opportunities(acct.Opportunities).allInactive()) {
                accountsToClose.add(acct);
            }
        }
        return accountsToClose;
    }
}