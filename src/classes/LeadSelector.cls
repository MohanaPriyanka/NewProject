/*************************************************************************************
 * Created By: peteryao on 2019-04-30
 * Description:
 * Test: LeadSelectorTest
 *************************************************************************************/
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.ApexDoc')
public without sharing class LeadSelector {
    public List<String> apiLeadFields = new List<String>{
        'FirstName',
        'LastName',
        'Email',
        'Application_Complete_Date__c',
        'Application_Type__c',
        'Business_Phone__c',
        'Business_Title__c',
        'bs_Sales_ID__c',
        'City',
        'Company',
        'Continue_Application_Link__c',
        'Customer_Referral__c',
        'Customer_type__c',
        'LASERCA__Home_Address__c',
        'LASERCA__Home_City__c',
        'LASERCA__Home_State__c',
        'LASERCA__Home_Zip__c',
        'LeadSource',
        'LoadZone__c',
        'Manual_Campaign_ID__c',
        'MobilePhone',
        'Parcel_Zip__c',
        'Partner_lookup__c',
        'Partner_Email__c',
        'Phone',
        'PostalCode',
        'Privacy_Policy_Acknowledged__c',
        'Product__c',
        'Product_Line__c',
        'Referral_Name__c',
        'Referral_Email__c',
        'Status',
        'State',
        'Street',
        'Terms_Conditions__c',
        'Utility_relationship__c',
        'Zuora_Payment_Ref_Id__c',
        'Zuora_Payment_Ref_Id_Expiration_Date__c'
    };

    public List<String> apiPropertyAccountFields = new List<String>{
        'Id', 
        'Lead__c', 
        'Name', 
        'BillingStreet', 
        'BillingCity', 
        'BillingStateCode', 
        'BillingPostalCode', 
        'Zuora_Payment_Ref_Id__c', 
        'Zuora_Payment_Ref_Id_Expiration_Date__c'
    };

    public List<String> apiUtilityAccountFields = new List<String>{
        'Id', 
        'Account__c', 
        'Name', 
        'Name_on_Account__c', 
        'Service_Address__c', 
        'Service_City__c', 
        'Service_State__c', 
        'Service_Zip_Code__c', 
        'Annual_kWh__c', 
        'Annual_Cost_of_Electricity__c'
    };


    public static List<Lead> selectConvertedByIds(List<Id> leadIds) {
        return [
            SELECT Id, ConvertedAccountId, Zuora_Payment_Ref_Id__c, Zuora_Payment_Ref_Id_Expiration_Date__c
            FROM Lead
            WHERE Id IN :leadIds
            AND ConvertedAccountId != NULL
        ];
    }

    public Lead selectOne(Id leadId) {
        List<Lead> leads = this.selectAll(new Set<Id>{leadId});
        if (leads.isEmpty()) {
            return null;
        }
        return leads[0];
    }


    public List<Lead> selectAll(Set<Id> leadIds) {
        return [
            SELECT 
                Id, 
                Application_Complete_Date__c,
                Application_Type__c, 
                bs_Sales_ID__c, 
                Business_Phone__c, 
                Business_Title__c, 
                City, 
                Company, 
                Continue_Application_Link__c,
                Contract_eSign_Link__c,
                CreatedDate,
                Customer_Referral__c, 
                Customer_Signed_Date__c, 
                Customer_type__c, 
                Email, 
                FirstName, 
                Generate_Docs_for_Review__c,
                LASERCA__Home_Address__c, 
                LASERCA__Home_City__c,
                LASERCA__Home_State__c, 
                LASERCA__Home_Zip__c, 
                LastName,
                LeadSource,
                LoadZone__c,
                Manual_Campaign_ID__c, 
                MobilePhone,
                Name,
                Parcel_Zip__c,
                Parent_Account__c,
                Partner_Email__c,
                Partner_Account__c,
                Partner_Account__r.Name,
                Partner_Lookup__c, 
                Partner_Lookup__r.Id, 
                Phone, 
                PostalCode, 
                Privacy_Policy_Acknowledged__c,  
                Product_line__c, 
                Product__c,
                Product__r.Id, 
                Product__r.Name, 
                Product__r.Generic_Terms_Conga_Template__c,
                Referral_Email__c,
                Referral_Name__c, 
                State, 
                Status, 
                Street,
                Underwriting_Criteria__c,
                Utility_relationship__r.Id, 
                Utility_relationship__r.EIA_ID__c, 
                Utility_relationship__r.Name, 
                Terms_Conditions__c, 
                Zuora_Payment_Ref_Id__c,
                Zuora_Payment_Ref_Id_Expiration_Date__c,
                (SELECT Id FROM Underwrite_Financial_Documents__r)
            FROM Lead
            WHERE Id = :leadIds
        ];
    }

    public Lead selectOneWithPropertiesAndUtilities(Id leadId) {
        String query = 'SELECT ' + String.join(apiLeadFields, ', ') + ', CreatedDate, Product__r.Name, Customer_Signed_Date__c, Utility_relationship__r.EIA_ID__c, Underwriting_Criteria__c';
        query += ', (SELECT ' + String.join(apiPropertyAccountFields, ', ') + ' FROM Accounts__r)';
        query += ', (SELECT ' + String.join(apiUtilityAccountFields, ', ') + ', Utility_lookup__c, Utility_Rate_Class__c, Utility_Rate_Class__r.Name FROM Utility_Account_Logs__r)';
        query += ', (SELECT Id FROM Contracts__r)';
        query += ', (SELECT Id FROM Underwrite_Financial_Documents__r)';
        query += ' FROM Lead WHERE Id = :leadId LIMIT 1';
        return Database.query(String.escapeSingleQuotes(query));
    }

    public List<Lead> selectForMerge(Set<Id> leadIds) {
        String fields = String.join(apiLeadFields, ', ');
        String query = 'SELECT ' + fields + ' FROM Lead ' + ' WHERE Id IN :leadIds ORDER BY CreatedDate ASC';
        List<Lead> leadList = Database.query(String.escapeSingleQuotes(query));
        return leadList;
    }

    public Lead selectOneForContractCreation(Id leadId) {
        List<Lead> leads = [
            SELECT Id, Customer_Signed_Date__c, Product__c, Product__r.Generic_Terms_Conga_Template__c,
                (SELECT Id FROM Accounts__r ORDER BY CreatedDate ASC LIMIT 1)
            FROM Lead WHERE Id = :leadId
        ];

        if(leads.isEmpty()) {
            return null;
        }

        return leads[0];
    }

    public Lead selectOneForStatusUpdate(Id leadId) {
        List<Lead> leads = [
            SELECT Id, Application_Complete_Date__c, Application_Status__c, Continue_Application_Link__c, Contract_eSign_Link__c,
                (SELECT Id FROM Accounts__r),
                (SELECT Id, Utility_lookup__r.Utility_Data_Collection_Mechanism__c FROM Utility_Account_Logs__r),
                (SELECT Id, Customer_Signature_Date_Time__c FROM Contracts__r)
            FROM Lead
            WHERE Id = :leadId
        ];

        if (leads.isEmpty()) {
            return null;
        }

        return leads[0];
    }

}