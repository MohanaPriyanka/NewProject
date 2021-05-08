/**
 * @description Sets BWTechnology users to System Admins, and then schedules the CSRecordLoader to load data. Intended
 * to be called by the PostSandboxRefresher. Because of the DML on the setup object, this needs to avoid other SObject updates
 * https://salesforce.stackexchange.com/questions/171550/sandboxpostcopy-functional-failure
 *
 * Tested By: PostSandboxRefresherTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class PostSandboxAdminSwitcher implements Schedulable {
    public static final String POST_SANDBOX_ADMIN_SWITCHER_JOB_NAME = 'PostSandboxAdminSwitcher';

    public void execute(SchedulableContext context) {
        try {
            setSystemAdmins();
            queueRecordLoader();
        } catch (Exception e) {
            Logger.logNow('PostSandboxAdminSwitcher', 'execute', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
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

    private void queueRecordLoader() {
        CSRecordLoader recordLoader = new CSRecordLoader();
        System.enqueueJob(recordLoader);
    }

}