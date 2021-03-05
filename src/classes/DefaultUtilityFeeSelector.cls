/**
 * Created by jeffr on 3/2/2021.
 *
 * Tested by: DefaultUtilityFeeSelectorTest
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class DefaultUtilityFeeSelector {

    public Default_Utility_Fee__c getActiveUCBRecordForUtility(Id utilityId) {
        List<Default_Utility_Fee__c> utilityFees = [
            SELECT Id, Utility_Admin_Fee__c, Start_Date__c, Method_for_UCB_Utility_Admin__c
            FROM Default_Utility_Fee__c
            WHERE Utility__c =: utilityId AND Start_Date__c <= TODAY AND Type__c = 'UCB'
            ORDER BY End_Date__c DESC
        ];
        return utilityFees.size() > 0 ? utilityFees[0] : null;
    }

}