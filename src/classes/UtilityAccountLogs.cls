/**
 * Created by SarahRenfro on 9/1/2020.
 *
 * Description: Could be extend the fflib_SObjectDomain class
 *
 * Tested By: UtilityAccountLogTriggerHandlerTest
 */

public inherited sharing class UtilityAccountLogs {
    public List<Utility_Account_Log__c> records;

    public UtilityAccountLogs(List<Utility_Account_Log__c> ualList) {
        records = ualList;
    }

    public void createUALSharesForGuestUser() {
        List<Utility_Account_Log__Share> shareRecords = new List<Utility_Account_Log__Share>();
        UserAndGroupSelector userSelector = new UserAndGroupSelector();
        User guestUser = userSelector.getGuestUser();

        for (Utility_Account_Log__c ual : records) {
            Utility_Account_Log__Share ualShare = new Utility_Account_Log__Share();
            ualShare.ParentId = ual.Id;
            ualShare.UserOrGroupId = guestUser.Id;
            ualShare.AccessLevel ='Read';
            ualShare.RowCause = Schema.Utility_Account_Log__Share.RowCause.Guest_User_Access__c;
            shareRecords.add(ualShare);
        }
        insert shareRecords;
    }
}