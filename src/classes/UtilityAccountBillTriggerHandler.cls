/*************************************************************************************
 * Created By:
 * Description:
 * Test: TestBillCreationandPayment, MultipleMonthProductionUpdateTest
 *************************************************************************************/

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class UtilityAccountBillTriggerHandler {
    public static Map<Id, List<Product_Escalator__c>> productEscalatorMap;

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public void createUASB( Map<Id, List<Transfer__c>> sssToTransfersMap,
                            Map<String, System_Bill__c > systemBillMap, 
                            Map<Id, Utility_Account_Bill__c> utilityAccountLogIdToUABMap, 
                            List<Utility_Account_Subscription__c> uasList,
                            Map<Id, List<Product_Escalator__c>>  productEscalationMap ){

        Set<Id> scheduleZIds = new Set<Id>();
        for(List<Transfer__c> transferList : sssToTransfersMap.values( )) {
            for (Transfer__c transfer : transferList) {
                scheduleZIds.add(transfer.Allocation_Schedule__c);
           }
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
                Utility_Account_Subscription__r.Externally_Serviced__c,
                Utility_Account_Subscription__r.Share_of_System__c ,
                Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Count_of_Transfers__c,
                Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Total_System_Size_kwh_dc__c,
                Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Billing_Method__c,
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

                List<Transfer__c> transferList = sssToTransfersMap.get(uas.Opportunity__r.Shared_Solar_System__r.Id);
                Integer transferCount = 0 ;

                //TODO: Check if UAS.Credit Value is populated --> if so, use that value,
                // if not populated, use the transfer's default value

                String systemBillKey = uas.Opportunity__r.Id + ' ' + uas.Opportunity__r.Shared_Solar_System__r.Name + ' ' + DateTime.newInstance(uab.Date__c.year(), uab.Date__c.month(),uab.Date__c.day()).format('yyyy-MM');
                System_Bill__c systemBill = systemBillMap.get(systemBillKey);

                if (systemBill != null){
                    for (Transfer__c transfer : transferList ) {
                        transferCount += 1;
                        try {
                            UASB__c uasb = catchCancelledUASes(
                                transfer,
                                uas,
                                scheduleZSubscriptionToUABIdMap,
                                transferCount,
                                transfer.Default_Credit_Value__c,
                                transfer.Attempted_kWh_Transfer__c,
                                transfer.Attempted_Transfer__c
                            );
                            //TODO: setting the unique ID in this way limits us from using a copy sandbox (Unique ID will not match Transfer after scramble)
                            // currently used on Account Bill and System Bill for upserts - going to have effect after Zuora?
                            uasb.Unique_Id__c = uas.Opportunity__r.Shared_Solar_System__c + ' - ' + uas.Id + ' - ' + transfer.Id;
                            uasb.CS_Billing_Log__c = uab.Id;
                            uasb.System_Bill__c = systemBill.Id;

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
                                                            Decimal productionCount){
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
                if (escalator.Starting_Credit_Transfer__c <= productionCount) {
                    activeEscalator = escalator;
                    break;
                }
            }
        }
        return activeEscalator;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static UASB__c catchCancelledUASes(  Transfer__c transfer,
                                                Utility_Account_Subscription__c uas,
                                                Map<Id, Schedule_Z_Subscription__c> scheduleZSubscriptionToUABIdMap,
                                                Decimal productionCount,
                                                Decimal nmcRate,
                                                Decimal systemProduction,
                                                Decimal systemNMCs){
        UASB__c uasbToCreate;

        if ( scheduleZSubscriptionToUABIdMap.containsKey(uas.Id)){
            uasbToCreate = setUASBFields(transfer, scheduleZSubscriptionToUABIdMap.get(uas.Id), productionCount, nmcRate, systemProduction, systemNMCs);
        } else {
            // Zero dollar bill for cancelled customers:
            uasbToCreate = new UASB__c(
                Date__c = transfer.Bill_Period__r.Bill_Date__c,
                Transfer__c = transfer.Id,
                Utility_Account_Subscription__c = uas.Id,
                Opportunity__c = uas.Opportunity__c,
                Shared_Solar_System__c = uas.Opportunity__r.Shared_Solar_System__c,
                Billing_Period_Start_Date__c = transfer.Date_of_Transfer__c,
                Billing_Period_End_Date__c = transfer.Date_of_Transfer__c.addMonths(1),
                Externally_Serviced__c = uas.Externally_Serviced__c,
                Total_System_NMCs__c = 0,
                Total_System_Production_kWh__c = 0,
                NMC_Rate__c = 0,
                Share_of_System__c = 0,
                Credits_Allocated__c = 0);
        }

        return uasbToCreate;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static UASB__c setUASBFields(Transfer__c transfer,
                                        Schedule_Z_Subscription__c szs,
                                        Decimal productionCount,
                                        Decimal nmcRate,
                                        Decimal systemProduction, 
                                        Decimal systemNMCs){

        productionCount =  productionCount + szs.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Count_of_Transfers__c;
        Product_Escalator__c escalatorProduct = getProductEscalator(szs, productionCount);
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
                                    Date__c = transfer.Bill_Period__r.Bill_Date__c,
                                    Transfer__c = transfer.Id,
                                    Utility_Account_Subscription__c = szs.Utility_Account_Subscription__r.Id,
                                    Opportunity__c = szs.Utility_Account_Subscription__r.Opportunity__c,
                                    Shared_Solar_System__c = szs.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__c,
                                    Billing_Period_Start_Date__c = transfer.Date_of_Transfer__c,
                                    Billing_Period_End_Date__c = transfer.Date_of_Transfer__c.addMonths(1),
                                    Externally_Serviced__c = szs.Utility_Account_Subscription__r.Externally_Serviced__c,
                                    NMC_Discount__c = szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.NMC_Discount__c,
                                    Total_System_Size_kW_DC__c = szs.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Total_System_Size_kWh_DC__c,
                                    NM_Rate_Floor__c = szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.NM_Rate_Floor__c,
                                    Pricing_Structure__c = szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.Pricing_Structure__c,
                                    Solar_Electricity_Rate__c = szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.Solar_Electricity_Rate__c,
                                    NMC_Rate__c = nmcRate,
                                    Share_of_System__c = shareOfSystem,
                                    Credits_Allocated__c = subscriptionNMCs,
                                    Total_System_NMCs__c = systemNMCs,
                                    Total_System_Production_kWh__c = systemProduction,
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