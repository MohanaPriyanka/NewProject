trigger accountBillTrigger on Account_Bill__c (after Update) {
    CheckAddressFieldUpdate handler = new CheckAddressFieldUpdate();
    handler.updateCheckAddressFromAccountBill(Trigger.new);
}