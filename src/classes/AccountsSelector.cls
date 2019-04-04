/*************************************************************************************
 * Created By: peteryao on 1/20/19  
 * Description: Can extend fflib_SObjectSelector
 * Test: AccountsSelectorTest
 *************************************************************************************/

public with sharing class AccountsSelector {
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
}