/**
 * @description Created by jeffparlin on 3/23/22. Determines object type of input Record Id. Useful for dynamic Flows
 * where passed-in recordId can be dynamically evaluated
 */
public without sharing class GetObjectName {

    @InvocableMethod
    public static List<String> returnObjectName(List<String> recordIdStrings) {
        List<String> objectNames = new List<String>();
        Id recordId = Id.valueOf(recordIdStrings[0]);
        objectNames.add(recordId.getSobjectType().getDescribe().getName());
        return objectNames;
    }

}