/**
 * Created by SarahRenfro on 3/5/2020.
 *
 * Tested By: FeatureServiceTest
 */

public without sharing class FeatureService {

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