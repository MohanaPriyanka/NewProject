/**
 * Created by aingram on 9/23/21.
 * @description Created to handle when a user's email is changed through verification so that the contact's email is only updated when the email has been verified
 * Tested by UserChangeEventTriggerHandlerTest
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class UserChangeEventTriggerHandler {

    public List<UserChangeEvent> newRecords = new List<UserChangeEvent>();

    public UserChangeEventTriggerHandler(List<UserChangeEvent> triggerNew) {
        this.newRecords = triggerNew;
    }

    public void afterInsert() {
        updateUserContactsOnEmailChange(newRecords);
    }

    private void updateUserContactsOnEmailChange(List<UserChangeEvent> newRecords) {
        Set<Id> userIds = filterUsersWithEmailUpdates(newRecords);
        updateRelatedContacts(userIds);
    }

    private Set<Id> filterUsersWithEmailUpdates(List<UserChangeEvent> newRecords) {
        Set<Id> userIds = new Set<Id>();
        for (UserChangeEvent event : newRecords) {
            EventBus.ChangeEventHeader header = event.ChangeEventHeader;
            if(header.changedFields.contains('Email') && header.changeType == 'UPDATE'){
                for (String recordId : header.recordIds) {
                    userIds.add(recordId);
                }
            }
        }

        return userIds;
    }


    private void updateRelatedContacts(Set<Id> userIds) {
        List<Contact> contactsWithUpdatedEmails = new List<Contact>();
        UserAndGroupSelector userSelector = new UserAndGroupSelector();
        List<User> users = userSelector.getUsersFromId(userIds);

        for (User u : users) {
            if (u.ContactId != null) {
                Contact c = u.Contact;
                c.Email = u.Email;
                contactsWithUpdatedEmails.add(c);
            }
        }

        update contactsWithUpdatedEmails;

    }

}