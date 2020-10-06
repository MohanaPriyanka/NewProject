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
}