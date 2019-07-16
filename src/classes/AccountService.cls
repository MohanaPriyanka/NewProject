/**
 * Created by jlugo on 2019-07-08.
 * Tested by system tests in RESTRouterV2Test
 */

public without sharing class AccountService {
    AccountsSelector accountsSelector = new AccountsSelector();

    public Account insertAccount(Account account) {
        insert account;
        account = accountsSelector.selectOne(account.Id);
        return account;
    }

    public Account updateAccount(Account account) {
        update account;
        account = accountsSelector.selectOne(account.Id);
        return account;
    }

}