/**
 * Created by PeterYao on 11/12/2019.
 */
@IsTest
public with sharing class ContactServiceTest {
    private static ContactService testContactService = new ContactService();
    private static void useMocks() {
        ContactService.contactSelector = (ContactSelector) Test.createStub(ContactSelector.class, new MockContactSelector());
    }

    @IsTest
    private static void testContactUpdate() {
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Test',
            Email = 'test@test.com'
        );
        insert testContact;
        Zuora_Contact__c zuoraContact = new Zuora_Contact__c(
            Contact__c = testContact.Id,
            Zuora_Id__c = '123455'
        );
        insert zuoraContact;

        System.assertEquals(0, ZuoraAPIHelper.endpointsCalled.size());

        Test.startTest();
        testContact.Email = 'updated@test.com';
        update testContact;
        Test.stopTest();

        System.assertEquals(1, ZuoraAPIHelper.endpointsCalled.size());
        System.assertEquals('/v1/action/update', ZuoraAPIHelper.endpointsCalled[0].endpoint);
        System.assert(ZuoraAPIHelper.endpointsCalled[0].jsonBody.contains('updated@test.com'));
        System.assert(!ZuoraAPIHelper.endpointsCalled[0].jsonBody.contains('test@test.com'));
    }

    @IsTest
    private static void testContactToZuoraContact() {
        useMocks();
        String json = '{"attributes":{"type":"Contact","url":"/services/data/v47.0/sobjects/Contact/003j000000bmTDhAAM"},' +
            '"Id":"003j000000bmTDhAAM",' +
            '"FirstName":"Mark",' +
            '"LastName":"Sylvia",' +
            '"Email":"updated@bluewavesolar.com",' +
            '"Zuora_Contacts__r":{"totalSize":2,"done":true,"records":[' +
            '{"attributes":{"type":"Zuora_Contact__c","url":"/services/data/v47.0/sobjects/Zuora_Contact__c/a8c0a000000KpfcAAC"},' +
            '"Contact__c":"003j000000bmTDhAAM","Id":"a8c0a000000KpfcAAC","Zuora_Id__c":"2c92a0fe6e3f70d7016e41223d837aeb"},' +
            '{"attributes":{"type":"Zuora_Contact__c","url":"/services/data/v47.0/sobjects/Zuora_Contact__c/a8c0a000000KpfcAAC"},' +
            '"Contact__c":"003j000000bmTDhAAM","Id":"a8c0a000000KpfdAAC","Zuora_Id__c":"2c92a0fe6e3f70d7016e41223d837aec"}' +
            ']' +
            '}' +
            '}';
        Contact mark = (Contact) System.JSON.deserialize(json, Contact.class);
        List<ZuoraAPI.ZuoraContact> zuoraContacts = testContactService.contactToZuoraContact(mark);
        System.assertEquals(2, zuoraContacts.size());
        System.assertEquals('updated@bluewavesolar.com', zuoraContacts[0].PersonalEmail);
        System.assertEquals('updated@bluewavesolar.com', zuoraContacts[1].PersonalEmail);
        System.assertNotEquals(zuoraContacts[0].Id, zuoraContacts[1].Id);

        System.assertEquals(0, ZuoraAPIHelper.endpointsCalled.size());

        Test.startTest();
        testContactService.updateZuoraContacts(zuoraContacts);
        Test.stopTest();

        System.assertEquals(1, ZuoraAPIHelper.endpointsCalled.size());
        System.assertEquals('/v1/action/update', ZuoraAPIHelper.endpointsCalled[0].endpoint);
    }

    @IsTest
    private static void testContactWithZuoraUpdates() {
        useMocks();
        String jsonWithoutZC = '{"attributes":{"type":"Contact","url":"/services/data/v47.0/sobjects/Contact/0030a000027EKrMAAW"},' +
            '"Id":"0030a000027EKrMAAW","FirstName":"Mark","LastName":"Sylvia","Email":"msylvia@bluewavesolar.com"}';
        Contact oldMarkWithoutZC = (Contact) System.JSON.deserialize(jsonWithoutZC, Contact.class);
        Contact newMarkWithoutZC = oldMarkWithoutZC.clone(true);
        String jsonWithZC = '{"attributes":{"type":"Contact","url":"/services/data/v47.0/sobjects/Contact/003j000000bmTDhAAM"},' +
            '"Id":"003j000000bmTDhAAM","FirstName":"Mark","LastName":"Sylvia","Email":"msylvia@bluewavesolar.com"}';
        Contact oldMarkWithZC = (Contact) System.JSON.deserialize(jsonWithZC, Contact.class);
        Contact newMarkWithZC = oldMarkWithZC.clone(true);

        Map<Id, Contact> oldContacts = new Map<Id, Contact>();
        Map<Id, Contact> newContacts = new Map<Id, Contact>();

        oldContacts.put(oldMarkWithoutZC.Id, oldMarkWithoutZC);
        newMarkWithoutZC.Email = 'changed@bluewavesolar.com';
        newContacts.put(newMarkWithoutZC.Id, newMarkWithoutZC);
        System.assertEquals(0, testContactService.contactsWithZuoraUpdates(oldContacts, newContacts).size(),
            'Expected no contact because there is no Zuora Contact');
        oldContacts.clear();
        newContacts.clear();

        oldContacts.put(oldMarkWithZC.Id, oldMarkWithZC);
        newMarkWithZC.Phone = '5551212';
        newContacts.put(newMarkWithZC.Id, newMarkWithZC);
        System.assertEquals(0, testContactService.contactsWithZuoraUpdates(oldContacts, newContacts).size(),
            'Expected no contact because there is no relevant change');

        oldContacts.clear();
        newContacts.clear();

        oldContacts.put(oldMarkWithZC.Id, oldMarkWithZC);
        newMarkWithZC.FirstName = 'mark';
        newContacts.put(newMarkWithZC.Id, newMarkWithZC);
        System.assertEquals(1, testContactService.contactsWithZuoraUpdates(oldContacts, newContacts).size(),
            'Expected a contact because there is relevant change for a contact with a Zuora Contact');
    }

    /*************
    *** MOCKS ***
    *************/
    public class MockContactSelector extends MockProvider {
        public MockContactSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getContactsWithZuoraContacts' {
                    Set<Id> contactIds = (Set<Id>) methodCall.listOfArgs[0];
                    String json;
                    if (contactIds.contains('003j000000bmTDhAAM')) {
                        json = '[' +
                            '{"attributes":{"type":"Contact","url":"/services/data/v47.0/sobjects/Contact/003j000000bmTDhAAM"},' +
                            '"Id":"003j000000bmTDhAAM","FirstName":"Mark","LastName":"Sylvia","Email":"msylvia@bluewavesolar.com",' +
                            '"Zuora_Contacts__r":{"totalSize":1,"done":true,"records":[' +
                            '{"attributes":{"type":"Zuora_Contact__c","url":"/services/data/v47.0/sobjects/Zuora_Contact__c/a8c0a000000KpfcAAC"},' +
                            '"Contact__c":"003j000000bmTDhAAM","Id":"a8c0a000000KpfcAAC","Zuora_Id__c":"2c92a0fe6e3f70d7016e41223d837aeb"}]}}]';
                    } else {
                        json = '[]';
                    }
                    List<Contact> contacts = (List<Contact>) System.JSON.deserialize(json, List<Contact>.class);
                    return contacts;
                }
            }
            return null;
        }
    }


}