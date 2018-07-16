/**
 * Created by mstackhouse on 7/9/2018.
 * Description: Used to perform manipulations on trade accounts while analyzing the PCRs
 * Test: PCRTradeAccountHandlerTest
 */


public with sharing class PCRTradeAccountHandler {
    public static void makeTradeAccountAdjustments(Lead lead) {
        Map<Id, LASERCA__Trade_Accounts__c> tradeAccountsToUpdate = new Map<Id, LASERCA__Trade_Accounts__c>();
        List<LASERCA__Trade_Accounts__c> tradeAccounts = [
            SELECT Id, LASERCA__Account_Ownership_Type__c, LASERCA__Account_Status_Type__c, LASERCA__Account_Type__c,
                LASERCA__Open_Date__c, LASERCA__Name_of_the_Institution__c, LASERCA__Last_Activity_Date__c,
                LASERCA__Payment_Pattern_Data__c, LASERCA__Remaining_Term__c, LASERCA__Credit_Text__c,
                LASERCA__Account_Balance__c, LASERCA__Personal_Credit_Report__c, Exclude_From_Rollup__c,
                LASERCA__Credit_Loan_Type__c
            FROM LASERCA__Trade_Accounts__c
            WHERE LASERCA__Personal_Credit_Report__c = : lead.Personal_Credit_Report__c
            OR LASERCA__Personal_Credit_Report__c = : lead.Personal_Credit_Report_Co_Applicant__c
        ];
        if (lead.Application_Type__c == 'Joint') {
            tradeAccountsToUpdate.putAll(deduplicateTradeAccounts(lead, tradeAccounts));
        }
        tradeAccountsToUpdate.putAll(adjustAutomotiveAccounts(tradeAccounts));

        update tradeAccountsToUpdate.values();
    }

    public static List<LASERCA__Trade_Accounts__c> adjustAutomotiveAccounts(List<LASERCA__Trade_Accounts__c> tradeAccounts) {
        List<LASERCA__Trade_Accounts__c> tradeAccountsToUpdate = new List<LASERCA__Trade_Accounts__c>();
        for (LASERCA__Trade_Accounts__c tradeAccount : tradeAccounts) {
            if (tradeAccount.LASERCA__Credit_Loan_Type__c != 'Automotive') {continue;}
            Integer remainingPayments = Integer.valueOf(Util.nullToZero(tradeAccount.LASERCA__Remaining_Term__c));
            if (remainingPayments <= 6) {
                tradeAccount.Exclude_From_Rollup__c = true;
                tradeAccountsToUpdate.add(tradeAccount);
            }
        }
        return tradeAccountsToUpdate;
    }

    public static List<LASERCA__Trade_Accounts__c> deduplicateTradeAccounts(Lead lead, List<LASERCA__Trade_Accounts__c> tradeAccounts) {
        List<LASERCA__Trade_Accounts__c> tradeAccountsToUpdate = new List<LASERCA__Trade_Accounts__c>();
        Map<String, LASERCA__Trade_Accounts__c> primaryTradeAccounts = new Map<String, LASERCA__Trade_Accounts__c>();
        Map<String, LASERCA__Trade_Accounts__c> coAppTradeAccounts = new Map<String, LASERCA__Trade_Accounts__c>();
        for (LASERCA__Trade_Accounts__c tradeAccount : tradeAccounts) {
            String accountCriteria = matchAccountCriteria(tradeAccount);
            if (tradeAccount.LASERCA__Personal_Credit_Report__c == lead.Personal_Credit_Report__c) {
                primaryTradeAccounts.put(accountCriteria, tradeAccount);
            } else if (tradeAccount.LASERCA__Personal_Credit_Report__c == lead.Personal_Credit_Report_Co_Applicant__c) {
                coAppTradeAccounts.put(accountCriteria, tradeAccount);
            }
        }
        for (LASERCA__Trade_Accounts__c tradeAccount : coAppTradeAccounts.values()) {
            String accountCriteria = matchAccountCriteria(tradeAccount);
            if (primaryTradeAccounts.containsKey(accountCriteria)) {
                tradeAccount.Exclude_From_Rollup__c = true;
                tradeAccountsToUpdate.add(tradeAccount);
            }
        }
        return tradeAccountsToUpdate;
    }

    public static String matchAccountCriteria(LASERCA__Trade_Accounts__c tradeAccount) {
        String accountCriteria = tradeAccount.LASERCA__Name_of_the_Institution__c;
        accountCriteria += ('_' + tradeAccount.LASERCA__Account_Ownership_Type__c);
        accountCriteria += ('_' + tradeAccount.LASERCA__Account_Balance__c);
        accountCriteria += ('_' + tradeAccount.LASERCA__Open_Date__c.format());
        return accountCriteria;
    }
}