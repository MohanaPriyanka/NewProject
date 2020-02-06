public without sharing class CongaTemplateAssigner implements Database.Batchable<SObject>{
    public List<APXTConga4__Conga_Template__c> congaTemplateList;
    public CS_Bill_Setting__c csBillSetting;

    public class TemplateKey {
        public Boolean isAutopay;
        public Boolean isAnchor;
        public Boolean isPaymentPlan;
        public Decimal billNumber;
        public Decimal uasbCount;
        public String clientBrandKey;
    }

    public CongaTemplateAssigner() {
        congaTemplateList = getTemplateList();
        csBillSetting = CSBillSettingSelector.getBillSetting();
    }

    public void executeBatch() {
        if (congaTemplateList != null){
            Database.executeBatch(this, 20);
        }
    }

    public List<APXTConga4__Conga_Template__c> getTemplateList(){

        List<APXTConga4__Conga_Template__c> congaTemplates = [
            SELECT Id, Name, Autopay__c, Anchor__c, Brand_Key__c, Max_Number_of_UASBs__c,
                Payment_Plan__c, Welcome_Insert__c, APXTConga4__Name__c
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
                        'AND Bill_Template__c = null ' +
                        'AND Published__c = false';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Account_Bill__c> scope){
        assignTemplates(scope,congaTemplateList);
    }

    public void assignTemplates(List<Account_Bill__c> absToAssign, List<APXTConga4__Conga_Template__c> congaTemplates){
        Map<Id, TemplateKey> abToTemplateKeyMap = new Map<Id, TemplateKey>();
        TemplateKey templateKey = new TemplateKey();

        for (System_Bill__c systemBill : [ SELECT Id, Name, Opportunity__r.Customer_Group__c, UASB_Count__c,
                                            Account_Bill__r.Id, Account_Bill__r.Parent_Account__r.Recurring_Billing__c,
                                            Account_Bill__r.Parent_Account__r.Client_Brand_Key__c,
                                            Account_Bill__r.Bill_Number__c, Account_Bill__r.Payment_Plan_Balance__c
                                            FROM System_Bill__c
                                            WHERE Account_Bill__c IN : absToAssign]){
            abToTemplateKeyMap = generateTemplateKeyMap(systemBill, abToTemplateKeyMap);
        }

        Map<Id,Account_Bill__c> accountBillsToUpdate = new Map<Id,Account_Bill__c>();

        for (Account_Bill__c accountBill : absToAssign){
            templateKey = abToTemplateKeyMap.get(accountBill.Id);
            if (templateKey.isAutopay) {
                accountBill.Bill_Message__c = csBillSetting.Default_Bill_Message_for_Autopay__c;
            } else {
                accountBill.Bill_Message__c = csBillSetting.Default_Bill_Message_for_Non_Autopay__c;
            }
            for (APXTConga4__Conga_Template__c template : congaTemplates){
                if (checkTemplateMatch(template, templateKey)){
                    accountBill.Bill_Template__c = template.Id;
                }
                if (checkInsertMatch(template, templateKey) ){
                    accountBill.Additional_Bill_Insert__c = template.Id;
                }
                accountBillsToUpdate.put(accountBill.Id, accountBill);
            }

            if (accountBill.Bill_Template__c == null){
                Logger.logLater('CongaTemplateAssigner','Cannot find template','AB:' + String.valueOf(accountBill.Id)+ ' ' + String.valueOf(templateKey), Logger.ERROR);
            }
        }
        update accountBillsToUpdate.values();
        Logger.flushLogs();
    }

    public Map<Id, TemplateKey> generateTemplateKeyMap(System_Bill__c systemBill, Map<Id, TemplateKey> abToTemplateKeyMap){
        TemplateKey templateKey = new TemplateKey();

        Id acctBillId = systemBill.Account_Bill__r.Id;
        Boolean anchorOpp = false;
        Boolean paymentPlan = false;

        if (systemBill.Opportunity__r.Customer_Group__c == 'Anchor' ||
            systemBill.Opportunity__r.Customer_Group__c == 'Public Offtake'){
            // assuming that an account will not have a  mix of customer groups:
            anchorOpp = true;
        }
        if (systemBill.Account_Bill__r.Payment_Plan_Balance__c > 0){
            paymentPlan = true;
        }
        if (abToTemplateKeyMap.containsKey(acctBillId)){
            templateKey = abToTemplateKeyMap.get(acctBillId);
            templateKey.uasbCount += systemBill.UASB_Count__c;
        } else {
            templateKey.isAutopay = systemBill.Account_Bill__r.Parent_Account__r.Recurring_Billing__c;
            templateKey.isAnchor = anchorOpp;
            templateKey.isPaymentPlan = paymentPlan;
            templateKey.uasbCount = systemBill.UASB_Count__c;
            templateKey.clientBrandKey = systemBill.Account_Bill__r.Parent_Account__r.Client_Brand_Key__c;
            templateKey.billNumber = systemBill.Account_Bill__r.Bill_Number__c;
            abToTemplateKeyMap.put(acctBillId, templateKey);
        }
        return abToTemplateKeyMap;
    }

    public Boolean checkTemplateMatch(APXTConga4__Conga_Template__c congaTemplate, TemplateKey templateKey) {
        Boolean isMatch = false;
        if (congaTemplate.Autopay__c == templateKey.isAutopay
            && congaTemplate.Anchor__c == templateKey.isAnchor
            && congaTemplate.Payment_Plan__c == templateKey.isPaymentPlan
            && congaTemplate.Brand_Key__c == templateKey.clientBrandKey
            && congaTemplate.Max_Number_of_UASBs__c >= templateKey.uasbCount
            && congaTemplate.Welcome_Insert__c == false){
                isMatch = true;
        }
        return isMatch;
    }

    public Boolean checkInsertMatch(APXTConga4__Conga_Template__c congaTemplate, TemplateKey templateKey) {
        // Assumes there is only 1 Welcome Insert per brand key

        Boolean isMatch = false;
        if (congaTemplate.Brand_Key__c == templateKey.clientBrandKey
            && templateKey.billNumber == 1
            && congaTemplate.Welcome_Insert__c == true){
            isMatch = true;
        }
        return isMatch;
    }

    public void finish(Database.BatchableContext bc){
        // Batchable Class must contain finish method, but nothing to do here:
    }
}