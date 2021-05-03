/**
 * @description Tested By ScheduledPostSandboxRefresherTest
 */
public with sharing class ScheduledPostSandboxRefresher implements SandboxPostCopy {
    public void runApexClass(SandboxContext context) {
        Integer minute = Datetime.now().addMinutes(30).minute();
        // Starting 30m from now to allow the queueable CS job to finish. Job will self-cancel once successful.
        String cronString = '0 ' + minute + ' * * * ?';
        String cronId = System.schedule(PostSandboxSchedulable.POST_SANDBOX_SCHEDULED_JOB_NAME, cronString, new PostSandboxSchedulable());
        Logger.logNow('PostSandboxRefresher', 'schedulePostSandboxJob', 'Created ' + cronId + ' for post post sandbox actions', Logger.ERROR);
    }
}