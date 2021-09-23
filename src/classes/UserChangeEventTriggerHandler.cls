/**
 * Created by aingram on 9/23/21.
 * @description Created to handle when a user's email is changed through verification
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class UserChangeEventTriggerHandler {

    public static void afterInsert(List<UserChangeEvent> newRecords) {
        filterUsersWithEmailUpdates(newRecords);
    }

    private static void filterUsersWithEmailUpdates(List<UserChangeEvent> newRecords) {
        Set<Id> userIds = new Set<Id>();
        for (UserChangeEvent event : newRecords) {
            EventBus.ChangeEventHeader header = event.ChangeEventHeader;

            if(header.changedFields.contains('Email')){
                for (Integer i = 0; i < header.recordIds.size(); i++ ) {
                    userIds.add(header.recordIds[i]);
                }
            }
        }

        updateRelatedContact(userIds);

    }

    @Future
    public static void updateRelatedContact(Set<Id> userIds) {
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
        }

        update relatedContacts;

    }

}