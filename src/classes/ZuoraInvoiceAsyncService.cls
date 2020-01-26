/*************************************************************************************
 * Created By: peteryao on 2019-06-12  
 * Description: This class starts batches of chained queueables, since we need to
 *    download PDFs from Zuora staying under the callout and heap size limits.
 * Test: ZuoraInvoiceServiceTest
 *************************************************************************************/

public with sharing class ZuoraInvoiceAsyncService implements Queueable, Database.AllowsCallouts, Database.Batchable<Zuora__ZInvoice__c> {
    public enum OperationType {DOWNLOAD, MAIL}
    public OperationType mode;
    public List<Zuora__ZInvoice__c> allInvoicesToDownload;
    public List<Zuora__ZInvoice__c> allInvoicesToMail;
    public List<Zuora__ZInvoice__c> invoicesAlreadySent;
    @TestVisible
    private static ZuoraInvoiceSelector invoiceSelector = new ZuoraInvoiceSelector();
    @TestVisible
    private static AccountsSelector accountSelector = new AccountsSelector();
    @TestVisible
    private static ZuoraInvoiceService invoiceService = new ZuoraInvoiceService(null);

    public ZuoraInvoiceAsyncService(List<Zuora__ZInvoice__c> sfdcZInvoices) {
        mode = OperationType.DOWNLOAD;
        allInvoicesToDownload = sfdcZInvoices;
    }

    public ZuoraInvoiceAsyncService(OperationType mode) {
        this.mode = mode;
        this.allInvoicesToMail = new List<Zuora__ZInvoice__c>();
        this.invoicesAlreadySent = new List<Zuora__ZInvoice__c>();
    }

    public void initForDownload() {
        allInvoicesToDownload = ZuoraInvoiceSelector.getInvoicesToDownload();
    }

    public Iterable<Zuora__ZInvoice__c> start(Database.BatchableContext context) {
        if (mode == OperationType.DOWNLOAD) {
            return allInvoicesToDownload;
        } else {
            return allInvoicesToMail;
        }
    }

    public void execute(Database.BatchableContext context, List<Zuora__ZInvoice__c> scope) {
        try {
            ZuoraInvoiceService invoiceService = new ZuoraInvoiceService(scope);
            if (mode == OperationType.DOWNLOAD) {
                invoiceService.downloadPDFs();
            } else {
                invoiceService.queueInvoicesToMail(scope);
            }
        } catch (Exception e) {
            Logger.logNow(
                'ZuoraInvoiceAsyncService',
                'execute batch',
                e.getMessage() + '\n' + e.getStackTraceString() + '\n' + scope,
                Logger.ERROR);
        } finally {
            Logger.flushLogs();
        }
    }

    public void finish(Database.BatchableContext context) {
    }

    public void execute(QueueableContext context) {
        try {
            ZuoraInvoiceService invoiceService = new ZuoraInvoiceService(allInvoicesToDownload);
            invoiceService.downloadPDFs();
        } catch (Exception e) {
            Logger.logNow(
                'ZuoraInvoiceAsyncService',
                'execute queueable',
                e.getMessage() + '\n' + e.getStackTraceString() + '\n' + allInvoicesToDownload,
                Logger.ERROR);
        } finally {
            Logger.flushLogs();
        }
    }

    @Future
    public static void handleFirstInvoices(Set<Id> invoiceIds) {
        try {
            List<DecoratedInvoice> firstInvoices = getDecoratedFirstInvoices(invoiceIds);
            invoiceService.setFirstBillInsert(firstInvoices);
            invoiceService.setFirstBillDateOnAccount(firstInvoices);
        } catch (Exception e) {
            Logger.logLater(
                'ZuoraInvoiceAsyncService',
                'handleFirstInvoices',
                'Exception caught: ' + e.getMessage() + '\n' + e.getStackTraceString(),
                Logger.ERROR
            );
        } finally {
            Logger.flushLogs();
        }
    }

    @TestVisible
    private static List<DecoratedInvoice> getDecoratedFirstInvoices(Set<Id> invoiceIds) {
        List<DecoratedInvoice> firstBillInvoices = new List<DecoratedInvoice>();

        List<Zuora__ZInvoice__c> allInvoices = invoiceSelector.getAll(invoiceIds);
        Map<Id, Zuora__ZInvoice__c> accountIdToInvoice = new Map<Id, Zuora__ZInvoice__c>();
        for (Zuora__ZInvoice__c zInvoice : allInvoices) {
            if (zInvoice.Zuora__Account__c == null) {
                Logger.logLater('ZuoraInvoiceAsyncService', 'getDecoratedFirstInvoices', 'Found invoice with no Account: ' + zInvoice.Id, Logger.ERROR);
            } else {
                accountIdToInvoice.put(zInvoice.Zuora__Account__c, zInvoice);
            }
        }

        List<Account> propertyAccounts = accountSelector.selectAll(accountIdToInvoice.keySet());
        for (Account account : propertyAccounts) {
            if (account.Zuora__Invoices__r.size() == 1) {
                DecoratedInvoice decoratedInvoice = new DecoratedInvoice(account, accountIdToInvoice.get(account.Id));
                firstBillInvoices.add(decoratedInvoice);
            }
        }
        return firstBillInvoices;
    }

    public class DecoratedInvoice {
        public Zuora__ZInvoice__c invoice;
        public Id utilityId;
        public String program;
        public Boolean anchor;
        public String clientBrandKey;

        public DecoratedInvoice(Account propertyAccount, Zuora__ZInvoice__c invoice) {
            this.invoice = invoice;
            this.anchor = (propertyAccount.Count_of_Large_Offtake_Opps__c >= 1);
            this.clientBrandKey = propertyAccount.Client_Brand_Key__c;
            setUtilityAndProgram(propertyAccount);
        }

        private void setUtilityAndProgram(Account propertyAccount) {
            for (Opportunity opportunity : propertyAccount.Opportunities) {
                if (program == null) {
                    program = opportunity.Shared_Solar_System__r.Product__r.Program__c;
                } else if (program != opportunity.Shared_Solar_System__r.Product__r.Program__c) {
                    Logger.logLater(
                        'DecoratedInvoice',
                        'setUtilityAndProgram',
                        'Multiple programs found for account when setting welcome letter: ' + propertyAccount,
                        Logger.ERROR
                    );
                }
                if (utilityId == null) {
                    utilityId = opportunity.Shared_Solar_System__r.Utility__c;
                } else if (utilityId != opportunity.Shared_Solar_System__r.Utility__c) {
                    Logger.logLater(
                        'DecoratedInvoice',
                        'setUtilityAndProgram',
                        'Multiple utilities found for account when setting welcome letter: ' + propertyAccount,
                        Logger.ERROR
                    );
                }
            }
        }
    }
}