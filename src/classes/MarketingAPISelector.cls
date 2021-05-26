/**
 * @description Gets Marketing Cloud API Custom Metadata
 * Tested By: MarketingAPITest
 */
public without sharing class MarketingAPISelector {
    public List<MCAPI_Config__mdt> getMarketingAPIConfig() {
        return [
            SELECT Id, Sandbox_Publish_to_Prod__c, Callouts_Per_Transaction__c
            FROM MCAPI_Config__mdt
        ];
    }
}