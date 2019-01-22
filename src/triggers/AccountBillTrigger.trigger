trigger AccountBillTrigger on Account_Bill__c (before Update, after Update) {
    if (Util.isDisabled('Disable_AccountBillTrigger__c')) {
        return;
    }
    AccountBillHandler handler = new AccountBillHandler();
    if (trigger.IsUpdate && trigger.IsBefore) {
        handler.handleAccountBill(Trigger.new);
    } else if (trigger.IsUpdate && trigger.IsAfter) {
        handler.setClientBrandKey(Trigger.new);
    }
}