/*************************************************************************************
 * Created By: peteryao on 2019-02-07  
 * Description: Provides user and permission information
 * Test: PermissionServiceTest
 *************************************************************************************/

public without sharing class PermissionService {
    public static Boolean userHasPermissionSetForClass(Id userId, String className) {
        List<PermissionSet> permissionSets = PermissionsSelector.selectPermissionSetsForClass(className);
        List<PermissionSetAssignment> assignments = PermissionsSelector.selectPermissionSetAssignments(permissionSets);

        for (PermissionSetAssignment psa : assignments) {
            if (psa.AssigneeId == userId) {
                return true;
            }
        }
        return false;
    }
}