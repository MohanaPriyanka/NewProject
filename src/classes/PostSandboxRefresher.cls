/**
  @description: Sets up a developer or full sandbox to have a minimal set of data to be able to test CS changes by
  first running PostSandboxAdminSwitcher, which runs the CSRecordLoader in another schedule (since we need to avoid
  a MIXED_DML_OPERATION).
  Tested By: PostSandboxRefresherTest
 **/
public without sharing class PostSandboxRefresher implements SandboxPostCopy {
    public void runApexClass(SandboxContext context) {
        try {
            Integer minute = Datetime.now().addMinutes(30).minute();
            // Starting 30m from now to allow the sandbox user table to finish setting up. Job will self-cancel once successful.
            String cronString = '0 ' + minute + ' * * * ?';
            System.schedule(PostSandboxAdminSwitcher.POST_SANDBOX_ADMIN_SWITCHER_JOB_NAME, cronString, new PostSandboxAdminSwitcher());
        } catch (Exception e) {
            Logger.logNow('PostSandboxRefresher', 'runApexClass', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        }
    }
}