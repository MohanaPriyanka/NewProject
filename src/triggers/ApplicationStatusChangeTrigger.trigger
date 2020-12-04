/**
 * Created by PeterYao on 12/2/2020.
 * Tested By: CSApplicationStatusEvaluatorTest
 */

trigger ApplicationStatusChangeTrigger on Application_Status_Change__e (after insert) {
    try {
        CSApplicationStatusEvaluator evaluator = new CSApplicationStatusEvaluator(Trigger.new);
        evaluator.updatePartnerApplicationStatus();
    } catch (Exception e) {
        Logger.logNow('ApplicationStatusChangeTrigger', 'main', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
    }
}