/*
   Tested by: BillingAccountServiceTest, PaymentCaseTest
 */
trigger BillingAccountTrigger on Zuora__CustomerAccount__c (after update, after insert) {
    if (Util.isDisabled('Disable_Billing_Account_Trigger__c')) {
        Logger.logNow('ZuoraBillingAccountTrigger','TriggerDisabled','Autopay Update and Autopay Cases did not execute because trigger is disabled','INFO');
        return;
    }
    PaymentCaseCreator pcc = new PaymentCaseCreator();
    ZuoraBillingAccountService billingAccountService = new ZuoraBillingAccountService();
    try {
        if (Trigger.isUpdate) {
            billingAccountService.checkPropertyAccountDiscrepancy(Trigger.new);
            pcc.closeAutopayCasesOnPaymentMethodUpdate(Trigger.oldMap, Trigger.newMap);
        } else if (Trigger.isInsert) {
            billingAccountService.setBillingAccountOnPropertyAccount(Trigger.new);
        }
    } catch (Exception excep) {
        // If something fails on the Salesforce side, we don't want to prevent z360 from inserting or updating a record
        // but just log an error instead:
        Logger.logNow('ZuoraBillingAccountTrigger','TriggerError',excep.getMessage() + '\n' + excep.getStackTraceString());
    }
}