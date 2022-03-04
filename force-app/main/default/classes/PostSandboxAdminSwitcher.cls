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
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

        List<User> usersToMakeSysAdmins = [
            SELECT Id, ProfileId
            FROM User
            WHERE IsActive = TRUE
            AND Id IN (
                SELECT AssigneeId
                FROM PermissionSetAssignment
                WHERE PermissionSet.Name = 'Edit_All'
            )
        ];
        for (User user : usersToMakeSysAdmins) {
            user.ProfileId = sysAdminProfile.Id;
        }
        update usersToMakeSysAdmins;
    }
}