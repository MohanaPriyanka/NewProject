/*
   Tested by: BillingAccountServiceTest, PaymentCaseTest, ZuoraGatewayAssignerTest
 */
trigger BillingAccountTrigger on Zuora__CustomerAccount__c (after update, after insert, before insert, before update) {
    if (Util.isDisabled('Disable_Billing_Account_Trigger__c')) {
        Logger.logNow('ZuoraBillingAccountTrigger','TriggerDisabled','Autopay Update and Autopay Cases did not execute because trigger is disabled','INFO');
        return;
    }
    PaymentCaseCreator pcc = new PaymentCaseCreator();
    ZuoraBillingAccountService billingAccountService = new ZuoraBillingAccountService();
    ZuoraGatewayAssigner gatewayAssigner = new ZuoraGatewayAssigner();
    try {
        switch on Trigger.operationType {
            when BEFORE_INSERT {
                gatewayAssigner.setDefaultPaymentGateway(Trigger.new);
            } when BEFORE_UPDATE {
                gatewayAssigner.setDefaultPaymentGateway(Trigger.new);
            } when AFTER_INSERT {
                billingAccountService.setBillingAccountOnPropertyAccount(Trigger.new);
            } when AFTER_UPDATE {
                billingAccountService.checkPropertyAccountDiscrepancy(Trigger.new);
                pcc.closeAutopayCasesOnPaymentMethodUpdate(Trigger.oldMap, Trigger.newMap);
            }
        }
    } catch (Exception excep) {
        // If something fails on the Salesforce side, we don't want to prevent z360 from inserting or updating a record
        // but just log an error instead:
        Logger.logNow('ZuoraBillingAccountTrigger','TriggerError',excep.getMessage() + '\n' + excep.getStackTraceString());
    }
}