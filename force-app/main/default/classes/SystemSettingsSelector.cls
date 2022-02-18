/**
 * Created by peteryao on 3/24/20.
 * Tested By: SystemSettingsSelectorTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class SystemSettingsSelector {
    public System_Settings__c getSystemSettings() {
        return [
            SELECT Id, Reports_Shared_to_Portal__c
            FROM System_Settings__c
            LIMIT 1
        ];
    }
}