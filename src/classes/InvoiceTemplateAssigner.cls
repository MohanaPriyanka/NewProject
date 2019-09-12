// Methods in batch class must be global or public, so suppress warnings:
@SuppressWarnings('PMD.ExcessiveParameterList')
public without sharing class InvoiceTemplateAssigner implements Schedulable, Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts{
    public List<zqu__InvoiceTemplate__c> invoiceTemplateList;
    public List<Account> accountsToUpdate;
    private CS_Bill_Setting__c csBillSetting;

    public class ZuoraInvoiceTemplate {
        public String name;
        public String id;
    }

    private class TemplateKey {
        public Boolean isAutopay;
        public Boolean isAnchor;
        public String clientBrandKey;
        public String id;

        public TemplateKey(Account account){
            this.isAutopay = account.Recurring_Billing__c;
            this.clientBrandKey = account.Parent_Account__r.Client_Brand_Key__c;
            if (account.Count_of_Large_Offtake_Opps__c > 0){
                this.isAnchor = true;
            } else {
                this.isAnchor = false;
            }
        }

        public Boolean matches(zqu__InvoiceTemplate__c invoiceTemplate){
            Boolean isMatch = false;
            if (invoiceTemplate.Autopay__c == this.isAutopay
                && invoiceTemplate.Anchor__c == this.isAnchor
                && invoiceTemplate.Brand_Key__c == this.clientBrandKey){
                isMatch = true;
            }
            return isMatch;
        }
    }

    public InvoiceTemplateAssigner() {
        invoiceTemplateList = getTemplateList();
        csBillSetting = CSBillSettingSelector.getBillSetting();
        if (accountsToUpdate == null){
            accountsToUpdate = getAccounts();
        }
    }

    public void executeBatch() {
        if (invoiceTemplateList != null){
            Database.executeBatch(this, 45);
        }
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    // We want users who don't have access to Zuora templates to be
    // able to get all zuora accounts and apply a template
    public List<zqu__InvoiceTemplate__c> getTemplateList(){
        List<zqu__InvoiceTemplate__c> invoiceTemplates = [
            SELECT Id, Name, Brand_Key__c,
                Autopay__c, Anchor__c,
                zqu__ZuoraId__c
            FROM zqu__InvoiceTemplate__c
            WHERE Active__c = true];
        return invoiceTemplates;
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    // We want users who don't have access to Zuora templates to be
    // able to get all zuora accounts and apply a template
    public List<Account> getAccounts(){
        List<Account> accounts = [
            SELECT Id, Name, Zuora_Id__c,
            Parent_Account__r.Client_Brand_Key__c,
            Recurring_Billing__c, Count_of_Large_Offtake_Opps__c,
            Zuora_Invoice_Message_1_of_2__c,
            Zuora_Invoice_Message_2_of_2__c
            FROM Account
            WHERE Zuora_Id__c != null];
        return accounts;
    }

    public List<Account> start(Database.BatchableContext bc) {
        return accountsToUpdate;
    }

    public void execute(Database.BatchableContext bc, List<Account> scope){
        List<ZuoraAPI.ZuoraAccount> zuoraAccounts = assignTemplates(scope,invoiceTemplateList);
        updateAccountsInZuora(zuoraAccounts);
        Logger.flushLogs();
    }

    private ZuoraAPI.ZuoraAccount setBillMessage(Account sfAccount, ZuoraAPI.ZuoraAccount zAccount){
        if (sfAccount.Zuora_Invoice_Message_1_of_2__c != null){
            zAccount.Notes = sfAccount.Zuora_Invoice_Message_1_of_2__c;
        } else if (sfAccount.Recurring_Billing__c){
            zAccount.Notes = csBillSetting.Default_Bill_Message_for_Autopay__c;
        } else {
            zAccount.Notes = csBillSetting.Default_Bill_Message_for_Non_Autopay__c;
        }
        if (sfAccount.Zuora_Invoice_Message_2_of_2__c != null){
            zAccount.BillMessage_Zcustom = sfAccount.Zuora_Invoice_Message_2_of_2__c;
        } else {
            zAccount.BillMessage_Zcustom = null;
        }
        return zAccount;
    }

    public List<ZuoraAPI.ZuoraAccount> assignTemplates(List<Account> accountsToAssign, List<zqu__InvoiceTemplate__c> invoiceTemplates){
        TemplateKey templateKey;

        Map<String,ZuoraAPI.ZuoraAccount> accountsToUpdate = new Map<String,ZuoraAPI.ZuoraAccount>();

        for (Account account : accountsToAssign){
            ZuoraAPI.ZuoraAccount zAccount = new ZuoraAPI.ZuoraAccount();
            zAccount.Id = account.Zuora_Id__c;
            zAccount = setBillMessage(account, zAccount);
            templateKey = new TemplateKey(account);
            for (zqu__InvoiceTemplate__c template : invoiceTemplates){
                if (templateKey.matches(template)){
                    zAccount.InvoiceTemplateId = template.zqu__ZuoraId__c;
                    accountsToUpdate.put(account.Zuora_Id__c, zAccount);
                    break;
                }
            }
            if (zAccount.InvoiceTemplateId == null){
                Logger.logLater('InvoiceTemplateAssigner','Cannot find template','Account:' + String.valueOf(account.Id)+ ' ' + String.valueOf(templateKey), Logger.ERROR);
            }
        }
        return accountsToUpdate.values();
    }

    private void updateAccountsInZuora(List<ZuoraAPI.ZuoraAccount> zuoraAccounts) {
        ZuoraAPI.ActionItems item = new ZuoraAPI.ActionItems();
        item.type = 'Account';
        item.objects = zuoraAccounts;

        try {
            HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/action/update', item, true);
            List<ZuoraAPI.SaveResult> resultList = (List<ZuoraAPI.SaveResult>) System.JSON.deserialize(response.getBody(), List<ZuoraAPI.SaveResult>.class);
            for (ZuoraAPI.SaveResult result : resultList){
                if (!result.Success) {
                    String customErrorMessage =
                        'Object: ' + String.valueOf(item) +
                            ' Zuora Error Message: ' + String.valueOf(result.Errors);
                    Logger.logLater('InvoiceTemplateAssigner', 'updateAccountsInZuora', customErrorMessage, 'ERROR');
                }
            }
        } catch (Exception unhandledException) {
            Logger.logLater(
                'InvoiceTemplateAssigner',
                'updateAccountsInZuora',
                unhandledException.getMessage() + unhandledException.getStackTraceString(),
                'ERROR'
            );
        }
    }

    public void finish(Database.BatchableContext bc){
        try {
            InvoiceTemplateAssigner clearAccountFieldsJob = new InvoiceTemplateAssigner();
            Datetime dt = Datetime.now();
            dt = dt.addDays(10);
            String cronExpress = '0 ' + dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ?';
            System.schedule('Clear Account Message Fields',cronExpress,clearAccountFieldsJob);
        } catch (Exception excep) {
            Logger.logNow('InvoiceTemplateAssigner','scheduleAccountClear','Account Clear could not be scheduled' + excep.getMessage(),'WARN');
        }
    }

    public void execute(SchedulableContext SC){
        clearAccountFields();
    }

    public void clearAccountFields(){
        try {
            List<Account> accountsWithMessages = AccountsSelector.selectAccountsWithBillMessages();
            for (Account acct : accountsWithMessages){
                acct.Zuora_Invoice_Message_1_of_2__c = null;
                acct.Zuora_Invoice_Message_2_of_2__c = null;
            }
            if (accountsWithMessages.size() > 150) {
                Database.executeBatch(new GenericBatchDMLOperation(accountsWithMessages, 'Update'));
            } else {
                update accountsWithMessages;
            }
        } catch (Exception excep) {
            Logger.logNow('InvoiceTemplateAssigner','clearAccountFields','Account Clear could not be executed' + excep.getMessage(),'WARN');
        }
    }
}