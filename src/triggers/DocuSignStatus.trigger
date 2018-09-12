/**
 * Created by mstackhouse on 9/6/2018.
 * Description: 
 * Test: 
 */


trigger DocuSignStatus on dsfs__DocuSign_Status__c (before update) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        DocuSignStatusTriggerHandler.voidChildren(Trigger.new);
    }
}