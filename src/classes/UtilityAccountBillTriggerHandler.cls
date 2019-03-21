/*************************************************************************************
 * Created By:
 * Description:
 * Test: TestBillCreationandPayment, MultipleMonthProductionUpdateTest
 *************************************************************************************/

public without sharing class UtilityAccountBillTriggerHandler {
    public static Map<Id, List<Product_Escalator__c>> productEscalatorMap;

    public void createUASB( Map<Id, Energy_Usage_Update__c> prodUpdateMap,
                            Map<String, System_Bill__c > systemBillMap, 
                            Map<Id, Utility_Account_Bill__c> utilityAccountLogIdToUABMap, 
                            List<Utility_Account_Subscription__c> uasList,
                            Map<Id, List<Product_Escalator__c>>  productEscalationMap ){

        Set<Id> scheduleZIds = new Set<Id>();
        for (Energy_Usage_Update__c productionUpdate : prodUpdateMap.Values()) {
            scheduleZIds.add(productionUpdate.Schedule_Z__c);
        }
        productEscalatorMap = productEscalationMap;

        // Collect Schedule Z Subscriptions related to the Schedule Zs
        List<Schedule_Z_Subscription__c> scheduleZSubscriptions = [
            SELECT Id, Customer_Subscription_kW_DC__c, Percent_Share__c, Utility_Account_Subscription__c,
                Utility_Account_Subscription__r.Id, 
                Utility_Account_Subscription__r.Name, 
                Utility_Account_Subscription__r.Utility_Account_Log__c, 
                Utility_Account_Subscription__r.Opportunity__r.Name,
                Utility_Account_Subscription__r.Opportunity__r.Account.Name,
                Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Name,
                Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__c,
                Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Id,
                Utility_Account_Subscription__r.Opportunity__r.AccountId,
                Utility_Account_Subscription__r.Customer_Subscription_KW_DC_STATIC__c,
                Utility_Account_Subscription__r.Customer_Subscription_KW_DC__c, 
                Utility_Account_Subscription__r.Opportunity__c,
                Utility_Account_Subscription__r.Opportunity__r.Product__r.NMC_Discount__c,
                Utility_Account_Subscription__r.Opportunity__r.Product__r.NM_Rate_Floor__c,
                Utility_Account_Subscription__r.Opportunity__r.Product__r.Solar_Electricity_Rate__c,
                Utility_Account_Subscription__r.Opportunity__r.Product__r.Pricing_Structure__c,
                Utility_Account_Subscription__r.Opportunity__r.Product__r.Percent_Share_Decimal_Places__c,
                Utility_Account_Subscription__r.Opportunity__r.Product_Escalation_Schedule__c,
                Utility_Account_Subscription__r.UAS_Number__c,
                Utility_Account_Subscription__r.Share_of_System__c ,
                Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Total_System_Size_kwh_dc__c, 
                Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Billing_Method__c,
                Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Count_of_Transfers__c,
                Utility_Account_Subscription__r.Opportunity__r.NMC_Value__c,
                Utility_Account_Subscription__r.Max_Account_Bill_Number__c,
                Schedule_Z__r.Shared_Solar_System__r.Utility__r.Credits_Allocated_Rounding_Method__c
            FROM Schedule_Z_Subscription__c
            WHERE Schedule_Z__c IN : scheduleZIds
            AND Stop_Credit_Transfer__c = FALSE
        ];

        Map<Id, Schedule_Z_Subscription__c> scheduleZSubscriptionToUABIdMap = new Map<Id, Schedule_Z_Subscription__c>();
        for (Schedule_Z_Subscription__c scheduleZSub : scheduleZSubscriptions) {
            scheduleZSubscriptionToUABIdMap.put(scheduleZSub.Utility_Account_Subscription__c, scheduleZSub);
        }

        // Get Adjustment List for UAS that belong to the Utility Account Logs
        // Do I need to look into Bill_Adjustments?
        List<Bill_Adjustment__c> adjustmentList = [
            SELECT Id, Name, UASB__c, Utility_Account_Subscription__c, Adjustment_Amount__c, Discounted_Bill__c,
                Utility_Account_Subscription__r.Id, Approval_Status__c, Credits_Allocated__c, Adjustment_Type__c, Discount__c
            FROM Bill_Adjustment__c
            WHERE Utility_Account_Subscription__r.Utility_Account_Log__c
                IN : utilityAccountLogIdToUABMap.keySet()
            AND Applied_to_Bill__c = FALSE
            AND Overpayment__c = FALSE
            AND Approval_Status__c = 'Approved'
            ORDER BY CreatedDate];

        Set<UASB__c> uasbSet = new Set<UASB__c>();
        Map<String, List<Bill_Adjustment__c>> adjustmentsToUpdateMap = new Map<String, List<Bill_Adjustment__c>>();

        for(Utility_Account_Subscription__c uas : uasList){
            if (utilityAccountLogIdToUABMap.containsKey(uas.Utility_Account_Log__c)){
                Utility_Account_Bill__c uab = utilityAccountLogIdToUABMap.get(uas.Utility_Account_Log__c);
                Energy_Usage_Update__c prodUpdate = prodUpdateMap.get(uas.Opportunity__r.Shared_Solar_System__r.Id);
                String systemBillKey = uas.Opportunity__r.Name + ' ' + uas.Opportunity__r.Shared_Solar_System__r.Name + ' ' + DateTime.newInstance(uab.Date__c.year(), uab.Date__c.month(),uab.Date__c.day()).format('yyyy-MM');
                System_Bill__c systemBill = systemBillMap.get(systemBillKey);
                if (systemBill != null){
                    try {
                        UASB__c uasb = catchCancelledUASes(prodUpdate,
                            uas,
                            scheduleZSubscriptionToUABIdMap,
                            1,
                            prodUpdate.Net_Metering_Rate_Applied__c,
                            prodUpdate.Production__c,
                            prodUpdate.Total_System_NMCs__c);
                        uasb.Unique_Id__c = uas.Opportunity__r.Shared_Solar_System__c + ' - ' + uas.Id + ' - ' + DateTime.newInstance(uab.Date__c.year(), uab.Date__c.month(), uab.Date__c.day()).format('yyyy-MM');
                        uasb.Name = uab.Name + uas.Opportunity__r.Shared_Solar_System__r.Name;
                        uasb.CS_Billing_Log__c = uab.Id;
                        uasb.System_Bill__c = systemBill.Id;
                        if (prodUpdate.Total_System_NMCs_2_of_4__c > 0 && scheduleZSubscriptionToUABIdMap.containsKey(uas.Id)) {
                            UASB__c uasbTwo = setUASBFields(prodUpdate,
                                scheduleZSubscriptionToUABIdMap.get(uas.id),
                                2,
                                prodUpdate.Net_Metering_Rate_Applied_2_of_4__c,
                                prodUpdate.Production_kWh_2_of_4__c,
                                prodUpdate.Total_System_NMCs_2_of_4__c);
                            uasbTwo.Unique_Id__c = uas.Opportunity__r.Shared_Solar_System__c + ' - ' + uas.Id + ' - ' + DateTime.newInstance(uab.Date__c.year(), uab.Date__c.month(), uab.Date__c.day()).format('yyyy-MM') + 'A';
                            uasbTwo.Name = uab.Name + uas.Opportunity__r.Shared_Solar_System__r.Name + 'A';
                            uasbTwo.CS_Billing_Log__c = uab.Id;
                            uasbTwo.System_Bill__c = systemBill.Id;
                            uasbSet.add(uasbTwo);
                            if (prodUpdate.Total_System_NMCs_3_of_4__c > 0 && scheduleZSubscriptionToUABIdMap.containsKey(uas.Id)) {
                                UASB__c uasbThree = setUASBFields(prodUpdate,
                                    scheduleZSubscriptionToUABIdMap.get(uas.id),
                                    3,
                                    prodUpdate.Net_Metering_Rate_Applied_3_of_4__c,
                                    prodUpdate.Production_kWh_3_of_4__c,
                                    prodUpdate.Total_System_NMCs_3_of_4__c);
                                uasbThree.Unique_Id__c = uas.Opportunity__r.Shared_Solar_System__c + ' - ' + uas.Id + ' - ' + DateTime.newInstance(uab.Date__c.year(), uab.Date__c.month(), uab.Date__c.day()).format('yyyy-MM') + 'B';
                                uasbThree.Name = uab.Name + uas.Opportunity__r.Shared_Solar_System__r.Name + 'B';
                                uasbThree.CS_Billing_Log__c = uab.Id;
                                uasbThree.System_Bill__c = systemBill.Id;
                                uasbSet.add(uasbThree);
                                if (prodUpdate.Total_System_NMCs_4_of_4__c > 0 && scheduleZSubscriptionToUABIdMap.containsKey(uas.Id)) {
                                    UASB__c uasbFour = setUASBFields(prodUpdate,
                                        scheduleZSubscriptionToUABIdMap.get(uas.id),
                                        4,
                                        prodUpdate.Net_Metering_Rate_Applied_4_of_4__c,
                                        prodUpdate.Production_kWh_4_of_4__c,
                                        prodUpdate.Total_System_NMCs_4_of_4__c);
                                    uasbFour.Unique_Id__c = uas.Opportunity__r.Shared_Solar_System__c + ' - ' + uas.Id + ' - ' + DateTime.newInstance(uab.Date__c.year(), uab.Date__c.month(), uab.Date__c.day()).format('yyyy-MM') + 'C';
                                    uasbFour.Name = uab.Name + uas.Opportunity__r.Shared_Solar_System__r.Name + 'C';
                                    uasbFour.CS_Billing_Log__c = uab.Id;
                                    uasbFour.System_Bill__c = systemBill.Id;
                                    uasbSet.add(uasbFour);
                                }
                            }
                        }
                        for (Bill_Adjustment__c adjust : adjustmentList) {
                            if (adjust.Utility_Account_Subscription__r.Id == uasb.Utility_Account_Subscription__c) {
                                uasb.Adjustment_Amount__c =
                                    Util.nullToZero(uasb.Adjustment_Amount__c) + Util.nullToZero(adjust.Adjustment_Amount__c);
                                // We should only include Production type adjustments in the UASB Adjusted Credit which is
                                // rolled up to the property account for reporting, since adjustments like BW Credit
                                // or Client Credit are compensating for BW servicing issues or writing off a balance
                                if (adjust.Adjustment_Type__c == 'Production') {
                                    uasb.Adjusted_Credits__c =
                                        Util.nullToZero(uasb.Adjusted_Credits__c) + Util.nullToZero(adjust.Credits_Allocated__c);
                                    uasb.Adjusted_Discount__c =
                                        Util.nullToZero(uasb.Adjusted_Discount__c) + Util.nullToZero(adjust.Discount__c);
                                }
                                List<Bill_Adjustment__c> adjustments = new List<Bill_Adjustment__c>();
                                if (adjustmentsToUpdateMap.containsKey(uasb.Unique_Id__c)) {
                                    adjustments = adjustmentsToUpdateMap.get(uasb.Unique_Id__c);
                                }
                                adjustments.add(adjust);
                                adjustmentsToUpdateMap.put(uasb.Unique_Id__c, adjustments);
                            }
                        }
                        uasbSet.add(uasb);
                    } catch (Exception e) {
                        String message = 'Utility Account System Bill not generated for UAS ' + uas.Id + 'Error: ' + String.valueOf(e);
                        Logger.logLater('UtilityAccountBillTriggerHandler', 'createUASB', message);
                    }
                }
            }
        }

        Logger.flushLogs();


        // if there are utility account subscription bills insert them

        if(uasbSet.size() > 0) {
            List<UASB__c> billList = new List<UASB__c>(uasbSet);
            upsert billList Unique_Id__c;
            // connect bill adjustments to UASBs
            for (UASB__c bill : billList) {
                if (adjustmentsToUpdateMap.containsKey(bill.Unique_Id__c)) {
                    List<Bill_Adjustment__c> adjustments = adjustmentsToUpdateMap.get(bill.Unique_Id__c);
                    for (Bill_Adjustment__c adjustment : adjustments) {
                        adjustment.UASB__c = bill.Id;
                    }
                    adjustmentsToUpdateMap.put(bill.Unique_ID__c, adjustments);
                }
            }
            if(adjustmentsToUpdateMap.size() > 0) {
                List<Bill_Adjustment__c> adjustmentsToUpdate = new List<Bill_Adjustment__c>();
                for (List<Bill_Adjustment__c> adjustments : adjustmentsToUpdateMap.values()) {
                    adjustmentsToUpdate.addAll(adjustments);
                }
                update adjustmentsToUpdate;
            }
        }

    }

    // Dependent on list of escalators being ordered by Number_of_Credit_Transfers__c descending
    public static Product_Escalator__c getProductEscalator( Schedule_Z_Subscription__c szs,
                                                            Decimal transferCount){
        if (productEscalatorMap == null){
            Map<Id, List<Product_Escalator__c>> productMap = ProductEscalatorSelector.getProductEscalationMap();
            productEscalatorMap = productMap;
        }

        List<Product_Escalator__c> escalatorList = new List<Product_Escalator__c>();
        Product_Escalator__c activeEscalator = null;

        String mapKeyScheduleId = szs.Utility_Account_Subscription__r.Opportunity__r.Product_Escalation_Schedule__c;
        if (productEscalatorMap.containsKey(mapKeyScheduleId)) {
            escalatorList = productEscalatorMap.get(mapKeyScheduleId);
            for (Product_Escalator__c escalator : escalatorList) {
                if (escalator.Starting_Credit_Transfer__c <= transferCount) {
                    activeEscalator = escalator;
                    break;
                }
            }
        }
        return activeEscalator;
    }

    public static UASB__c catchCancelledUASes(  Energy_Usage_Update__c prodUpdate,
                                                Utility_Account_Subscription__c uas,
                                                Map<Id, Schedule_Z_Subscription__c> scheduleZSubscriptionToUABIdMap,
                                                Decimal transferCount,
                                                Decimal nmcRate,
                                                Decimal systemProduction,
                                                Decimal systemNMCs){
        UASB__c uasbToCreate;

        if ( scheduleZSubscriptionToUABIdMap.containsKey(uas.Id)){
            uasbToCreate = setUASBFields(prodUpdate, scheduleZSubscriptionToUABIdMap.get(uas.Id), transferCount, nmcRate, systemProduction, systemNMCs);
        } else {
            // Zero dollar bill for cancelled customers:
            uasbToCreate = new UASB__c( Date__c = prodUpdate.Date__c,
                Production_Update__c = prodUpdate.Id,
                Utility_Account_Subscription__c = uas.Id,
                Opportunity__c = uas.Opportunity__c,
                Shared_Solar_System__c = uas.Opportunity__r.Shared_Solar_System__c,
                Billing_Period_Start_Date__c = prodUpdate.Billing_Period_Start_Date__c,
                Billing_Period_End_Date__c = prodUpdate.Billing_Period_End_Date__c,
                Total_System_NMCs__c = 0,
                Total_System_Production_kWh__c = 0,
                NMC_Rate__c = 0,
                Share_of_System__c = 0,
                Credits_Allocated__c = 0);
        }

        return uasbToCreate;
    }

    public static UASB__c setUASBFields(Energy_Usage_Update__c prodUpdate,
                                        Schedule_Z_Subscription__c szs,
                                        Decimal transferCount,
                                        Decimal nmcRate,
                                        Decimal systemProduction, 
                                        Decimal systemNMCs){
        transferCount =  transferCount + szs.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Count_of_Transfers__c;
        Product_Escalator__c escalatorProduct = getProductEscalator(szs, transferCount);
        Decimal shareOfSystem = szs.Percent_Share__c;
        String creditsRoundingMethod = szs.Schedule_Z__r.Shared_Solar_System__r.Utility__r.Credits_Allocated_Rounding_Method__c;
        // Calculate % Share of Production (kWh)
        Decimal subscriptionProduction = ((shareOfSystem/100) * systemProduction).setScale(2, roundingMode.HALF_UP);

        // Calculate Credits Allocated to Customer, either as % of kWh or % of $. Xcel Applies rate in 2 stages:
        Decimal subscriptionNMCs = 0;
        String billingMethod = szs.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Billing_Method__c;
        if (billingMethod == 'NMC'){
            subscriptionNMCs = (shareOfSystem/100) * systemNMCs;
            subscriptionNMCs = Util.roundValue(subscriptionNMCs, 2, creditsRoundingMethod);
        } else if (billingMethod == 'kWh') {
            subscriptionNMCs = ((nmcRate - 0.02)*subscriptionProduction).setScale(2, roundingMode.HALF_UP) + ((0.02)*subscriptionProduction).setScale(2, roundingMode.HALF_UP);
        }

        UASB__c generatedUASB = new UASB__c( Customer_Subscription_KW_DC__c = szs.Customer_Subscription_kW_DC__c,
                                    Date__c = prodUpdate.Date__c,
                                    Production_Update__c = prodUpdate.Id,
                                    Utility_Account_Subscription__c = szs.Utility_Account_Subscription__r.Id,  
                                    Opportunity__c = szs.Utility_Account_Subscription__r.Opportunity__c,
                                    Shared_Solar_System__c = szs.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__c,
                                    Billing_Period_Start_Date__c = prodUpdate.Billing_Period_Start_Date__c,
                                    Billing_Period_End_Date__c = prodUpdate.Billing_Period_End_Date__c,
                                    NMC_Discount__c = szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.NMC_Discount__c,
                                    Total_System_Size_kW_DC__c = szs.Utility_Account_Subscription__r.Opportunity__r.shared_solar_system__r.Total_System_Size_kWh_DC__c,
                                    NM_Rate_Floor__c = szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.NM_Rate_Floor__c,
                                    Pricing_Structure__c = szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.Pricing_Structure__c,
                                    Solar_Electricity_Rate__c = szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.Solar_Electricity_Rate__c,
                                    NMC_Rate__c = nmcRate,
                                    Total_System_NMCs__c = systemNMCs,
                                    Total_System_Production_kWh__c = systemProduction,
                                    Share_of_System__c = shareOfSystem,
                                    Credits_Allocated__c = subscriptionNMCs,
                                    Subscription_Production_kWh_Static__c = subscriptionProduction,
                                    Schedule_Z_Subscription__c = szs.Id);
      
        if (billingMethod == 'NMC'){
            generatedUASB.Size_off_NMCs__c = true;
        }

        if (escalatorProduct != null){
            generatedUASB.NMC_Discount__c = escalatorProduct.New_NMC_Discount__c;
            generatedUASB.Solar_Electricity_Rate__c = escalatorProduct.New_Solar_Electricity_Rate__c;
        }

        return generatedUASB;
    }

}