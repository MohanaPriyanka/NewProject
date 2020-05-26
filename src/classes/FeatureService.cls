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

    /*************
      *** MOCKS ***
      *************/
    @TestVisible
    private class Mock extends MockProvider {
        private Boolean enabled = false;
        private Map<String, Boolean> featureFlagMap;
        public Mock(Boolean enabled) {
            this.enabled = enabled;
        }
        public Mock(Map<String, Boolean> featureFlagMap) {
            this.featureFlagMap = featureFlagMap;
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'isEnabled' {
                    String featureName = (String) methodCall.listOfArgs[0];
                    if (featureFlagMap != null) {
                        if (featureFlagMap.containsKey(featureName)) {
                            return featureFlagMap.get(featureName);
                        } else {
                            throw new Util.BWException('Feature needs to be set explicitly in map: ' + featureName);
                        }
                    } else {
                        return enabled;
                    }
                }
            }
            return null;
        }
    }
}