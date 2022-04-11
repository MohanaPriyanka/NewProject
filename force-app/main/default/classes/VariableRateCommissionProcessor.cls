/**
 * @description Created by jeffparlin on 2/25/22. Processes Variable Rate Commissions for single Partner. Creates
 * Partner_Payment__c records corresponding to Subscription_Order__c records for a subscription, and applies those payment
 * records to the specified Invoice__c record to be later remitted to the Partner by Accounting.
 * Tested By: PartnerCommissionGenerationTest
 */
public without sharing class VariableRateCommissionProcessor extends PartnerCommissionProcessor {

    @TestVisible private static SubscriptionOrderSelector soSelector = new SubscriptionOrderSelector();
    @TestVisible private static CommissionPaymentSelector paymentSelector = new CommissionPaymentSelector();
    @TestVisible private static FeatureService featureService = new FeatureService();
    private static Boolean clawbackPaymentsEnabled;

    public VariableRateCommissionProcessor(Map<Id, Opportunity> variableRateOpps, fflib_SObjectUnitOfWork uow,
        Id currentPartner)
    {
        super.opportunities = variableRateOpps;
        super.unitOfWork = uow;
        super.currentPartner = currentPartner;
        retrieveDependencies();
    }

    public override void retrieveDependencies() {
        clawbackPaymentsEnabled = featureService.isEnabled('Clawback_Partner_Commissions');
        constructIterableDealSummaries();
    }

    public override void generateCommissionPayments() {
        for (DealSummary deal : deals) {
            try {
                if (contractExecutionCommissionNeeded(deal)) {
                    generateContractExecutionCommission(deal);
                } else if (firstBillSentCommissionNeeded(deal)) {
                    generateFirstBillSentCommission(deal);
                } else if (firstBillPaidCommissionNeeded(deal)) {
                    generateFirstBillPaidCommission(deal);
                } else if (clawbackCommissionNeeded(deal)) {
                    generateClawbackCommission(deal);
                }
            } catch (Exception e) {
                String message =  deal + '\n\n' + e.getMessage() + ' ' + e.getStackTraceString();
                Logger.logLater('VariableRateCommissionProcessor', 'generateCommissionPayments', message, Logger.ERROR);
            }
        }
        Logger.flushLogs();
    }

    private void constructIterableDealSummaries() {
        Map<Id,List<Subscription_Order__c>> ordersByOpp = soSelector.getByOppForVariableCommission(opportunities.keySet());
        Map<Id,List<Commission_Payment__c>> paymentsByOpp = paymentSelector.getByOppForVariableCommission(opportunities.keySet());
        for (Id oppId : opportunities.keySet()) {
            DealSummary deal = new DealSummary();
            deal.opportunity = opportunities.get(oppId);
            deal.subscriptionOrders = ordersByOpp.get(oppId);
            deal.commissionPayments = paymentsByOpp.get(oppId);
            deals.add(deal);
        }
    }

    private Boolean contractExecutionCommissionNeeded(DealSummary deal) {
        Boolean dealMeetsCriteria = deal.opportunity.StageName == 'Complete' && !deal.subscriptionOrders.isEmpty();
        return dealMeetsCriteria && !existingCommissionFound(deal.commissionPayments, 'Contract Execution');
    }

    private Boolean firstBillSentCommissionNeeded(DealSummary deal) {
        Boolean dealMeetsCriteria = deal.opportunity.StageName == 'Complete' &&
            Util.nullToZero(deal.opportunity.Commission_Structure__r.Cents_kW_DC_First_Bill__c) != 0 &&
            deal.opportunity.First_Bill_Sent_Date__c != null;
        return dealMeetsCriteria && !existingCommissionFound(deal.commissionPayments, 'First Bill Sent');
    }

    private Boolean firstBillPaidCommissionNeeded(DealSummary deal) {
        Boolean dealMeetsCriteria = deal.opportunity.StageName == 'Complete' &&
            Util.nullToZero(deal.opportunity.Commission_Structure__r.Cents_kW_DC_First_Bill_Paid__c) != 0 &&
            deal.opportunity.First_Bill_Paid_Date__c != null;
        return dealMeetsCriteria && !existingCommissionFound(deal.commissionPayments, 'First Bill Paid');
    }

    private Boolean clawbackCommissionNeeded(DealSummary deal) {
        Boolean dealMeetsCriteria = deal.opportunity.StageName != 'Complete';
        return dealMeetsCriteria &&
            existingCommissionFound(deal.commissionPayments, 'Contract Execution') &&
            !existingCommissionFound(deal.commissionPayments, 'Cancellation/Refund');
    }

    private void generateContractExecutionCommission(DealSummary deal) {
        Commission_Payment__c executionCommission =  buildBaseCommissionPayment(deal, 'Contract Execution', 'Contract Execution');
        Decimal totalContractCloseAmount = 0;

        for (Subscription_Order__c order : deal.subscriptionOrders) {
            totalContractCloseAmount += getAndRegisterAmountFromSubscriptionOrder(
                order,
                Subscription_Order__c.Contract_Close_Estimated_Commission__c,
                Subscription_Order__c.Contract_Close_Commission_Amount__c,
                Subscription_Order__c.Contract_Close_Commission__c,
                executionCommission
            );
        }

        executionCommission.Contract_Execution_Amount__c = totalContractCloseAmount;
        executionCommission.Amount_Due__c = totalContractCloseAmount;
        unitOfWork.registerNew(executionCommission);
    }

    private void generateFirstBillSentCommission(DealSummary deal) {
        Commission_Payment__c firstBillSentCommission = buildBaseCommissionPayment(deal, 'First Bill Sent', 'First Bill Sent');
        Decimal totalContractCloseAmount = 0;
        Decimal totalFirstBillSentAmount = 0;

        for (Subscription_Order__c order : deal.subscriptionOrders) {
            if (!order.Included_in_Contract_Close__c) {
                continue;
            }
            totalContractCloseAmount += getAndRegisterAmountFromSubscriptionOrder(
                order,
                Subscription_Order__c.Contract_Close_Estimated_Commission__c,
                Subscription_Order__c.Contract_Close_Commission_Amount__c,
                Subscription_Order__c.Contract_Close_Commission__c,
                firstBillSentCommission
            );
            totalFirstBillSentAmount += getAndRegisterAmountFromSubscriptionOrder(
                order,
                Subscription_Order__c.First_Bill_Sent_Estimated_Commission__c,
                Subscription_Order__c.First_Bill_Sent_Commission_Amount__c,
                Subscription_Order__c.First_Bill_Sent_Commission__c,
                firstBillSentCommission
            );
        }

        firstBillSentCommission.Contract_Execution_Amount__c = totalContractCloseAmount;
        firstBillSentCommission.First_Bill_Sent_Amount__c = totalFirstBillSentAmount;
        firstBillSentCommission.Amount_Due__c = totalContractCloseAmount + totalFirstBillSentAmount;
        unitOfWork.registerNew(firstBillSentCommission);
    }

    private void generateFirstBillPaidCommission(DealSummary deal) {
        Commission_Payment__c firstBillPaidCommission = buildBaseCommissionPayment(deal, 'First Bill Paid', 'First Bill Paid');
        Decimal totalContractCloseAmount = 0;
        Decimal totalFirstBillSentAmount = 0;
        Decimal totalFirstBillPaidAmount = 0;

        for (Subscription_Order__c order : deal.subscriptionOrders) {
            if (!order.Included_in_Contract_Close__c) {
                continue;
            }
            totalContractCloseAmount += getAndRegisterAmountFromSubscriptionOrder(
                order,
                Subscription_Order__c.Contract_Close_Estimated_Commission__c,
                Subscription_Order__c.Contract_Close_Commission_Amount__c,
                Subscription_Order__c.Contract_Close_Commission__c,
                firstBillPaidCommission
            );
            totalFirstBillSentAmount += getAndRegisterAmountFromSubscriptionOrder(
                order,
                Subscription_Order__c.First_Bill_Sent_Estimated_Commission__c,
                Subscription_Order__c.First_Bill_Sent_Commission_Amount__c,
                Subscription_Order__c.First_Bill_Sent_Commission__c,
                firstBillPaidCommission
            );
            totalFirstBillPaidAmount += getAndRegisterAmountFromSubscriptionOrder(
                order,
                Subscription_Order__c.First_Bill_Paid_Estimated_Commission__c,
                Subscription_Order__c.First_Bill_Paid_Commission_Amount__c,
                Subscription_Order__c.First_Bill_Paid_Commission__c,
                firstBillPaidCommission
            );
        }

        firstBillPaidCommission.Contract_Execution_Amount__c = totalContractCloseAmount;
        firstBillPaidCommission.First_Bill_Sent_Amount__c = totalFirstBillSentAmount;
        firstBillPaidCommission.First_Bill_Paid_Amount__c = totalFirstBillPaidAmount;
        firstBillPaidCommission.Amount_Due__c = totalContractCloseAmount + totalFirstBillSentAmount + totalFirstBillPaidAmount;
        unitOfWork.registerNew(firstBillPaidCommission);
    }

    private void generateClawbackCommission(DealSummary deal) {
        Commission_Payment__c clawbackCommission = buildBaseCommissionPayment(deal, 'Chargeback', 'Cancellation/Refund');
        Decimal totalContractCloseAmount = 0;
        Decimal totalFirstBillSentAmount = 0;
        Decimal totalFirstBillPaidAmount = 0;

        for (Subscription_Order__c order : deal.subscriptionOrders) {
            totalContractCloseAmount += getAndRegisterAmountFromSubscriptionOrder(
                order,
                Subscription_Order__c.Contract_Close_Estimated_Commission__c,
                Subscription_Order__c.Contract_Close_Commission_Amount__c,
                Subscription_Order__c.Contract_Close_Commission__c,
                clawbackCommission
            );
            totalFirstBillSentAmount += getAndRegisterAmountFromSubscriptionOrder(
                order,
                Subscription_Order__c.First_Bill_Sent_Estimated_Commission__c,
                Subscription_Order__c.First_Bill_Sent_Commission_Amount__c,
                Subscription_Order__c.First_Bill_Sent_Commission__c,
                clawbackCommission
            );
            totalFirstBillPaidAmount += getAndRegisterAmountFromSubscriptionOrder(
                order,
                Subscription_Order__c.First_Bill_Paid_Estimated_Commission__c,
                Subscription_Order__c.First_Bill_Paid_Commission_Amount__c,
                Subscription_Order__c.First_Bill_Paid_Commission__c,
                clawbackCommission
            );
        }

        clawbackCommission.Contract_Execution_Amount__c = totalContractCloseAmount;
        clawbackCommission.First_Bill_Sent_Amount__c = totalFirstBillSentAmount;
        clawbackCommission.First_Bill_Paid_Amount__c = totalFirstBillPaidAmount;
        clawbackCommission.Amount_Due__c = totalContractCloseAmount + totalFirstBillSentAmount + totalFirstBillPaidAmount;

        if (clawbackPaymentsEnabled) {
            unitOfWork.registerNew(clawbackCommission);
        }
    }

    private Commission_Payment__c buildBaseCommissionPayment(DealSummary deal, String nameSuffix, String type) {
        return new Commission_Payment__c(
            Commission_Structure__c = deal.opportunity.Commission_Structure__c,
            Name = deal.opportunity.Partner_tag_lookup__r.Account__r.Name + ' - ' +
                deal.opportunity.Name.left(50) + ' - ' + nameSuffix,
            Opportunity__c = deal.opportunity.Id,
            Status__c = 'Pending Approval',
            Commission_Type__c = type,
            Invoice__c = getInvoiceForPartner().Id
        );
    }

    private Boolean existingCommissionFound(List<Commission_Payment__c> commissionPayments, String commissionType) {
        if (commissionPayments == null || commissionPayments?.isEmpty()) {
            return false;
        }
        for (Commission_Payment__c payment : commissionPayments) {
            if (payment.Commission_Type__c == commissionType) {
                return true;
            }
        }
        return false;
    }

    private Decimal getAndRegisterAmountFromSubscriptionOrder(Subscription_Order__c order, SObjectField estimatedAmountField,
        SObjectField amountField, SObjectField commissionLookupField, Commission_Payment__c commissionPayment)
    {
        if (order.get(amountField) == null && order.get(commissionLookupField) == null) {
            // This subscription order has not been applied to a Commission Payment yet, so stamp amount and apply
            // to the current Commission_Payment__c record being generated
            order.put(amountField, order.get(estimatedAmountField));
            unitOfWork.registerDirty(order, commissionLookupField, commissionPayment);
            return (Decimal) order.get(amountField);
        }
        return 0;
    }
}