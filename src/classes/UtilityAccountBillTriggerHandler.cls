public with sharing class UtilityAccountBillTriggerHandler {
    public void createUASB(List<Utility_Account_Bill__c> utilityAccountBillList){
        Map<Id, Utility_Account_Bill__c> utilityAccountLogIdToUABMap = new Map<Id, Utility_Account_Bill__c>();
        Map<string, System_Bill__c > systemBillMap = new Map<string, System_Bill__c >();
        Map<String, Bill_Adjustment__c > adjustmentMap = new Map<String, Bill_Adjustment__c >();
        Map<String, Bill_Adjustment__c> adjustmentsToUpdateMap = new Map<String, Bill_Adjustment__c>();
        List<Bill_Adjustment__c> adjustmentsToAddList = new List<Bill_Adjustment__c>();
        Map<String, System_Bill__c> systemBillstoUpdateMap = new Map<String, System_Bill__c>();

        for(Utility_Account_Bill__c uab : utilityAccountBillList){
            if (!uab.Published__c){
                utilityAccountLogIdToUABMap.put(uab.Utility_Account_Log__c, uab);
            }
        }

        List<Bill_Adjustment__c> adjustmentList = [ SELECT Id, Name, UASB__c,
                                                Utility_Account_Subscription__c, 
                                                Adjustment_Amount__c, Discounted_Bill__c,
                                                Utility_Account_Subscription__r.Id
                                                FROM Bill_Adjustment__c
                                                WHERE Utility_Account_Subscription__r.Utility_Account_Log__c
                                                IN : utilityAccountLogIdToUABMap.keySet()
                                                AND Applied_to_Bill__c = false 
                                                AND Overpayment__c = false
                                                ORDER BY CreatedDate]; 

        for(System_Bill__c systemBill : [   SELECT Id, Name, Unique_Id__c, Date__c, 
                                            Opportunity__r.Name,
                                            Opportunity__r.Shared_Solar_System__r.Name
                                            FROM System_Bill__c 
                                            WHERE Id != null]){
            systemBillMap.put(systemBill.Unique_Id__c, systemBill);
        }        
        Set<UASB__c> uasbSet = new Set<UASB__c>();
        for(Utility_Account_Subscription__c uas : [ SELECT Id, Name, Customer_Subscription_KW_DC_STATIC__c,
                                                            Customer_Subscription_KW_DC__c, 
                                                            Opportunity__c, 
                                                            Opportunity__r.Name,
                                                            Opportunity__r.Shared_Solar_System__r.Name,
                                                            Opportunity__r.Product__r.NMC_Discount__c,
                                                            Opportunity__r.Product__r.NM_Rate_Floor__c,
                                                            Opportunity__r.Product__r.Solar_Electricity_Rate__c,
                                                            Opportunity__r.Product__r.Pricing_Structure__c,
                                                            UAS_Number__c,
                                                            Share_of_System__c ,                                                            
                                                            Utility_Account_Log__c,
                                                            Opportunity__r.Shared_Solar_System__r.Total_System_Size_kwh_dc__c, 
                                                            Opportunity__r.NMC_Value__c, 
                                                            Opportunity__r.Shared_Solar_System__c
                                                    FROM Utility_Account_Subscription__c 
                                                    WHERE Utility_Account_Log__c != null 
                                                    AND Opportunity__c != null 
                                                    AND Opportunity__r.StageName = 'Complete'          
                                                    AND Next_Schedule_Z_Status__c != 'Not Enacted: Addition'     
                                                    AND Next_Schedule_Z_Status__c != 'Cancelled'                                      
                                                    AND Utility_Account_Log__c IN : utilityAccountLogIdToUABMap.keySet()
                                                    ORDER BY UAS_Number__c]){
            if(utilityAccountLogIdToUABMap.containsKey(uas.Utility_Account_Log__c)){
                Utility_Account_Bill__c uab = utilityAccountLogIdToUABMap.get(uas.Utility_Account_Log__c);
                string systemBillKey = uas.Opportunity__r.Name + ' ' + uas.Opportunity__r.Shared_Solar_System__r.Name + ' ' + DateTime.newInstance(uab.Date__c.year(), uab.Date__c.month(),uab.Date__c.day()).format('yyyy-MM');
                
                if(uab.Shared_Solar_System__c == uas.Opportunity__r.Shared_Solar_System__c){
                    UASB__c uasb = setUASBFields(uas, uab, systemBillMap, systemBillKey);
                    uasb.NMC_Rate__c = uab.Net_Metering_Rate_Applied__c;
                    uasb.Total_System_Production_kWh__c = uab.Production_kWh_DC__c;                                                                                     
                    uasb.Total_System_NMCs__c = uab.Total_System_NMCs__c;
                    uasb.Unique_Id__c = uas.Opportunity__r.Shared_Solar_System__c + ' - ' + uas.Id + ' - ' + DateTime.newInstance(uab.Date__c.year(), uab.Date__c.month(),uab.Date__c.day()).format('yyyy-MM');
                    for (Bill_Adjustment__c adjust : adjustmentList) {
                        if (uasb.Adjustment_Amount__c == NULL) {
                            uasb.Adjustment_Amount__c = 0;
                        }
                        if (adjust.Utility_Account_Subscription__r.Id == uasb.Utility_Account_Subscription__c){
                            uasb.Adjustment_Amount__c = uasb.Adjustment_Amount__c + adjust.Adjustment_Amount__c;
                            adjustmentsToUpdateMap.put(uasb.Unique_Id__c, adjust);
                        }
                    }
                    uasbSet.add(uasb);
                    if (uab.Total_System_NMCs_2_of_4__c > 0) {
                        UASB__c uasbTwo = setUASBFields(uas, uab, systemBillMap, systemBillKey);
                        uasbTwo.NMC_Rate__c = uab.Net_Metering_Rate_Applied_2_of_4__c;
                        uasbTwo.Total_System_Production_kWh__c = uab.Production_kWh_2_of_4__c;                                                                                       
                        uasbTwo.Total_System_NMCs__c = uab.Total_System_NMCs_2_of_4__c;
                        uasbTwo.Unique_Id__c = uas.Opportunity__r.Shared_Solar_System__c + ' - ' + uas.Id + ' - ' + DateTime.newInstance(uab.Date__c.year(), uab.Date__c.month(),uab.Date__c.day()).format('yyyy-MM') + 'A';
                        uasbSet.add(uasbTwo);
                        if (uab.Total_System_NMCs_3_of_4__c > 0) {
                            UASB__c uasbThree = setUASBFields(uas, uab, systemBillMap, systemBillKey);
                            uasbThree.NMC_Rate__c = uab.Net_Metering_Rate_Applied_3_of_4__c;
                            uasbThree.Total_System_Production_kWh__c = uab.Production_kWh_3_of_4__c;                                                                                       
                            uasbThree.Total_System_NMCs__c = uab.Total_System_NMCs_3_of_4__c;
                            uasbThree.Unique_Id__c = uas.Opportunity__r.Shared_Solar_System__c + ' - ' + uas.Id + ' - ' + DateTime.newInstance(uab.Date__c.year(), uab.Date__c.month(),uab.Date__c.day()).format('yyyy-MM') + 'B';
                            uasbSet.add(uasbThree);
                            if (uab.Total_System_NMCs_4_of_4__c > 0) {
                                UASB__c uasbFour = setUASBFields(uas, uab, systemBillMap, systemBillKey);
                                uasbFour.NMC_Rate__c = uab.Net_Metering_Rate_Applied_4_of_4__c;
                                uasbFour.Total_System_Production_kWh__c = uab.Production_kWh_4_of_4__c;                                                                                       
                                uasbFour.Total_System_NMCs__c = uab.Total_System_NMCs_4_of_4__c;
                                uasbFour.Unique_Id__c = uas.Opportunity__r.Shared_Solar_System__c + ' - ' + uas.Id + ' - ' + DateTime.newInstance(uab.Date__c.year(), uab.Date__c.month(),uab.Date__c.day()).format('yyyy-MM') + 'C';
                                uasbSet.add(uasbFour);
                            }
                        }
                    } 
                }
            }
        }
        if(uasbSet.size() > 0) {
            List<UASB__c> billList = new List<UASB__c>(uasbSet);
            upsert billList Unique_Id__c;

            for (UASB__c bill : billList) {
                if (adjustmentsToUpdateMap.containsKey(bill.Unique_Id__c)) {
                    adjustmentsToUpdateMap.get(bill.Unique_Id__c).UASB__c = bill.Id;
                }
            }

            if(adjustmentsToUpdateMap.size() > 0) {
                update adjustmentsToUpdateMap.Values();
            }
        }
    }

    public static UASB__c setUASBFields(Utility_Account_Subscription__c uas, Utility_Account_Bill__c uab, Map<string, System_Bill__c> systemBillMap, String systemBillKey){
        UASB__c generatedUASB = new UASB__c( Name = uab.Name + uas.Opportunity__r.Shared_Solar_System__r.Name,
                                    Customer_Subscription_KW_DC__c = uas.Customer_Subscription_KW_DC_STATIC__c,
                                    CS_Billing_Log__c = uab.Id, 
                                    Date__c = uab.Date__c,
                                    Production_Update__c = uab.Production_Update__c,
                                    Utility_Account_Subscription__c = uas.Id,  
                                    System_Bill__c = systemBillMap.get(systemBillKey).Id,
                                    Opportunity__c = uas.Opportunity__c,
                                    Shared_Solar_System__c = uas.Opportunity__r.Shared_Solar_System__c,
                                    Billing_Period_Start_Date__c = uab.Billing_Period_Start_Date__c,
                                    Billing_Period_End_Date__c = uab.Billing_Period_End_Date__c,
                                    Total_System_Size_kW_DC__c = uas.Opportunity__r.shared_solar_system__r.Total_System_Size_kWh_DC__c,
                                    NMC_Discount__c = uas.Opportunity__r.Product__r.NMC_Discount__c,
                                    NM_Rate_Floor__c = uas.Opportunity__r.Product__r.NM_Rate_Floor__c,
                                    Pricing_Structure__c = uas.Opportunity__r.Product__r.Pricing_Structure__c,
                                    Solar_Electricity_Rate__c = uas.Opportunity__r.Product__r.Solar_Electricity_Rate__c,
                                    Size_off_NMCs__c = uab.Size_off_NMCs__c,
                                    Share_of_System__c = uas.Share_of_System__c);
        return generatedUASB;     
    }

}