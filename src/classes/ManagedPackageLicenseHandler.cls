/**
 * Created by jpentaleri on 7/9/2018.
 */

public with sharing class ManagedPackageLicenseHandler {
    // Source: https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_objects_packagelicense.htm

    public static void assignChargentLicense(List<User> triggeredUsers) {
        List<User> usersToAssignList = new List<User>();
        String packageNamespacePrefix = 'ChargentOrders';

        Profile communityProfile = [SELECT Id
        FROM Profile
        WHERE Name = 'Community Solar Community User'];

        for (User userToCheck : triggeredUsers){
            if (userToCheck.ProfileId == communityProfile.Id){
                usersToAssignList.add(userToCheck);
            }
        }
        assignLicense(usersToAssignList, packageNamespacePrefix);
    }

    public static void assignLicense(List<User> usersToAssign, String PACKAGE_NAMESPACE_PREFIX) {
        //find the PackageLicense Id
        PackageLicense pl = [   SELECT Id, NamespacePrefix, AllowedLicenses,
                                    UsedLicenses, ExpirationDate,Status
                                FROM PackageLicense
                                WHERE NamespacePrefix = :PACKAGE_NAMESPACE_PREFIX];
        System.assert(pl != null, 'Error Assigning Managed Package to User');
        List<UserPackageLicense> firstUPLs = new List<UserPackageLicense>();

        //create a new UserPackageLicense record for each user with the specified profile
        for (User assignUser : usersToAssign){
            UserPackageLicense upl = new UserPackageLicense();
            upl.PackageLicenseId = pl.Id;
            upl.UserId = assignUser.Id;
            firstUPLs.add(upl);
        }

        try {
            insert(firstUPLs);
        } catch (Exception e) {
            String exceptionText = 'Allowed Licenses: ' +
                pl.AllowedLicenses + ' Used Licenses: ' +
                pl.UsedLicenses + ' Message:' +
                String.valueOf(e);
            Logger.logNow('ChargentLicenseAssignmentHandler','assignLicense',exceptionText);
        }
    }
}