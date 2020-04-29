public class ZuoraUsageService implements Database.AllowsCallouts{
    @TestVisible
    private static FeatureService featureService = new FeatureService();
    private static ZuoraSubscriptionService subscriptionService = new ZuoraSubscriptionService();
    public class ZuoraUsageItems {
        public String type = 'Usage';
        public List<ZuoraUsage> objects;
    }

    public class ZuoraUsage {
        public String AccountId;
        public String ChargeNumber;
        public Datetime EndDateTime;
        public Decimal Quantity;
        public Datetime StartDateTime;
        public String SubscriptionNumber;
        public String Description;
        public String ProjectName_Zcustom;
        public Decimal SolarSavings_Zcustom;
        public Decimal UtilityCredit_Zcustom;
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

    public static ZuoraUsageItems convertSFUsageToZuoraUsage (List<SObject> sfUsageRecord, Date invoiceDate){
        ZuoraUsageItems zuoraObject = new ZuoraUsageItems();
        List<ZuoraUsage> zuoraUsageLineItems = new List<ZuoraUsage>();

        for (SObject sfUsage : sfUsageRecord) {
            try {
                if (sfUsage.Id.getSObjectType() == UASB__c.sObjectType) {
                    UASB__c uasb = (UASB__c) sfUsage;
                    ZuoraUsage usage = convertUASBToUsage(uasb);
                    if (usage.ChargeNumber != null && usage.SubscriptionNumber != null){
                        zuoraUsageLineItems.add(usage);
                    }
                } else if (sfUsage.Id.getSObjectType() == Bill_Adjustment__c.sObjectType) {
                    Bill_Adjustment__c adjust = (Bill_Adjustment__c) sfUsage;
                    ZuoraUsage usage = convertAdjustToUsage(adjust, invoiceDate);
                    if (usage.ChargeNumber != null && usage.SubscriptionNumber != null){
                        zuoraUsageLineItems.add(usage);
                    }
                }
            } catch (Util.BWException bwException) {
                Logger.logLater(
                    'ZuoraUsageService',
                    'convertSFUsageToZuoraUsage',
                    'Conversion to usage failed for id: ' + sfUsage.Id + bwException.getMessage(),
                    Logger.ERROR
                );
            }
        }
        zuoraObject.objects = zuoraUsageLineItems;
        return zuoraObject;
    }

    @TestVisible
    private static ZuoraUsage convertUASBToUsage(UASB__c uasb){
        ZuoraUsage usage = new ZuoraUsage();
        String zuoraAcctId = uasb.Utility_Account_Subscription__r.Opportunity__r.Account.Zuora_Id__c;
        String client = uasb.Client_Account_Number__c;
        String project = uasb.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Unique_ID__c;
        String subscriptionNumber;
        String chargeNumber;
        if (featureService.isEnabled('Multiple_Subscriptions')) {
            ZuoraAPI.Subscription subscription = subscriptionService.getSubscriptionsByAccount(zuoraAcctId).getSubscriptionFor(client, project);
            if (subscription == null) {
                throw new Util.FatalBWException('Did not find a subscription with ' +
                    'client ' + client + ' and project ' + project + ' to upload uasb: ' + uasb.Id);
            }
            subscriptionNumber = subscription.subscriptionNumber;
            chargeNumber = subscription.getRatePlanChargeFor(client, project).number_Zreserved;
        } else {
            ZuoraAPI.OrderBySubscriptionOwner subscription = ZuoraSubscriptionService.getOrderBySubscriptionOwner(zuoraAcctId);
            subscriptionNumber = subscription.getSubscriptionNumber();
            chargeNumber = subscription.getChargeNumber(client, project);
        }
        usage.AccountId = zuoraAcctId;
        usage.SubscriptionNumber = subscriptionNumber;
        usage.ChargeNumber = chargeNumber;
        usage.Quantity = uasb.Discounted_Bill__c;
        // UASB Date__c is the date of the production update, favored over using the Billing Period Start and End Date
        usage.StartDateTime = firstOfTheMonth(uasb.Date__c);
        usage.EndDateTime = firstOfTheMonth(uasb.Date__c) + 1;
        usage.ProjectName_Zcustom = uasb.Shared_Solar_System__r.Name;
        usage.Description = uasb.Shared_Solar_System__r.Utility__r.Name
            + ' #'
            + uasb.Utility_Account_Subscription__r.Utility_Account_Log__r.Name;
        usage.SolarSavings_Zcustom = uasb.Savings__c;
        usage.UtilityCredit_Zcustom = Util.roundValue(uasb.Net_Metering_Credits_Allocated__c, 2, 'HALF_UP');
        usage.CRM_ID_Zcustom = uasb.Id;
        return usage;
    }

    @TestVisible
    private static ZuoraUsage convertAdjustToUsage(Bill_Adjustment__c adjust, Date invoiceDate){
        ZuoraUsage usage = new ZuoraUsage();
        String zuoraAcctId = adjust.Utility_Account_Subscription__r.Opportunity__r.Account.Zuora_Id__c;
        String client = adjust.Client__r.Account_Number__c;
        String project = adjust.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Unique_ID__c;
        String subscriptionNumber;
        String chargeNumber;
        if (featureService.isEnabled('Multiple_Subscriptions')) {
            ZuoraAPI.Subscription subscription = subscriptionService.getSubscriptionsByAccount(zuoraAcctId).getSubscriptionFor(client, project);
            if (subscription == null) {
                throw new Util.FatalBWException('Did not find a subscription to upload adjustment: ' + adjust.Id);
            }
            subscriptionNumber = subscription.subscriptionNumber;
            chargeNumber = subscription.getRatePlanChargeFor(client, project).number_Zreserved;
        } else {
            ZuoraAPI.OrderBySubscriptionOwner subscription = ZuoraSubscriptionService.getOrderBySubscriptionOwner(zuoraAcctId);
            subscriptionNumber = subscription.getSubscriptionNumber();
            chargeNumber = subscription.getChargeNumber(client, project);
        }
        usage.AccountId = zuoraAcctId;
        usage.SubscriptionNumber = subscriptionNumber;
        usage.ChargeNumber = chargeNumber;
        usage.Quantity = adjust.Adjustment_Amount__c;
        usage.StartDateTime = firstOfTheMonth(invoiceDate);
        usage.EndDateTime = firstOfTheMonth(invoiceDate) + 1;
        usage.ProjectName_Zcustom = adjust.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Name;
        usage.Description = adjust.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Utility__r.Name
            + ' #'
            + adjust.Utility_Account_Subscription__r.Utility_Account_Log__r.Name;
        usage.SolarSavings_Zcustom = adjust.Discount__c;
        usage.UtilityCredit_Zcustom = Util.roundValue(adjust.Credits_Allocated__c, 2, 'HALF_UP');
        usage.CRM_ID_Zcustom = adjust.Id;
        return usage;
    }

    private static Datetime firstOfTheMonth(Date d) {
        return Datetime.newInstance(d.year(), d.month(), 1);
    }

    public static Map<String, List<SObject>> handleAPIResponse(List<ZuoraUsage> attemptedUsageList, HttpResponse response){
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
                        Zuora_Id__c = usageLine.Id
                    );
                    uasbsToUpdate.add(uasbToUpdate);
                } else if (objectType == Bill_Adjustment__c.sObjectType){
                    Bill_Adjustment__c adjustToUpdate = new Bill_Adjustment__c(
                        Id = sfId,
                        Zuora_Id__c = usageLine.Id
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