/**
 * @description Created by: Kristin White on 10/19/2020
 * Tested by: UtilityDataRequestServiceTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class UtilityDataRequestSelector {

    public Map<Id, Utility_Data_Request__c> selectMapForKWHById(List<Utility_Data_Request__c> udrList) {
        Map<Id, Utility_Data_Request__c> selectedUDRs = new Map<Id, Utility_Data_Request__c>([
            SELECT Id, Name, Annual_kWh__c, Request_Status_new__c, State__c, Utility__c, Average_Demand__c,
                Utility_Account_Log__c, Account_Number__c, Account_Type__c, Utility_Account_Log__r.Service_State__c,
                Utility_Account_Log__r.Lead__r.Product__r.X4_month_sizing_method__c, Customer_Name__c, Zip_Code__c,
                Utility_Account_Log__r.Lead__r.Customer_type__c, Num_UDRPs_Avg_Demand__c, City__c,
                Old_Account_Number__c, Num_UDRPs_Annual_kWh__c, Address_Line_1__c, Address_Line_2__c,
                Government_Credit_Code__c, LDC_Customer_Eligibility__c, Service_Provider__c
            FROM Utility_Data_Request__c
            WHERE Id IN :(udrList)
        ]);
        return selectedUDRs;
    }

    public List<Utility_Data_Request__c> selectUdrsForErrorCase(Set<Id> udrIds) {
        return [
            SELECT Id, Exception_Reason_Code__c, Utility_Account_Log__r.Lead__c, Utility_Account_Log__r.Lead__r.Name,
                Utility_Account_Log__r.Lead__r.Partner_Account__c, Utility_Account_Log__r.Lead__r.Sales_Person__c,
                Utility_Account_Log__r.Name, Utility_Account_Log__r.Lead__r.IsConverted
            FROM Utility_Data_Request__c
            WHERE Id IN :udrIds
        ];
    }

    public static List<Utility_Data_Request__c> getRelatedUdrsByUal(Set<Id> ualIds) {
        return [
            SELECT Id, Detail_Status__c, Request_Status_new__c, Header_Status__c, Utility_Account_Log__c
            FROM Utility_Data_Request__c
            WHERE Utility_Account_Log__c IN :ualIds
            AND Request_Status_new__c IN ('Pending', 'Sent', 'Partial Data Received', 'Data Received')
        ];
    }

    public Set<Id> getUtilityDataRequestsWithOpenErrorCases(List<Utility_Data_Request__c> erroredUtilityDataRequests) {
        Set<Id> udrsWithOpenErrorCases = new Set<Id>();
        Map<Id, Id> leadIdToUdrId = new Map<Id, Id>();
        for (Utility_Data_Request__c udr : erroredUtilityDataRequests) {
            leadIdToUdrId.put(udr.Utility_Account_Log__r.Lead__c, udr.Id);
        }
        List<Case> openCasesForEDIErrors = [
            SELECT Lead_Lookup__c
            FROM Case
            WHERE Lead_Lookup__c IN :leadIdToUdrId.keySet()
            AND QC_Case_Subject__c = :CaseFactory.ediErrorQCSubject
            AND IsClosed = FALSE
        ];
        for (Case c : openCasesForEDIErrors) {
            udrsWithOpenErrorCases.add(leadIdToUdrId.get(c.Lead_Lookup__c));
        }
        return udrsWithOpenErrorCases;
    }
}