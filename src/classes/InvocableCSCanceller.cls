/**
 * Created by peteryao on 6/25/20.
 * Tested By: CSCancellationSchedulerTest
 */

public without sharing class InvocableCSCanceller {
    private static CSCancellationScheduler csCancellationScheduler = new CSCancellationScheduler();
    @InvocableMethod(Label='InvocableCSCanceller' Description='Runs ad-hoc cancellation steps')
    public static List<String> cancelCS(List<CancellationStep> steps) {
        return new List<String>{''};
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