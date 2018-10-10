/*************************************************************************************
 * Created By:
 * Description:
 * Test: TestBillCreationandPayment, MultipleMonthProductionUpdateTest
 *************************************************************************************/

public without sharing class UtilityAccountBillTriggerHandler {
    private void printSOQLLimits(String location) {
        System.debug(LoggingLevel.ERROR, 'SOQL Limites: ' + location + ': ' +  Limits.getQueries());
    }

    public void createUASB( Map<Id, Energy_Usage_Update__c> prodUpdateMap, 
                            Map<String, System_Bill__c > systemBillMap, 
                            Map<Id, Utility_Account_Bill__c> utilityAccountLogIdToUABMap, 
                            List<Utility_Account_Subscription__c> uasList){
        printSOQLLimits('******* Start UAB Trigger *******');

        Set<Id> scheduleZIds = new Set<Id>();
        for (Energy_Usage_Update__c productionUpdate : prodUpdateMap.Values()) {
            scheduleZIds.add(productionUpdate.Schedule_Z__c);
        }
        printSOQLLimits('After Collecting Sched Z on Prod Updates');

        printSOQLLimits('Before Collecting Sched Z Subs on Prod Updates');
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
                Utility_Account_Subscription__r.UAS_Number__c,
                Utility_Account_Subscription__r.Share_of_System__c ,
                Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Total_System_Size_kwh_dc__c, 
                Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Billing_Method__c,
                Utility_Account_Subscription__r.Opportunity__r.NMC_Value__c,
                Utility_Account_Subscription__r.Max_Account_Bill_Number__c
            FROM Schedule_Z_Subscription__c
            WHERE Schedule_Z__c IN : scheduleZIds
        ];

        Map<Id, Schedule_Z_Subscription__c> scheduleZSubscriptionToUABIdMap = new Map<Id, Schedule_Z_Subscription__c>();
        for (Schedule_Z_Subscription__c scheduleZSub : scheduleZSubscriptions) {
            scheduleZSubscriptionToUABIdMap.put(scheduleZSub.Utility_Account_Subscription__c, scheduleZSub);
        }
        printSOQLLimits('After Collecting Sched Z Subs on Prod Updates');

        printSOQLLimits('Before Collecting Adjustments');
        // Get Adjustment List for UAS that belong to the Utility Account Logs
        // Do I need to look into Bill_Adjustments?
        List<Bill_Adjustment__c> adjustmentList = [ SELECT Id, Name, UASB__c,
                                                Utility_Account_Subscription__c,
                                                Adjustment_Amount__c, Discounted_Bill__c,
                                                Utility_Account_Subscription__r.Id,
                                                Approval_Status__c
                                                FROM Bill_Adjustment__c
                                                WHERE Utility_Account_Subscription__r.Utility_Account_Log__c
                                                IN : utilityAccountLogIdToUABMap.keySet()
                                                AND Applied_to_Bill__c = false
                                                AND Overpayment__c = false
                                                AND Approval_Status__c = 'Approved'
                                                ORDER BY CreatedDate];

        printSOQLLimits('After Collecting Adjustments');


        printSOQLLimits('Before Building UASBs');
        Set<UASB__c> uasbSet = new Set<UASB__c>();
        Map<String, List<Bill_Adjustment__c>> adjustmentsToUpdateMap = new Map<String, List<Bill_Adjustment__c>>();
        for(Utility_Account_Subscription__c uas : uasList){
            if (utilityAccountLogIdToUABMap.containsKey(uas.Utility_Account_Log__c)){
                Utility_Account_Bill__c uab = utilityAccountLogIdToUABMap.get(uas.Utility_Account_Log__c);
                Energy_Usage_Update__c prodUpdate = prodUpdateMap.get(uas.Opportunity__r.Shared_Solar_System__r.Id);
                String systemBillKey = uas.Opportunity__r.Name + ' ' + uas.Opportunity__r.Shared_Solar_System__r.Name + ' ' + DateTime.newInstance(uab.Date__c.year(), uab.Date__c.month(),uab.Date__c.day()).format('yyyy-MM');
                System_Bill__c systemBill = systemBillMap.get(systemBillKey);
                if (uab.Shared_Solar_System__c == uas.Opportunity__r.Shared_Solar_System__c && systemBill != null){
                    try {
                        UASB__c uasb = setUASBFields(prodUpdate,
                            scheduleZSubscriptionToUABIdMap.get(uas.id),
                            prodUpdate.Net_Metering_Rate_Applied__c,
                            prodUpdate.Production__c,
                            prodUpdate.Total_System_NMCs__c);
                        uasb.Unique_Id__c = uas.Opportunity__r.Shared_Solar_System__c + ' - ' + uas.Id + ' - ' + DateTime.newInstance(uab.Date__c.year(), uab.Date__c.month(), uab.Date__c.day()).format('yyyy-MM');
                        uasb.Name = uab.Name + uas.Opportunity__r.Shared_Solar_System__r.Name;
                        uasb.CS_Billing_Log__c = uab.Id;
                        uasb.System_Bill__c = systemBill.Id;
                        if (prodUpdate.Total_System_NMCs_2_of_4__c > 0) {
                            UASB__c uasbTwo = setUASBFields(prodUpdate,
                                scheduleZSubscriptionToUABIdMap.get(uas.id),
                                prodUpdate.Net_Metering_Rate_Applied_2_of_4__c,
                                prodUpdate.Production_kWh_2_of_4__c,
                                prodUpdate.Total_System_NMCs_2_of_4__c);
                            uasbTwo.Unique_Id__c = uas.Opportunity__r.Shared_Solar_System__c + ' - ' + uas.Id + ' - ' + DateTime.newInstance(uab.Date__c.year(), uab.Date__c.month(), uab.Date__c.day()).format('yyyy-MM') + 'A';
                            uasbTwo.Name = uab.Name + uas.Opportunity__r.Shared_Solar_System__r.Name + 'A';
                            uasbTwo.CS_Billing_Log__c = uab.Id;
                            uasbTwo.System_Bill__c = systemBill.Id;
                            uasbSet.add(uasbTwo);
                            if (prodUpdate.Total_System_NMCs_3_of_4__c > 0) {
                                UASB__c uasbThree = setUASBFields(prodUpdate,
                                    scheduleZSubscriptionToUABIdMap.get(uas.id),
                                    prodUpdate.Net_Metering_Rate_Applied_3_of_4__c,
                                    prodUpdate.Production_kWh_3_of_4__c,
                                    prodUpdate.Total_System_NMCs_3_of_4__c);
                                uasbThree.Unique_Id__c = uas.Opportunity__r.Shared_Solar_System__c + ' - ' + uas.Id + ' - ' + DateTime.newInstance(uab.Date__c.year(), uab.Date__c.month(), uab.Date__c.day()).format('yyyy-MM') + 'B';
                                uasbThree.Name = uab.Name + uas.Opportunity__r.Shared_Solar_System__r.Name + 'B';
                                uasbThree.CS_Billing_Log__c = uab.Id;
                                uasbThree.System_Bill__c = systemBill.Id;
                                uasbSet.add(uasbThree);
                                if (prodUpdate.Total_System_NMCs_4_of_4__c > 0) {
                                    UASB__c uasbFour = setUASBFields(prodUpdate,
                                        scheduleZSubscriptionToUABIdMap.get(uas.id),
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
                            if (uasb.Adjustment_Amount__c == NULL) {
                                uasb.Adjustment_Amount__c = 0;
                            }
                            if (adjust.Utility_Account_Subscription__r.Id == uasb.Utility_Account_Subscription__c) {
                                uasb.Adjustment_Amount__c = uasb.Adjustment_Amount__c + adjust.Adjustment_Amount__c;
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

        printSOQLLimits('After Building UASBs');

        // if there are utility account subscription bills insert them

        if(uasbSet.size() > 0) {
            printSOQLLimits('Before Upserting UASBs');
            List<UASB__c> billList = new List<UASB__c>(uasbSet);
            upsert billList Unique_Id__c;
            // connect bill adjustments to UASBs
            printSOQLLimits('After Inserting UASBs');
            for (UASB__c bill : billList) {
                if (adjustmentsToUpdateMap.containsKey(bill.Unique_Id__c)) {
                    List<Bill_Adjustment__c> adjustments = adjustmentsToUpdateMap.get(bill.Unique_Id__c);
                    for (Bill_Adjustment__c adjustment : adjustments) {
                        adjustment.UASB__c = bill.Id;
                    }
                    adjustmentsToUpdateMap.put(bill.Unique_ID__c, adjustments);
                }
            }
            printSOQLLimits('Before Updating Adjustments');
            if(adjustmentsToUpdateMap.size() > 0) {
                List<Bill_Adjustment__c> adjustmentsToUpdate = new List<Bill_Adjustment__c>();
                for (List<Bill_Adjustment__c> adjustments : adjustmentsToUpdateMap.values()) {
                    adjustmentsToUpdate.addAll(adjustments);
                }
                update adjustmentsToUpdate;
            }
            printSOQLLimits('After Updating Adjustments');
        }

    }

    public static UASB__c setUASBFields(Energy_Usage_Update__c prodUpdate,
                                        Schedule_Z_Subscription__c szs,
                                        Decimal nmcRate, 
                                        Decimal systemProduction, 
                                        Decimal systemNMCs){

        Decimal shareOfSystem = szs.Percent_Share__c;

        // Calculate % Share of Production (kWh)
        Decimal subscriptionProduction = ((shareOfSystem/100) * systemProduction).setScale(2, roundingMode.HALF_UP);

        // Calculate Credits Allocated to Customer, either as % of kWh or % of $. Xcel Applies rate in 2 stages:
        Decimal subscriptionNMCs = 0;
        String billingMethod = szs.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Billing_Method__c;
        if (billingMethod == 'NMC'){
            subscriptionNMCs = (shareOfSystem/100) * systemNMCs;
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
                                    Total_System_Size_kW_DC__c = szs.Utility_Account_Subscription__r.Opportunity__r.shared_solar_system__r.Total_System_Size_kWh_DC__c,
                                    NMC_Discount__c = szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.NMC_Discount__c,
                                    NM_Rate_Floor__c = szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.NM_Rate_Floor__c,
                                    Pricing_Structure__c = szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.Pricing_Structure__c,
                                    Solar_Electricity_Rate__c = szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.Solar_Electricity_Rate__c,
                                    NMC_Rate__c = nmcRate,
                                    Total_System_NMCs__c = systemNMCs,
                                    Total_System_Production_kWh__c = systemProduction,
                                    Share_of_System__c = shareOfSystem,
                                    Credits_Allocated__c = subscriptionNMCs.setScale(2, roundingMode.HALF_UP),
                                    Subscription_Production_kWh_Static__c = subscriptionProduction,
                                    Schedule_Z_Subscription__c = szs.Id);
      
        if (billingMethod == 'NMC'){
            generatedUASB.Size_off_NMCs__c = true;
        }

        return generatedUASB;     
    }

}
