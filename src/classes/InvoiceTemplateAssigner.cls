public without sharing class InvoiceTemplateAssigner implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts{
    public List<Invoice_Template__c> invoiceTemplateList;
    public CS_Bill_Setting__c csBillSetting;

    public class ZuoraInvoiceTemplate {
        public String name;
        public String id;
    }

    public class TemplateKey {
        public Boolean isAutopay;
        public Boolean isAnchor;
        public String clientBrandKey;
        public String id;
    }

    public InvoiceTemplateAssigner() {
        invoiceTemplateList = getTemplateList();
        csBillSetting = CSBillSettingSelector.getBillSetting();
    }

    public void executeBatch() {
        if (invoiceTemplateList != null){
            Database.executeBatch(this, 20);
        }
    }

    public List<Invoice_Template__c> getTemplateList(){
        List<Invoice_Template__c> invoiceTemplates = [
            SELECT Id, Name, Brand_Key__c,
                Autopay__c, Anchor__c,
                External_Id__c
            FROM Invoice_Template__c
            WHERE Active__c = true];
        return invoiceTemplates;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query =  'SELECT Id, Name, Zuora_Id__c, ' +
                        'Parent_Account__r.Client_Brand_Key__c, ' +
                        'Recurring_Billing__c, Count_of_Large_Offtake_Opps__c '+
                        'FROM Account '+
                        'WHERE Zuora_Id__c != null';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope){
        List<ZuoraAPI.ZuoraAccount> zuoraAccounts = assignTemplates(scope,invoiceTemplateList);
        updateAccountsInZuora(zuoraAccounts);
        Logger.flushLogs();
    }

    public List<ZuoraAPI.ZuoraAccount> assignTemplates(List<Account> accountsToAssign, List<Invoice_Template__c> invoiceTemplates){
        TemplateKey templateKey = new TemplateKey();

        Map<String,ZuoraAPI.ZuoraAccount> accountsToUpdate = new Map<String,ZuoraAPI.ZuoraAccount>();

        for (Account account : accountsToAssign){
            ZuoraAPI.ZuoraAccount zAccount = new ZuoraAPI.ZuoraAccount();
            zAccount.Id = account.Zuora_Id__c;
            templateKey.isAutopay = account.Recurring_Billing__c;
            templateKey.clientBrandKey = account.Parent_Account__r.Client_Brand_Key__c;

            if (account.Count_of_Large_Offtake_Opps__c > 0){
                templateKey.isAnchor = true;
                zAccount.Notes = csBillSetting.Default_Bill_Message_for_Autopay__c;
            } else {
                templateKey.isAnchor = false;
                zAccount.Notes = csBillSetting.Default_Bill_Message_for_Non_Autopay__c;
            }
            for (Invoice_Template__c template : invoiceTemplates){
                if (checkTemplateMatch(template, templateKey)){
                    zAccount.InvoiceTemplateId = template.External_Id__c;
                }
                accountsToUpdate.put(account.Zuora_Id__c, zAccount);
            }
            if (zAccount.InvoiceTemplateId == null){
                Logger.logLater('InvoiceTemplateAssigner','Cannot find template','Account:' + String.valueOf(account.Id)+ ' ' + String.valueOf(templateKey), Logger.ERROR);
            }
        }
        return accountsToUpdate.values();
    }

    public Boolean checkTemplateMatch(Invoice_Template__c invoiceTemplate, TemplateKey templateKey) {
        Boolean isMatch = false;
        if (invoiceTemplate.Autopay__c == templateKey.isAutopay
            && invoiceTemplate.Anchor__c == templateKey.isAnchor
            && invoiceTemplate.Brand_Key__c == templateKey.clientBrandKey){
                isMatch = true;
        }
        return isMatch;
    }

    public void updateAccountsInZuora(List<ZuoraAPI.ZuoraAccount> zuoraAccounts) {
        ZuoraAPI.ActionItems item = new ZuoraAPI.ActionItems();
        item.type = 'Account';
        item.objects = zuoraAccounts;

        try {
            HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/action/update', item, true);
            List<ZuoraAPI.SaveResult> result = (List<ZuoraAPI.SaveResult>) System.JSON.deserialize(response.getBody(), List<ZuoraAPI.SaveResult>.class);
            if (!result[0].Success) {
                String customErrorMessage =
                    'Object: ' + String.valueOf(item) +
                        ' Zuora Error Message: ' + String.valueOf(result[0].Errors);
                Logger.logLater('InvoiceTemplateAssigner', 'updateAccountsInZuora', customErrorMessage, 'ERROR');
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

    /* public List<TemplateKey> getZuoraTemplates(){
         HttpResponse response = ZuoraAPIHelper.callJSONEndpointWithOAuth('GET','/settings/invoice-templates?returnIds=true',null,true);
         List<ZuoraInvoiceTemplate> templates = (List<ZuoraInvoiceTemplate>) System.JSON.deserialize(response.getBody(), List<ZuoraInvoiceTemplate>.class);
         List<TemplateKey> InvoiceTemplates = new List<TemplateKey>();

         for (ZuoraInvoiceTemplate template : templates){
             //Template Naming Convention: Autopay_TRUE_Anchor_TRUE_Key_BlueWaveLogo v. Autopay_FALSE_Anchor_FALSE_Key_AmpRed
             String templateNameFromZuora = template.name;
             TemplateKey key = new TemplateKey();
             key.id = template.id;
             key.isAnchor = false;
             key.isAutopay = false;
             if (templateNameFromZuora.contains('Autopay_TRUE')){
                 key.isAutopay = true;
             }
             if (templateNameFromZuora.contains('Anchor_TRUE')){
                 key.isAutopay = true;
             }
             Integer startLocation = templateNameFromZuora.indexOf('Key_');
             key.clientBrandKey = templateNameFromZuora.substring(startLocation,templateNameFromZuora.length());
             InvoiceTemplates.add(TemplateKey);
         }
         return InvoiceTemplates;
     } */

    public void finish(Database.BatchableContext bc){
        // Need to have finish method in batch job
    }
}