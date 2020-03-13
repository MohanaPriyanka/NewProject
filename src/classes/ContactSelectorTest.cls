/**
 * Created by PeterYao on 11/12/2019.
 */
@IsTest
public with sharing class ContactSelectorTest {
    @IsTest
    private static void testSelectForZuora() {
        Contact contactOne = new Contact(
            FirstName = 'Foo',
            LastName = 'Test'
        );
        Contact contactTwo = new Contact(
            FirstName = 'Bar',
            LastName = 'Test'
        );
        insert new List<Contact>{contactOne, contactTwo};

        Zuora_Contact__c zuoraContact = new Zuora_Contact__c(
            Contact__c = contactTwo.Id,
            Zuora_Id__c = '123456'
        );
        insert zuoraContact;

        ContactSelector contactSelector = new ContactSelector();
        List<Contact> contactsWithZuoraContacts =
            contactSelector.getContactsWithZuoraContacts(new Set<Id>{contactOne.Id, contactTwo.Id});
        System.assertEquals(1, contactsWithZuoraContacts.size());
        System.assertEquals(contactTwo.Id, contactsWithZuoraContacts[0].Id);
    }

    @IsTest
    private static void testSelectByParentAccountIds() {
        Account parent = new Account(
            Name = 'Parent Testcase'
        );
        insert parent;

        Contact contactOne = new Contact(
            FirstName = 'Foo',
            LastName = 'Test',
            AccountId = parent.Id
        );
        Contact contactTwo = new Contact(
            FirstName = 'Bar',
            LastName = 'Test',
            AccountId = parent.Id
        );

        Contact contactThree = new Contact(
            FirstName = 'NoParent',
            LastName = 'Testcase'
        );
        insert new List<Contact>{contactOne, contactTwo, contactThree};

        List<Contact> checkContacts = ContactSelector.selectByParentAccountIds(new List<Id>{parent.Id});
        System.assertEquals(2, checkContacts.size());
        System.assertEquals(parent.Id, checkContacts[0].AccountId);
    }
}