/**
  Tested by: ContentServiceTest
 */
trigger ContentVersionTrigger on ContentVersion (before update, after insert) {
    switch on Trigger.operationType {

        when BEFORE_UPDATE {
            ContentService.setReadyForPaperBillQueue(Trigger.oldMap, Trigger.new);
        } when AFTER_INSERT {
            ContentService.createDistribution(Trigger.new);
        }
    }
}