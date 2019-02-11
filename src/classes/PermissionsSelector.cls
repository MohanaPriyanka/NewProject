/*************************************************************************************
 * Created By: peteryao on 2019-02-07  
 * Description: 
 * Test: PermissionsSelectorTest
 *************************************************************************************/

public with sharing class PermissionsSelector {
    // Users with the Author Apex profile permission get a generated non-custom permission set for apex classes.
    // This excludes those permission sets.
    public static List<PermissionSet> selectPermissionSetsForClass(String className) {
        List<ApexClass> apexClasses = [
            SELECT Id,
            (SELECT Id, ParentId, Parent.IsCustom, Parent.Name FROM SetupEntityAccessItems WHERE Parent.IsCustom = TRUE)
            FROM ApexClass
            WHERE Name = :className
            LIMIT 1
        ];
        if (apexClasses.isEmpty()) {
            return new List<PermissionSet>();
        } else {
            return setupEntityAccessToPermissionSets(apexClasses[0].SetupEntityAccessItems);
        }
    }

    private static List<PermissionSet> setupEntityAccessToPermissionSets(List<SetupEntityAccess> setupEntityAccesses) {
        List<PermissionSet> permissionSets = new List<PermissionSet>();
        for (SetupEntityAccess setupEntityAccess : setupEntityAccesses) {
            PermissionSet ps = new PermissionSet(
                Id = setupEntityAccess.ParentId,
                Name = setupEntityAccess.Parent.Name
            );
            permissionSets.add(ps);
        }
        return permissionSets;
    }

    public static List<PermissionSetAssignment> selectPermissionSetAssignments(List<PermissionSet> permissionSets) {
        return [
            SELECT Id, PermissionSetId, Assignee.Id, Assignee.Name
            FROM PermissionSetAssignment
            WHERE PermissionSetId = :permissionSets
        ];
    }
}