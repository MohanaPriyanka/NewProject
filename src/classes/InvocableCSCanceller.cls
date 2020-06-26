/**
 * Created by peteryao on 6/25/20.
 * Tested By: CSCancellationSchedulerTest
 */

public without sharing class InvocableCSCanceller {
    private static CSCancellationScheduler csCancellationScheduler = new CSCancellationScheduler();
    @InvocableMethod(Label='InvocableCSCanceller' Description='Runs ad-hoc cancellation steps')
    public static List<String> cancelCS(List<CancellationStep> steps) {
        if (steps.size() != 1) {
            throw new Util.BWException('One step at a time');
        }
        CancellationStep step = steps[0];
        String outputMessage;
        switch on step.stepName {
            when 'OverdueAccounts' {
                outputMessage = csCancellationScheduler.handleOverdueAccounts(step.preview);
            }
            when 'Opportunities' {
                outputMessage = csCancellationScheduler.handleOpportunities(step.preview);
            }
            when 'AccountsRemovedFromAllProjects' {
                outputMessage = csCancellationScheduler.handleAccountsToRemove(step.preview);
            }
            when 'All' {
                outputMessage = csCancellationScheduler.handleAccountsAndOpportunities(step.preview, null);
            }
            when else {
                throw new Util.BWException('Unknown step: ' + step.stepName);
            }
        }
        return new List<String>{outputMessage};
    }

    public class CancellationStep {
        @InvocableVariable(Label='Preview Only' Description='Do not commit any changes, just preview' Required=true)
        public Boolean preview;
        @InvocableVariable(Label='Step' Description='Either OverdueAccounts, Opportunities, AccountsRemovedFromAllProjects, or All' Required=false)
        public String stepName;
        public CancellationStep() {
        }
        public CancellationStep(Boolean preview, String stepName) {
            this.preview = preview;
            this.stepName = stepName;
        }
    }
}