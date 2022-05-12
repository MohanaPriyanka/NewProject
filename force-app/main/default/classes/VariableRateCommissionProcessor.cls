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
        Id currentPartner) {
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
                String message = deal + '\n\n' + e.getMessage() + ' ' + e.getStackTraceString();
                Logger.logLater('VariableRateCommissionProcessor', 'generateCommissionPayments', message, Logger.ERROR);
            }
        }
        calculateCommissionAmounts();
        Logger.flushLogs();
    }

    private void constructIterableDealSummaries() {
        Map<Id, List<Subscription_Order__c>> ordersByOpp = soSelector.getByOppForVariableCommission(opportunities.keySet());
        Map<Id, List<Commission_Payment__c>> paymentsByOpp = paymentSelector.getByOppForVariableCommission(opportunities.keySet());
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
        PartnerCommissionCalculator.Input payment = new PartnerCommissionCalculator.Input();
        payment.record = buildBaseCommissionPayment(deal, 'Contract Execution', 'Contract Execution');

        for (Subscription_Order__c order : deal.subscriptionOrders) {
            if (!order.Included_in_Contract_Close__c) {
                continue;
            }
            linkOrderToCommissionPayment(
                order, Subscription_Order__c.Contract_Close_Commission__c, payment.record, payment.contractCloseOrders
            );
        }
        super.paymentDetails.add(payment);
    }

    private void generateFirstBillSentCommission(DealSummary deal) {
        PartnerCommissionCalculator.Input payment = new PartnerCommissionCalculator.Input();
        payment.record = buildBaseCommissionPayment(deal, 'First Bill Sent', 'First Bill Sent');

        for (Subscription_Order__c order : deal.subscriptionOrders) {
            if (!order.Included_in_Contract_Close__c) {
                continue;
            }
            linkOrderToCommissionPayment(
                order, Subscription_Order__c.Contract_Close_Commission__c, payment.record, payment.firstBillSentOrders
            );
            linkOrderToCommissionPayment(
                order, Subscription_Order__c.First_Bill_Sent_Commission__c, payment.record, payment.firstBillSentOrders
            );
        }
        super.paymentDetails.add(payment);
    }

    private void generateFirstBillPaidCommission(DealSummary deal) {
        PartnerCommissionCalculator.Input payment = new PartnerCommissionCalculator.Input();
        payment.record = buildBaseCommissionPayment(deal, 'First Bill Paid', 'First Bill Paid');

        for (Subscription_Order__c order : deal.subscriptionOrders) {
            if (!order.Included_in_Contract_Close__c) {
                continue;
            }
            linkOrderToCommissionPayment(
                order, Subscription_Order__c.Contract_Close_Commission__c, payment.record, payment.firstBillPaidOrders
            );
            linkOrderToCommissionPayment(
                order, Subscription_Order__c.First_Bill_Sent_Commission__c, payment.record, payment.firstBillPaidOrders
            );
            linkOrderToCommissionPayment(
                order, Subscription_Order__c.First_Bill_Paid_Commission__c, payment.record, payment.firstBillPaidOrders
            );
        }
        super.paymentDetails.add(payment);
    }

    private void generateClawbackCommission(DealSummary deal) {
        PartnerCommissionCalculator.Input payment = new PartnerCommissionCalculator.Input();
        payment.record = buildBaseCommissionPayment(deal, 'Chargeback', 'Cancellation/Refund');

        for (Subscription_Order__c order : deal.subscriptionOrders) {
            linkOrderToCommissionPayment(
                order, Subscription_Order__c.Contract_Close_Commission__c, payment.record, payment.contractCloseOrders
            );
            linkOrderToCommissionPayment(
                order, Subscription_Order__c.First_Bill_Sent_Commission__c, payment.record, payment.firstBillSentOrders
            );
            linkOrderToCommissionPayment(
                order, Subscription_Order__c.First_Bill_Paid_Commission__c, payment.record, payment.firstBillPaidOrders
            );
        }
        if (clawbackPaymentsEnabled) {
            super.paymentDetails.add(payment);
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

    /**
     * @description Link a Subscription Order to a Commission Payment if eligible
     * @param order Subscription Order in question
     * @param commissionPaymentLookup Lookup field on Subscription Order for specific commission (e.g. Contract Close Commission)
     * @param commissionPayment Commission Payment to relate Subscription Order to
     * @param relatedListToApplyTo Related List to relate Subscription Order to (for PartnerCommissionCalculator)
     */
    private void linkOrderToCommissionPayment(
        Subscription_Order__c order,
        SObjectField commissionPaymentLookup,
        Commission_Payment__c commissionPayment,
        List<Subscription_Order__c> relatedListToApplyTo)
    {
        if (order.get(commissionPaymentLookup) == null) {
            unitOfWork.registerDirty(order, commissionPaymentLookup, commissionPayment);
            relatedListToApplyTo.add(order);
        }
    }

    private void calculateCommissionAmounts() {
        PartnerCommissionCalculator calculator = new PartnerCommissionCalculator(super.paymentDetails);
        calculator.calculate();
        for (PartnerCommissionCalculator.Input payment : super.paymentDetails) {
            unitOfWork.registerNew(payment.record);
        }
    }
}