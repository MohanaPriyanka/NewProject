// Tested by: UserHandlerTest

public without sharing class UserHandler implements Queueable{
    private List<Contact> contactsToCreateUsers;
    @TestVisible
    private UserAndGroupSelector userSelector = new UserAndGroupSelector();

    public UserHandler() {
    }

    public UserHandler(List<Contact> userContacts) {
        this.contactsToCreateUsers = userContacts;
    }

    public void execute(QueueableContext context) {
        Map<Id, User> usersToInsertMap = new Map<Id, User>();
        Set<Id> alreadyAttempted = new Set<Id>();
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name='Community Solar Community User'];

        for (Contact userContact : contactsToCreateUsers){
            if (userContact.Email != null &&
                userContact.FirstName != null &&
                userContact.LastName != null &&
                userContact.AccountId != null) {
                User userToInsert = setUserFields(userContact, profileRecord.Id);
                usersToInsertMap.put(userContact.Id, userToInsert);
            }
        }
        attemptInsert(usersToInsertMap, alreadyAttempted);
        Logger.flushLogs();

    }

    public static User setUserFields(Contact userContact, String profileId) {
        // Username is limited to 80 characters, Nickname to 40 and Alias to 8:

        User userToInsert = new User(
            FirstName = userContact.FirstName,
            LastName = userContact.LastName,
            Alias = userContact.FirstName.left(2) + userContact.LastName.right(6),
            Email = userContact.Email,
            EmailEncodingKey ='UTF-8',
            LanguageLocaleKey ='en_US',
            LocaleSidKey ='en_US',
            Country ='United States',
            IsActive = true,
            ContactId = userContact.Id,
            ProfileId = profileId,
            TimeZoneSidKey='America/New_York',
            Username= userContact.Email,
            CommunityNickname = userContact.FirstName.left(10) + userContact.LastName.left(30)
        );
        return userToInsert;
    }

    public static void attemptInsert(Map<Id, User> usersToInsertMap, Set<Id> alreadyAttempted) {
        // If the username or nickname already exists, try to create a new one.
        // If it doesn't work even with the new value, log an error to flag manual intervention
        try {
            Util.insertSObjs(usersToInsertMap.values());
        } catch (Exception e) {
            String response = e.getMessage();
            // Example: 'Insert failed. First exception on row 0; first error: DUPLICATE_COMM_NICKNAME'
            // Working back from the error message, want to get row number of record that hit error
            Integer location;
            Integer recordToRetry;
            Integer recordToRemove;
            Map<Id, User> newUserMap;

            if (response.contains('DUPLICATE_USERNAME')) {
                location = response.indexOf('DUPLICATE_USERNAME');
                recordToRetry = Integer.valueOf(response.substring(location-16,location-15));
                newUserMap = catchPreviouslyUsedValues(usersToInsertMap, recordToRetry);
            } else if (response.contains('DUPLICATE_COMM_NICKNAME')) {
                location = response.indexOf('DUPLICATE_COMM_NICKNAME');
                recordToRetry = Integer.valueOf(response.substring(location-16,location-15));
                newUserMap = catchPreviouslyUsedValues(usersToInsertMap, recordToRetry);
            } else if (response.contains('PORTAL_USER_ALREADY_EXISTS_FOR_CONTACT')) {
                location = response.indexOf('PORTAL_USER_ALREADY_EXISTS_FOR_CONTACT');
                recordToRemove = Integer.valueOf(response.substring(location-16,location-15));
                Id errorContactId = usersToInsertMap.values()[recordToRemove].ContactId;
                newUserMap = usersToInsertMap;
                newUserMap.remove(errorContactId);
            } else {
                String message = 'Unhandled Error: ' + response + '\nUsers to insert: ' + usersToInsertMap.values();
                Logger.logLater('UserHandler',
                                'attemptInsert',
                                message);
            }
            if (recordToRetry != null) {
                Id errorContactId = newUserMap.values()[recordToRetry].ContactId;
                if (alreadyAttempted.contains(errorContactId)) {
                    newUserMap.remove(errorContactId);
                    Logger.logLater('UserHandler',
                                    'attemptInsert',
                                    'Could not generate unique username or nickname. Contact: ' + errorContactId);
                } else {
                    alreadyAttempted.add(errorContactId);
                }
                attemptInsert(newUserMap, alreadyAttempted);
            }
        }
    }

    public static Map<Id, User> catchPreviouslyUsedValues(Map<Id, User> usersToInsertMap, Integer recordNumber) {
        // If the customer's email is already used as a username, create a fake bluewave email for them:
        User userWithError = usersToInsertMap.values()[recordNumber];
        userWithError.Username = userWithError.FirstName.left(40) + userWithError.LastName.left(40) + '@bluewavesolar.com';
        userWithError.CommunityNickname = userWithError.LastName.left(5) + userWithError.FirstName.left(25);
        usersToInsertMap.put(userWithError.ContactId, userWithError);
        return usersToInsertMap;
    }

    public void createPortalActivationEmailLog(Set<Id> userIdSet){
        try {
            List<Task> tasksToInsert = new List<Task>();
            List<User> communityUsers = userSelector.getUsersFromId(userIdSet);
            for (User communityUser : communityUsers) {
                Task taskToInsert = new Task(
                    Subject = 'EMAIL LOG: Portal Activation Welcome Email Sent',
                    Description = 'Email body is variable, see community settings for detail',
                    Status = 'Closed',
                    WhoId = communityUser.ContactId
                );
                tasksToInsert.add(taskToInsert);
            }
            insert tasksToInsert;
        } catch(Exception excep){
            Logger.logNow('UserHandler','createPortalActivationEmailLog',excep.getMessage() + '_' + excep.getStackTraceString());
        }
    }
}