/*************************************************************************************
 * Created By: jpentaleri on 2019-07-29
 * Description: Used to load late fees into Zuora as Debit Memos
 * Should be deleted/removed after the historical migration (late fees aren't charged anymore
 * and system bills will be retired)
 *
 * Tested By: ZuoraHistoricalLateFeesServiceTest
 *************************************************************************************/

public without sharing class ZuoraHistoricalLateFeeService implements Database.Batchable<System_Bill__c>, Database.AllowsCallouts{
    public static ZuoraAPI.DebitMemo convertSFLateFeesToDebitMemos(System_Bill__c systemBill){
        ZuoraAPI.DebitMemoCharge debitCharge = new ZuoraAPI.DebitMemoCharge();
        debitCharge.Amount = systemBill.Late_Fees__c.setScale(2);
        debitCharge.ChargeId = getChargeFromSystemBill(systemBill);

        ZuoraAPI.DebitMemo debitMemo = new ZuoraAPI.DebitMemo();
        debitMemo.AccountId = systemBill.Account_Bill__r.Parent_Account__r.Zuora_Id__c;
        debitMemo.EffectiveDate = systemBill.Account_Bill__r.Date__c;
        debitMemo.Project_Zcustom = systemBill.Opportunity__r.Shared_Solar_System__r.Unique_ID__c;
        debitMemo.ClientOwner_Zcustom = systemBill.Client__r.Account_Number__c;
        debitMemo.Charges = new List<ZuoraAPI.DebitMemoCharge>{
            debitCharge
        };
        debitMemo.CRM_ID_Zcustom = systemBill.Id;
        debitMemo.ReasonCode = 'Late Fee';
        return debitMemo;
    }

    public static String getChargeFromSystemBill(System_Bill__c systemBill){
        String zuoraAcctId = systemBill.Account_Bill__r.Parent_Account__r.Zuora_Id__c;

        ZuoraAPI.OrderBySubscriptionOwner subscription = ZuoraSubscriptionService.getOrderBySubscriptionOwner(zuoraAcctId);
        return subscription.getProductRatePlanChargeId(
            systemBill.Client__r.Account_Number__c,
            systemBill.Opportunity__r.Shared_Solar_System__r.Unique_ID__c
        );
    }

    public static ZuoraAPI.GenericResponse sendDebitMemoToZuoraAndPost(System_Bill__c systemBill){
        ZuoraAPI.DebitMemo debitMemo;
        debitMemo = convertSFLateFeesToDebitMemos(systemBill);
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('POST','/v1/debitmemos',debitMemo,false);
        ZuoraAPI.GenericResponse zResponse = new ZuoraAPI.GenericResponse();
        zResponse = (ZuoraAPI.GenericResponse)JSON.deserialize(response.getBody(), ZuoraAPI.GenericResponse.class);
        ZuoraCreditDebitMemoService.postDebitMemo(zResponse.Id);
        return zResponse;
    }

    public void executeBatch(){
        Database.executeBatch(this, 20);
    }

    public List<System_Bill__c> start(Database.BatchableContext bc){
        List<System_Bill__c> sbWithLateFee = [
            SELECT Id, Late_Fees__c, Account_Bill__r.Parent_Account__r.Zuora_Id__c,
                Account_Bill__r.Date__c, Client__r.Account_Number__c,
                Opportunity__r.Shared_Solar_System__r.Unique_ID__c
            FROM System_Bill__c
            WHERE Late_Fees__c > 0
        ];
        return sbWithLateFee;
    }

    public void execute(Database.BatchableContext bc, List<System_Bill__c> scope){
        try {
            for (System_Bill__c bill : scope){
                sendDebitMemoToZuoraAndPost(bill);
            }
        } catch (Exception excep){
            Logger.logLater('ZuoraHistoricalLateFeeService', 'execute', excep.getMessage() + '\n' + excep.getStackTraceString());
        }
        Logger.flushLogs();
    }

    public void finish(Database.BatchableContext bc){
        Logger.logNow('ZuoraHistoricalLateFeeService', 'finish', 'doneProcessing');
    }
}