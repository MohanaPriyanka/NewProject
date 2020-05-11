/*************************************************************************************
 * Created By: peteryao on 2019-07-26  
 * Description: Applied payments for historical migration
 * Test: ZuoraHistoricalApplicationTest
 *************************************************************************************/

public with sharing class ZuoraHistoricalApplicationService implements ZuoraOutstandingItemsService.Processor, Queueable, Database.AllowsCallouts {

    @TestVisible
    private ZuoraHistoricalCustomApplicationService customApplicationService = new ZuoraHistoricalCustomApplicationService();
    @TestVisible
    private List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems;
    private ZuoraOutstandingItemsService.ProcessingParameter processingParameter;
    @TestVisible
    private Map<String, Id> projectUniqueIdToEntityMap;
    // If debugging in a sandbox, we need mapping from SSS Names to production Ids
    // public Map<String, Id> projectUniqueIdToEntityMap = (Map<String, Id>) JSON.deserialize('{"SSS-000093":"a1Ij00000008uBREAY","SSS-000092":"a1Ij00000014jfCEAQ","SSS-000091":"a1Ij00000014k5ZEAQ","SSS-000090":"a1Ij00000008uBREAY","SSS-000089":"a1Ij0000000luDUEAY","SSS-000088":"a1Ij0000000m5GwEAI","SSS-000096":"a1I0a000008nB8fEAE","SSS-000097":null,"SSS-000087":"a1Ij0000000mPnaEAE","SSS-000086":null,"SSS-000085":"a1Ij00000008uBREAY","SSS-000084":"a1Ij00000014jfCEAQ","SSS-000083":"a1I0a000008mrlLEAQ","SSS-000082":null,"SSS-000104":"a1I0a00000A1U2vEAF","SSS-000081":null,"SSS-000080":null,"SSS-000079":null,"SSS-000078":null,"SSS-000077":null,"SSS-000076":null,"SSS-000075":null,"SSS-000074":"a1I0a000008mrlVEAQ","SSS-000073":"a1I0a000008mrlQEAQ","SSS-000072":"a1I0a000006Xf6nEAC","SSS-000071":"a1I0a000006WwpyEAC","SSS-000070":"a1I0a000006WwptEAC","SSS-000069":"a1I0a000006WwpoEAC","SSS-000068":"a1I0a000006WwpjEAC","SSS-000067":"a1I0a000008D37XEAS","SSS-000066":"a1I0a000008D37XEAS","SSS-000065":"a1I0a000008D37XEAS","SSS-000064":"a1I0a000008CDtbEAG","SSS-000063":"a1Ij0000000luD3EAI","SSS-000062":"a1Ij0000000m5GwEAI","SSS-000061":null,"SSS-000060":"a1I0a000008mrlaEAA","SSS-000059":null,"SSS-000058":null,"SSS-000102":"a1I0a00000A1YCMEA3","SSS-000101":"a1I0a00000A1YC7EAN","SSS-000100":"a1I0a00000A1YCCEA3","SSS-000103":"a1I0a00000A1YCHEA3","SSS-000098":"a1I0a00000A1ah3EAB","SSS-000099":"a1I0a00000A1ah8EAB","SSS-000057":"a1Ij0000000luD8EAI","SSS-000056":"a1Ij0000000luCrEAI","SSS-000055":null,"SSS-000054":null,"SSS-000053":"a1Ij0000000luDQEAY","SSS-000052":"a1I0a000005GhmkEAC","SSS-000051":"a1Ij0000000luD0EAI","SSS-000050":"a1Ij0000000luD0EAI","SSS-000049":"a1Ij0000000luCkEAI","SSS-000048":"a1Ij0000000luCkEAI","SSS-000047":null,"SSS-000046":null,"SSS-000135":null,"SSS-000136":null,"SSS-000132":null,"SSS-000129":null,"SSS-000131":null,"SSS-000134":null,"SSS-000133":null,"SSS-000130":null,"SSS-000045":"a1Ij0000000luD0EAI","SSS-000043":null,"SSS-000042":"a1I0a000005GLSdEAO","SSS-000041":"a1Ij0000003lFzBEAU","SSS-000040":null,"SSS-000039":null,"SSS-000038":null,"SSS-000037":null,"SSS-000036":null,"SSS-000035":null,"SSS-000034":"a1I0a000004y0hREAQ","SSS-000033":null,"SSS-000032":null,"SSS-000031":null,"SSS-000030":null,"SSS-000029":null,"SSS-000028":null,"SSS-000027":null,"SSS-000026":null,"SSS-000025":"a1I0a000006Wyj6EAC","SSS-000024":"a1Ij0000000luDAEAY","SSS-000023":"a1Ij0000000luDAEAY","SSS-000022":"a1Ij0000000luDAEAY","SSS-000021":"a1Ij0000000luDEEAY","SSS-000020":"a1Ij0000000luDEEAY","SSS-000019":"a1Ij0000000luDEEAY","SSS-000018":"a1Ij0000000luDAEAY","SSS-000017":"a1Ij0000000luDEEAY","SSS-000016":"a1Ij0000000luDEEAY","SSS-000015":null,"SSS-000014":null,"SSS-000013":null,"SSS-000012":null,"SSS-000011":null,"SSS-000010":null,"SSS-00009":"a1Ij0000000luD7EAI","SSS-000008":null,"SSS-000118":null,"SSS-000126":null,"SSS-000121":null,"SSS-000117":null,"SSS-000127":null,"SSS-000122":null,"SSS-000120":null,"SSS-000114":null,"SSS-000125":null,"SSS-000111":null,"SSS-000119":null,"SSS-000124":null,"SSS-000113":null,"SSS-000123":null,"SSS-000115":null,"SSS-000007":null,"SSS-000109":null,"SSS-000112":null,"SSS-000106":null,"SSS-000107":"a1I0a000008mrlVEAQ","SSS-000116":null,"SSS-000110":null,"SSS-000006":null,"SSS-000105":null,"SSS-000108":null,"SSS-000005":"a1Ij0000003lKrLEAU","SSS-000004":null,"SSS-000003":"a1Ij0000000luD1EAI","SSS-000002":"a1Ij0000000luCzEAI","SSS-000001":"a1Ij0000000luCsEAI"}', Map<String, Id>.class);
    private String defaultPaymentMethodId;

    // Required when instantiating via Type.newInstance()
    public ZuoraHistoricalApplicationService() {
        this.customApplicationService.init();
    }

    public void processOutstandingItems(List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems,
        ZuoraOutstandingItemsService.ProcessingParameter processingParameter) {
        this.outstandingItems = outstandingItems;
        this.processingParameter = processingParameter;
        getProjectMap();
        if (defaultPaymentMethodId == null) {
            getDefaultPaymentMethodId();
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
        defaultPaymentMethodId = ZuoraPaymentMethodSelector.getDefaultPaymentMethodId();
    }

    @TestVisible
    private ZuoraSubscriptionService.ClientProject getClientProjectFromTransaction(ChargentOrders__Transaction__c trx, Boolean withOpenBalance) {
        // We need the client, project, and charge Id to create a memo, and for credit memos, we want to create one with an existing outstanding item
        ZuoraSubscriptionService.ClientProject clientProjectAssignment;

        ZuoraAPI.OrderBySubscriptionOwner orderBySubscriptionOwner =
            ZuoraSubscriptionService.getOrderBySubscriptionOwner(trx.ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Zuora_Id__c);
        Set<ZuoraSubscriptionService.ClientProject> clientProjects =
            orderBySubscriptionOwner.getClientProjectsFromOrders();

        if (withOpenBalance) {
            for (ZuoraOutstandingItemsService.OutstandingItem outstandingItem : outstandingItems) {
                if (matchesClientEntityOrProject(outstandingItem, trx)) {
                    clientProjectAssignment = getClientProjectFromOutstandingItem(outstandingItem, clientProjects);
                    break;
                }
            }
        } else {
            for (ZuoraSubscriptionService.ClientProject clientProject : clientProjects) {
                if (matchesClientEntityOrProject(clientProject, trx)) {
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

    private Boolean matchesClientEntityOrProject(ZuoraOutstandingItemsService.OutstandingItem outstandingItem, ChargentOrders__Transaction__c trx) {
        if (outstandingItem.AmountOutstanding <= 0 ||
            outstandingItem.Client != trx.Client__r.Account_Number__c) {
            return false;
        }
        if (customApplicationService.hasCustomApplication(trx.Id) && customApplicationService.getProjectMapping(trx.Id) != null) {
            return customApplicationService.getProjectMapping(trx.Id) == outstandingItem.Project;
        }
        return projectUniqueIdToEntityMap.get(outstandingItem.Project) == trx.ChargentOrders__Order__r.Entity__c;
    }

    private Boolean matchesClientEntityOrProject(ZuoraSubscriptionService.ClientProject clientProject, ChargentOrders__Transaction__c trx) {
        if (clientProject.clientName != trx.Client__r.Account_Number__c) {
            return false;
        }
        if (customApplicationService.hasCustomApplication(trx.Id) && customApplicationService.getProjectMapping(trx.Id) != null) {
            return customApplicationService.getProjectMapping(trx.Id) == clientProject.projectName;
        }
        return projectUniqueIdToEntityMap.get(clientProject.projectName) == trx.ChargentOrders__Order__r.Entity__c;
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
        paymentApplication.effectiveDate = DateUtil.convertGmtToDate(effectiveDate);
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

    // Queueable execution is another queueable chain that happens after getting outstanding items, to process
    // credit memos and transactions
    public void execute(QueueableContext context) {
        processOutstandingItems(outstandingItems, processingParameter);
    }

    // Used just to sort credit memos and payments. Transfer payments should get sorted before other credit memos
    // and payments, to avoid a historical import issue: for four customers, the transfer debit memo for an entity
    // is created after all payments for that entity were processed, so the debit memo was left outstanding and a
    // payment was left unapplied.
    public class Payable implements Comparable {
        @TestVisible
        private Datetime payableDate;
        @TestVisible
        private ZuoraAPI.CreditMemoWithItem creditMemo;
        @TestVisible
        private ChargentOrders__Transaction__c payment;

        public Payable(ZuoraAPI.CreditMemoWithItem creditMemo) {
            this.payableDate = creditMemo.CreditMemo.creditMemoDate;
            this.creditMemo = creditMemo;
        }

        public Payable(ChargentOrders__Transaction__c payment) {
            payment.ChargentOrders__Amount__c = payment.ChargentOrders__Amount__c.setScale(2, RoundingMode.HALF_UP);
            this.payableDate = payment.CreatedDate;
            this.payment = payment;
        }

        public Boolean sortFirst() {
            if (payment != null) {
                if (payment.ChargentOrders__Amount__c < 0 &&
                    (payment.ChargentOrders__Type__c == 'Transfer' ||
                        payment.ChargentOrders__Type__c == 'Refund' ||
                        payment.ChargentOrders__Response_Status__c == 'Returned')) {
                    return true;
                }
            }
            return false;
        }

        public Integer compareTo(Object compareTo) {
            Payable compareToItem = (Payable) compareTo;
            // If both items are transfers, or if none are transfers, just compare dates.
            if ((this.sortFirst() && compareToItem.sortFirst()) ||
                (!this.sortFirst() && !compareToItem.sortFirst())) {
                return simpleComparison(compareToItem);
            } else {
                return transferComparison(compareToItem);
            }
        }

        private Integer simpleComparison(Payable compareToItem) {
            Integer returnValue = 0;
            if (payableDate > compareToItem.payableDate) {
                returnValue = 1;
            } else if (payableDate < compareToItem.payableDate) {
                returnValue = -1;
            }
            return returnValue;
        }

        // This is used if one of the comparisons, but not both, is a transfer. The Transfer
        // always goes first (-1).
        private Integer transferComparison(Payable compareToItem) {
            if (this.sortFirst()) {
                return -1;
            } else {
                return 1;
            }
        }
    }
}