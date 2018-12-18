/**
 * Created by Sarah Renfro on 12/6/2018.
 *
 *
 * Tested By: CSAccountCancellerTest
 */

public without sharing class CSAccountCanceller {

    public static void handleOverdueAccounts() {
        List<Account> updatedAccounts = new List<Account>();
        List<Account> accountList = [
            SELECT Id, Days_Past_Due__c, Cancellation_Request_Date__c, Cancellation_Reason__c, Cancellation_Comments__c,
            (SELECT Id FROM Opportunities WHERE Customer_Group__c IN ('Anchor', 'Public Offtake'))
            FROM Account
            WHERE RecordTypeId = '012j00000010HeQ' AND Days_Past_Due__c > 67 AND Override_Delinquency_Removal__c = FALSE
            AND Cancellation_Request_Date__c = NULL
        ];

        for (Account acct : accountList) {
            if (acct.Opportunities.isEmpty()){
                    acct.Cancellation_Reason__c = 'Lack of Payment';
                    acct.Cancellation_Request_Date__c = System.today();
                    acct.Cancellation_Comments__c = 'Automated Cancellation';
                updatedAccounts.add(acct);
            }
        }

        if (!updatedAccounts.isEmpty()) {
            update updatedAccounts;
        }
    }
}