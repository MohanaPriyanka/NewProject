/**
 * Created by peteryao on 12/28/19.
 * Description: Because of the reasons described in this post (https://salesforce.stackexchange.com/a/240183/47356),
 *  this handles profile updates via a job scheduled by the PostSandboxRefresher
 * Tested By: PostSandboxRefresherTest
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class PostSandboxSchedulable implements Schedulable {
    public static final String POST_SANDBOX_SCHEDULED_JOB_NAME = 'PostSandboxSchedulable';
    public void execute(SchedulableContext context) {
        try {
            setSystemAdmins();
            cancelPostSandboxCronJob();
        } catch (Exception e) {
            Logger.logNow('PostSandboxSchedulable', 'setSystemAdmins', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        }
    }

    private void setSystemAdmins() {
        if (!Util.isSandboxOrTest()) {
            throw new Util.BWException('Only set system admins in sandboxes!');
        }
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

        List<User> usersToMakeSysAdmins = [
            SELECT Id, ProfileId
            FROM User
            WHERE Profile.Name = 'BW Technology'
            AND IsActive = TRUE
        ];
        for (User user : usersToMakeSysAdmins) {
            user.ProfileId = sysAdminProfile.Id;
        }
        update usersToMakeSysAdmins;
    }

    private void cancelPostSandboxCronJob() {
        List<CronTrigger> triggerList = [
            SELECT Id
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE :POST_SANDBOX_SCHEDULED_JOB_NAME
        ];
        for (CronTrigger t : triggerList) {
            System.abortJob(t.Id);
        }
    }
}