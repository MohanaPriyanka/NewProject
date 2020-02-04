/**
 * Created by SarahRenfro on 1/29/2020.
 *
 * TestedBy: FeatureServiceTest
 */

public with sharing class FeatureService {
    @TestVisible
    private static FeatureSelector featureSelector = new FeatureSelector();

    public Boolean isEnabled(String developerName) {
        Custom_Feature_Enablement__mdt feature = featureSelector.getCustomFeature(developerName);
        if (feature == null) {
            return false;
        } else {
            return feature.Feature_is_Enabled__c;
        }
    }

}