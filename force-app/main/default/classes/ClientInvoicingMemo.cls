/**
 * Created by peteryao on 9/16/20.
 * Tested By: ClientInvoicingFeeWaiveServiceTest
 */

public with sharing class ClientInvoicingMemo {
    public Id clientInvoicingMemoId;
    public Id sharedSolarSystemId;
    public Datetime effectiveDate;
    public Decimal approvedChangeInSubscription;
    public String type;
    public ClientInvoicingMemo(Id sharedSolarSystemId, Datetime effectiveDate, Decimal approvedChangeInSubscription) {
        this.sharedSolarSystemId = sharedSolarSystemId;
        this.effectiveDate = effectiveDate;
        this.approvedChangeInSubscription = approvedChangeInSubscription;
    }

    public ClientInvoicingMemo(Client_Invoicing_Memo__c cim) {
        this.clientInvoicingMemoId = cim.Id;
        this.sharedSolarSystemId = cim.Subscription_Order__r.Utility_Account_Subscription__r.Shared_Solar_System__c;
        this.effectiveDate = cim.Effective_Date__c;
        this.approvedChangeInSubscription = cim.Subscription_Order__r.Approved_Change_in_Subscription__c;
        this.type = cim.Type__c;
    }
}