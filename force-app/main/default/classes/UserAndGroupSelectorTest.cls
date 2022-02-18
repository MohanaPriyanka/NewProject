/**
 * Created by peteryao on 3/25/20.
 */
@IsTest
public with sharing class UserAndGroupSelectorTest {
    private static UserAndGroupSelector selector = new UserAndGroupSelector();

    @IsTest
    private static void testGetAllGroupMap() {
        Map<Id, Group> groupMap = selector.getAllGroupMap();
        System.assertNotEquals(null, groupMap);
    }

    @IsTest
    private static void testGetAllGroupMembers() {
        List<GroupMember> groupMembers = selector.getAllGroupMembers();
        System.assertNotEquals(null, groupMembers);
    }

    @IsTest
    private static void testGetExternalUserMap() {
        Map<Id, User> userMap = selector.getExternalUserMap();
        System.assertNotEquals(null, userMap);
    }

    @IsTest
    private static void testGetUserRoleMap() {
        Map<Id, UserRole> userRoleMap = selector.getUserRoleMap();
        System.assertNotEquals(null, userRoleMap);
    }

    @IsTest
    private static void testGetUserFromId() {
        User oneUser = [
            SELECT Id
            FROM User
            LIMIT 1
        ];
        List<User> users = selector.getUsersFromId(new Set<Id>{oneUser.Id});
        System.assertNotEquals(null, users);
    }

    @IsTest
    private static void testGetGuestUser() {
        User guestUser = selector.getGuestUser();
        System.assertNotEquals(null, guestUser);
    }

    @IsTest
    private static void testGetUsersByAccountIds() {
        List<User> users = new UserAndGroupSelector().getUsersByAccountIds(new Set<Id>());
        System.assertNotEquals(null, users, 'Should always get a list of users, even when there are no users');
    }
}