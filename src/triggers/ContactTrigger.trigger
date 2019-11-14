/**
 * Created by PeterYao on 11/11/2019.
 * Tested By: ContactServiceTest
 */

trigger ContactTrigger on Contact (after update) {
    if (Util.isDisabled('Disable_ContactTrigger__c')) {
        return;
    }
    ContactService contactService = new ContactService();

    switch on Trigger.operationType {
        when AFTER_UPDATE {
            contactService.batchContactUpdatesToZuora(Trigger.oldMap, Trigger.newMap);
        }
    }
}