/*************************************************************************************
 * Created By: peteryao on 1/20/19  
 * Description: 
 * Tested By: UASSelectorTest
 *************************************************************************************/
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class UASSelector {
    @TestVisible private static List<Utility_Account_Subscription__c> mockedUASes;

    public static List<Utility_Account_Subscription__c> selectUASesByAccounts(Set<Id> accounts) {
        return [
            SELECT Id,
                Subscription_Type__c,
                Annual_kWh_Subscription_Future_Rollup__c,
                Future_Customer_Subscription_KWDC_Rollup__c,
                Annual_Cost_Future_Rollup__c,
                Utility_Account_Log__r.Account__c,
                Utility_Account_Log__r.Account__r.Id,
                Utility_Account_Log__r.Account__r.Name,
                Utility_Account_Log__r.Account__r.Client_Brand_Key__c,
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
            AND Future_Customer_Subscription_KWDC_Rollup__c != 0
        ];
    }
    public static List<Utility_Account_Subscription__c> selectByUAL(Set<Id> ualIds) {
        return [
            SELECT Id,
                Subscription_Type__c,
                Annual_kWh_Subscription_Future_Rollup__c,
                Future_Customer_Subscription_KWDC_Rollup__c,
                Annual_Cost_Future_Rollup__c,
                Utility_Account_Log__r.Name,
                Utility_Account_Log__r.Account__c,
                Utility_Account_Log__r.Account__r.Id,
                Utility_Account_Log__r.Date_Utility_Account_Cancelled__c,
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

    /**
     * @description Includes the last approved Subscription Order to check if a cancelled UAS is being transferred
     * @param uasIds Set of UAS Ids to select
     * @return List of UASes
     */
    public static List<Utility_Account_Subscription__c> selectByIds(Set<Id> uasIds) {
        if (mockedUASes != null) {
            return mockedUASes;
        }
        return [
            SELECT Id,
                Name,
                Opportunity__c,
                Opportunity__r.Id,
                Shared_Solar_System__c,
                Subscription_Type__c,
                Sizing_Method__r.Size_Ratio__c,
                Sizing_Method__r.Value_of_NMC__c,
                Future_Customer_Subscription_KWDC_Rollup__c,
                Annual_kWh_Subscription_Future_Rollup__c,
                Annual_Cost_Future_Rollup__c, (
                SELECT Id, Type__c, Previous_kw_DC_Subscription__c
                FROM Subscription_Orders__r
                WHERE Approval_Status__c = 'Approved'
                ORDER BY Effective_Date__c DESC
                LIMIT 1
            )
            FROM Utility_Account_Subscription__c
            WHERE Id IN :uasIds
        ];
    }
    public Map<Id, Utility_Account_Subscription__c> getUASMap(Set<Id> uasIds) {
        Map<Id, Utility_Account_Subscription__c> uasMap = new Map<Id, Utility_Account_Subscription__c>( [
            SELECT Id,
                Annual_Cost_Future_Rollup__c,
                Annual_kWh_Subscription_Future_Rollup__c,
                Future_Customer_Subscription_KWDC_Rollup__c,
                Future_Share_of_System_Rollup__c,
                Sizing_Method__c,
                Sizing_Method__r.Size_Ratio__c,
                Sizing_Method__r.Value_of_NMC__c,
                Shared_Solar_System__r.Client_Account__c,
                Shared_Solar_System__r.Expected_Yield_kWh_kW__c,
                Shared_Solar_System__r.Total_System_Size_kWh_DC__c,
                Shared_Solar_System__r.Utility__r.Number_of_Decimal_Places__c,
                Opportunity__r.NMC_Tariff__c,
                Opportunity__r.NMC_Tariff__r.Value_of_NMC__c,
                Opportunity__r.Product__c,
                Opportunity__r.Product__r.Customer_Subscription_Type__c
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
                Opportunity__r.Customer_Sub_Group__c,
                Opportunity__r.ContractId,
                Shared_Solar_System__c,
                SSS_Id__c
            FROM Utility_Account_Subscription__c
            WHERE (Opportunity__r.Shared_Solar_System__c IN : sssIdList OR Shared_Solar_System__c IN :sssIdList)
            AND Next_Schedule_Z_Status__c = 'Active Subscription'
            AND (Future_Customer_Subscription_KWDC_Rollup__c != 0 OR Customer_Subscription_KW_DC__c != 0)
        ];
    }

    @SuppressWarnings('PMD.ApexSOQLInjection')
    public List<Utility_Account_Subscription__c> getUASForCloneByOpp(Set<Id> oppIds) {
        String fields = Util.getCreatableFieldsSOQL('Utility_Account_Subscription__c');
        String soql = 'SELECT Annual_kWh_Subscription_Future_Rollup__c, Annual_Cost_Future_Rollup__c, Subscription_Type__c, ' +
            'Future_Customer_Subscription_KWDC_Rollup__c, Shared_Solar_System__r.Name, Sizing_Method__r.Size_Ratio__c, ' +
            'Sizing_Method__r.Value_of_NMC__c, (\n' +
            '  SELECT Id, Type__c, Previous_kw_DC_Subscription__c\n' +
            '  FROM Subscription_Orders__r\n' +
            '  WHERE Approval_Status__c = \'Approved\'\n' +
            '  ORDER BY Effective_Date__c DESC\n' +
            '  LIMIT 1\n' +
            '), \n' +
            fields +
            ' WHERE Opportunity__c IN :oppIds AND Next_Schedule_Z_Status__c = \'Active Subscription\'';
        return Database.query(soql);
    }

    public Map<Id,Decimal> getUASSummaryByOpportunity(Set<Id> oppIds) {
        Map<Id,Decimal> oppToUASSummaryMap = new Map<Id,Decimal>();

        List<AggregateResult> uasSummary = [
            SELECT COUNT(Id) numberOfRecords,
                Opportunity__c opportunityId,
                SUM(Future_Customer_Subscription_KWDC_Rollup__c) kWTotal
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__c IN : oppIds
            AND Next_Schedule_Z_Status__c = 'Active Subscription'
            GROUP BY Opportunity__c
        ];
        for (AggregateResult uasAgg : uasSummary){
            Id opportunityId = (Id)uasAgg.get('opportunityId');
            oppToUASSummaryMap.put(opportunityId,(Decimal)uasAgg.get('kWTotal'));
        }
        return oppToUASSummaryMap;
    }

    public List<Utility_Account_Subscription__c> getUASesForAssignmentAgreement(Id assignmentAgreementId) {
        return [
            SELECT Id,
                Name,
                Opportunity__c,
                Opportunity__r.Id,
                Opportunity__r.Shared_Solar_System__r.Name,
                Opportunity__r.Name,
                Opportunity__r.ContractId,
                Opportunity__r.Contract.Assignment_Agreement__c,
                Opportunity__r.Contract.Parent_Contract__c,
                Opportunity__r.Personal_Credit_Report2__c,
                Utility_Account_Log__r.Name
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.Contract.Assignment_Agreement__c = : assignmentAgreementId
            AND Next_Schedule_Z_Status__c = 'Active Subscription'
        ];
    }

    public List<Utility_Account_Subscription__c> getNonAnchorUASesForAllocationSchedule(Id allocationScheduleId) {
        return [
            SELECT Id,
                Name,
                Opportunity__c,
                Opportunity__r.Id,
                Opportunity__r.Shared_Solar_System__r.Name,
                Opportunity__r.Account.Name,
                Opportunity__r.Name,
                Opportunity__r.ContractId,
                Opportunity__r.Contract.Assignment_Agreement__c,
                Opportunity__r.Contract.Parent_Contract__c,
                Opportunity__r.Personal_Credit_Report2__c,
                Utility_Account_Log__r.Name,
                Utility_Account_Log__r.Name_on_Account__c
            FROM Utility_Account_Subscription__c
            WHERE Next_Schedule_Z_Status__c = 'Active Subscription'
            AND Id IN
            (SELECT Utility_Account_Subscription__c
            FROM Schedule_Z_Subscription__c
            WHERE Schedule_Z__c =: allocationScheduleId
            AND Utility_Account_Subscription__r.Opportunity__r.Customer_Group__c != 'Anchor')
        ];
    }
}