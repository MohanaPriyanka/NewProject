/*************************************************************************************
 * Created By: peteryao on 2019-02-07  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class PermissionServiceTest {
    @TestSetup
    public static void testSetup() {
        PermissionsSelectorTest.testSetup();
    }

    @IsTest
    public static void testUserHasPermissionSetForClass() {
        User standardUser = [SELECT Id FROM User WHERE Email = 'foo@bar.com'];
        System.assertEquals(true, PermissionService.userHasPermissionSetForClass(standardUser.Id, 'PermissionsSelector'));
        System.assertEquals(false, PermissionService.userHasPermissionSetForClass(standardUser.Id, 'PermissionsSelectorTest'));
        System.assertEquals(true, PermissionService.userHasPermissionSetForClass(UserInfo.getUserId(), 'PermissionsSelector'));
        System.assertEquals(false, PermissionService.userHasPermissionSetForClass(UserInfo.getUserId(), 'PermissionsSelectorTest'));
    }
}