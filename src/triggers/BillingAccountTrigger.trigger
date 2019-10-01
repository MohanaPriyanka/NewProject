trigger BillingAccountTrigger on Zuora__CustomerAccount__c (after update) {
    if (Util.isDisabled('Disable_Billing_Account_Trigger__c')) {
        Logger.logNow('ZuoraBillingAccountTrigger','TriggerDisabled','Autopay Update did not execute because trigger is disabled','INFO');
        return;
    }
    try {
        if (Trigger.isUpdate) {
            ZuoraBillingAccountService.updatePropertyAccount(Trigger.new);
        }
    } catch (Exception excep) {
        // If something fails on the Salesforce side, we don't want to prevent z360 from inserting or updating a record
        // but just log an error instead:
        Logger.logNow('ZuoraBillingAccountTrigger','TriggerError',excep.getMessage() + excep.getStackTraceString());
    }
}