/*************************************************************************************
 * Created By: peteryao on 1/14/19  
 * Description: 
 * Test: 
 *************************************************************************************/

@IsTest
public class OpportunitiesTest {
    @TestSetup public static void setupTestData() {
        CSPaymentTest.CSPaymentSetupTestData();
    }

    @IsTest
    public static void testIsCancelledWaitlist() {
        List<Opportunity> opps = [
            SELECT Id,
            (SELECT Id, Name
            FROM Utility_Account_Subscriptions__r
            WHERE Next_Schedule_Z_Status__c = 'Active Subscription')
            FROM Opportunity
            WHERE Name = 'BDonut Shop'
            AND StageName = 'Complete'
        ];
        System.assertEquals(1, opps.size());
        System.assertEquals(0, opps[0].Utility_Account_Subscriptions__r.size());

        // An opp with no UASes shouldn't be cancelled (these are old opportunities)
        System.assertEquals(false, Opportunities.isCancelledWaitlist(opps[0]));

        opps = [
            SELECT Id,
            (SELECT Id, Name, Total_Count_of_Schedule_Zs__c
            FROM Utility_Account_Subscriptions__r
            WHERE Next_Schedule_Z_Status__c = 'Active Subscription')
            FROM Opportunity
            WHERE Name = 'ADonut Shop'
            AND StageName = 'Complete'
        ];
        System.assertEquals(1, opps.size());
        System.assertEquals(5, opps[0].Utility_Account_Subscriptions__r.size());
        List<Schedule_Z_Subscription__c> scheduleZSubscriptions = [
            SELECT Id
            FROM Schedule_Z_Subscription__c
            WHERE Utility_Account_Subscription__c IN : opps[0].Utility_Account_Subscriptions__r
        ];
        System.assertEquals(4, scheduleZSubscriptions.size());

        // An opp with UASes with Active Schedule Z's shouldn't be cancelled
        System.assertEquals(false, Opportunities.isCancelledWaitlist(opps[0]));

        for (Utility_Account_Subscription__c uas : opps[0].Utility_Account_Subscriptions__r) {
            uas.Next_Schedule_Z_Status__c = 'Inactive Subscription';
        }
        update opps[0].Utility_Account_Subscriptions__r;

        opps = [
            SELECT Id,
            (SELECT Id, Name, Total_Count_of_Schedule_Zs__c, Next_Schedule_Z_Status__c
            FROM Utility_Account_Subscriptions__r)
            FROM Opportunity
            WHERE Name = 'ADonut Shop'
            AND StageName = 'Complete'
        ];
        // This opp should still not be cancelled even though UASes are Inactive, since the UASes have Schedule Z Subscriptions
        System.assertEquals(false, Opportunities.isCancelledWaitlist(opps[0]));

        delete scheduleZSubscriptions;

        opps = [
            SELECT Id,
            (SELECT Id, Name, Total_Count_of_Schedule_Zs__c, Next_Schedule_Z_Status__c
            FROM Utility_Account_Subscriptions__r)
            FROM Opportunity
            WHERE Name = 'ADonut Shop'
            AND StageName = 'Complete'
        ];
        // Now, it should be cancelled since the UASes are Inactive and there are no schedule z subscriptions
        System.assertEquals(true, Opportunities.isCancelledWaitlist(opps[0]));
    }

    @IsTest
    public static void testFinishedBilling() {
        List<Opportunity> opps = [
            SELECT Id, (SELECT Id, Name FROM Utility_Account_Subscription_Bills__r)
            FROM Opportunity
            WHERE Name = 'PaymentTestOpp6'
            AND StageName = 'Complete'
        ];
        System.assertEquals(1, opps.size());
        System.assertEquals(0, opps[0].Utility_Account_Subscription_Bills__r.size());
        // This opportunity doesn't have any system bills, so we can't be finished billing
        System.assertEquals(false, Opportunities.finishedBilling(opps[0]));

        opps = [
            SELECT Id, (SELECT Id, Date__c, Name FROM Utility_Account_Subscription_Bills__r ORDER BY Date__c DESC LIMIT 1)
            FROM Opportunity
            WHERE Name = 'PaymentTestOpp1'
            AND StageName = 'Complete'
        ];
        System.assertEquals(1, opps.size());
        System.assertEquals(1, opps[0].Utility_Account_Subscription_Bills__r.size());
        System.assertEquals(Date.newInstance(2018, 1, 1), opps[0].Utility_Account_Subscription_Bills__r[0].Date__c);

        // This opp has an old system bill, it should be ready to be cancelled
        System.assertEquals(true, Opportunities.finishedBilling(opps[0]));

        opps[0].Utility_Account_Subscription_Bills__r[0].Date__c = Date.today()-30;
        update opps[0].Utility_Account_Subscription_Bills__r[0];
        opps = [
            SELECT Id, (SELECT Id, Date__c, Name FROM Utility_Account_Subscription_Bills__r ORDER BY Date__c DESC LIMIT 1)
            FROM Opportunity
            WHERE Name = 'PaymentTestOpp1'
            AND StageName = 'Complete'
        ];
        // This opp has an recent system bill, it shouldn't be cancelled (since maybe we were delayed in generating
        // bills
        System.assertEquals(false, Opportunities.finishedBilling(opps[0]));
    }
}