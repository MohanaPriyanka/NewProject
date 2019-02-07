/**
 * Created by abarnes on 1/15/2019.
 *
 * Description: Intended to implement fflib_SObjectDomain in the future
 *
 * Tested by: AccountsTest
 */

public class Accounts {
    public List<Account> records;

    public Accounts(List<Account> sObjectList) {
        records = sObjectList;
    }

    public void close() {
        for (Account acct : records) {
            acct.Status__c = 'Closed';
        }

        update records;
    }
}