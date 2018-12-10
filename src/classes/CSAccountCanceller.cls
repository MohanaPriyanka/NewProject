/**
 * Created by Sarah Renfro on 12/6/2018.
 *
 *
 * Tested By: CSAccountCancellerTest
 */

public with sharing class CSAccountCanceller {

    public static void handleOverdueAccounts() {
        List<Account> updatedAccounts = new List<Account>();

        //Querying for Opps instead of Accounts --> for some reason I was unable to grab the Opps related list for delinquent accounts
        //Need to filter for already cancelled Accounts --> Check Cancellation_Request_Date__c
        Set<String> accounts = new Set<String>();
        List<Opportunity> oppsList = [
            SELECT Id, Account.Id, Account.Product_Line__c, Account.RecordTypeId, Account.Days_Past_Due__c, Customer_Group__c
            FROM Opportunity
            WHERE Customer_Group__c NOT IN ('Anchor', 'Public Offtake')
            AND Account.RecordTypeId = '012j00000010HeQ' AND Account.Product_Line__c = 'Community Solar'
            AND Account.Days_Past_Due__c > 67 AND Account.Override_Delinquency_Removal__c != TRUE
            AND Account.Cancellation_Request_Date__c = NULL
        ];

//        List<Account> delinquentAccounts = [
//            SELECT Id, Days_Past_Due__c, Cancellation_Reason__c, Cancellation_Request_Date__c, Cancellation_Comments__c,
//            (SELECT Id FROM Opportunities__r WHERE Customer_Group__c IN ('Anchor', 'Public Offtake'))
//            FROM Account
//            WHERE Product_Line__c = 'Community Solar'
//            AND RecordTypeId = '012j00000010HeQ'
//            AND Days_Past_Due__c > 67 AND Override_Delinquency_Removal__c != TRUE AND Cancellation_Request_Date__c = null
//        ];

        //Work through Opportunities to grab all the Accounts
        if (!oppsList.isEmpty()) {
            for (Opportunity opp : oppsList) {
                if (!accounts.contains(opp.Account.Id)) {
                    accounts.add(opp.Account.Id);
                }
            }
            //One query outside of the above loop but could I avoid the loop?
            List<Account> accountList = [
                SELECT Id, Cancellation_Request_Date__c, Cancellation_Comments__c,
                    Cancellation_Reason__c, Days_Past_Due__c
                FROM Account
                WHERE Id IN :accounts
            ];

            //Update the Accounts
            for (Account acct : accountList) {
                if (acct.Cancellation_Reason__c == null) {
                    acct.Cancellation_Reason__c = 'Lack of Payment';
                }
                acct.Cancellation_Request_Date__c = System.today();
                acct.Cancellation_Comments__c = 'Automated Cancellation';
                updatedAccounts.add(acct);
            }

            if (!updatedAccounts.isEmpty()) {
                update updatedAccounts;
            }
        }
    }
}