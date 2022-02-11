/* Tested by: ZuoraUsageServiceTest, UASBSelectorTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class UASBSelector {

    public static Database.QueryLocator uasbsNotYetInZuora(Date invoiceDate) {
        String query =
            'SELECT Id, Name, Date__c, ' +
            '    Net_Metering_Credits_Allocated__c, Savings__c,' +
            '    Discounted_Bill__c, Shared_Solar_System__r.Name,' +
            '    Shared_Solar_System__r.System_Utility__c,' +
            '    Utility_Account_Subscription__r.Name,' +
            '    Utility_Account_Subscription__r.Utility_Account_Log__r.Name,' +
            '    Utility_Account_Subscription__r.Shared_Solar_System__r.Unique_ID__c,' +
            '    Utility_Account_Subscription__r.Opportunity__r.Account.Zuora_Id__c,' +
            '    Client_Account_Number__c, ' + // A formula for the Client Account that is stamped on UASB on insert
            '    Credits_on_Bill_Period__c, ' +
            '    Billing_Period_Start_Date__c, ' +
            '    Billing_Period_End_Date__c ' +
                'FROM UASB__c ' +
            'WHERE Zuora_Id__c = NULL ' +
            'AND Date__c <= ' + String.valueOf(invoiceDate) + ' ' +
            // handle various UCB and externally serviced permutations
            'AND (' +
                '(Billing_Method__c = \'UCB\' ' + 'AND Utility_Account_Subscription__r.Externally_Serviced_Override__c = \'Internally Serviced\') ' +
                'OR (Billing_Method__c = null AND Externally_Serviced__c = FALSE)' +
            ') ' +
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
            WHERE Externally_Serviced__c = TRUE
            AND Ready_For_Production_Detail__c = TRUE
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

    /**
     * @description Retrieves the latest UASB by BILL DATE (if one exists) for the specified Allocation Schedule Subscription
     * @param szsList List of SZS'es (Allocation Schedule Subscriptions or ALSS's)
     * @return Map of SZS Id to latest UASB__c (latest bill) for the subscription account
     */
    public Map<String,UASB__c> getLatestUcbUasbBySzs(List<Schedule_Z_Subscription__c> szsList) {
        Map<Id,Id> uasToSzs = new Map<Id,Id>();
        for (Schedule_Z_Subscription__c szs : szsList) {
            uasToSzs.put(szs.Utility_Account_Subscription__c, szs.Id);
        }

        Map<String,UASB__c> priorUasbBySzs = new Map<String,UASB__c>();
        for (Utility_Account_Subscription__c uas :
            [SELECT Id,
                (SELECT Id, Ending_Banked_Credits__c, Date__c
                 FROM Utility_Account_Subscription_Bills__r
                 WHERE Billing_Method__c = 'UCB'
                 ORDER BY Date__c DESC LIMIT 1)
            FROM Utility_Account_Subscription__c
            WHERE Id IN : uasToSzs.keySet()])
        {
            UASB__c priorUasb = uas.Utility_Account_Subscription_Bills__r.isEmpty() ? null : uas.Utility_Account_Subscription_Bills__r[0];
            priorUasbBySzs.put(uasToSzs.get(uas.Id), priorUasb);
        }

        return priorUasbBySzs;
    }

    /**
     * @description Used to update the Property Account's First CS Bill Date, and generate commissions
     * @param transfers UCB Transfers
     * @return List of UASBs
     */
    public List<UASB__c> getUasbsForUCBTransfers(List<Transfer__c> transfers) {
        return [
            SELECT Id, Date__c,
                Utility_Account_Subscription__c,
                Utility_Account_Subscription__r.Opportunity__c,
                Utility_Account_Subscription__r.Opportunity__r.AccountId,
                Utility_Account_Subscription__r.Opportunity__r.Account.First_CS_Bill_Date__c
            FROM UASB__c
            WHERE Transfer__c IN :transfers
            AND Shared_Solar_System__r.UCB__c = TRUE
        ];
    }
}