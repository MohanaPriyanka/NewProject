/*************************************************************************************
Created By Jordan Pentaleri 08/2019
Tested By: ZuoraGLServiceTest
*************************************************************************************/
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class ZuoraGLService implements Schedulable, ZuoraDataQueryService.Processor {
    public Integer daysToLookBack;
    public Map<String, String> depositAccountToClientMap;

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
        String Gateway;
        String Lockbox;
        String PaymentMethod;
        String ArchivedChargentData;
    }

    public void executePostQueryJob(ZuoraDataQueryService.ProcessingParameter method, String response) {
        switch on method.methodName {
            // GL Methods: Insert one object's journal entries, then queue next object:
            when 'GL_InvoiceItem' {
                generalGLRecordInsert(response, 'InvoiceItem');
                String queryString = ZuoraGLSelector.getCreditMemos(method.startDate, method.endDate);
                method.methodName = 'GL_CreditMemo';
                ZuoraDataQueryService.callFromApex(queryString, method);
            }
            when 'GL_CreditMemo' {
                generalGLRecordInsert(response, 'CreditMemo');
                String queryString = ZuoraGLSelector.getDebitMemos(method.startDate, method.endDate);
                method.methodName = 'GL_DebitMemo';
                ZuoraDataQueryService.callFromApex(queryString, method);
            }
            when 'GL_DebitMemo' {
                generalGLRecordInsert(response, 'DebitMemo');
                String queryString = ZuoraGLSelector.getPaymentPartsDM(method.startDate, method.endDate);
                method.methodName = 'GL_PaymentPartDM';
                ZuoraDataQueryService.callFromApex(queryString, method);
            }
            when 'GL_PaymentPartDM' {
                generalGLRecordInsert(response, 'PaymentPart');
                String queryString = ZuoraGLSelector.getPaymentPartsIV(method.startDate, method.endDate);
                method.methodName = 'GL_PaymentPartIV';
                ZuoraDataQueryService.callFromApex(queryString, method);
            }
            when 'GL_PaymentPartIV' {
                generalGLRecordInsert(response, 'PaymentPart');
            }
        }
    }

    public void generalGLRecordInsert(String response, String objectType){
        List<GeneralLedgerItem> ledgerItems = new List<GeneralLedgerItem>();
        List<Journal_Entry__c> journalEntriesList = new List<Journal_Entry__c>();

        ledgerItems = (List<GeneralLedgerItem>)JSON.deserialize(response, List<GeneralLedgerItem>.class);
        if (objectType == 'PaymentPart' || objectType == 'DebitMemo'){
            depositAccountToClientMap = getDepositAccountToClientMap();
        }

        for (GeneralLedgerItem ledger : ledgerItems){
            Journal_Entry__c entry = new Journal_Entry__c();
            entry.Object_Type__c = objectType;
            entry.Project__c = ledger.Project;
            entry.Client__c = ledger.Client;
            entry.Amount__c = ledger.Amount;
            entry.Reason_Code__c = ledger.reasonCode;
            entry.External_Id__c = ledger.ExternalId;
            entry.Customer_Account__c = ledger.CustomerAccount;

            // Use CRMId as a switch for historical data v. new data in Zuora
            if (objectType == 'PaymentPart' && ledger.CRMId == null) {
                // Going forward, we will report on payments when they are applied:
                entry.Date__c = Date.valueOf(ledger.GLDatetime);
                entry = setZuoraPaymentFields(ledger, entry);
            } else {
                // Historical Migration, we reported on transactions when they were made.
                entry.Date__c = ledger.GLDate;
            }

            if ((objectType == 'DebitMemo' && ledger.reasonCode == 'Returned Payment') || objectType == 'PaymentPart') {
                if (ledger.ArchivedChargentData == null){
                    entry = setZuoraPaymentFields(ledger, entry);
                } else {
                    entry = setArchivedPaymentFields(ledger, entry);
                }
            }
            journalEntriesList.add(entry);
        }
        if (journalEntriesList.size() > 10000){
            Database.executeBatch(new GenericBatchDMLOperation(journalEntriesList, 'Upsert'));
        } else {
            upsert journalEntriesList External_Id__c;
        }
        Logger.flushLogs();
    }

    public Map<String, String> getDepositAccountToClientMap(){
        Map<String, String> depositAccountToClientMap = new Map<String, String>();
        GatewaySelector gatewaySelector = new GatewaySelector();
        List<Zuora__PaymentGateway__c> zuoraGateways = gatewaySelector.getAllZuoraGateways();

        for (Zuora__PaymentGateway__c zuoraGateway : zuoraGateways){
            depositAccountToClientMap.put(
                zuoraGateway.Name,
                zuoraGateway.Client_Owner__r.Account_Number__c
            );
        }
        return depositAccountToClientMap;
    }

    public Journal_Entry__c setArchivedPaymentFields(GeneralLedgerItem ledger, Journal_Entry__c entry) {
        ZuoraAPI.ArchivedChargentData chargentData;
        chargentData = (ZuoraAPI.ArchivedChargentData)System.JSON.deserialize(ledger.ArchivedChargentData, ZuoraAPI.ArchivedChargentData.class);
        entry.Paid_To_Client__c = chargentData.ClientNumber;
        entry.Deposit_Account__c = chargentData.GatewayName;
        entry.Payment_Method__c = chargentData.PaymentMethod;
        return entry;
    }

    public Journal_Entry__c setZuoraPaymentFields(GeneralLedgerItem ledger, Journal_Entry__c entry){
        if (ledger.Gateway != null){
            entry.Deposit_Account__c = ledger.Gateway;
            if (depositAccountToClientMap.containsKey(ledger.Gateway)){
                entry.Paid_To_Client__c = depositAccountToClientMap.get(ledger.Gateway);
            } else {
                Logger.logLater('ZuoraGLService','Map Gateway to Client','Could not find client for gateway: ' + JSON.serialize(ledger));
            }
        } else if (ledger.Lockbox != null) {
            try {
                // Assumes Lockbox naming convention of (Lockbox Name)_(Client Number)
                entry.Deposit_Account__c = ledger.Lockbox.split('_')[0];
                entry.Paid_To_Client__c = ledger.Lockbox.split('_')[1];
            } catch (Exception excep){
                Logger.logLater('ZuoraGLService','Map Lockbox to Client','Could not find client for lockbox: ' + JSON.serialize(ledger));
            }
        }
        if (ledger.PaymentMethod != null){
            entry.Payment_Method__c = ledger.PaymentMethod;
        }
        return entry;
    }
}