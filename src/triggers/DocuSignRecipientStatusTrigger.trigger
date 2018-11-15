/*************************************************************************************
 * Created By: peteryao on 10/12/18  
 * Description: 
 * Test: DocuSignHelperTest
 *************************************************************************************/

trigger DocuSignRecipientStatusTrigger on dsfs__DocuSign_Recipient_Status__c (before update) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        DocuSignRecipientStatusHandler.voidChildren(Trigger.new);
    }
}