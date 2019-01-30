trigger AccountBillTrigger on Account_Bill__c (before Update, after Update) {
    if (Util.isDisabled('Disable_AccountBillTrigger__c')) {
        return;
    }
    if (trigger.IsUpdate && trigger.IsBefore) {
        AccountBillHandler.handleAccountBill(Trigger.new);
    } else if (trigger.IsUpdate && trigger.IsAfter) {
        AccountBillHandler.setClientBrandKey(Trigger.new);
    }
}