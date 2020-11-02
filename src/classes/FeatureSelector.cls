/**
 * Created by SarahRenfro on 3/5/2020.
 *
 * Tested By: FeatureServiceTest
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class FeatureSelector {

    public Custom_Feature_Enablement__mdt getCustomFeature(String developerName) {
        return [
            SELECT Id, MasterLabel, Feature_is_Enabled__c
            FROM Custom_Feature_Enablement__mdt
            WHERE DeveloperName = :developerName
        ];
    }

    public System_Default__mdt getSystemDefaults() {
        return [
            SELECT Id, Application_Complete_Email_Template__c
            FROM System_Default__mdt
        ];
    }
}