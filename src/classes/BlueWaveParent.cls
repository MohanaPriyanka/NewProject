/*************************************************************************************
 * Created By: Peter Yao
 * Description: Controller for BlueWaveParent super component that can be used for all
 *              custom lightning components
 *
 Tested By: LoanUnderwritingControllerTest
 *************************************************************************************/

public without sharing class BlueWaveParent {
    public static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

    @AuraEnabled 
    public static void updateSObject(SObject sobj) {
        update sobj;
    }

    @AuraEnabled 
    public static List<String> getPicklistFields(String objectName, String fieldName){
        Schema.SObjectType ctype = globalDescribe.get(objectName); 
        Map<String, Schema.SobjectField> fmap = ctype.getDescribe().fields.getMap();

        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = fmap.get(fieldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) {
            options.add(f.getLabel());
        }

        return options;
    }
    
}