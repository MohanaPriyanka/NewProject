/* Created by Jordan Pentaleri on 2/11/19
Description: place to hold queries for production updates
Tests: ProductionUpdateSelectorTest
*/

public class ProductionUpdateSelector {
    public static List<Energy_Usage_Update__c> getProductionUpdatesByMonth(Integer billMonth, String billYear) {
        return [
            SELECT Name, Id, Shared_Solar_System__c, Schedule_Z__c,
            YearDate__c, Credits_on_Bill_Period__c,
            MonthDate__c, Total_System_NMCs__c, Production__c,
            Generate_Bills__c, Total_System_NMCs_2_of_4__c,
            Total_System_NMCs_3_of_4__c, Production_kWh_2_of_4__c,
            Production_kWh_3_of_4__c, Total_System_NMCs_4_of_4__c,
            Production_kWh_4_of_4__c, Net_Metering_Rate_Applied__c,
            Billing_Method__c, Date__c, Billing_Period_Start_Date__c,
            Billing_Period_End_Date__c, Month_Number__c, Year__c,
            Net_Metering_Rate_Applied_2_of_4__c,
            Net_Metering_Rate_Applied_3_of_4__c,
            Net_Metering_Rate_Applied_4_of_4__c,
            Shared_Solar_System__r.Name,
            Schedule_Z__r.Name, Bill_Status__c
            FROM Energy_Usage_Update__c
            WHERE Month_Number__c = : billMonth
            AND YearDate__c = : billYear
            ORDER BY Name, Generate_Bills__c
        ];
    }

    public static List<Energy_Usage_Update__c> getAllProductionUpdatesById(List<Id> prodUpdateIdList) {
        return [
            SELECT Name, Id, Shared_Solar_System__c, Schedule_Z__c,
                YearDate__c, Credits_on_Bill_Period__c,
                MonthDate__c, Total_System_NMCs__c, Production__c,
                Generate_Bills__c, Total_System_NMCs_2_of_4__c,
                Total_System_NMCs_3_of_4__c, Production_kWh_2_of_4__c,
                Production_kWh_3_of_4__c, Total_System_NMCs_4_of_4__c,
                Production_kWh_4_of_4__c, Net_Metering_Rate_Applied__c,
                Billing_Method__c, Date__c, Billing_Period_Start_Date__c,
                Billing_Period_End_Date__c, Month_Number__c, Year__c,
                Net_Metering_Rate_Applied_2_of_4__c,
                Net_Metering_Rate_Applied_3_of_4__c,
                Net_Metering_Rate_Applied_4_of_4__c,
                Shared_Solar_System__r.Name,
                Schedule_Z__r.Name, Bill_Status__c
            FROM Energy_Usage_Update__c
            WHERE Id IN : prodUpdateIdList
        ];
    }
}