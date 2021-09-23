/**
 * Created by aingram on 9/23/21.
 * @description Created to handle when a user's email is changed through verification so that the contact's email is only updated when the email has been verified
 * Tested by UserChangeEventTriggerHandlerTest
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class UserChangeEventTriggerHandler {

    public static void afterInsert(List<UserChangeEvent> newRecords) {
        updateUserContactsOnEmailChange(newRecords);
    }

    private static void updateUserContactsOnEmailChange(List<UserChangeEvent> newRecords) {
        Set<Id> userIds = filterUsersWithEmailUpdates(newRecords);
        updateRelatedContacts(userIds);
    }

    private static Set<Id> filterUsersWithEmailUpdates(List<UserChangeEvent> newRecords) {
        Set<Id> userIds = new Set<Id>();
        for (UserChangeEvent event : newRecords) {
            EventBus.ChangeEventHeader header = event.ChangeEventHeader;
            if(header.changedFields.contains('Email') && header.changeType == 'UPDATE'){
                for (Integer i = 0; i < header.recordIds.size(); i++ ) {
                    userIds.add(header.recordIds[i]);
                }
            }
        }

        return userIds;
    }


    public static void updateRelatedContacts(Set<Id> userIds) {
        Map<Id, String> emailToContactIdMap = new Map<Id, String>();
        UserAndGroupSelector userSelector = new UserAndGroupSelector();
        List<User> users = userSelector.getUsersFromId(userIds);

        for (User u : users) {
            if (u.ContactId != null) {
                emailToContactIdMap.put(u.ContactId, u.Email);
            }
        }

        List<Contact> relatedContacts = ContactSelector.getContactsWithRelatedFields(emailToContactIdMap.keySet());

        for (Contact con : relatedContacts) {
            con.Email = emailToContactIdMap.get(con.Id);
            System.debug(con.Email);
        }

        update relatedContacts;

    }

}