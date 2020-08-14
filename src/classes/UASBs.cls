/**
 * Created by SarahRenfro on 8/14/2020.
 * Description: Could extend the fflib_SObjectDomain class
 * Tested By: UASBSelectorTest
 */

public inherited sharing class UASBs {
    private List<UASB__c> records;

    public UASBs(List<UASB__c> uasbs) {
        this.records = uasbs;
    }

    public void validate() {
        for (UASB__c uasb : records) {
            if (uasb.Zuora_Id__c != null ) {
                uasb.addError('Oops! This UASB cannot be deleted because it is linked to a Zuora record. Please contact Biz Apps for more information.');
            }
        }
    }
}