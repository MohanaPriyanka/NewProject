/* Tested by: ZuoraUsageServiceTest, UASBSelectorTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class UASBSelector {
    public static Database.QueryLocator uasbsNotYetInZuora(Date invoiceDate) {
        String query =
            'SELECT Id, Name, Date__c, System_Bill__c,' +
            '    Net_Metering_Credits_Allocated__c, Savings__c,' +
            '    Discounted_Bill__c, Shared_Solar_System__r.Name,' +
            '    Shared_Solar_System__r.System_Utility__c,' +
            '    Utility_Account_Subscription__r.Name,' +
            '    Utility_Account_Subscription__r.Utility_Account_Log__r.Name,' +
            '    Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__r.Account_Number__c,' +
            '    Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Unique_ID__c,' +
            '    Utility_Account_Subscription__r.Opportunity__r.Account.Zuora_Id__c,' +
            '    System_Bill__r.Account_Bill__c,' +
            '    Client_Account_Number__c ' +
            'FROM UASB__c ' +
            'WHERE Zuora_Id__c = NULL ' +
            'AND Date__c <= ' + String.valueOf(invoiceDate) + ' ' +
            'AND Externally_Serviced__c = FALSE ' +
            'ORDER BY Utility_Account_Subscription__r.Opportunity__r.AccountId, Date__c';
        return Database.getQueryLocator(query);
    }

    public Map<String,List<UASB__c>> getUASBMapFromExternalIds(Set<String> zuoraIds){
        Map<String,List<UASB__c>> externalIdToUASBMap = new Map<String,List<UASB__c>>();
        List<UASB__c> uasbList = [
            SELECT Id, Transfer__c, Savings__c, Zuora_Id__c, Discounted_Bill__c
            FROM UASB__c
            WHERE Zuora_Id__c IN : zuoraIds
        ];
        for (UASB__c bill : uasbList) {
            if (externalIdToUASBMap.containsKey(bill.Zuora_Id__c)){
                List<UASB__c> billList = externalIdToUASBMap.get(bill.Zuora_Id__c);
                billList.add(bill);
                externalIdToUASBMap.put(bill.Zuora_Id__c,billList);
            } else {
                externalIdToUASBMap.put(bill.Zuora_Id__c,new List<UASB__c>{bill});
            }
        }
        return externalIdToUASBMap;
    }

    public List<UASB__c> getUnservicedWithoutProductionDetail(Integer batchSize){
        return new List<UASB__c>([
            SELECT Id, Externally_Serviced__c, Transfer__c, Credits_Allocated__c
            FROM UASB__c
            WHERE Externally_Serviced__c = true
            AND Ready_for_Production_Detail__c = true
            LIMIT : batchSize
        ]);
    }

    public List<AggregateResult> selectAggregateAnchorUASBs() {

        List<AggregateResult> activeAnchorRollups = [
            SELECT SUM(Subscription_Production_kWh_Static__c) productionSummary,
                Utility_Account_Subscription__c uasId
            FROM UASB__c
            WHERE Date__c = LAST_N_MONTHS:12
            AND (Utility_Account_Subscription__r.Customer_Group__c = 'Anchor' OR
                Utility_Account_Subscription__r.Opportunity__r.Customer_Sub_Group__c = 'Public Offtake')
            AND Utility_Account_Subscription__r.Externally_Serviced__c = FALSE
            GROUP BY Utility_Account_Subscription__c
            ];

        return activeAnchorRollups;
    }
}