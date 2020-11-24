/**
 * Created by peteryao on 3/23/20.
 * Tested By: UserAndGroupSelectorTest
 */

public inherited sharing class UserAndGroupSelector {
    public Map<Id, Group> getAllGroupMap() {
        Map<Id, Group> groups = new Map<Id, Group>([
            SELECT Id, DeveloperName, Type, RelatedId
            FROM Group
        ]);
        return groups;
    }

    public List<GroupMember> getAllGroupMembers() {
        return [
            SELECT Id, GroupId, UserOrGroupId, Group.DeveloperName
            FROM GroupMember
        ];
    }

    public Map<Id, User> getExternalUserMap() {
        return new Map<Id, User>([
            SELECT Id, UserRoleId
            FROM User
            WHERE IsPortalEnabled = TRUE
            AND IsActive = TRUE
        ]);
    }

    public Map<Id, UserRole> getUserRoleMap() {
        return new Map<Id, UserRole>([
           SELECT Id, PortalType
           FROM UserRole
        ]);
    }

    public List<User> getUsersFromId(Set<Id> userIds){
        return new List<User>([
            SELECT Id, ContactId
            FROM User
            WHERE Id IN : userIds
        ]);
    }

    public User getGuestUser() {
        return [
            SELECT Id
            FROM User
            WHERE Name = 'Apply Site Guest User'
            LIMIT 1
        ];
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public MultiMap getUsersByAccountIds(Set<Id> accountIds) {
        List<User> users = [
            SELECT Id, AccountId
            FROM User
            WHERE AccountId IN :accountIds
        ];
        MultiMap usersByAccountId = MultiMap.newSetInstance();
        for (User user : users) {
            usersByAccountId.putValue(user.AccountId, user.Id);
        }
        return usersByAccountId;
    }

}