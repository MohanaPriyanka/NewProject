public class ZuoraUsageService implements Database.AllowsCallouts{

    public class ZuoraUsage {
        public String AccountId;
        public String ChargeNumber;
        public Datetime EndDateTime;
        public Decimal Quantity;
        public Datetime StartDateTime;
        public String SubscriptionNumber;
        public String Description;
        public String SolarSavings_Zcustom;
        public String UtilityCredit_Zcustom;
        public String CRM_ID_Zcustom;
        public String UOM = 'Dollars';
    }

    public class ZuoraResponse {
        public String Success;
        public String Id;
        public List<ZuoraError> Errors;
    }

    public class ZuoraError {
        public String Code;
        public String Message;
    }

    public static List<ZuoraUsage> convertSFUsageToZuoraUsage (List<SObject> sfUsageRecord){
        List<ZuoraUsage> zuoraUsageLineItems = new List<ZuoraUsage>();

        for (SObject sfUsage : sfUsageRecord) {
            if (sfUsage.Id.getSObjectType() == UASB__c.sObjectType) {
                UASB__c uasb = (UASB__c) sfUsage;
                ZuoraUsage usage = new ZuoraUsage();
                usage.AccountId = uasb.Utility_Account_Subscription__r.SRPC__r.Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c;
                usage.Quantity = uasb.Discounted_Bill__c;
                usage.StartDateTime = uasb.Billing_Period_Start_Date__c;
                usage.EndDateTime = uasb.Billing_Period_Start_Date__c; // change to end date!!
                usage.SubscriptionNumber = uasb.Utility_Account_Subscription__r.SRPC__r.Zuora__Subscription__r.Name;
                usage.ChargeNumber = uasb.Utility_Account_Subscription__r.SRPC__r.Zuora__ChargeNumber__c;
                usage.Description = uasb.Shared_Solar_System__r.Utility__r.Name
                    + ' #'
                    + uasb.Utility_Account_Subscription__r.Utility_Account_Log__r.Name;
                usage.SolarSavings_Zcustom = String.valueOf(uasb.Savings__c);
                usage.UtilityCredit_Zcustom = String.valueOf(Util.roundValue(uasb.Net_Metering_Credits_Allocated__c, 2, 'HALF_UP'));
                usage.CRM_ID_Zcustom = uasb.Id;
                zuoraUsageLineItems.add(usage);
            } else if (sfUsage.Id.getSObjectType() == Bill_Adjustment__c.sObjectType) {
                Bill_Adjustment__c adjust = (Bill_Adjustment__c) sfUsage;
                ZuoraUsage usage = new ZuoraUsage();
                usage.AccountId = adjust.UASB__r.Utility_Account_Subscription__r.SRPC__r.Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c;
                usage.Quantity = adjust.Adjustment_Amount__c ;
                usage.StartDateTime = adjust.UASB__r.Billing_Period_Start_Date__c;
                usage.EndDateTime = adjust.UASB__r.Billing_Period_Start_Date__c; // change to end date!!
                usage.SubscriptionNumber = adjust.UASB__r.Utility_Account_Subscription__r.SRPC__r.Zuora__Subscription__r.Name;
                usage.ChargeNumber = adjust.UASB__r.Utility_Account_Subscription__r.SRPC__r.Zuora__ChargeNumber__c;
                usage.Description = adjust.UASB__r.Shared_Solar_System__r.Utility__r.Name
                    + ' #'
                    + adjust.UASB__r.Utility_Account_Subscription__r.Utility_Account_Log__r.Name;
                usage.SolarSavings_Zcustom = String.valueOf(adjust.Discount__c);
                usage.UtilityCredit_Zcustom = String.valueOf(Util.roundValue(adjust.Credits_Allocated__c, 2, 'HALF_UP'));
                usage.CRM_ID_Zcustom = adjust.Id;
                zuoraUsageLineItems.add(usage);
            }
        }
        return zuoraUsageLineItems;
    }

    public static String convertZuoraUsageToJSON (List<ZuoraUsage> zuoraUsageLineItems) {
        String jsonString = JSON.serialize(zuoraUsageLineItems);
        jsonString = '{ "objects": ' + jsonString + ', "type": "Usage" }';
        jsonString = jsonString.replace('_Zcustom','__c');
        return jsonString;
    }

    public static HttpResponse usageAPICall(String jsonString){
        // Replace with general Zuora api class
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint('https://rest.apisandbox.zuora.com/v1/action/create');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('zuora-version', '224.0');
        request.setHeader('Accept', 'application/json');
        request.setBody(jsonString);
        Zuora.zApi zApiInstance = new Zuora.zApi();
        HttpResponse response = zApiInstance.sendRequest(request);

        return response;
    }

    public static Map<String, List<SObject>> handleAPIResponse(List<ZuoraUsage> attemptedUsageList, HttpResponse response){
        System.debug(response.getBody());
        // Returns list of Usage Id, or Error Message:
        List<ZuoraResponse> zResponses = new List<ZuoraResponse>();
        zResponses = (List<ZuoraResponse>)JSON.deserialize(response.getBody(), List<ZuoraResponse>.class);

        Integer count = 0;
        List<UASB__c> uasbsToUpdate = new List<UASB__c>();
        List<Bill_Adjustment__c> adjustmentsToUpdate = new List<Bill_Adjustment__c>();

        for (ZuoraUsage attemptedUsage : attemptedUsageList){
            ZuoraResponse usageLine = zResponses[count];
            count += 1;
            if (usageLine.Success == 'true'){
                Id sfID = attemptedUsage.CRM_ID_Zcustom;
                Schema.SObjectType objectType = sfId.getSObjectType();
                if (objectType == UASB__c.sObjectType){
                    UASB__c uasbToUpdate = new UASB__c(
                        Id = sfId,
                        Zuora_Usage_Id__c = usageLine.Id
                    );
                    uasbsToUpdate.add(uasbToUpdate);
                } else if (objectType == Bill_Adjustment__c.sObjectType){
                    Bill_Adjustment__c adjustToUpdate = new Bill_Adjustment__c(
                        Id = sfId,
                        Zuora_Usage_Id__c = usageLine.Id
                    );
                    adjustmentsToUpdate.add(adjustToUpdate);
                }
            } else {
                String errorMessage = attemptedUsage.CRM_ID_Zcustom + '_' + String.valueOf(usageLine.Errors);
                Logger.logLater('ZuoraUsageService', 'handleAPIResponse', errorMessage);
            }
        }
        Map<String, List<SObject>> objectToRecordList = new Map<String, List<SObject>>();
        objectToRecordList.put('UASB',uasbsToUpdate);
        objectToRecordList.put('Bill_Adjustment',adjustmentsToUpdate);
        return objectToRecordList;
    }
}