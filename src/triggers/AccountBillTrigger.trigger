trigger AccountBillTrigger on Account_Bill__c (before Update, after Update) { 
    if (trigger.IsUpdate && trigger.IsBefore) {
        AccountBillHandler.handleAccountBill(Trigger.new);
    } else if (trigger.IsUpdate && trigger.IsAfter) {
        AccountBillHandler.updateCheckAddressFromAccountBill(Trigger.new);
    }
}