/**
 * @description Gets Marketing Cloud API Custom Metadata
 * Tested By: MarketingAPITest
 */
public without sharing class MarketingAPISelector {
    public List<MCAPI_Config__mdt> getMarketingAPIConfig() {
        return [
            SELECT Id, Sandbox_Publish_to_Prod__c, Callouts_Per_Transaction__c, Autopay_Reminder_Journey_Id__c, Change_in_COD_Email_Journey_Id__c, Credits_Flowing_Email_Journey_Id__c
            FROM MCAPI_Config__mdt
        ];
    }
}