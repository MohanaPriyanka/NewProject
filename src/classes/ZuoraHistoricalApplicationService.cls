/*************************************************************************************
 * Created By: peteryao on 2019-07-26  
 * Description: Applied payments for historical migration
 * Test: ZuoraHistoricalApplicationTest
 *************************************************************************************/

public with sharing class ZuoraHistoricalApplicationService implements ZuoraOutstandingItemsService.Processor, Queueable, Database.AllowsCallouts {
    private List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems;
    private ZuoraOutstandingItemsService.ProcessingParameter processingParameter;
    @TestVisible
    private Map<String, Id> projectUniqueIdToEntityMap;
    private String defaultPaymentMethodId;

    // Required when instantiating via Type.newInstance()
    public ZuoraHistoricalApplicationService() {
    }

    public ZuoraHistoricalApplicationService(List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems,
        ZuoraOutstandingItemsService.ProcessingParameter processingParameter) {
        this.outstandingItems = outstandingItems;
        this.processingParameter = processingParameter;
    }

    public void processOutstandingItems(List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems,
        ZuoraOutstandingItemsService.ProcessingParameter processingParameter) {
        this.outstandingItems = outstandingItems;
        this.processingParameter = processingParameter;
        getProjectMap();
        if (defaultPaymentMethodId == null) {
            getDefaultPaymentMethodId();
        }
        while (!processingParameter.payables.isEmpty()) {
            Payable payable = (Payable) processingParameter.payables[0];
            try {
                if (payable.creditMemo != null) {
                    applyCreditMemo(payable);
                }
                if (payable.payment != null) {
                    createAndApplyPayment(payable.payment);
                }
                processingParameter.payables.remove(0);
            } catch (Util.FatalBWException bwe) {
                Logger.logLater('ZuoraHistoricalApplicationService', 'processOutstandingItems',
                    'Error processing payable, stopping further processing: \n' + bwe.getMessage() + '\n' + bwe.getStackTraceString() + '\n' + payable,
                    Logger.ERROR);
                break;
            } catch (Exception e) {
                Logger.logLater('ZuoraHistoricalApplicationService', 'processOutstandingItems',
                    'Warning processing payable, will requeue: \n' + e.getMessage() + '\n' + e.getStackTraceString() + '\n' + payable,
                    Logger.WARN);
                requeue();
                break;
            }
        }
        Logger.flushLogs();
    }

    private void getProjectMap() {
        if (projectUniqueIdToEntityMap != null) {
            return;
        }
        this.projectUniqueIdToEntityMap = new Map<String, Id>();
        List<Shared_Solar_System__c> sharedSolarSystems = [
            SELECT Id, Unique_ID__c, BWC_Project_Entity_Manual__c
            FROM Shared_Solar_System__c
        ];
        for (Shared_Solar_System__c sharedSolarSystem : sharedSolarSystems) {
            projectUniqueIdToEntityMap.put(sharedSolarSystem.Unique_ID__c, sharedSolarSystem.BWC_Project_Entity_Manual__c);
        }
    }

    private void getDefaultPaymentMethodId() {
        if (defaultPaymentMethodId != null) {
            return;
        }
        String result = ZuoraAPIHelper.query('SELECT Id, AccountId FROM PaymentMethod WHERE Type = \'Cash\' AND AccountId = NULL LIMIT 1',
            false);
        ZuoraAPI.ZuoraQueryResult queryResult = (ZuoraAPI.ZuoraQueryResult) JSON.deserialize(result, ZuoraAPI.ZuoraQueryResult.class);
        if (queryResult.records.size() >= 1) {
            defaultPaymentMethodId = queryResult.records[0].Id;
        } else {
            throw new Util.BWException('Did not find a default payment method id to use');
        }
    }

    private void applyCreditMemo(Payable payable) {
        List<ZuoraOutstandingItemsService.OutstandingItem> itemsWithApplication =
            ZuoraOutstandingItemsService.applyToOutstandingItems(
                outstandingItems,
                payable.creditMemo.CreditMemo.unappliedAmount,
                payable.creditMemo.CreditMemo.Project_Zcustom,
                payable.creditMemo.CreditMemo.ClientOwner_Zcustom
            );
        ZuoraCreditMemoAllocationService.CreditMemoApplication creditMemoApplication =
            ZuoraCreditMemoAllocationService.groupByInvoiceAndDebitMemo(payable.creditMemo, itemsWithApplication);
        String urlString = '/v1/creditmemos/' + payable.creditMemo.CreditMemo.id +'/apply';
        Logger.logLater('ZuoraCreditMemoAllocationService', 'processOutstandingItems',
            'Request Endpoint: ' + urlString + '\n' +
                'Request Body: ' + JSON.serialize(creditMemoApplication),
            Logger.INFO);
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint( 'PUT', urlString, creditMemoApplication, false);
        Logger.logLater('ZuoraCreditMemoAllocationService', 'processOutstandingItems',
            'Response Body: ' + response.getBody(),
            Logger.INFO);
    }

    private void createAndApplyPayment(ChargentOrders__Transaction__c trx) {
        // Transfers could use five callouts, so don't start this unless there are at least five callouts and 10 seconds
        // that remain. Otherwise, we could end up creating a record and not posting or not applying it.
        if (ZuoraAPIHelper.getCalloutsRemaining() < 5 && ZuoraAPIHelper.getCalloutSecondsRemaining() < 10) {
            throw new Util.BWException('Not applying payment ' + trx.Id + ' because of callouts (' + ZuoraAPIHelper.getCalloutsRemaining() +
                ') or time (' + ZuoraAPIHelper.getCalloutSecondsRemaining() + ') remaining. Will retry.');
        }
        switch on trx.ChargentOrders__Type__c {
            when 'Transfer' {
                // Chargent Transactions are by Entity, but Credit/Debit Memos are project specific, so we need to translate
                handleTransfer(trx);
            }
            when 'Credit' {
                ZuoraSubscriptionService.ClientProject clientProjectAssignment = getClientProjectFromTransaction(trx, true);
                createAndApplyCreditMemo(trx, clientProjectAssignment, 'Refund');
            }
            when 'Refund' {
                ZuoraSubscriptionService.ClientProject clientProjectAssignment = getClientProjectFromTransaction(trx, true);
                createAndApplyCreditMemo(trx, clientProjectAssignment, 'Refund');
            }
            when else {
                // How do we handle this negative Charge? https://bluewavesolar.my.salesforce.com/a210a00000a4aUWAAY
                ZuoraAPI.Payment payment = createPayment(trx);
                applyPayment(trx, payment);
            }
        }
    }

    @TestVisible
    private void handleTransfer(ChargentOrders__Transaction__c trx) {
        if (trx.ChargentOrders__Amount__c < 0) {
            ZuoraSubscriptionService.ClientProject clientProjectAssignment = getClientProjectFromTransaction(trx, true);
            createAndApplyCreditMemo(trx, clientProjectAssignment, 'Transfer');
        } else {
            ZuoraSubscriptionService.ClientProject clientProjectAssignment = getClientProjectFromTransaction(trx, false);
            ZuoraAPI.ZuoraDebitMemo zuoraDebitMemo = createAndPostDebitMemo(trx, clientProjectAssignment);
            // Now that we've posted a new debit memo from this transfer, we need to add an outstanding item to the list
            // so that a future payment will be applied to it (since we're not querying outstanding items between each payment that
            // is applied)
            addDebitMemoToOutstandingItems(zuoraDebitMemo);
        }
    }

    private void addDebitMemoToOutstandingItems(ZuoraAPI.ZuoraDebitMemo zuoraDebitMemo) {
        ZuoraAPI.DebitMemoWithItems debitMemoWithItems = ZuoraOutstandingItemsService.getDebitMemoItems(zuoraDebitMemo);
        ZuoraOutstandingItemsService.OutstandingItem outstandingItem = new ZuoraOutstandingItemsService.OutstandingItem();
        outstandingItem.AmountOutstanding = zuoraDebitMemo.amount;
        outstandingItem.EffectiveDate = zuoraDebitMemo.debitMemoDate;
        outstandingItem.Project = zuoraDebitMemo.Project_Zcustom;
        outstandingItem.Client = zuoraDebitMemo.ClientOwner_Zcustom;
        outstandingItem.Id = debitMemoWithItems.items[0].id;
        outstandingItem.ParentId = zuoraDebitMemo.id;
        outstandingItem.IsInvoiceItem = false;
        outstandingItems.add(outstandingItem);
        outstandingItems.sort();
    }

    private void createAndApplyCreditMemo(ChargentOrders__Transaction__c trx, ZuoraSubscriptionService.ClientProject clientProjectAssignment, String reasonCode) {
        ZuoraAPI.ZuoraCreditMemo zuoraCreditMemo = createAndPostCreditMemo(trx, clientProjectAssignment, reasonCode);
        ZuoraAPI.CreditMemoWithItem creditMemoWithItem =
            ZuoraCreditMemoAllocationService.getItemFromCreditMemo(zuoraCreditMemo);
        Payable payable = new Payable(creditMemoWithItem);
        applyCreditMemo(payable);
    }

    private ZuoraSubscriptionService.ClientProject getClientProjectFromTransaction(ChargentOrders__Transaction__c trx, Boolean withOpenBalance) {
        // We need the client, project, and charge Id to create a memo, and for credit memos, we want to create one with an existing outstanding item
        ZuoraSubscriptionService.ClientProject clientProjectAssignment;

        ZuoraAPI.OrderBySubscriptionOwner orderBySubscriptionOwner =
            ZuoraSubscriptionService.getOrderBySubscriptionOwner(trx.ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Zuora_Id__c);
        Set<ZuoraSubscriptionService.ClientProject> clientProjects =
            orderBySubscriptionOwner.getClientProjectsFromOrders();

        if (withOpenBalance) {
            for (ZuoraOutstandingItemsService.OutstandingItem outstandingItem : outstandingItems) {
                if (outstandingItem.AmountOutstanding > 0 &&
                    outstandingItem.Client == trx.Client__r.Account_Number__c &&
                    projectUniqueIdToEntityMap.get(outstandingItem.Project) == trx.ChargentOrders__Order__r.Entity__c) {
                    clientProjectAssignment = getClientProjectFromOutstandingItem(outstandingItem, clientProjects);
                    break;
                }
            }
        } else {
            for (ZuoraSubscriptionService.ClientProject clientProject : clientProjects) {
                if (projectUniqueIdToEntityMap.get(clientProject.projectName) == trx.ChargentOrders__Order__r.Entity__c) {
                    clientProjectAssignment = clientProject;
                    break;
                }
            }
        }

        if (clientProjectAssignment == null) {
            throw new Util.FatalBWException('Could not assign this transfer transaction to a project with an open balance: ' + trx.Id);
        }
        return clientProjectAssignment;
    }

    private ZuoraSubscriptionService.ClientProject getClientProjectFromOutstandingItem(ZuoraOutstandingItemsService.OutstandingItem outstandingItem, Set<ZuoraSubscriptionService.ClientProject> clientProjects) {
        for (ZuoraSubscriptionService.ClientProject clientProject : clientProjects) {
            if (clientProject.projectName == outstandingItem.Project &&
                clientProject.clientName == outstandingItem.Client) {
                return clientProject;
            }
        }
        throw new Util.FatalBWException('Could not find a client project for this outstanding item: ' + outstandingItem);
    }


    private ZuoraAPI.ZuoraCreditMemo createAndPostCreditMemo(ChargentOrders__Transaction__c trx, ZuoraSubscriptionService.ClientProject clientProjectAssignment, String reasonCode) {
        ZuoraAPI.CreditMemo creditMemo = new ZuoraAPI.CreditMemo();
        creditMemo.accountId = trx.ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Zuora_Id__c;
        ZuoraAPI.CreditCharge creditCharge = new ZuoraAPI.CreditCharge();
        if (trx.ChargentOrders__Amount__c > 0) {
            throw new Util.FatalBWException('Expected a negative amount when creating credit memo for transaction ' + trx.Id);
        }
        creditCharge.amount = -trx.ChargentOrders__Amount__c;
        creditCharge.chargeId = clientProjectAssignment.productRatePlanChargeId;
        creditMemo.charges = new List<ZuoraAPI.CreditCharge>();
        creditMemo.charges.add(creditCharge);
        creditMemo.reasonCode = reasonCode;
        creditMemo.Project_Zcustom = clientProjectAssignment.projectName;
        creditMemo.ClientOwner_Zcustom = clientProjectAssignment.clientName;
        creditMemo.CRM_ID_Zcustom = trx.Id;
        creditMemo.effectiveDate = Date.newInstance(trx.CreatedDate.date().year(), trx.CreatedDate.date().month(), trx.CreatedDate.date().day());

        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('POST','/v1/creditmemos',creditMemo,false);
        ZuoraAPI.GenericResponse zResponse =
            (ZuoraAPI.GenericResponse) JSON.deserialize(response.getBody(), ZuoraAPI.GenericResponse.class);
        if (!zResponse.success){
            throw new Util.BWException('Could not create credit memo: ' + creditMemo + '\n' + 'Got response: ' + zResponse);
        }
        ZuoraCreditDebitMemoService.postCreditMemo(zResponse.Id);

        ZuoraAPI.ZuoraCreditMemo zuoraCreditMemo = new ZuoraAPI.ZuoraCreditMemo();
        zuoraCreditMemo.id = zResponse.Id;
        zuoraCreditMemo.accountId = creditMemo.accountId;
        zuoraCreditMemo.creditMemoDate = creditMemo.effectiveDate;
        zuoraCreditMemo.amount = creditCharge.amount;
        zuoraCreditMemo.unappliedAmount = creditCharge.amount;
        zuoraCreditMemo.Project_Zcustom = creditMemo.Project_Zcustom;
        zuoraCreditMemo.ClientOwner_Zcustom = creditMemo.ClientOwner_Zcustom;

        return zuoraCreditMemo;
    }

    private ZuoraAPI.ZuoraDebitMemo createAndPostDebitMemo(ChargentOrders__Transaction__c trx, ZuoraSubscriptionService.ClientProject clientProjectAssignment) {
        ZuoraAPI.DebitMemo debitMemo = new ZuoraAPI.DebitMemo();
        debitMemo.accountId = trx.ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Zuora_Id__c;
        ZuoraAPI.DebitMemoCharge debitMemoCharge = new ZuoraAPI.DebitMemoCharge();
        debitMemoCharge.amount = trx.ChargentOrders__Amount__c;
        debitMemoCharge.chargeId = clientProjectAssignment.productRatePlanChargeId;
        debitMemo.charges = new List<ZuoraAPI.DebitMemoCharge>();
        debitMemo.charges.add(debitMemoCharge);
        debitMemo.reasonCode = 'Transfer';
        debitMemo.Project_Zcustom = clientProjectAssignment.projectName;
        debitMemo.ClientOwner_Zcustom = clientProjectAssignment.clientName;
        debitMemo.CRM_ID_Zcustom = trx.Id;
        debitMemo.effectiveDate = Date.newInstance(trx.CreatedDate.date().year(), trx.CreatedDate.date().month(), trx.CreatedDate.date().day());

        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('POST','/v1/debitmemos', debitMemo,false);
        ZuoraAPI.GenericResponse zResponse =
            (ZuoraAPI.GenericResponse) JSON.deserialize(response.getBody(), ZuoraAPI.GenericResponse.class);
        if (!zResponse.success){
            throw new Util.BWException('Could not create debit memo: ' + debitMemo + '\n' + 'Got response: ' + zResponse);
        }
        ZuoraCreditDebitMemoService.postDebitMemo(zResponse.Id);

        ZuoraAPI.ZuoraDebitMemo zuoraDebitMemo = new ZuoraAPI.ZuoraDebitMemo();
        zuoraDebitMemo.id = zResponse.Id;
        zuoraDebitMemo.accountId = debitMemo.accountId;
        zuoraDebitMemo.debitMemoDate = debitMemo.effectiveDate;
        zuoraDebitMemo.amount = debitMemoCharge.amount;
        zuoraDebitMemo.Project_Zcustom = debitMemo.Project_Zcustom;
        zuoraDebitMemo.ClientOwner_Zcustom = debitMemo.ClientOwner_Zcustom;

        return zuoraDebitMemo;
    }

    private ZuoraAPI.Payment createPayment(ChargentOrders__Transaction__c trx) {
        ZuoraAPI.Payment payment = new ZuoraAPI.Payment();
        payment.accountId = trx.ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Zuora_Id__c;
        payment.amount = trx.ChargentOrders__Amount__c;
        payment.type = 'External';
        payment.currency_Zreserved = 'USD';
        payment.paymentMethodId = defaultPaymentMethodId;
        payment.effectiveDate = Date.newInstance(trx.CreatedDate.date().year(), trx.CreatedDate.date().month(), trx.CreatedDate.date().day());

        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/payments', payment, false);
        payment = (ZuoraAPI.Payment) JSON.deserialize(ZuoraAPIHelper.cleanJSON(response.getBody()), ZuoraAPI.Payment.class);
        return payment;
    }

    private ZuoraAPI.ZuoraPaymentApplication applyPayment(ChargentOrders__Transaction__c trx, ZuoraAPI.Payment payment) {
        List<ZuoraOutstandingItemsService.OutstandingItem> itemsToApply =
            ZuoraOutstandingItemsService.applyToOutstandingItems(
                outstandingItems,
                trx.ChargentOrders__Amount__c,
                trx.ChargentOrders__Order__r.Entity__c,
                trx.Client__r.Account_Number__c,
                projectUniqueIdToEntityMap,
                // If we passed trx.CreatedDate, we could apply this payment only to outstanding items that were effective
                // on or before this date. I think we'd want to apply the payment in this way, see if any late fees are
                // applied, and then run it again with any remaining unapplied amounts for future invoices (i.e. overpayment
                // application)
                null
            );

        ZuoraAPI.ZuoraPaymentApplication paymentApplication = outstandingItemToPaymentApplication(itemsToApply, trx.CreatedDate);
        if (paymentApplication.hasItemsToApply()) {
            ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/payments/' + payment.id + '/apply', paymentApplication, false);
        }
        return paymentApplication;
    }

    @TestVisible
    private ZuoraAPI.ZuoraPaymentApplication outstandingItemToPaymentApplication(List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems,
        Datetime effectiveDate) {
        ZuoraAPI.ZuoraPaymentApplication paymentApplication = new ZuoraAPI.ZuoraPaymentApplication();
        Map<String, ZuoraAPI.ZuoraInvoiceApplication> invoiceToInvoiceItemMap = new Map<String, ZuoraAPI.ZuoraInvoiceApplication>();
        Map<String, ZuoraAPI.ZuoraDebitMemoApplication> debitMemoToDebitMemoItemMap = new Map<String, ZuoraAPI.ZuoraDebitMemoApplication>();
        for (ZuoraOutstandingItemsService.OutstandingItem outstandingItem : outstandingItems) {
            if (outstandingItem.AmountToApply == null || outstandingItem.AmountToApply == 0) {
                continue;
            }

            if (outstandingItem.IsInvoiceItem) {
                addInvoiceItemToMap(outstandingItem, invoiceToInvoiceItemMap);
            } else {
                addDebitMemoItemToMap(outstandingItem, debitMemoToDebitMemoItemMap);
            }

            // Since we need the payment application to be effective after the invoice item/debit memo item is effective to avoid
            // "The specified effective date should be later than or equal to the invoice date."
            if (outstandingItem.EffectiveDate > effectiveDate) {
                effectiveDate = outstandingItem.EffectiveDate + 1;
            }
        }
        paymentApplication.effectiveDate = Date.newInstance(effectiveDate.year(), effectiveDate.month(), effectiveDate.day());
        paymentApplication.invoices = invoiceToInvoiceItemMap.values();
        paymentApplication.debitMemos = debitMemoToDebitMemoItemMap.values();
        return paymentApplication;
    }

    private void addInvoiceItemToMap(ZuoraOutstandingItemsService.OutstandingItem outstandingItem,
        Map<String, ZuoraAPI.ZuoraInvoiceApplication> invoiceToItemMap) {
        ZuoraAPI.ZuoraInvoiceItemApplication invoiceItemApplication = new ZuoraAPI.ZuoraInvoiceItemApplication();
        invoiceItemApplication.amount = outstandingItem.AmountToApply;
        invoiceItemApplication.invoiceItemId = outstandingItem.Id;
        ZuoraAPI.ZuoraInvoiceApplication invoiceApplication = invoiceToItemMap.get(outstandingItem.ParentId);
        if (invoiceApplication != null) {
            invoiceApplication.items.add(invoiceItemApplication);
            invoiceApplication.amount += outstandingItem.AmountToApply;
        } else {
            invoiceApplication = new ZuoraAPI.ZuoraInvoiceApplication();
            invoiceApplication.invoiceId = outstandingItem.ParentId;
            invoiceApplication.amount = outstandingItem.AmountToApply;
            invoiceApplication.items = new List<ZuoraAPI.ZuoraInvoiceItemApplication>();
            invoiceApplication.items.add(invoiceItemApplication);
            invoiceToItemMap.put(outstandingItem.ParentId, invoiceApplication);
        }
    }

    private void addDebitMemoItemToMap(ZuoraOutstandingItemsService.OutstandingItem outstandingItem,
        Map<String, ZuoraAPI.ZuoraDebitMemoApplication> debitMemoToItemMap) {
        ZuoraAPI.ZuoraDebitMemoItemApplication debitMemoItemApplication = new ZuoraAPI.ZuoraDebitMemoItemApplication();
        debitMemoItemApplication.amount = outstandingItem.AmountToApply;
        debitMemoItemApplication.debitMemoItemId = outstandingItem.Id;
        ZuoraAPI.ZuoraDebitMemoApplication debitMemoApplication = debitMemoToItemMap.get(outstandingItem.ParentId);
        if (debitMemoApplication != null) {
            debitMemoApplication.items.add(debitMemoItemApplication);
            debitMemoApplication.amount += outstandingItem.AmountToApply;
        } else {
            debitMemoApplication = new ZuoraAPI.ZuoraDebitMemoApplication();
            debitMemoApplication.debitMemoId = outstandingItem.ParentId;
            debitMemoApplication.amount = outstandingItem.AmountToApply;
            debitMemoApplication.items = new List<ZuoraAPI.ZuoraDebitMemoItemApplication>();
            debitMemoApplication.items.add(debitMemoItemApplication);
            debitMemoToItemMap.put(outstandingItem.ParentId, debitMemoApplication);
        }
    }

    private void requeue() {
        ZuoraHistoricalApplicationService applicationService = new ZuoraHistoricalApplicationService(outstandingItems, processingParameter);
        System.enqueueJob(applicationService);
        Logger.flushLogs();
    }

    // Queueable execution is another queueable chain that happens after getting outstanding items, to process
    // credit memos and transactions
    public void execute(QueueableContext context) {
        processOutstandingItems(outstandingItems, processingParameter);
    }

    public static List<Payable> getSortedPayables(List<ZuoraAPI.CreditMemoWithItem> creditMemos, List<ChargentOrders__Transaction__c> payments) {
        List<Payable> payables = new List<Payable>();
        for (ZuoraAPI.CreditMemoWithItem creditMemo : creditMemos) {
            payables.add(new Payable(creditMemo));
        }
        for (ChargentOrders__Transaction__c payment : payments) {
            payables.add(new Payable(payment));
        }
        payables.sort();
        return payables;
    }

    // Used just to sort credit memos and payments
    public class Payable implements Comparable {
        private Datetime payableDate;
        private ZuoraAPI.CreditMemoWithItem creditMemo;
        private ChargentOrders__Transaction__c payment;

        public Payable(ZuoraAPI.CreditMemoWithItem creditMemo) {
            this.payableDate = creditMemo.CreditMemo.creditMemoDate;
            this.creditMemo = creditMemo;
        }

        public Payable(ChargentOrders__Transaction__c payment) {
            this.payableDate = payment.CreatedDate;
            this.payment = payment;
        }

        public Integer compareTo(Object compareTo) {
            Payable compareToItem = (Payable) compareTo;
            Integer returnValue = 0;
            if (payableDate > compareToItem.payableDate) {
                // Set return value to a positive value.
                returnValue = 1;
            } else if (payableDate < compareToItem.payableDate) {
                // Set return value to a negative value.
                returnValue = -1;
            }
            return returnValue;
        }
    }
}