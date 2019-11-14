/**
 * Created by PeterYao on 11/12/2019.
 * Tested by: ContactServiceTest
 */

public with sharing class ContactService {
    @TestVisible
    private static ContactSelector contactSelector = new ContactSelector();

    public void batchContactUpdatesToZuora(Map<Id, Contact> oldContacts, Map<Id, Contact> newContacts) {
        try {
            List<ZuoraAPI.ZuoraContact> zuoraContacts = new List<ZuoraAPI.ZuoraContact>();
            for (Contact contact : contactsWithZuoraUpdates(oldContacts, newContacts)) {
                zuoraContacts.addAll(contactToZuoraContact(contact));
            }
            updateZuoraContacts(zuoraContacts);
        } catch (Exception e) {
            Logger.logLater(
                'ContactService',
                'handleUpdatesToZuora',
                'Caught Exception',
                Logger.ERROR
            );
        } finally {
            Logger.flushLogs();
        }
    }

    @TestVisible
    private void updateZuoraContacts(List<ZuoraAPI.ZuoraContact> zuoraContacts) {
        ZuoraAPI.ActionItems actionItems = new ZuoraAPI.ActionItems();
        actionItems.type = 'Contact';
        actionItems.objects = zuoraContacts;
        ZuoraGenericBatchOperation genericBatchOperation =
            new ZuoraGenericBatchOperation(actionItems, ZuoraAPIHelper.ActionDMLOperations.DMLUPDATE);
        Database.executeBatch(genericBatchOperation, 50);
    }

    @TestVisible
    private List<ZuoraAPI.ZuoraContact> contactToZuoraContact(Contact contact) {
        List<ZuoraAPI.ZuoraContact> zuoraContacts = new List<ZuoraAPI.ZuoraContact>();
        for (Zuora_Contact__c zuoraContact : contact.Zuora_Contacts__r) {
            ZuoraAPI.ZuoraContact zuoraContactToUpdate = new ZuoraAPI.ZuoraContact();
            zuoraContactToUpdate.Id = zuoraContact.Zuora_Id__c;
            zuoraContactToUpdate.FirstName = contact.FirstName;
            zuoraContactToUpdate.LastName = contact.LastName;
            zuoraContactToUpdate.PersonalEmail = contact.Email;
            zuoraContacts.add(zuoraContactToUpdate);
        }
        return zuoraContacts;
    }

    @TestVisible
    private List<Contact> contactsWithZuoraUpdates(Map<Id, Contact> oldContacts, Map<Id, Contact> newContacts) {
        Map<Id, Contact> contactsWithUpdates = new Map<Id, Contact>();
        for (Contact contact : newContacts.values()) {
            if (contact.Email != oldContacts.get(contact.Id).Email ||
                !contact.FirstName.equals(oldContacts.get(contact.Id).FirstName) ||
                !contact.LastName.equals(oldContacts.get(contact.Id).LastName)) {
                contactsWithUpdates.put(contact.Id, contact);
            }
        }
        return contactSelector.getContactsWithZuoraContacts(contactsWithUpdates.keySet());
    }
}