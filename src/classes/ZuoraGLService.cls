/*************************************************************************************
Created By Jordan Pentaleri 08/2019
Tested By: ZuoraGLServiceTest
*************************************************************************************/
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class ZuoraGLService implements Schedulable {
    public Integer daysToLookBack;

    public void execute(SchedulableContext ctx){
        Date today = System.today();
        if (daysToLookBack == null){
            daysToLookBack = 30;
        }
        getAllDataFromZuora(today.addDays(daysToLookBack), today);
    }

    public static void getAllDataFromZuora(Date startDate, Date endDate){
        /* Starts with Invoice Items, then starts chain of Credit Memos, Debit Memos and Payment Parts:
            Zuora does not perform well when multiple queries are running at the same time.
        */
        String queryString = ZuoraGLSelector.getInvoiceItems(startDate, endDate);
        ZuoraDataQueryService.ProcessingParameter methodToRunAfter = new ZuoraDataQueryService.ProcessingParameter();
        methodToRunAfter.className = 'ZuoraGLService';
        methodToRunAfter.methodName = 'GL_InvoiceItem';
        methodToRunAfter.startDate = startDate;
        methodToRunAfter.endDate = endDate;
        ZuoraDataQueryService.callFromApex(queryString,methodToRunAfter);
    }

    public class GeneralLedgerItem {
        String Project;
        String Client;
        String CustomerAccount;
        String CRMId;
        Date GLDate;
        Datetime GLDatetime;
        Decimal Amount;
        String ReasonCode;
        String ExternalId;
    }

    public static void executePostQueryJob(ZuoraDataQueryService.ProcessingParameter method, String response) {
        switch on method.methodName {
            // GL Methods: Insert one object's journal entries, then queue next object:
            when 'GL_InvoiceItem' {
                ZuoraGLService.generalGLRecordInsert(response, 'InvoiceItem');
                String queryString = ZuoraGLSelector.getCreditMemos(method.startDate, method.endDate);
                method.methodName = 'GL_CreditMemo';
                ZuoraDataQueryService.callFromApex(queryString, method);
            }
            when 'GL_CreditMemo' {
                ZuoraGLService.generalGLRecordInsert(response, 'CreditMemo');
                String queryString = ZuoraGLSelector.getDebitMemos(method.startDate, method.endDate);
                method.methodName = 'GL_DebitMemo';
                ZuoraDataQueryService.callFromApex(queryString, method);
            }
            when 'GL_DebitMemo' {
                ZuoraGLService.generalGLRecordInsert(response, 'DebitMemo');
                String queryString = ZuoraGLSelector.getPaymentPartsDM(method.startDate, method.endDate);
                method.methodName = 'GL_PaymentPartDM';
                ZuoraDataQueryService.callFromApex(queryString, method);
            }
            when 'GL_PaymentPartDM' {
                ZuoraGLService.generalGLRecordInsert(response, 'PaymentPart');
                String queryString = ZuoraGLSelector.getPaymentPartsIV(method.startDate, method.endDate);
                method.methodName = 'GL_PaymentPartIV';
                ZuoraDataQueryService.callFromApex(queryString, method);
            }
            when 'GL_PaymentPartIV' {
                ZuoraGLService.generalGLRecordInsert(response, 'PaymentPart');
            }
        }
    }

    public static void generalGLRecordInsert(String response, String objectType){
        List<GeneralLedgerItem> ledgerItems = new List<GeneralLedgerItem>();
        List<Journal_Entry__c> journalEntriesList = new List<Journal_Entry__c>();

        ledgerItems = (List<GeneralLedgerItem>)JSON.deserialize(response, List<GeneralLedgerItem>.class);

        for (GeneralLedgerItem ledger : ledgerItems){
            Journal_Entry__c entry = new Journal_Entry__c();
            entry.Object_Type__c = objectType;
            entry.Project__c = ledger.Project;
            entry.Client__c = ledger.Client;
            entry.Customer_Account__c = ledger.CustomerAccount;
            if (objectType == 'PaymentPart' && ledger.CRMId == null){
                // Use CRMId as a switch for historical data v. new data in Zuora.
                // Going forward, we will report on payments when they are applied:
                entry.Date__c = Date.valueOf(ledger.GLDatetime);
            } else {
                // Historical Migration, we reported on transactions when they were made.
                entry.Date__c = ledger.GLDate;
            }
            entry.Amount__c = ledger.Amount;
            entry.Reason_Code__c = ledger.reasonCode;
            entry.External_Id__c = ledger.ExternalId;
            journalEntriesList.add(entry);
        }
        if (journalEntriesList.size() > 10000){
            Database.executeBatch(new GenericBatchDMLOperation(journalEntriesList, 'Upsert'));
        } else {
            upsert journalEntriesList External_Id__c;
        }
    }
}