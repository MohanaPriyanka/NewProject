/*************************************************************************************
 * Created By: peteryao on 1/20/19
 * Description: Can extend fflib_SObjectSelector
 * Test: AccountsSelectorTest
 *************************************************************************************/

public without sharing class AccountsSelector {
    public static List<Account> selectCS67DaysPastDueWithAnchorOpps() {
        return [
            SELECT Id, Days_Past_Due__c, Cancellation_Request_Date__c, Cancellation_Reason__c, Cancellation_Comments__c,
            (SELECT Id
            FROM Opportunities
            WHERE Customer_Group__c IN ('Anchor', 'Public Offtake')
            OR RecordType.Name = 'Business Development- Offtake')
            FROM Account
            WHERE RecordType.Name = 'Property'
            AND Days_Past_Due__c > 67
            AND Override_Delinquency_Removal__c = FALSE
            AND Cancellation_Request_Date__c = NULL
        ];
    }

    public static List<Account> selectCSNotRemoved() {
        return [
            SELECT Id,
                Send_Bills_Contact__c, Send_Bills_Contact__r.FirstName,
                Send_Bills_Contact__r.Email, Send_Bills_Contact__r.Additional_Email__c,
                Additional_Contact__r.Email, Additional_Contact__r.Additional_Email__c,
                Date_Removed_from_Project__c,
            (SELECT Id, Name, Number_of_Removed_UASes__c, Number_of_Subscribed_UASes__c, Last_Date_UAS_Removed_From_Project__c
            FROM Utility_Account_Logs__r)
            FROM Account
            WHERE Count_of_CS_Opportunities__c > 0
            AND Date_Removed_from_Project__c = NULL
            AND RecordType.Name = 'Property'
        ];
    }

    public static List<Account> selectNotClosed(Set<Id> accountIds) {
        return [
            SELECT Id, Cancellation_Request_Date__c,
                Send_Bills_Contact__c,
                Send_Bills_Contact__r.Email,
                Send_Bills_Contact__r.FirstName,
                Send_Bills_Contact__r.Additional_Email__c,
                Additional_Contact__r.Email,
                Additional_Contact__r.Additional_Email__c,
            (SELECT Id, StageName FROM Opportunities WHERE Product_Line__c = 'Community Solar')
            FROM Account
            WHERE Id IN :accountIds
            AND Status__c != 'Closed'
        ];
    }

    public static List<Account> selectWithSendBillsContact(Set<Id> accountIds) {
        return [
            SELECT Id, Name, Account_Number__c, Zuora_Id__c, Send_Bills_Contact__c, Send_Bills_Contact__r.AccountId,
                Send_Bills_Contact__r.Id, Send_Bills_Contact__r.FirstName, Send_Bills_Contact__r.LastName,
                Send_Bills_Contact__r.Email, Recurring_Billing__c,
                Address_Attn__c, BillingStreet, BillingCity, BillingState, BillingPostalCode,
                Additional_Contact__r.Email
            FROM Account
            WHERE Id IN :accountIds
        ];
    }

    public Account selectOne(Id accountId) {
        List<Account> accounts = this.selectAll(new Set<Id>{accountId});
        if (accounts.isEmpty()) {
            return null;
        }
        return accounts[0];
    }

    public List<Account> selectAll(Set<Id> accountIds) {
        return [
            SELECT Id, Name, BillingStreet, BillingCity, BillingStateCode, BillingPostalCode,
                Zuora_Payment_Ref_Id__c, Zuora_Payment_Ref_Id_Expiration_Date__c, Lead__c
            FROM Account
            WHERE Id = :accountIds
        ];
    }

    public List<Account> selectPropertyAccountsByLeadIds(Set<Id> leadIds) {
        return [
            SELECT Id, Name, BillingStreet, BillingCity, BillingStateCode, BillingPostalCode,
                Zuora_Payment_Ref_Id__c, Zuora_Payment_Ref_Id_Expiration_Date__c, Lead__c
            FROM Account
            WHERE Lead__c = :leadIds
            AND RecordType.Name = 'Property'
        ];
    }
}