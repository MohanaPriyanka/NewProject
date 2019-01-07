public without sharing class CongaTemplateAssigner implements Database.Batchable<SObject>{
    public Map<String, List<CongaTemplateAssigner.TemplateKey>> congaTemplateMap;
    public List<APXTConga4__Conga_Template__c> congaTemplateList;

    public class TemplateKey {
        public Boolean isAutopay;
        public Boolean isAnchor;
        public Decimal uasbCount;
        public String clientBrandKey;
    }

    public CongaTemplateAssigner(Map<Id,APXT_BPM__Conductor__c> oldMap, List<APXT_BPM__Conductor__c> newList) {
        Boolean getTemplates = false;
        for (APXT_BPM__Conductor__c conductor : newList) {
            if (conductor.Assign_Templates__c && !oldMap.get(conductor.Id).Assign_Templates__c) {
                getTemplates = true;
            }
        }
        if (getTemplates){
            congaTemplateList = getTemplateList();
        }
    }

    public List<APXTConga4__Conga_Template__c> getTemplateList(){

        List<APXTConga4__Conga_Template__c> congaTemplates = [
            SELECT Id, Name, Autopay__c, Anchor__c, Brand_Key__c, Max_Number_of_UASBs__c
            FROM APXTConga4__Conga_Template__c
            WHERE Active__c = true
            ORDER BY Max_Number_of_UASBs__c DESC];

        return congaTemplates;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query =  'SELECT Id, Name, Bill_Template__c '+
                        'FROM Account_Bill__c '+
                        'WHERE Month__c = '+ System.Today().month() + ' ' +
                        'AND Year__c = \'' + String.valueOf(System.Today().year()) + '\' ' +
                        'AND Published__c = false';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Account_Bill__c> scope){
        Map<Id, TemplateKey> abToTemplateKeyMap = new Map<Id, TemplateKey>();
        TemplateKey templateKey = new TemplateKey();

        for (System_Bill__c systemBill : [ SELECT Id, Name, Opportunity__r.Customer_Group__c, UASB_Count__c,
                                            Account_Bill__r.Id, Account_Bill__r.Parent_Account__r.Recurring_Billing__c,
                                            Account_Bill__r.Parent_Account__r.Client_Brand_Key__c
                                            FROM System_Bill__c
                                            WHERE Account_Bill__c IN : scope]){
            abToTemplateKeyMap = generateTemplateKeyMap(systemBill, abToTemplateKeyMap);
        }

        Map<Id,Account_Bill__c> accountBillsToUpdate = new Map<Id,Account_Bill__c>();

        for (Account_Bill__c accountBill : scope){
            templateKey = abToTemplateKeyMap.get(accountBill.Id);

            for (APXTConga4__Conga_Template__c template : congaTemplateList){
                if (checkTemplateMatch(template, templateKey)){
                    accountBill.Bill_Template__c = template.Id;
                    accountBillsToUpdate.put(accountBill.Id, accountBill);
                }
            }

            if (accountBill.Bill_Template__c == null){
                Logger.logLater('CongaTemplateAssigner','Cannot find template','AB:' + String.valueOf(accountBill.Id)+ ' ' + String.valueOf(templateKey));
            }
        }
        update accountBillsToUpdate.values();
        Logger.flushLogs();
    }

    public Map<Id, TemplateKey> generateTemplateKeyMap(System_Bill__c systemBill, Map<Id, TemplateKey> abToTemplateKeyMap){
        TemplateKey templateKey = new TemplateKey();

        Id acctBillId = systemBill.Account_Bill__r.Id;
        Boolean anchorOpp = false;
        if (systemBill.Opportunity__r.Customer_Group__c == 'Anchor' ||
            systemBill.Opportunity__r.Customer_Group__c == 'Public Offtake'){
            // assuming that an account will not have a  mix of customer groups:
            anchorOpp = true;
        }
        if (abToTemplateKeyMap.containsKey(acctBillId)){
            templateKey = abToTemplateKeyMap.get(acctBillId);
            templateKey.uasbCount += systemBill.UASB_Count__c;
            abToTemplateKeyMap.put(acctBillId, templateKey);
        } else {
            templateKey.isAutopay = systemBill.Account_Bill__r.Parent_Account__r.Recurring_Billing__c;
            templateKey.isAnchor = anchorOpp;
            templateKey.uasbCount = systemBill.UASB_Count__c;
            templateKey.clientBrandKey = systemBill.Account_Bill__r.Parent_Account__r.Client_Brand_Key__c;

            abToTemplateKeyMap.put(acctBillId, templateKey);
        }
        return abToTemplateKeyMap;
    }

    public Boolean checkTemplateMatch(APXTConga4__Conga_Template__c congaTemplate, TemplateKey templateKey) {
        Boolean isMatch = false;
        if (congaTemplate.Autopay__c == templateKey.isAutopay
            && congaTemplate.Anchor__c == templateKey.isAnchor
            && congaTemplate.Brand_Key__c == templateKey.clientBrandKey
            && congaTemplate.Max_Number_of_UASBs__c >= templateKey.uasbCount){
                isMatch = true;
        }
        return isMatch;
    }

    public void finish(Database.BatchableContext bc){
    }
}