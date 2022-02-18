/*************************************************************************************
 * Created By: peteryao on 1/14/19  
 * Description: Could be extend the fflib_SObjectDomain class
 * Test: OpportunitiesTest, CSCancellationServiceTest
 *************************************************************************************/

public inherited sharing class Opportunities {
    public List<Opportunity> records;
    public static List<String> closedOpportunityStages = new List<String>{'Cancelled', 'Expired', 'DUPLICATE', 'Dead', 'Complete'};
    public static List<String> lostOpportunityStages = new List<String>{'Cancelled', 'Expired', 'DUPLICATE', 'Dead'};
    private static Integer systemBillGenerationGracePeriod;
    static {
        List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();
        if (systemProperties.isEmpty() || systemProperties[0].System_Bill_Generation_Grace_Period__c == null) {
            systemBillGenerationGracePeriod = 15;
        } else {
            systemBillGenerationGracePeriod = (Integer)systemProperties[0].System_Bill_Generation_Grace_Period__c;
        }
    }

    public Opportunities(List<Opportunity> sObjectList) {
        records = sObjectList;
    }

    // Since waitlist customers don't have a Schedule Z Subscriptions, if they have any UASes and
    // they're all inactive, the opportunity should be cancelled. Alternatively, if they have any
    // Schedule Z Subscriptions or they're not Inactive, we shouldn't cancel them.
    public static Boolean isCancelledWaitlist(Opportunity opp) {
        if (opp.Utility_Account_Subscriptions__r.isEmpty()) {
            return false;
        }
        for (Utility_Account_Subscription__c uas : opp.Utility_Account_Subscriptions__r) {
            if (uas.Total_Count_of_Schedule_Zs__c != 0 ||
                uas.Next_Schedule_Z_Status__c != 'Inactive Subscription') {
                return false;
            }
        }
        return true;
    }

    // Used to know if we start billing this opportunity via System Bills, but have finished (they've cancelled or
    // we've stopped billing overdue balances
    // Transitioned from System Bill to UASB Jan 2020 because we will only make UASBs going forward:
    public static Boolean finishedBilling(Opportunity opp) {
        if (opp.Utility_Account_Subscription_Bills__r.isEmpty()) {
            return false;
        } else if (opp.Utility_Account_Subscription_Bills__r[0].Date__c > Date.today() - 30 - systemBillGenerationGracePeriod) {
            return false;
        }
        return true;
    }

    public static Boolean hasActiveUASes(Opportunity opp) {
        for (Utility_Account_Subscription__c uas : opp.Utility_Account_Subscriptions__r) {
            if (uas.Next_Schedule_Z_Status__c == 'Active Subscription') {
                return true;
            }
        }
        return false;
    }

    public static Boolean anyUASIsTransferring(Opportunity opp) {
        for (Utility_Account_Subscription__c uas : opp.Utility_Account_Subscriptions__r) {
            if (uas.Transferring_Subsc_to_Another_UAS__c && uas.Transferred_To__c == null) {
                return true;
            }
        }
        return false;
    }

    // Depends on Most Recent Enacted ALSS to tell whether the UAS has ever been enacted
    public static Boolean allEnactedUASesAreRemoved(Opportunity opp) {
        if (opp.Utility_Account_Subscriptions__r.isEmpty()) {
            return false;
        }
        for (Utility_Account_Subscription__c uas : opp.Utility_Account_Subscriptions__r) {
            if ((uas.Most_Recent_Enacted_ALSS__c != null && uas.Date_Removed_from_Project__c == null) ||
                (uas.Most_Recent_Enacted_ALSS__c == null && uas.Date_Removed_from_Project__c != null)) {
                return false;
            }
        }
        return true;
    }

    public static Boolean anyEnactedUASes(Opportunity opp) {
        for (Utility_Account_Subscription__c uas : opp.Utility_Account_Subscriptions__r) {
            if (uas.Most_Recent_Enacted_ALSS__c != null) {
                return true;
            }
        }
        return false;
    }

    public Boolean allInactive() {
        for (Opportunity opportunity : records) {
            if (isActive(opportunity.StageName)) {
                return false;
            }
        }
        return true;
    }

    public static Boolean isActive(String stageName) {
        return (!lostOpportunityStages.contains(stageName));
    }

    public static Boolean shouldCancel(Opportunity opportunity) {
        if (anyUASIsTransferring(opportunity)) {
            return false;
        }
        if (isCancelledWaitlist(opportunity) ||
            (finishedBilling(opportunity) && !hasActiveUASes(opportunity))) {
            return true;
        }
        return false;
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public void cancel() {
        for (Opportunity opp : records) {
            opp.StageName = 'Cancelled';
        }
        update records;
    }
}