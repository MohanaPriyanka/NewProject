/**
 * Created by PeterYao on 11/12/2019.
 * Tested By: ContactSelectorTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class ContactSelector {
    // Don't get Account Address fields with this query, since the Account related to the contact is the Parent account,
    // not the property account
    public List<Contact> getContactsWithZuoraContacts(Set<Id> contactIds) {
        List<Contact> contactsWithZContacts = new List<Contact>();
        List<Contact> allContacts = [
            SELECT Id, FirstName, LastName, Email, (
                SELECT Id, Zuora_Id__c FROM Zuora_Contacts__r
            )
            FROM Contact
            WHERE Id = :contactIds
        ];
        for (Contact contact : allContacts) {
            if (contact.Zuora_Contacts__r.size() > 0) {
                contactsWithZContacts.add(contact);
            }
        }
        return contactsWithZContacts;
    }

    public static List<Contact> selectByParentAccountIds(List<Id> parentAccountIds) {
        return [
            SELECT Id, FirstName, LastName, Email, AccountId
            FROM Contact
            WHERE AccountId IN : parentAccountIds
        ];
    }

    public static Contact selectContactBySalesRepId(String salesRepId) {
        if (String.isBlank(salesRepId)) {
            return null;
        }
        List<Contact> contacts = [
            SELECT Id
            FROM Contact
            WHERE Sales_Representative__c = :salesRepId
            LIMIT 1
        ];
        return contacts.size() > 0 ? contacts[0] : null;
    }
}