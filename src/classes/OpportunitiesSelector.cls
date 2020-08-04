/*************************************************************************************
 * Created By: peteryao on 1/19/19  
 * Description: Can extend fflib_SObjectSelector
 * Test: OpportunitiesSelectorTest
 *************************************************************************************/
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class OpportunitiesSelector {
    @TestVisible
    private static FeatureService featureService = new FeatureService();
    // To be used when cancelling opportunities, so we also exclude Anchors and Public Offtake
    public static List<Opportunity> selectAllCompleteCSWithUASesAndSystemBills() {
        return [
            SELECT Id, Name,
            (SELECT Id, Name, Next_Schedule_Z_Status__c, Total_Count_of_Schedule_Zs__c, Transferring_Subsc_to_Another_UAS__c FROM Utility_Account_Subscriptions__r),
            (SELECT Id, Name, Date__c FROM Utility_Account_Subscription_Bills__r ORDER BY Date__c DESC LIMIT 1)
            FROM Opportunity
            WHERE StageName = 'Complete'
            AND Product_Line__c = 'Community Solar'
            AND Customer_Group__c != 'Anchor'
            AND Customer_Sub_Group__c != 'Public Offtake'
            ORDER BY Name
        ];
    }
    public static List<Opportunity> selectByIds(List<Id> oppIds) {
        return [
            SELECT Id,
                Contract_Status__c,
                Product_Line__c,
                Parent_Account_ID__c,
                BlueWave_Signature_Status__c
            FROM Opportunity
            WHERE Id IN: oppIds
        ];
    }
    public static List<Opportunity> selectAllCompleteCSWithUASes(Set<Id> oppIds) {
        return [
            SELECT Id, Name, Date_Removed_from_Project__c,
            (
                SELECT Id, Name, Most_Recent_Enacted_ALSS__c, Next_Schedule_Z_Status__c, Total_Count_of_Schedule_Zs__c,
                    Transferring_Subsc_to_Another_UAS__c, Date_Removed_from_Project__c
                FROM Utility_Account_Subscriptions__r
            )
            FROM Opportunity
            WHERE StageName = 'Complete'
            AND Product_Line__c = 'Community Solar'
            AND Customer_Group__c != 'Anchor'
            AND Customer_Sub_Group__c != 'Public Offtake'
            AND Id = :oppIds
        ];
    }
    public static Opportunity selectForContractSend(Id opportunityId) {
        return [
            SELECT Id, Name, Parent_Account_Name__c, Salesperson_Email__c, Sales_tag__c, Application_Type__c,
                Email__c, Co_Applicant_Email__c, Co_Applicant_Full_Name__c, Docusign_Template__c
            FROM Opportunity
            WHERE Id = : opportunityId
            LIMIT 1
        ];
    }
    public  Map<Id, Opportunity> selectOpportunityMap(Set<Id> oppIds) {
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
            SELECT Id, Shared_Solar_System__c, Shared_Solar_System__r.Name
            FROM Opportunity
            WHERE Id IN :oppIds
        ]);
        return oppMap;
    }
    public List<Opportunity> selectWithoutFirstInvoiceCommission(Set<Id> accountIds){
        return [
            SELECT Id, Name, AccountId, Account.Account_Number__c, Shared_Solar_System__r.Unique_ID__c,
                CS_Capacity_Allocated__c, Commission_Structure__r.Cents_kW_DC_First_Bill_Paid__c,
                Commission_Structure__r.Cents_kW_DC_First_Bill__c, StageName, Product_Line__c,
                Commission_Structure__c, Partner_tag_lookup__c, Partner_tag_lookup__r.Id, Partner_tag_lookup__r.Name
            FROM Opportunity
            WHERE Commission_Structure__r.Cents_kW_DC_First_Bill__c != null
            AND Commission_Structure__r.Cents_kW_DC_First_Bill__c != 0
            AND ID NOT IN (SELECT Opportunity__c FROM Commission_Payment__c WHERE Commission_Type__c = 'First Bill Sent')
            AND Account.Zuora_Id__c != null
            AND Shared_Solar_System__r.Number_of_Billed_Production_Periods__c > 0
            AND AccountId IN : accountIds
        ];
    }
    public List<Opportunity> selectWithoutFirstPaymentCommission(Set<Id> accountIds){
        return [
            SELECT Id, Name, AccountId, Account.Account_Number__c, Shared_Solar_System__r.Unique_ID__c,
                CS_Capacity_Allocated__c, Commission_Structure__r.Cents_kW_DC_First_Bill_Paid__c,
                Commission_Structure__r.Cents_kW_DC_First_Bill__c, StageName, Product_Line__c,
                Commission_Structure__c,  Partner_tag_lookup__c, Partner_tag_lookup__r.Id, Partner_tag_lookup__r.Name
            FROM Opportunity
            WHERE Commission_Structure__r.Cents_kW_DC_First_Bill_Paid__c != null
            AND Commission_Structure__r.Cents_kW_DC_First_Bill_Paid__c != 0
            AND ID NOT IN (SELECT Opportunity__c FROM Commission_Payment__c WHERE Commission_Type__c = 'First Bill Paid')
            AND Account.Zuora_Id__c != null
            AND Shared_Solar_System__r.Number_of_Billed_Production_Periods__c > 0
            AND AccountId IN : accountIds
        ];
    }

    public List<Opportunity> selectByIdWithApprovedCommissionPayment(Set<Id> opportunityIds) {
        return [
            SELECT Id, StageName, Product_Line__c,  Name, AccountId, Account.Account_Number__c, Shared_Solar_System__r.Unique_ID__c,
                CS_Capacity_Allocated__c, Commission_Structure__r.Cents_kW_DC_Up_Front__c, Product__c,
                Commission_Structure__c, Partner_tag_lookup__c, Partner_tag_lookup__r.Id, Partner_tag_lookup__r.Name,
                (SELECT Id FROM Commission_Payments__r WHERE Status__c = 'Approved' AND Commission_Type__c = 'Contract Execution')
            FROM Opportunity
            WHERE Id IN : opportunityIds
        ];
    }

    public List<Opportunity> getOppsFromSSS(Set<Id> sssIds) {
        return [
            SELECT Id, Name,
                Account.Parent_Account__c,
                Shared_Solar_System__r.Id
            FROM Opportunity
            WHERE Shared_Solar_System__r.Id IN : sssIds
        ];
    }
    public Map<Id, Opportunity> getOppsForTestMethods(Set<Id> oppIds) {
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
            SELECT Id, Lead__r.IsConverted, Lead__c
            FROM Opportunity
            WHERE Id IN :oppIds
            AND Lead__r.IsConverted = FALSE
        ]);
        return oppMap;
    }

    public Map<Id, Date> selectFirstCustomerSignedDateByAssignmentAgreement(Set<Id> contractIds) {
        //Contract and Assignment Agreement relationships depend on the Customer Contract Object Feature Flag
        //FLAG OFF --> Opportunity.Assignment Agreement == contractIds
        //FLAG ON --> Opportunity.Contract.Assignment Agreement == contractIds

        List<AggregateResult> oppResults = [
            SELECT Shared_Solar_System__r.Id sssId,
                MIN(Assignment_Agreement__r.CompanySignedDate) firstDateOFF,
                MIN(Contract.Assignment_Agreement__r.CompanySignedDate) firstDateON
            FROM Opportunity
            WHERE (Assignment_Agreement__c IN :contractIds
            OR Contract.Assignment_Agreement__c IN :contractIds)
            AND Shared_Solar_System__r.Customer_Assignment_Date__c = NULL
            GROUP BY Shared_Solar_System__r.Id
        ];

        Map<Id, Date> firstCustomerDateMap = new Map<Id, Date>();
        Boolean customerContractFeature = featureService.isEnabled('Customer_Contract_Object');
        for (AggregateResult ar : oppResults) {
            if (customerContractFeature) {
                firstCustomerDateMap.put ((Id)ar.get('sssId'), (Date) ar.get('firstDateON'));
            } else {
                firstCustomerDateMap.put ((Id)ar.get('sssId'), (Date) ar.get('firstDateOFF'));
            }
        }
        return firstCustomerDateMap;
    }



   // Invocable methods can have at most one input parameter and its data type must be a List of primitive data types
    @InvocableMethod(Label='selectOpportunitiesForClientAssignment' Description='Gets Opp without Assignment Agreement for a list of entities')
    public static List<List<Opportunity>> selectOpportunitiesForClientAssignment(List<List<String>> inputParameters){
        List<String> entityIds = inputParameters[0];
        List<Opportunity> opportunities = [
            SELECT Id, Assignment_Agreement__c
            FROM Opportunity
            WHERE Id IN (
                SELECT Opportunity__c
                FROM Utility_Account_Subscription__c
                WHERE Opportunity__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__c IN : entityIds
                AND Next_Schedule_Z_Status__c = 'Active Subscription'
                AND Opportunity__r.Assignment_Agreement__c = null
                AND Opportunity__r.Partner_tag_lookup__r.Account__r.RecordType.DeveloperName != 'Client_Account'
                AND Opportunity__r.Account.Account_Temperature__c != 'Hot'
                AND Opportunity__r.StageName = 'Complete'
            )
        ];
        return new List<List<Opportunity>>{opportunities};
    }

    public List<Opportunity> getCompleteOppsWithoutContracts() {
        return [
            SELECT Id, AccountId,
                Contract_Status__c,
                Product_Line__c,
                Parent_Account_ID__c,
                BlueWave_Signature_Status__c,
                Product__c,
                Assignment_Agreement__c
            FROM Opportunity
            WHERE StageName = 'Complete'
            AND Shared_Solar_System__c != null
            AND ContractId = null
        ];
    }
}