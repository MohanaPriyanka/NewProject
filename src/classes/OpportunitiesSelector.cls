/*************************************************************************************
 * Created By: peteryao on 1/19/19  
 * Description: Can extend fflib_SObjectSelector
 * Test: OpportunitiesSelectorTest
 *************************************************************************************/
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.ApexDoc')
public without sharing class OpportunitiesSelector {
    private static String fieldsToGenerateCommissions = 'Id, \n' +
        'Name, \n' +
        'AccountId, \n' +
        'Account.Account_Number__c, \n' +
        'Shared_Solar_System__r.Unique_ID__c,\n' +
        'Shared_Solar_System__r.Name, \n' +
        'CS_Capacity_Allocated__c,\n' +
        'Commission_Structure__r.Cents_kW_DC_First_Bill_Paid__c,\n' +
        'Commission_Structure__r.Cents_kW_DC_First_Bill__c, \n' +
        'StageName, \n' +
        'Product_Line__c,\n' +
        'Commission_Structure__c, \n' +
        'Partner_tag_lookup__c, \n' +
        'Partner_tag_lookup__r.Id, \n' +
        'Partner_tag_lookup__r.Name, \n' +
        'Partner_tag_lookup__r.Account__c, \n' +
        'Partner_tag_lookup__r.Account__r.RecordType.Name,\n' +
        'Partner_Account__c, \n' +
        'Partner_Account__r.Name, \n' +
        'Partner_Account__r.RecordType.Name';

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
            SELECT Id, Contract_Status__c, Product_Line__c,
                Parent_Account_ID__c, BlueWave_Signature_Status__c,
                Lead__c, StageName
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

    private String defaultCommissionQueryString() {
        return 'SELECT ' + fieldsToGenerateCommissions + '\n' +
            'FROM Opportunity\n' +
            'WHERE StageName = \'Complete\' \n' +
            'AND Shared_Solar_System__r.Number_of_Billed_Production_Periods__c > 0 \n';
    }

    private String firstBillSentCommissionQueryString() {
        return defaultCommissionQueryString() +
            'AND Id NOT IN (SELECT Opportunity__c FROM Commission_Payment__c WHERE Commission_Type__c = \'First Bill Sent\') \n' +
            'AND Commission_Structure__r.Cents_kW_DC_First_Bill__c != NULL \n' +
            'AND Commission_Structure__r.Cents_kW_DC_First_Bill__c != 0 \n';
    }

    private String firstBillPaidCommissionQueryString() {
        return defaultCommissionQueryString() +
            'AND Id NOT IN (SELECT Opportunity__c FROM Commission_Payment__c WHERE Commission_Type__c = \'First Bill Paid\') \n' +
            'AND Commission_Structure__r.Cents_kW_DC_First_Bill_Paid__c != NULL \n' +
            'AND Commission_Structure__r.Cents_kW_DC_First_Bill_Paid__c != 0 \n';
    }

    @SuppressWarnings('PMD.ApexSOQLInjection')
    public List<Opportunity> selectWithoutFirstInvoiceCommission(Set<Id> accountIds) {
        String query = firstBillSentCommissionQueryString() +
            'AND AccountId IN :accountIds';
        return Database.query(query);
    }

    @SuppressWarnings('PMD.ApexSOQLInjection')
    public List<Opportunity> selectWithoutFirstPaymentCommission(Set<Id> accountIds) {
        String query = firstBillPaidCommissionQueryString() +
            'AND AccountId IN :accountIds';
        return Database.query(query);
    }

    @SuppressWarnings('PMD.ApexSOQLInjection')
    public List<Opportunity> selectWithoutFirstInvoiceCommissionByOpp(Set<Id> opportunityIds) {
        String query = firstBillSentCommissionQueryString() +
            'AND Id IN :opportunityIds';
        return Database.query(query);
    }

    @SuppressWarnings('PMD.ApexSOQLInjection')
    public List<Opportunity> selectWithoutFirstPaymentCommissionByOpp(Set<Id> opportunityIds) {
        String query = firstBillPaidCommissionQueryString() +
            'AND Id IN :opportunityIds';
        return Database.query(query);
    }

    public List<Opportunity> selectByIdWithCommissionPayment(Set<Id> opportunityIds) {
        return [
            SELECT Id, StageName, Product_Line__c,  Name, AccountId, Account.Account_Number__c, Shared_Solar_System__r.Unique_ID__c,
                Shared_Solar_System__r.Name, CS_Capacity_Allocated__c, Commission_Structure__r.Cents_kW_DC_Up_Front__c,
                Product__c, Commission_Structure__c, Partner_tag_lookup__c, Partner_tag_lookup__r.Id,
                Partner_tag_lookup__r.Account__c, Partner_tag_lookup__r.Name, Partner_tag_lookup__r.Account__r.Name,
                Partner_tag_lookup__r.Account__r.RecordType.Name, Partner_Account__c, Partner_Account__r.Name,
                Partner_Account__r.RecordType.Name,
                (SELECT Id, Status__c FROM Commission_Payments__r WHERE Commission_Type__c = 'Contract Execution')
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
        List<AggregateResult> oppResults = [
            SELECT Shared_Solar_System__r.Id sssId,
                MIN(Contract.Assignment_Agreement__r.CompanySignedDate) firstCompanySignedDate
            FROM Opportunity
            WHERE (Assignment_Agreement__c IN :contractIds
            OR Contract.Assignment_Agreement__c IN :contractIds)
            AND Shared_Solar_System__r.Customer_Assignment_Date__c = NULL
            GROUP BY Shared_Solar_System__r.Id
        ];
        Map<Id, Date> firstCustomerDateMap = new Map<Id, Date>();
        for (AggregateResult ar : oppResults) {
            firstCustomerDateMap.put ((Id)ar.get('sssId'), (Date) ar.get('firstCompanySignedDate'));
        }
        return firstCustomerDateMap;
    }

    @SuppressWarnings('PMD.ApexSOQLInjection')
    public static List<Opportunity> selectOpportunitiesForClientAssignment(Id entityId, Date cutoffDate, Boolean clientAcquiredCustomers) {
        String soql =
            'SELECT Id, Assignment_Agreement__c\n' +
                '  FROM Opportunity\n' +
                '  WHERE Id IN (\n' +
                '      SELECT Opportunity__c\n' +
                '      FROM Utility_Account_Subscription__c\n' +
                '      WHERE Opportunity__r.Shared_Solar_System__r.Contract_Assignment_Entity__c = :entityId\n' +
                '      AND Opportunity__r.Contract_Close_Date__c <= :cutoffDate\n' +
                '      AND Next_Schedule_Z_Status__c = \'Active Subscription\'\n' +
                '      AND Opportunity__r.Assignment_Agreement__c = NULL\n' +
                '      AND Opportunity__r.Customer_Group__c != \'Anchor\'\n' +
                '      AND Opportunity__r.StageName = \'Complete\'\n' +
                '      AND Opportunity__r.Partner_tag_lookup__r.Account__r.RecordType.DeveloperName ' + (clientAcquiredCustomers?'=':'!=') + '\'Client_Account\'\n' +
                '  )';
        return Database.query(soql);
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

    public List<Opportunity> getCustomerOpportunitiesByAssignmentAgreement(Id assignmentAgreementId) {
        return [
            SELECT Id, Name, Personal_Credit_Report2__c
            FROM Opportunity
            WHERE Contract.Assignment_Agreement__c = : assignmentAgreementId
        ];
    }


    public Map<Id, Decimal> getAggregateOpportunitySubscriptions(Set<Id> oppIds) {
        List<AggregateResult> oppResults = [
            SELECT Opportunity__r.Id oppId, SUM(Future_Customer_Subscription_KWDC_Rollup__c) total
            FROM Utility_Account_Subscription__c
            WHERE Next_Schedule_Z_Status__c = 'Active Subscription'
            AND Opportunity__r.Id IN :oppIds
            GROUP BY Opportunity__r.Id
        ];
        Map<Id, Decimal> oppSubscriptionMap = new Map<Id, Decimal>();
        for (AggregateResult ar : oppResults) {
            oppSubscriptionMap.put((Id) ar.get('oppId'), (Decimal) ar.get('total') );
        }
        return oppSubscriptionMap;
    }

    public MultiMap getOpportunitiesWithOpenQCCases(Set<Id> oppIds) {
        List<Case> casesWithOpportunities = [
            SELECT Id, Related_Opportunity__c
            FROM Case
            WHERE Related_Opportunity__c = :oppIds
            AND Category__c = 'QC'
            AND IsClosed = FALSE
        ];
        return CollectionUtil.multiMapByField(casesWithOpportunities, Case.Related_Opportunity__c);
    }

    public List<Opportunity> selectRetiredOpportunities(Set<Id> oppIds) {
        return [
            SELECT Id, Name, AccountId, Date_Removed_from_Project__c,
            (SELECT Id, Date_Removed_from_Project__c
            FROM Utility_Account_Subscriptions__r)
            FROM Opportunity
            WHERE Id IN :oppIds
            AND Date_Removed_from_Project__c != null
        ];
    }
    
    public List<Opportunity> getOpportunitiesByAAsNeedingAddendumSent(Set<Id> assignmentAgreementIds) {
        List<Opportunity> resultList = [
            SELECT Id, Contract.Id, Contract.Product__r.Addendum_Template_Id__c, Contract.Addendum_Sent_Date__c, 
            Account.Send_Bills_Contact__r.Id, Shared_Solar_System__c, Shared_Solar_System__r.Name, 
            Shared_Solar_System__r.Address__c, Shared_Solar_System__r.City__c, Shared_Solar_System__r.State__c, 
            Shared_Solar_System__r.Zip_Code__c, Shared_Solar_System__r.Total_System_Size_kWh_DC__c, 
            Shared_Solar_System__r.Home_Electricity_Offset__c, Contract.Assignment_Agreement__c, 
            Product__c, Product__r.Addendum_Template_Id__c
            FROM Opportunity
            WHERE Contract.Assignment_Agreement__c IN: assignmentAgreementIds
            AND Contract.Addendum_Sent_Date__c = null
            AND Product__r.Addendum_Template_Id__c != null
        ];
        return resultList;
    }
    
}