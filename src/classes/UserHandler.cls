public without sharing class UserHandler{
    public static void createCSCommunityUser(List<Contact> userContacts) {
        Map<Id, User> usersToInsertMap = new Map<Id, User>();
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name='Community Solar Community User'];

        for (Contact userContact : userContacts){
            User userToInsert = setUserFields(userContact, profileRecord.Id);
            usersToInsertMap.put(userContact.Id, userToInsert);
        }

        String response = attemptInsert(usersToInsertMap);
        System.debug(response);

        /* ConnectApi.CommunityPage comm = ConnectApi.Communities.getCommunities();
        for (ConnectApi.Community community : comm.communities) {
            if (community.name == 'BlueWave Member Portal') {
                communityID = community.id;
            }
        }
        */
    }

    public static User setUserFields(Contact userContact, String profileId) {
        User userToInsert = new User(
            FirstName = userContact.FirstName,
            Lastname = userContact.LastName,
            Alias = 'xxx234',
            Email = userContact.Email,
            Emailencodingkey ='UTF-8',
            Languagelocalekey ='en_US',
            Localesidkey ='en_US',
            Country ='United States',
            IsActive = true,
            ContactId = userContact.Id,
            Profileid = profileId,
            Timezonesidkey='America/New_York', // !! fix this
            Username= userContact.Email
        );
        return userToInsert;
    }

    public static String attemptInsert(Map<Id, User> usersToInsertMap) {
        // If the username already exists, try to create a new username. If it doesn't work even with the new
        // username, log an error to flag manual intervention
        String responseMessage = 'all good';
        try {
            insert usersToInsertMap.values();
        } catch (Exception e){
            system.debug(e.getMessage());
            // IF the error is a username error:
            // need to get erroredUser from message somehow
            // Otherwise, log a generic error and remove from list

         /*   if (newerror = erroredUser){
                1. remove from list
                2. log error
            } */

            User erroredUser;
            Map<Id, User> newUserMap = catchPreviouslyUsedEmail(usersToInsertMap, erroredUser);
            attemptInsert(newUserMap);
            responseMessage = 'hitError';
        }
        return responseMessage;
    }

    public static Map<Id, User> catchPreviouslyUsedEmail(Map<Id, User> usersToInsertMap, User erroredUser) {
        String firstName = erroredUser.FirstName;
        String lastName = erroredUser.LastName;
        Id contactId = erroredUser.ContactId;

        erroredUser.Username = firstName.left(1) + ' ' + lastName + '@bluewavesolar.com';
        usersToInsertMap.put(contactId, erroredUser);
        return usersToInsertMap;
    }
}