/*************************************************************************************
 * Created By: peteryao on 1/20/19  
 * Description: 
 * Tested By: UASSelectorTest
 *************************************************************************************/
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class UASSelector {
    public static List<Utility_Account_Subscription__c> selectByAccounts(Set<Id> accounts) {
        return [
            SELECT Id,
                Subscription_Type__c,
                Annual_kWh_Subscription_Future_Rollup__c,
                Annual_Cost_Future_Rollup__c,
                Utility_Account_Log__r.Account__c,
                Utility_Account_Log__r.Account__r.Id,
                Utility_Account_Log__r.Account__r.Name,
                Utility_Account_Log__r.Account__r.Cancellation_Comments__c,
                Utility_Account_Log__r.Account__r.Send_Bills_Contact__c,
                Utility_Account_Log__r.Account__r.Send_Bills_Contact__r.Email,
                Utility_Account_Log__r.Account__r.Send_Bills_Contact__r.FirstName,
                Utility_Account_Log__r.Account__r.Send_Bills_Contact__r.Additional_Email__c,
                Utility_Account_Log__r.Account__r.Additional_Contact__r.Email,
                Opportunity__r.Product__r.Cancellation_Paragraph_Two__c,
                Opportunity__r.Product__r.Cancellation_Paragraph_Three__c
            FROM Utility_Account_Subscription__c
            WHERE Utility_Account_Log__r.Account__c = :accounts
        ];
    }
    public static List<Utility_Account_Subscription__c> selectByUAL(Set<Id> ualIds) {
        return [
            SELECT Id,
                Utility_Account_Log__c,
                Utility_Account_Log__r.Name,
                Utility_Account_Log__r.Account__c,
                Utility_Account_Log__r.Account__r.Id,
                Utility_Account_Log__r.Account__r.Name,
                Utility_Account_Log__r.Account__r.Send_Bills_Contact__c,
                Utility_Account_Log__r.Account__r.Parent_Account__c
            FROM Utility_Account_Subscription__c
            WHERE Utility_Account_Log__c IN :ualIds
        ];
    }
    public List<Utility_Account_Subscription__c> selectByOpp(Set<Id> oppIds) {
        return [
            SELECT Id,
                Shared_Solar_System__c,
                Next_Schedule_Z_Status__c,
                Annual_Cost_Future_Rollup__c,
                Annual_kWh_Subscription_Future_Rollup__c,
                Future_Customer_Subscription_KWDC_Rollup__c,
                Future_Share_of_System_Rollup__c
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__c IN :oppIds
            AND (Future_Customer_Subscription_KWDC_Rollup__c != 0
            OR Customer_Subscription_KW_DC__c != 0)
        ];
    }
    public static List<Utility_Account_Subscription__c> selectByIds(Set<Id> uasIds) {
        return [
            SELECT Id,
                Name,
                Opportunity__c,
                Opportunity__r.Id,
                Shared_Solar_System__c
            FROM Utility_Account_Subscription__c
            WHERE Id IN :uasIds
        ];
    }
    public Map<Id, Utility_Account_Subscription__c> getUASMap(Set<Id> uasIds) {
        Map<Id, Utility_Account_Subscription__c> uasMap = new Map<Id, Utility_Account_Subscription__c>( [
            SELECT Id,
                Shared_Solar_System__r.Client_Account__c,
                Shared_Solar_System__r.Expected_Yield_kWh_kW__c,
                Shared_Solar_System__r.Total_System_Size_kWh_DC__c,
                Shared_Solar_System__r.Utility__r.Number_of_Decimal_Places__c,
                Opportunity__r.NMC_Tariff__c,
                Opportunity__r.NMC_Tariff__r.Value_of_NMC__c,
                Opportunity__r.Product__c
            FROM Utility_Account_Subscription__c
            WHERE Id IN :uasIds
        ]);
        return uasMap;
	}
    public static Map<Id, Utility_Account_Subscription__c> selectByIdsAsMap(Set<Id> uasIds){
        Map<Id, Utility_Account_Subscription__c> uasWithClientMap = new Map<Id, Utility_Account_Subscription__c>([
            SELECT Id,
                Opportunity__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__c,
                Externally_Serviced__c
            FROM Utility_Account_Subscription__c
            WHERE Id IN : uasIds
        ]);
        return uasWithClientMap;
    }
    public List<AggregateResult> getBrandKeySummary(Set<Id> parentAccountIds) {
        List<AggregateResult> uasSummary = [
            SELECT COUNT(Id) numberOfRecords,
                Opportunity__r.AccountId propertyAccount,
                Opportunity__r.Account.Parent_Account__c parentAccount,
                Opportunity__r.Shared_Solar_System__r.Client_Brand_Key__c sssBrandKey,
                Opportunity__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__r.Client_Brand_Key__c entityBrandKey
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.Account.Parent_Account__c IN : parentAccountIds
            GROUP BY Opportunity__r.AccountId,
                Opportunity__r.Account.Parent_Account__c,
                Opportunity__r.Shared_Solar_System__r.Client_Brand_Key__c,
                Opportunity__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__r.Client_Brand_Key__c
        ];
        return uasSummary;
    }
    public List<Utility_Account_Subscription__c> selectActiveUASBySSS(Set<Id> sssIdList) {
        return [
            SELECT Id,
                Name,
                Annual_Cost_Future_Rollup__c,
                Annual_kWh_Subscription_Future_Rollup__c,
                Customer_Subscription_KW_DC__c,
                Future_Customer_Subscription_KWDC_Rollup__c,
                Future_Share_of_System_Rollup__c,
                Next_Schedule_Z_Status__c,
                Opportunity__c,
                Opportunity_Stage__c,
                Customer_Group__c,
                Opportunity__r.Shared_Solar_System__c,
                Shared_Solar_System__c,
                SSS_Id__c
            FROM Utility_Account_Subscription__c
            WHERE (Opportunity__r.Shared_Solar_System__c IN : sssIdList OR Shared_Solar_System__c IN :sssIdList)
            AND Next_Schedule_Z_Status__c = 'Active Subscription'
            AND (Future_Customer_Subscription_KWDC_Rollup__c != 0 OR Customer_Subscription_KW_DC__c != 0)
        ];
    }

    public List<Utility_Account_Subscription__c> getUASForCloneByOpp(Set<Id> oppIds) {
        String fields = Util.getCreatableFieldsSOQL('Utility_Account_Subscription__c');
        String szStatus = 'Active Subscription';
        String soql = 'SELECT Annual_kWh_Subscription_Future_Rollup__c, Annual_Cost_Future_Rollup__c, Subscription_Type__c, ' +
            'Shared_Solar_System__r.Name,' + fields + ' WHERE Opportunity__c IN :oppIds AND Next_Schedule_Z_Status__c = :szStatus';
        return Database.query(String.escapeSingleQuotes(soql));
    }

    public Map<Id,Decimal> getUASSummaryByOpportunity(Set<Id> oppIds, Boolean useSubscriptionOrders) {
        Map<Id,Decimal> oppToUASSummaryMap = new Map<Id,Decimal>();

        List<AggregateResult> uasSummary = [
            SELECT COUNT(Id) numberOfRecords,
                Opportunity__c opportunityId,
                SUM(Future_Customer_Subscription_KWDC_Rollup__c) postSubOrderkWSize,
                SUM(Customer_Subscription_KW_DC__c) preSubOrderkWSize
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__c IN : oppIds
            AND Next_Schedule_Z_Status__c = 'Active Subscription'
            GROUP BY Opportunity__c
        ];
        for (AggregateResult uasAgg : uasSummary){
            Id opportunityId = (Id)uasAgg.get('opportunityId');
            if (useSubscriptionOrders) {
                oppToUASSummaryMap.put(opportunityId,(Decimal)uasAgg.get('postSubOrderkWSize'));
            } else {
                oppToUASSummaryMap.put(opportunityId,(Decimal)uasAgg.get('preSubOrderkWSize'));
            }
        }
        return oppToUASSummaryMap;
    }
}