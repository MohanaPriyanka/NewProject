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
        System.assertEquals(1, contactsWithZuoraContacts.size(),'We should only find one contact with a Zuora ID');
        System.assertEquals(contactTwo.Id, contactsWithZuoraContacts[0].Id,'The contact found should have a Zuora ID');
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
        System.assertEquals(2, checkContacts.size(),'We should find two contacts for our parent Account');
        System.assertEquals(parent.Id, checkContacts[0].AccountId,'The ID on the selected contact should match the parent account ID');
    }

    @IsTest
    private static void testSelectContactBySalesRepId() {
        Partner__c partner = new Partner__c(
            Name = 'Test Partner',
            Email__c = 'test@email.com'
        );
        insert partner;

        BSST__c salesTeam = new BSST__c(
            Partner__c = partner.Id
        );
        insert salesTeam;

        Contact salesRep = new Contact(
            FirstName = 'Test',
            LastName = 'Rep',
            Sales_Representative__c = salesTeam.Id
        );
        insert salesRep;

        Contact returnedSalesRep = ContactSelector.selectContactBySalesRepId(salesTeam.Id);
        System.assertEquals(salesRep.Id, returnedSalesRep.Id, 'Expected a sales rep Contact to be returned');
    }

    @IsTest
    private static void testInvocableSendBillsContactsSelector() {
        Id sssId =  (Util.getFakeId(Shared_Solar_System__c.SObjectType));
        Boolean includeActiveOnly = TRUE;
       
        InvocableSendBillsContactsSelector.GetSendBillsContactsBySSSIdInfo sendBillsContactRequest =
            new InvocableSendBillsContactsSelector.GetSendBillsContactsBySSSIdInfo();

        sendBillsContactRequest.sharedSolarSystemId = sssId;
        sendBillsContactRequest.includeActiveALSOnly = includeActiveOnly;
        
        List<List<Contact>> contactListWrapper = 
            InvocableSendBillsContactsSelector.GetSendBillsContactsBySSSId(new List<InvocableSendBillsContactsSelector.GetSendBillsContactsBySSSIdInfo>{sendBillsContactRequest});



        System.assertEquals(1,contactListWrapper.size(),'The InvocableSendBillsContactSelector should always return' + 
        'a list of contact lists (even if the contact list has no contacts in it');
        System.assertEquals(0,contactListWrapper[0].size(),'There should be no Send Bills Contacts for a SSS that is not found in the database');

    }

}