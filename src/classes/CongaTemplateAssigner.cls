public without sharing class CongaTemplateAssigner implements Database.Batchable<SObject>{
    public Map<String, List<CongaTemplateAssigner.templateSelectionOption>> congaTemplateMap;
    public List<APXTConga4__Conga_Template__c> congaTemplateList;

    public class templateSelectionOption {
        public Boolean isAutopay;
        public Boolean isAnchor;
        public Decimal uasbCount;
        public String clientBrandKey;
    }

    public CongaTemplateAssigner(Map<Id,APXT_BPM__Conductor__c> oldMap, List<APXT_BPM__Conductor__c> newList) {
        system.debug('ENTERED');
        for (APXT_BPM__Conductor__c conductor : newList) {
            if (conductor.Assign_Templates__c && !oldMap.get(conductor.Id).Assign_Templates__c) {
                congaTemplateList = getTemplateList();
                system.debug('templtes' + congaTemplateList);
                Database.executeBatch(this, 10);
            }
        }
    }

    public List<APXTConga4__Conga_Template__c> getTemplateList(){

        List<APXTConga4__Conga_Template__c> congaTemplates = [
            SELECT Id, Name, Autopay__c, Anchor__c, Brand_Key__c, Max_Number_of_UASBs__c
            FROM APXTConga4__Conga_Template__c
            // WHERE Active__c = true
            ORDER BY CreatedDate DESC];

        return congaTemplates;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query =  'SELECT Id, Name '+
                        'FROM Account_Bill__c '+
                        'WHERE Month__c = '+ System.Today().month() + ' ' +
                        'AND Year__c = \'' + String.valueOf(System.Today().year()) + '\' ' +
                        'AND Published__c = false';

        system.debug('queryString' + query);
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Account_Bill__c> scope){
        system.debug('template list' + congaTemplateList);
        Map<Id, templateSelectionOption> abToTemplateKeyMap = new Map<Id, templateSelectionOption>();

        for (System_Bill__c systemBill : [ SELECT Id, Name, Opportunity__r.Customer_Group__c, UASB_Count__c,
                                            Account_Bill__r.Id, Account_Bill__r.Parent_Account__r.Recurring_Billing__c,
                                            Account_Bill__r.Parent_Account__r.Client_Brand_Key__c
                                            FROM System_Bill__c
                                            WHERE Account_Bill__c IN : scope]){
            Id acctBillId = systemBill.Account_Bill__r.Id;
            Boolean anchorOpp = false;
            if (systemBill.Opportunity__r.Customer_Group__c == 'Anchor' ||
                systemBill.Opportunity__r.Customer_Group__c == 'Public Offtake'){
                // assuming that an account will not have a  mix of customer groups:
                anchorOpp = true;
            }
            if (abToTemplateKeyMap.containsKey(acctBillId)){
                templateSelectionOption abQualities = abToTemplateKeyMap.get(acctBillId);
                abQualities.uasbCount += systemBill.UASB_Count__c;
                abToTemplateKeyMap.put(acctBillId, abQualities);
            } else {
                templateSelectionOption billKey = new templateSelectionOption();
                billKey.isAutopay = systemBill.Account_Bill__r.Parent_Account__r.Recurring_Billing__c;
                billKey.isAnchor = anchorOpp;
                billKey.uasbCount = systemBill.UASB_Count__c;
                billKey.clientBrandKey = systemBill.Account_Bill__r.Parent_Account__r.Client_Brand_Key__c;

                abToTemplateKeyMap.put(acctBillId, billKey);
            }
        }

        List<Account_Bill__c> accountBillsToUpdate = new List<Account_Bill__c>();

        for (Account_Bill__c accountBill : scope){
            templateSelectionOption abCriteria = abToTemplateKeyMap.get(accountBill.Id);

            for (APXTConga4__Conga_Template__c template : congaTemplateList){
                if (template.Autopay__c == abCriteria.isAutopay
                    && template.Anchor__c == abCriteria.isAnchor
                    && template.Brand_Key__c == abCriteria.clientBrandKey
                    && template.Max_Number_of_UASBs__c >= abCriteria.uasbCount){
                    accountBill.Conga_Template__c = template.Id;
                    accountBillsToUpdate.add(accountBill);
                } else {
                    Logger.logLater('CongaTemplateAssigner','execute','Cannot find template: '+ String.valueOf(abCriteria));
                }
            }
        }
        update accountBillsToUpdate;
    }

    public void finish(Database.BatchableContext bc){
        Logger.flushLogs();
    }
}