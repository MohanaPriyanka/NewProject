/*************************************************************************************
 * Created By: peteryao on 1/14/19  
 * Description: Could be extend the fflib_SObjectDomain class
 * Test: CSOpportunitiesTest
 *************************************************************************************/

public class Opportunities {
    public List<Opportunity> records;
    private static Integer systemBillGenerationGracePeriod;

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
    public static Boolean finishedBilling(Opportunity opp) {
        if (systemBillGenerationGracePeriod == null) {
            List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();
            if (systemProperties.isEmpty() || systemProperties[0].System_Bill_Generation_Grace_Period__c == null) {
                systemBillGenerationGracePeriod = 15;
            } else {
                systemBillGenerationGracePeriod = (Integer)systemProperties[0].System_Bill_Generation_Grace_Period__c;
            }
        }

        if (opp.System_Bills__r.isEmpty()) {
            return false;
        } else if (opp.System_Bills__r[0].Date__c > Date.today() - 30 - systemBillGenerationGracePeriod) {
            return false;
        } else {
            return true;
        }
    }

    public void cancel() {
        for (Opportunity opp : records) {
            opp.StageName = 'Cancelled';
        }
        if (!records.isEmpty()) {
            update records;
        }
    }
}