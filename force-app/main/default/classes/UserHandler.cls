// Tested by: UserHandlerTest

public without sharing class UserHandler implements Queueable{
    private List<Contact> contactsToCreateUsers;
    @TestVisible
    private UserAndGroupSelector userSelector = new UserAndGroupSelector();

    @SuppressWarnings('PMD.EmptyStatementBlock')
    public UserHandler() {}

    public UserHandler(List<Contact> userContacts) {
        this.contactsToCreateUsers = userContacts;
    }

    public void execute(QueueableContext context) {
        Map<Id, User> usersToInsertMap = new Map<Id, User>();
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name='Community Solar User'];

        for (Contact userContact : contactsToCreateUsers){
            if (userContact.Email != null &&
                userContact.FirstName != null &&
                userContact.LastName != null &&
                userContact.AccountId != null) {
                User userToInsert = setUserFields(userContact, profileRecord.Id);
                usersToInsertMap.put(userContact.Id, userToInsert);
            }
        }

        attemptInsert(usersToInsertMap);
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

    public static void attemptInsert(Map<Id, User> usersToInsertMap) {
        Database.SaveResult[] saveResults = Database.insert(usersToInsertMap.values(), false);

        for(Integer i = 0; i < saveResults.size(); i++){
            Database.SaveResult result = saveResults[i];
            if (!result.isSuccess()) {
                Id contactId = usersToInsertMap.values()[i].ContactId;
                Database.Error err = result.getErrors()[0];
                String response = err.getMessage();

                if (response.contains('Duplicate Username') || response.contains('Duplicate Nickname')) {
                    String message = 'Could not generate unique username or nickname. Contact: ';
                    Logger.logLater('UserHandler',
                            'attemptInsert',
                            message + contactId);
                } else {
                    String message = 'Unhandled Error: ' + response + '\nUser to insert: ' + contactId;
                    Logger.logLater('UserHandler', 'attemptInsert', message);
                }
            }
        }
        Logger.flushLogs();
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