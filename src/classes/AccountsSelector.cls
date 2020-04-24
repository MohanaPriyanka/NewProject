/*************************************************************************************
 * Created By: peteryao on 1/20/19  
 * Description: Can extend fflib_SObjectSelector
 * Test: AccountsSelectorTest
 *************************************************************************************/
// These should run as system for backend processing
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class AccountsSelector {
    public static List<Account> selectCS67DaysPastDueWithAnchorOpps() {
        return [
            SELECT Id, Name, Days_Past_Due__c, Cancellation_Request_Date__c, Cancellation_Reason__c, Cancellation_Comments__c,
            (SELECT Id
            FROM Opportunities
            WHERE Customer_Group__c IN ('Anchor', 'Public Offtake')
            OR RecordType.Name = 'Business Development- Offtake')
            FROM Account
            WHERE RecordType.Name = 'Property'
            AND Days_Past_Due__c > 67
            AND Override_Delinquency_Removal__c = FALSE
            AND Cancellation_Request_Date__c = NULL
            ORDER BY Name
        ];
    }

    public static List<Account> selectCSNotRemoved() {
        return [
            SELECT Id, Name,
                Send_Bills_Contact__c, Send_Bills_Contact__r.FirstName,
                Send_Bills_Contact__r.Email, Send_Bills_Contact__r.Additional_Email__c,
                Additional_Contact__r.Email, Additional_Contact__r.Additional_Email__c,
                Date_Removed_from_Project__c,
            (SELECT Id, Date_Removed_from_Project__c, StageName FROM Opportunities),
            (SELECT Id, Name, Number_of_Removed_UASes__c, Number_of_Subscribed_UASes__c, Last_Date_UAS_Removed_From_Project__c
            FROM Utility_Account_Logs__r)
            FROM Account
            WHERE Count_of_CS_Opportunities__c > 0
            AND Date_Removed_from_Project__c = NULL
            AND RecordType.Name = 'Property'
            ORDER BY Name
        ];
    }

    public static List<Account> selectNotClosed(Set<Id> accountIds) {
        return [
            SELECT Id, Cancellation_Request_Date__c,
                Send_Bills_Contact__c,
                Send_Bills_Contact__r.Email,
                Send_Bills_Contact__r.FirstName,
                Send_Bills_Contact__r.Additional_Email__c,
                Additional_Contact__r.Email,
                Additional_Contact__r.Additional_Email__c,
            (SELECT Id, StageName FROM Opportunities WHERE Product_Line__c = 'Community Solar')
            FROM Account
            WHERE Id IN :accountIds
            AND Status__c != 'Closed'
        ];
    }

    public static List<Account> selectWithSendBillsContact(Set<Id> accountIds) {
        return [
            SELECT Id, Name, Account_Number__c, Zuora_Id__c, Send_Bills_Contact__c, Send_Bills_Contact__r.AccountId,
                Send_Bills_Contact__r.Id, Send_Bills_Contact__r.FirstName, Send_Bills_Contact__r.LastName,
                Send_Bills_Contact__r.Email, Recurring_Billing__c,
                Address_Attn__c, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                Additional_Contact__r.Email, Client_Brand_Key__c, Zuora_Payment_Ref_Id__c, Zuora_Payment_Ref_Id_Expiration_Date__c
            FROM Account
            WHERE Id IN :accountIds
        ];
    }

    public static List<Account> selectAccountsWithBillMessages() {
        return [
            SELECT Id, Zuora_Invoice_Message_1_of_2__c, Zuora_Invoice_Message_2_of_2__c
            FROM Account
            WHERE Zuora_Invoice_Message_1_of_2__c != null
            OR Zuora_Invoice_Message_2_of_2__c != null
        ];
    }

    public Account selectOne(Id accountId) {
        List<Account> accounts = this.selectAll(new Set<Id>{accountId});
        if (accounts.isEmpty()) {
            return null;
        }
        return accounts[0];
    }

    public List<Account> selectAll(Set<Id> accountIds) {
        return [
            SELECT Id, Name, Address_Attn__c, BillingStreet, BillingCity, BillingState, BillingStateCode, BillingPostalCode, BillingCountry,
                Zuora_Payment_Ref_Id__c, Zuora_Payment_Ref_Id_Expiration_Date__c, Lead__c,
                Send_Bills_Contact__c, Send_Bills_Contact__r.Email, Send_Bills_Contact__r.FirstName, Send_Bills_Contact__r.LastName,
                Additional_Contact__c, Additional_Contact__r.Email,
                Client_Brand_Key__c, Count_of_Large_Offtake_Opps__c,
                Zuora_Id__c,
            (
                SELECT Id, Shared_Solar_System__r.Product__r.Program__c, Shared_Solar_System__r.Utility__c
                FROM Opportunities WHERE Product_Line__c = 'Community Solar' AND StageName = 'Complete'
            ), (
                SELECT Id, Zuora__DueDate__c
                FROM Zuora__Invoices__r
                ORDER BY Zuora__DueDate__c DESC
            ), (
                SELECT Id, Zuora_Payment_Method__c
                FROM Cases
                WHERE IsClosed = FALSE
                AND Zuora_Payment_Method__c != NULL

            )
            FROM Account
            WHERE Id = :accountIds
        ];
    }

    public List<Account> selectPropertyAccountsByLeadIds(Set<Id> leadIds) {
        return [
            SELECT Id, Name, BillingStreet, BillingCity, BillingStateCode, BillingPostalCode, BillingState, BillingCountry,
                Zuora_Payment_Ref_Id__c, Zuora_Payment_Ref_Id_Expiration_Date__c, Lead__c, Account_Number__c, Additional_Contact__r.Id,
                Client_Brand_Key__c, Address_Attn__c, Send_Bills_Contact__c, Send_Bills_Contact__r.AccountId,
                Send_Bills_Contact__r.Id, Send_Bills_Contact__r.FirstName, Send_Bills_Contact__r.LastName,
                Send_Bills_Contact__r.Email
            FROM Account
            WHERE Lead__c = :leadIds
            AND RecordType.Name = 'Property'
        ];
    }

    // Returns a map instead of the aggregate result list so it can be mocked (since we can't deserialize AggregateResult):
    // https://salesforce.stackexchange.com/questions/203810/how-to-deserialize-aggregateresults
    public List<Map<String, Object>> selectForReconciliation(List<String> zuoraAccountIds) {
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        List<AggregateResult> aggregateResults = [
            SELECT Account.Id Id, Account.Zuora_Id__c Zuora_Id__c, Account.Name AccountName,
                Account.Client_Brand_Key__c CommunicationProfileId,
                MAX(Product__r.Days_in_Bill_Period__c) DaysInBillingPeriod,
                COUNT_DISTINCT(Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__r.Name) DistinctGateways,
                MAX(Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__r.Name) GatewayName
            FROM Opportunity
            WHERE StageName = 'Complete'
            AND Account.Zuora_Id__c IN :zuoraAccountIds
            GROUP BY Account.Id, Account.Zuora_Id__c, Account.Name, Account.Client_Brand_Key__c
        ];
        for (AggregateResult aggregateResult : aggregateResults) {
            results.add(aggregateResult.getPopulatedFieldsAsMap());
        }
        return results;
    }

    public List<Account> getAccountsById(Set<Id> accountIds){
        return [
            SELECT Id, Parent_Account__c, Client_Brand_Key__c, RecordType.Name
            FROM Account
            WHERE Id IN : accountIds
        ];
    }

    public Map<Id,Account> selectById(Set<Id> acctIds){
        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, Last_Bill_Send_Date_New_Charges_Zuora__c, Total_Outstanding_Balance_Zuora__c
            FROM Account
            WHERE Id IN : acctIds
        ]);
        return accountMap;
    }

    public List<Account> getPropertiesFromParent(Set<Id> acctIds){
        List<Account> properties = new List<Account>([
            SELECT Id, Bill_Delivery_Preference__c
            FROM Account
            WHERE Parent_Account__c IN : acctIds
        ]);
        return properties;
    }

    public Map<String,Account> selectByBlueWaveId(Set<String> blueWaveIds){
        Map<String,Account> bwIdToAccountMap = new Map<String,Account>();
        for (Account acct : [   SELECT Id, Account_Number__c
                                FROM Account
                                WHERE Account_Number__c IN : blueWaveIds]){
            bwIdToAccountMap.put(acct.Account_Number__c, acct);
        }
        return bwIdToAccountMap;
    }
}