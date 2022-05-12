/**
 * @description Created by jeffparlin on 5/4/22. Determines and sets Partner Commission Amounts.
 * - Calculates Commission Payment records based on input SO's. Used in InvocableCommissionStructureChanger.cls
 * - Stamps approved commission amounts on SO's when Commission Payments are marked as approved
 * Tested By: PartnerCommissionGenerationTest, InvocableCommissionStructureChangerTest
 */
public without sharing class PartnerCommissionCalculator {

    @TestVisible private static CommissionPaymentSelector paymentSelector = new CommissionPaymentSelector();
    public List<Input> paymentDetails;

    /**
     * @description Constructor used for VariableRateCommissionProcessor where Subscription Order lookups have not yet been
     * committed to the database
     */
    public PartnerCommissionCalculator(List<Input> payments) {
        this.paymentDetails = payments;
    }

    /**
     * @description Constructor to handle Commission Payments for a single Opportunity
     * @param opportunityId Opportunity
     */
    public PartnerCommissionCalculator(Id opportunityId) {
        this.paymentDetails = parseInputsFromQuery(paymentSelector.getWithSubscriptionOrdersBySingleOpp(opportunityId));
    }

    public class Input {
        public Commission_Payment__c record;
        public Boolean requiresUpsert = false;
        public List<Subscription_Order__c> contractCloseOrders = new List<Subscription_Order__c>();
        public List<Subscription_Order__c> firstBillSentOrders = new List<Subscription_Order__c>();
        public List<Subscription_Order__c> firstBillPaidOrders = new List<Subscription_Order__c>();
    }

    public void calculate() {
        for (Input payment : this.paymentDetails) {
            Decimal amountDue = 0;
            Decimal contractExecutionAmount = 0;
            Decimal firstBillSentAmount = 0;
            Decimal firstBillPaidAmount = 0;

            for (Subscription_Order__c order : payment.contractCloseOrders) {
                amountDue += order.Contract_Close_Estimated_Commission__c;
                contractExecutionAmount += order.Contract_Close_Estimated_Commission__c;
            }
            for (Subscription_Order__c order : payment.firstBillSentOrders) {
                amountDue += order.First_Bill_Sent_Estimated_Commission__c;
                firstBillSentAmount += order.First_Bill_Sent_Estimated_Commission__c;
            }
            for (Subscription_Order__c order : payment.firstBillPaidOrders) {
                amountDue += order.First_Bill_Paid_Estimated_Commission__c;
                firstBillPaidAmount += order.First_Bill_Paid_Estimated_Commission__c;
            }

            if (Util.nullToZero(payment?.record.Amount_Due__c) != amountDue) {
                payment.record.Amount_Due__c = amountDue;
                payment.requiresUpsert = true;
            }
            if (Util.nullToZero(payment?.record.Contract_Execution_Amount__c) != contractExecutionAmount) {
                payment.record.Contract_Execution_Amount__c = contractExecutionAmount;
                payment.requiresUpsert = true;
            }
            if (Util.nullToZero(payment?.record.First_Bill_Sent_Amount__c) != firstBillSentAmount) {
                payment.record.First_Bill_Sent_Amount__c = firstBillSentAmount;
                payment.requiresUpsert = true;
            }
            if (Util.nullToZero(payment?.record.First_Bill_Paid_Amount__c) != firstBillPaidAmount) {
                payment.record.First_Bill_Paid_Amount__c = firstBillPaidAmount;
                payment.requiresUpsert = true;
            }
        }
    }

    public List<Commission_Payment__c> getUpsertList() {
        List<Commission_Payment__c> upsertList = new List<Commission_Payment__c>();
        for (Input paymentDetail : this.paymentDetails) {
            if (paymentDetail.requiresUpsert) {
                upsertList.add(paymentDetail.record);
            }
        }
        return upsertList;
    }

    private static List<Input> parseInputsFromQuery(List<Commission_Payment__c> payments) {
        List<Input> inputList = new List<Input>();
        for (Commission_Payment__c paymentRecord : payments) {
            Input payment = new Input();
            payment.record = paymentRecord;
            payment.contractCloseOrders = paymentRecord.Subscription_Orders__r;
            payment.firstBillSentOrders = paymentRecord.First_Bill_Subscription_Orders__r;
            payment.firstBillPaidOrders = paymentRecord.First_Bill_Paid_Subscription_Orders__r;
            inputList.add(payment);
        }
        return inputList;
    }
}