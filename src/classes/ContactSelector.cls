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

    public static List<Contact> selectSendBillsContactBySSSId(Id  sharedSolarSystemId) {
        Set<Contact> sendBillsContacts = new Set<Contact>();
        List<Opportunity> getSendBillsContactsFromOpp =  [
            SELECT Account.Send_Bills_Contact__r.Id,  Account.Send_Bills_Contact__r.Email
            FROM Opportunity 
            WHERE Shared_Solar_System__c = :sharedSolarSystemId
            AND Opportunity.StageName = 'Complete'
            AND Account.Send_Bills_Contact__r.Email != NULL
        ];
        for (Opportunity opportunity : getSendBillsContactsFromOpp) {
            sendBillsContacts.add(opportunity.Account.Send_Bills_Contact__r);
        }
        return new List<Contact>(sendBillsContacts);
        
    }


    public static List<Contact> selectSendBillsContactByContract(Set<Id> contractIds){
        List<Id> contactIdList = new List<Id>();
        List<Contract> contractList = [
            SELECT Id, Account.Send_Bills_Contact__r.Id
            FROM Contract 
            WHERE Id IN :contractIds
        ];
        for(Contract con : contractList){
            contactIdList.add(con.Account.Send_Bills_Contact__r.Id);
        }
        List<Contact> returnList = [
            SELECT Id, Email, FirstName
            FROM Contact 
            WHERE Id IN :contactIdList
        ];
        return returnList;
    }
    

    public static List<Contact> selectActiveAlsSendBillsContactBySSSId(Id  sharedSolarSystemId) {
        Set<Contact> sendBillsContacts = new Set<Contact>();
        List<Schedule_Z_Subscription__c> getSendBillsContactsfromALS =  [
            SELECT Utility_Account_Subscription__r.Opportunity__r.Account.Send_Bills_Contact__r.Id,
                Utility_Account_Subscription__r.Opportunity__r.Account.Send_Bills_Contact__r.Email
            FROM Schedule_Z_Subscription__c 
            WHERE Schedule_Z__r.Shared_Solar_System__c = :sharedSolarSystemId
            AND Schedule_Z__r.Status__c IN ('Submitted to Utility', 'Enacted by Utility')
            AND Schedule_Z__r.Date_Submitted_to_Utility__c !=NULL
        ];
        for (Schedule_Z_Subscription__c sendBillsContactfromALS : getSendBillsContactsfromALS) {
            sendBillsContacts.add(sendBillsContactfromALS.Utility_Account_Subscription__r.Opportunity__r.Account.Send_Bills_Contact__r);
        }
        return new List<Contact>(sendBillsContacts);


    }
    

}