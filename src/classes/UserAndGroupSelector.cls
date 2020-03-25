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
        ]);
    }

    public Map<Id, UserRole> getUserRoleMap() {
        return new Map<Id, UserRole>([
           SELECT Id, PortalType
           FROM UserRole
        ]);
    }
}