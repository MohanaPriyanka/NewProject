/**
 * Created by peteryao on 3/24/20.
 */
@IsTest
public with sharing class SystemSettingsSelectorTest {
    @IsTest
    private static void testGetSystemSettings() {
        System_Settings__c systemSettings = new System_Settings__c(
            Reports_Shared_to_Portal__c = '{}'
        );
        insert systemSettings;
        SystemSettingsSelector selector = new SystemSettingsSelector();
        System.assertEquals('{}', selector.getSystemSettings().Reports_Shared_to_Portal__c);
    }
}