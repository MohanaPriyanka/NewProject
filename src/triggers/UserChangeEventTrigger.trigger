/**
 * Created by aingram on 9/23/21.
 * @description Change Event trigger can only handle after insert operations
 */

trigger UserChangeEventTrigger on UserChangeEvent (after insert) {

    UserChangeEventTriggerHandler handler = new UserChangeEventTriggerHandler(Trigger.new);

    if (Trigger.isAfter && Trigger.isInsert) {
        handler.afterInsert();
    }

}