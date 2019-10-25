/**
 * Created by PeterYao on 10/14/2019.
 * Tested By: ZuoraHistoricalCustomApplicationTest
 */

public with sharing class ZuoraHistoricalCustomApplicationService {
    private Map<Id, CustomApplications> transactionIdsToPaymentApplications;
    @TestVisible
    private StaticResourceSelector staticResourceSelector = new StaticResourceSelector();

    public ZuoraHistoricalCustomApplicationService() {
    }

    public void init() {
        transactionIdsToPaymentApplications = new Map<Id, CustomApplications>();
        StaticResource sr = staticResourceSelector.getStaticResource('ZuoraCustomPaymentApplications');
        CSVReader csvReader = new CSVReader(sr.Body.toString());
        String[] line;
        csvReader.readLine(); // skip the header line
        while ((line = csvReader.readLine()) != null) {
            PaymentApplication pa = new PaymentApplication(line);
            if (transactionIdsToPaymentApplications.containsKey(pa.transactionId)) {
                transactionIdsToPaymentApplications.get(pa.transactionId).add(pa);
            } else {
                transactionIdsToPaymentApplications.put(pa.transactionId, new CustomApplications(pa));
            }
        }
    }

    public void log(Id trxId, String method, Object obj, String severity) {
        if (hasCustomApplication(trxId)) {
            Logger.logLater('ZuoraHistoricalCustomApplicationService', trxId + ': ' + method, JSON.serializePretty(obj), severity);
        }
    }

    public Boolean hasCustomApplication(Id transactionId) {
        return transactionIdsToPaymentApplications.containsKey(transactionId);
    }

    public String getProjectMapping(Id transactionId) {
        if (!hasCustomApplication(transactionId) || transactionIdsToPaymentApplications.get(transactionId).projectMapping == null) {
            return null;
        }

        return transactionIdsToPaymentApplications.get(transactionId).projectMapping.projectName;
    }

    public void customApplication(Id transactionId, List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems, List<ZuoraOutstandingItemsService.OutstandingItem> itemsToApply) {
        if (!hasCustomApplication(transactionId)) {
            return;
        }
        Logger.logLater('ZuoraHistoricalCustomApplicationService', transactionId + ': ' + 'applyPayment postapplication', JSON.serializePretty(outstandingItems), Logger.WARN);
        Logger.logLater('ZuoraHistoricalCustomApplicationService', transactionId + ': ' + 'itemsToApply', JSON.serializePretty(itemsToApply), Logger.WARN);

        List<PaymentApplication> outstandingItemApplications =
            transactionIdsToPaymentApplications.get(transactionId).outstandingItemApplications;
        List<PaymentApplication> itemApplications =
            transactionIdsToPaymentApplications.get(transactionId).itemApplications;

        for (ZuoraOutstandingItemsService.OutstandingItem oi : outstandingItems) {
            checkAndSetOutstandingItem(oi, outstandingItemApplications, itemsToApply);
        }
        for (ZuoraOutstandingItemsService.OutstandingItem applyItem : itemsToApply) {
            checkAndSetApplyItem(applyItem, itemApplications);
        }
    }

    @TestVisible
    private void checkAndSetOutstandingItem(ZuoraOutstandingItemsService.OutstandingItem outstandingItem,
        List<PaymentApplication> paymentApplications, List<ZuoraOutstandingItemsService.OutstandingItem> itemsToApply) {
        for (PaymentApplication pa : paymentApplications) {
            if (pa.isRelevant(outstandingItem)) {
                pa.handleOutstandingItem(outstandingItem, itemsToApply);
            }
        }
    }

    @TestVisible
    private void checkAndSetApplyItem(ZuoraOutstandingItemsService.OutstandingItem applyItem,
        List<PaymentApplication> itemApplications) {
        for (PaymentApplication pa : itemApplications) {
            if (pa.isRelevant(applyItem)) {
                pa.handleItemApplication(applyItem);
            }
        }
    }

    public class CustomApplications {
        List<PaymentApplication> outstandingItemApplications;
        List<PaymentApplication> itemApplications;
        // Used to force a returned payment to go to a project
        PaymentApplication projectMapping;

        public CustomApplications(PaymentApplication pa) {
            outstandingItemApplications = new List<PaymentApplication>();
            itemApplications = new List<PaymentApplication>();
            add(pa);
        }

        public void add(PaymentApplication pa) {
            if (pa.type == 'OutstandingItem') {
                outstandingItemApplications.add(pa);
            } else if (pa.type == 'ApplyItem') {
                itemApplications.add(pa);
            } else if (pa.type == 'ProjectMapping') {
                projectMapping = pa;
            } else {
                throw new Util.BWException('Unknown custom payment application type found in csv: ' + pa);
            }
        }
    }

    public class PaymentApplication {
        public String customer;
        public String transactionId;
        public String type;
        public Date effectiveDate;
        public String projectName;
        public String clientName;
        public Decimal startingAmount;
        public Decimal applicationAmount;
        public Decimal expectedAmount;
        public Boolean isInvoice;
        public Boolean createApplication;

        public PaymentApplication() {
        }

        public PaymentApplication(String[] csvLine) {
            this.customer = csvLine[0];
            this.transactionId = csvLine[1];
            this.type = csvLine[2];
            this.effectiveDate = Date.parse(csvLine[3]);
            this.projectName = csvLine[4];
            this.clientName = csvLine[5];
            this.startingAmount = Decimal.valueOf(Util.nullToZero(csvLine[6]));
            this.applicationAmount = Decimal.valueOf(Util.nullToZero(csvLine[7]));
            this.expectedAmount = Decimal.valueOf(Util.nullToZero(csvLine[8]));
            this.isInvoice = Boolean.valueOf(csvLine[9]);
            this.createApplication = Boolean.valueOf(csvLine[10]);
        }

        public Boolean isRelevant(ZuoraOutstandingItemsService.OutstandingItem oi) {
            return (oi.EffectiveDate == this.effectiveDate &&
                oi.Project == this.projectName &&
                oi.Client == this.clientName &&
                oi.IsInvoiceItem == this.isInvoice);
        }

        public void handleOutstandingItem(ZuoraOutstandingItemsService.OutstandingItem outstandingItem,
            List<ZuoraOutstandingItemsService.OutstandingItem> itemsToApply) {
            if (outstandingItem.AmountOutstanding == expectedAmount) {
                outstandingItem.AmountOutstanding = startingAmount - applicationAmount;
                if (createApplication) {
                    ZuoraOutstandingItemsService.OutstandingItem newApplyItem = outstandingItem.clone();
                    newApplyItem.AmountToApply = applicationAmount;
                    itemsToApply.add(newApplyItem);
                }
            } else {
                Logger.logLater(
                    'ZuoraHistoricalApplicationService',
                    'custom applyPayment',
                    'Expected ' + projectName + ' to have '+ expectedAmount +' outstanding' + '\n' + JSON.serialize(outstandingItem),
                    Logger.WARN
                );
            }
        }

        public void handleItemApplication(ZuoraOutstandingItemsService.OutstandingItem applyItem) {
            if (applyItem.AmountToApply == expectedAmount) {
                // There might be two debit memos for same project, client, and amount to apply (0), e.g. a client credit
                // and late fee, both not being applied by this transaction. We need to update the right one.
                if (applyItem.AmountOutstanding >= applicationAmount) {
                    applyItem.AmountToApply = applicationAmount;
                }
            } else {
                Logger.logLater(
                    'ZuoraHistoricalApplicationService',
                    'custom applyPayment',
                    'Expected ' + projectName + ' to have ' + expectedAmount + ' applied' + '\n' + JSON.serialize(applyItem),
                    Logger.WARN);
            }
        }
    }
}