/**
 * Created by SarahRenfro on 1/29/2020.
 *
 * TestedBy: FeatureServiceTest
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
}