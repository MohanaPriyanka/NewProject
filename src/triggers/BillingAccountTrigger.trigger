trigger BillingAccountTrigger on Zuora__CustomerAccount__c (after update) {

    if (Util.isDisabled('Disable_Billing_Account_Trigger__c')) {
        return;
    }
    try {
        if (Trigger.isUpdate) {
            BillingAccountService.updatePropertyAccount(Trigger.new);
        }
    } catch (Exception excep) {
        // If something fails on the Salesforce side, we don't want to prevent z360 from inserting or updating a record
        // but just log an error instead:
        Logger.logNow('BillingAccountTrigger','TriggerError',excep.getMessage() + excep.getStackTraceString());
    }
}