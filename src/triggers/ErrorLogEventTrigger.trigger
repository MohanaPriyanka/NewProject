/**
 * @description Created by jeffparlin on 10/14/21. Inserts Error Logs from platform events irrespective of if the
 *  calling transaction fails or throws an exception
 */
trigger ErrorLogEventTrigger on Error_Log_Event__e (after insert) {
    Logger.insertLogs(Trigger.new);
}