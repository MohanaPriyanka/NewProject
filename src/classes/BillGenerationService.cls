@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class BillGenerationService {
    public static Map<Id, List<Product_Escalator__c>> productEscalatorMap;
    public static ScheduleZSubscriptionSelector szsSelector = new ScheduleZSubscriptionSelector();
    public static ProductEscalatorSelector escalatorSelector = new ProductEscalatorSelector();

    // Archive once we are creating only UASBs:
    public static List<Schedule_Z_Subscription__c>  getScheduleZSubscriptionList(Set<Id> scheduleZIds){
        List<Schedule_Z_Subscription__c> onTimeSZSes;
        List<Schedule_Z_Subscription__c> overdueSZSes;
        Set<Id> uasIdsAlreadyBilling = new Set<Id>();

        onTimeSZSes = ScheduleZSubscriptionSelector.getListForBilling(scheduleZIds);
        for (Schedule_Z_Subscription__c szs : onTimeSZSes) {
            uasIdsAlreadyBilling.add(szs.Utility_Account_Subscription__c);
        }
        System_Properties__c sysProp = System_Properties__c.getAll().values()[0];
        Decimal minimumBalance = Util.nullToZero(sysProp.Minimum_Balance_Bills_for_Cancelled__c);
        Date maxPastDueDate = Date.today().addDays(-(Integer.valueOf(Util.nullToZero(sysProp.Days_Generate_Bills_For_Cancelled__c))));
        overdueSZSes = ScheduleZSubscriptionSelector.getOverdueSZSubscriptions(
            minimumBalance,
            maxPastDueDate,
            uasIdsAlreadyBilling
        );
        onTimeSZSes.addAll(overdueSZSes);
        return onTimeSZSes;
    }

    // Called from Preview Bills Screen on Transfer:
    @AuraEnabled
    public static List<UASB__c> calculateUASBsFromTransfer(Transfer__c transfer) {
        BillGenerationService billGenService = new BillGenerationService();
        billGenService.checkRequiredTransferFields(transfer);
        List<UASB__c> uasbs = billGenService.calculateUASBesFromSZSes(billGenService.getScheduleZSubscriptionList(transfer), transfer);
        return uasbs;
    }

    @TestVisible
    private List<Schedule_Z_Subscription__c> getScheduleZSubscriptionList(Transfer__c transfer) {
        List<Schedule_Z_Subscription__c> onTimeSZSes;
        List<Schedule_Z_Subscription__c> overdueSZSes;
        Set<Id> uasIdsAlreadyBilling = new Set<Id>();

        onTimeSZSes = szsSelector.getOnTimeListForBillingOffTransfer(new Set<Id>{transfer.Allocation_Schedule__c});
        for (Schedule_Z_Subscription__c szs : onTimeSZSes) {
            uasIdsAlreadyBilling.add(szs.Utility_Account_Subscription__c);
        }
        overdueSZSes = szsSelector.getOverdueSZSForBillingOffTransfer(new Set<Id>{transfer.Shared_Solar_System__c}, uasIdsAlreadyBilling);
        onTimeSZSes.addAll(overdueSZSes);
        return onTimeSZSes;
    }

    @TestVisible
    private List<UASB__c> calculateUASBesFromSZSes(List<Schedule_Z_Subscription__c> szsList, Transfer__c transfer){
        checkRequiredTransferFields(transfer);
        List<UASB__c> uasbsToInsert = new List<UASB__c>();
        for (Schedule_Z_Subscription__c szs : szsList){
            if (szs.Schedule_Z__c == transfer.Allocation_Schedule__c){
                uasbsToInsert.add(setUASBFields(szs, transfer));
            } else {
                uasbsToInsert.add(setZeroDollarUASBFields(szs, transfer));
            }
        }
        return uasbsToInsert;
    }

    private void checkRequiredTransferFields(Transfer__c transfer){
        String errorMessage = 'Cannot make UASBs from a Transfer ';
        if (transfer.Allocation_Schedule__c == null){
            throw new AuraHandledException(errorMessage + 'because the Transfer does not have an Allocation Schedule populated');
        } else if (transfer.Attempted_kWh_Transfer__c == null || transfer.Attempted_Transfer__c == null){
            throw new AuraHandledException(errorMessage + 'without Attempted kWh Transfer & Attempted Transfer populated');
        } else if (transfer.Default_Credit_Value__c == null){
            throw new AuraHandledException(errorMessage + 'without Default Credit Value populated');
        } else if (transfer.Bill_Period__c == null || transfer.Bill_Period__r.Bill_Date__c == null || transfer.Date_of_Transfer__c == null){
            throw new AuraHandledException(errorMessage + 'without Date of Transfer & Bill Period Date populated');
        }
    }

    @TestVisible
    private UASB__c setUASBFields(Schedule_Z_Subscription__c szs, Transfer__c transfer){
        Product_Escalator__c escalatorProduct;
        if (szs.Utility_Account_Subscription__r.Opportunity__r.Product_Escalation_Schedule__c != null){
            Integer productionCount =  (Integer)szs.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Count_of_Transfers__c;
            escalatorProduct = getProductEscalator(szs, productionCount);
        }
        Decimal shareOfSystem = szs.Percent_Share__c;
        String creditsRoundingMethod = szs.Schedule_Z__r.Shared_Solar_System__r.Utility__r.Credits_Allocated_Rounding_Method__c;

        // Calculate % Share of Production (kWh)
        Decimal subscriptionProduction = ((shareOfSystem/100) * transfer.Attempted_kWh_Transfer__c).setScale(2, roundingMode.HALF_UP);

        // Calculate Credits Allocated to Customer, either as % of kWh or % of $. Xcel Applies rate in 2 stages:
        Decimal subscriptionNMCs = 0;
        String billingMethod = szs.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Billing_Method__c;

        if (billingMethod == 'NMC'){
            subscriptionNMCs = (shareOfSystem/100) * transfer.Attempted_Transfer__c;
            subscriptionNMCs = Util.roundValue(subscriptionNMCs, 2, creditsRoundingMethod);
        } else if (billingMethod == 'kWh') {
            subscriptionNMCs = ((transfer.Default_Credit_Value__c - 0.02)*subscriptionProduction).setScale(2, roundingMode.HALF_UP) + ((0.02)*subscriptionProduction).setScale(2, roundingMode.HALF_UP);
        }

        UASB__c generatedUASB = new UASB__c(
            Customer_Subscription_KW_DC__c = szs.Customer_Subscription_kW_DC__c,
            Date__c = transfer.Bill_Period__r.Bill_Date__c,
            Transfer__c = transfer.Id,
            Utility_Account_Subscription__c = szs.Utility_Account_Subscription__r.Id,
            Opportunity__c = szs.Utility_Account_Subscription__r.Opportunity__c,
            Shared_Solar_System__c = szs.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__c,
            Billing_Period_Start_Date__c = transfer.Date_of_Transfer__c,
            Billing_Period_End_Date__c = transfer.Date_of_Transfer__c.addMonths(1),
            //Externally_Serviced__c = szs.Utility_Account_Subscription__r.Externally_Serviced__c,
            NMC_Discount__c = szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.NMC_Discount__c,
            Total_System_Size_kW_DC__c = szs.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Total_System_Size_kWh_DC__c,
            NM_Rate_Floor__c = szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.NM_Rate_Floor__c,
            Pricing_Structure__c = szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.Pricing_Structure__c,
            Solar_Electricity_Rate__c = szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.Solar_Electricity_Rate__c,
            NMC_Rate__c = transfer.Default_Credit_Value__c,
            Share_of_System__c = shareOfSystem,
            Credits_Allocated__c = subscriptionNMCs,
            Total_System_NMCs__c = transfer.Attempted_Transfer__c,
            Total_System_Production_kWh__c = transfer.Attempted_kWh_Transfer__c,
            Subscription_Production_kWh_Static__c = subscriptionProduction,
            Schedule_Z_Subscription__c = szs.Id
        );

        if (billingMethod == 'NMC'){
            generatedUASB.Size_off_NMCs__c = true;
        }

        if (escalatorProduct != null){
            generatedUASB.NMC_Discount__c = escalatorProduct.New_NMC_Discount__c;
            generatedUASB.Solar_Electricity_Rate__c = escalatorProduct.New_Solar_Electricity_Rate__c;
        }

        return generatedUASB;
    }

    @TestVisible
    private UASB__c setZeroDollarUASBFields(Schedule_Z_Subscription__c szs, Transfer__c transfer){
        // Zero dollar bill for cancelled customers:
        UASB__c zeroDollarUASB = new UASB__c(
            Date__c = transfer.Bill_Period__r.Bill_Date__c,
            Transfer__c = transfer.Id,
            Utility_Account_Subscription__c = szs.Utility_Account_Subscription__r.Id,
            Opportunity__c = szs.Utility_Account_Subscription__r.Opportunity__c,
            Shared_Solar_System__c = szs.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__c,
            Billing_Period_Start_Date__c = transfer.Date_of_Transfer__c,
            Billing_Period_End_Date__c = transfer.Date_of_Transfer__c.addMonths(1),
           // Externally_Serviced__c = szs.Utility_Account_Subscription__r.Externally_Serviced__c,
            Total_System_NMCs__c = 0,
            Total_System_Production_kWh__c = 0,
            Subscription_Production_kWh_Static__c = 0,
            NMC_Rate__c = 0,
            Share_of_System__c = 0,
            Credits_Allocated__c = 0
        );
        return zeroDollarUASB;
    }

    @TestVisible
    private Product_Escalator__c getProductEscalator(Schedule_Z_Subscription__c szs, Integer productionCount){
        if (productEscalatorMap == null){
            Map<Id, List<Product_Escalator__c>> productMap = escalatorSelector.getProductEscalations();
            productEscalatorMap = productMap;
        }

        List<Product_Escalator__c> escalatorList = new List<Product_Escalator__c>();
        Product_Escalator__c activeEscalator = null;

        String mapKeyScheduleId = szs.Utility_Account_Subscription__r.Opportunity__r.Product_Escalation_Schedule__c;
        system.debug(mapKeyScheduleId);
        system.debug(productEscalatorMap);
        if (productEscalatorMap.containsKey(mapKeyScheduleId)) {
            escalatorList = productEscalatorMap.get(mapKeyScheduleId);
            for (Product_Escalator__c escalator : escalatorList) {
                if (escalator.Starting_Credit_Transfer__c <= productionCount) {
                    activeEscalator = escalator;
                    break;
                }
            }
        }
        return activeEscalator;
    }

    @AuraEnabled
    public static void insertUASBs(List<UASB__c> uasbsToInsert, Transfer__c transfer) {
        insert uasbsToInsert;
        transfer.Bills_Generated__c = true;
        update transfer;
    }
}