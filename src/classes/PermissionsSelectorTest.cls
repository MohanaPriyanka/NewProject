/*************************************************************************************
 * Created By: peteryao on 2019-02-07  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class PermissionsSelectorTest {
    @TestSetup
    public static void testSetup() {
        PermissionSet pr = new PermissionSet(
            Label='Test Permission Set',
            Name='Test_Permission_Set'
        );
        insert pr;

        List<ApexClass> apexClasses = [SELECT Id FROM ApexClass WHERE Name = 'PermissionsSelector'];
        SetupEntityAccess sea = new SetupEntityAccess(
            ParentId = pr.Id,
            SetupEntityId = apexClasses[0].Id);
        insert sea;

        Profile profileRecord = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        User standardUser = new User(
            FirstName = 'First',
            LastName = 'Last',
            Alias = 'fbc',
            Email = 'foo@bar.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileRecord.Id,
            Country = 'United States',
            IsActive = true,
            TimeZoneSidKey = 'America/New_York',
            Username = 'foo@bar.com'
        );
        insert standardUser;

        PermissionSetAssignment psa = new PermissionSetAssignment(
            PermissionSetId = pr.Id,
            AssigneeId = standardUser.Id
        );
        insert psa;
        PermissionSetAssignment psa2 = new PermissionSetAssignment(
            PermissionSetId = pr.Id,
            AssigneeId = UserInfo.getUserId()
        );
        insert psa2;
    }

    @IsTest
    public static void testSelectPermissionSetsForClass() {
        // We should find a permission set for the selector, the one created in testSetup
        System.assertEquals(1, PermissionsSelector.selectPermissionSetsForClass('PermissionsSelector').size());
        System.assertEquals('Test_Permission_Set', PermissionsSelector.selectPermissionSetsForClass('PermissionsSelector')[0].Name);
        // We shouldn't ever have a permission set for a test class, so we expect an empty list
        System.assertEquals(0, PermissionsSelector.selectPermissionSetsForClass('PermissionsSelectorTest').size());
    }

    @IsTest
    public static void testSelectPermissionSetAssignments() {
        List<PermissionSet> selectorPermissionSets = PermissionsSelector.selectPermissionSetsForClass('PermissionsSelector');
        List<PermissionSet> selectorTestPermissionSets = PermissionsSelector.selectPermissionSetsForClass('PermissionsSelectorTest');
        // Both standard user and running user should have the selector permission set
        System.assertEquals(2, PermissionsSelector.selectPermissionSetAssignments(selectorPermissionSets).size());
        // But there shouldn't be any permission sets, nor assignments, for the selector test class
        System.assertEquals(0, PermissionsSelector.selectPermissionSetAssignments(selectorTestPermissionSets).size());
    }
}