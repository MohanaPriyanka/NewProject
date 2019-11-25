/**
 * Created by mstackhouse on 7/9/2018.
 * Description: Used to perform manipulations on trade accounts while analyzing the PCRs
 *  In General, it is best to not exclude something that should be excluded later, than exclude something that shouldn't
 *  be excluded. We'd rather have a customer not be pre-approved and later approved, than pre-approved and go back on
 *  our decision.
 * Test: PCRTradeAccountHandlerTest
 */


public without sharing class PCRTradeAccountHandler {
    public static Decimal calculateHouseholdMonthlyDebt(Lead lead, List<LASERCA__Trade_Accounts__c> tradeAccounts) {
        // capital pool is null until we figure out the flow for assigning banks
        Loan_Data__c capitalPool;
        Decimal householdMonthlyDebt = 0;
        Map<Id, LASERCA__Trade_Accounts__c> tradeAccountsToAdjust = getTradeAccounts(lead, tradeAccounts);

        tradeAccounts = makeTradeAccountAdjustments(tradeAccountsToAdjust, lead, capitalPool);
        if (tradeAccounts != null) {
            for (LASERCA__Trade_Accounts__c tradeAccount : tradeAccounts) {
                if (!tradeAccount.Exclude_From_Rollup__c) {
                    // capital pool is null until we figure out the flow for assigning banks
                    householdMonthlyDebt += calculateMonthlyPayment(tradeAccount, null);
                }
            }
        }
        return householdMonthlyDebt;
    }

    public static Decimal calculateMonthlyPayment(LASERCA__Trade_Accounts__c tradeAccount, Loan_Data__c capitalPool) {
        Decimal monthlyPayment = 0;
        // capital pool payment adjustments, could create an object that sets these. Want to wait until full solution
        // before creating a new object
        if (capitalPool == null || capitalPool.Investor__c == 'Avidia Bank') {
            if (tradeAccount.LASERCA__Account_Balance__c > 0 &&
                tradeAccount.LASERCA__Account_Type__c == 'Revolving' &&
                (tradeAccount.LASERCA__Monthly_Payment__c == tradeAccount.LASERCA__Account_Balance__c || tradeAccount.LASERCA__Monthly_Payment__c == null)){
                monthlyPayment = (tradeAccount.LASERCA__Account_Balance__c * 0.03);
            } else if (tradeAccount.LASERCA__Monthly_Payment__c != null) {
                monthlyPayment = tradeAccount.LASERCA__Monthly_Payment__c;
            }
        }
        return monthlyPayment;
    }

    public static List<LASERCA__Trade_Accounts__c> makeTradeAccountAdjustments(Map<Id, LASERCA__Trade_Accounts__c> tradeAccounts, Lead lead, Loan_Data__c capitalPool) {
        tradeAccounts.putAll(adjustAutomotiveAccounts(tradeAccounts.values(), capitalPool));

        if (tradeAccounts.size() > 0) {
            update tradeAccounts.values();
        }
        return tradeAccounts.values();
    }

    public static List<LASERCA__Trade_Accounts__c> adjustAutomotiveAccounts(List<LASERCA__Trade_Accounts__c> tradeAccounts, Loan_Data__c capitalPool) {
        List<LASERCA__Trade_Accounts__c> tradeAccountsToUpdate = new List<LASERCA__Trade_Accounts__c>();
        for (LASERCA__Trade_Accounts__c tradeAccount : tradeAccounts) {
            if (tradeAccount.LASERCA__Credit_Loan_Type__c != 'Automotive') {continue;}
            Integer maxRemainingPaymentsForExclusion = capitalPoolRemainingAutoPaymentExclusion(capitalPool);
            if (tradeAccount.LASERCA__Remaining_Term__c != null
                && Integer.valueOf(tradeAccount.LASERCA__Remaining_Term__c) <= maxRemainingPaymentsForExclusion) {
                tradeAccount.Exclude_From_Rollup__c = true;
                tradeAccountsToUpdate.add(tradeAccount);
            }
        }
        return tradeAccountsToUpdate;
    }

    public static Integer capitalPoolRemainingAutoPaymentExclusion(Loan_Data__c capitalPool) {
        // capital pool payment adjustments, could create an object that sets these. Want to wait until full solution
        // before creating a new object
        if (capitalPool == null || capitalPool.Investor__c == 'Avidia Bank') {
            return 6;
        } else {
            // setting to zero for default case
            return 0;
        }
    }


    private static Map<Id, LASERCA__Trade_Accounts__c> getTradeAccounts(Lead lead, List<LASERCA__Trade_Accounts__c> tradeAccounts) {
        Map<Id, LASERCA__Trade_Accounts__c> tradeAccountsToAdjust = new Map<Id, LASERCA__Trade_Accounts__c>();
        if (tradeAccounts == null) {
            for (LASERCA__Trade_Accounts__c tradeAccount : [
                SELECT Id, LASERCA__Account_Ownership_Type__c, LASERCA__Account_Status_Type__c, LASERCA__Account_Type__c,
                    LASERCA__Open_Date__c, LASERCA__Name_of_the_Institution__c, LASERCA__Last_Activity_Date__c,
                    LASERCA__Payment_Pattern_Data__c, LASERCA__Remaining_Term__c, LASERCA__Credit_Text__c,
                    LASERCA__Account_Balance__c, LASERCA__Personal_Credit_Report__c, Exclude_From_Rollup__c,
                    LASERCA__Credit_Loan_Type__c, LASERCA__Monthly_Payment__c
                FROM LASERCA__Trade_Accounts__c
                WHERE LASERCA__Personal_Credit_Report__c = : lead.Personal_Credit_Report__c
                OR LASERCA__Personal_Credit_Report__c = : lead.Personal_Credit_Report_Co_Applicant__c
            ]) {
                tradeAccountsToAdjust.put(tradeAccount.Id, tradeAccount);
            }
        } else {
            for (LASERCA__Trade_Accounts__c tradeAccount : tradeAccounts) {
                tradeAccountsToAdjust.put(tradeAccount.Id, tradeAccount);
            }
        }
        return tradeAccountsToAdjust;
    }
}