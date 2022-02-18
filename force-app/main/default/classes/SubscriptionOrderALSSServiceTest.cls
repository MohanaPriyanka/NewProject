@isTest
public without sharing class SubscriptionOrderALSSServiceTest{
    @isTest
    public static void testGetAllocationScheduleSubscription(){
        useMocks();
        List<Schedule_Z_Subscription__c> szsList = getSZSMock();
        SubscriptionOrderALSSService service = new SubscriptionOrderALSSService();
        List<Subscription_Order__c> subOrders = service.getAllocationScheduleSubscription(szsList);

        // Not all SZS's have subscription orders that need an update, and some have > 1
        System.assertEquals(13,szsList.size());
        System.assertEquals(14,subOrders.size());

        for (Subscription_Order__c order : subOrders){
            System.assertNotEquals(null,order.Allocation_Schedule_Subscription__c);
            if (order.Name == 'SO-00143'){
                // Override existing values if ALS is not enacted:
                System.assertNotEquals('a543K0000000ISFQA2',order.Allocation_Schedule_Subscription__c);
                System.assertEquals('a543K0000000ISSQA3',order.Allocation_Schedule_Subscription__c);
            } else if (order.Name == 'SO-00135'){
                // Set if originally null:
                System.assertEquals('a543K0000000ISSQB1',order.Allocation_Schedule_Subscription__c);
            }
        }
    }

    @isTest
    public static void testMultipleMatches(){
        useMocks();

        List<Error_Log__c> beforeLogs = [
            SELECT Id
            FROM Error_Log__c
            WHERE Class__c = 'SubscriptionOrderALSSService'
        ];
        System.assertEquals(0,beforeLogs.size());

        List<Schedule_Z_Subscription__c> szsList = getSZSMockSameUAS();
        SubscriptionOrderALSSService service = new SubscriptionOrderALSSService();
        List<Subscription_Order__c> subOrders = service.getAllocationScheduleSubscription(szsList);

        List<Error_Log__c> afterLogs = [
            SELECT Id
            FROM Error_Log__c
            WHERE Class__c = 'SubscriptionOrderALSSService'
        ];
        System.assert(afterLogs.size() > 0);
    }

    private static void useMocks() {
        SubscriptionOrderALSSService.soSelector = (SubscriptionOrderSelector) Test.createStub(SubscriptionOrderSelector.class, new MockSOSelector());
    }

    public class MockSOSelector extends MockProvider {
        public MockSOSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            String subscriptionOrdersAsString = '[' +
                '{"Id":"a9W3K00000003DHUAY","Name":"SO-00144","Utility_Account_Subscription__c":"a1d3K0000000mq8QAA","Allocation_Schedule_Subscription__c":"a543K0000000ISGQA2"},' +
                '{"Id":"a9W3K00000003DGUAY","Name":"SO-00143","Utility_Account_Subscription__c":"a1d3K0000000mq7QAA","Allocation_Schedule_Subscription__c":"a543K0000000ISFQA2"},' +
                '{"Id":"a9W3K00000003DFUAY","Name":"SO-00142","Utility_Account_Subscription__c":"a1d3K0000000mq6QAA","Allocation_Schedule_Subscription__c":"a543K0000000ISEQA2"},' +
                '{"Id":"a9W3K00000003DEUAY","Name":"SO-00141","Utility_Account_Subscription__c":"a1d3K0000000mq5QAA","Allocation_Schedule_Subscription__c":"a543K0000000ISDQA2"},' +
                '{"Id":"a9W3K00000003DDUAY","Name":"SO-00140","Utility_Account_Subscription__c":"a1d3K0000000mq4QAA"},' +
                '{"Id":"a9W3K00000003DCUAY","Name":"SO-00139","Utility_Account_Subscription__c":"a1d3K0000000mq3QAA"},' +
                '{"Id":"a9W3K00000003D8UAI","Name":"SO-00135","Utility_Account_Subscription__c":"a1d3K0000000mpzQAA"},' +
                '{"Id":"a9W3K00000003D5UAI","Name":"SO-00132","Utility_Account_Subscription__c":"a1d3K0000000mpwQAA"},' +
                '{"Id":"a9W3K00000003D6UAI","Name":"SO-00133","Utility_Account_Subscription__c":"a1d3K0000000mpwQAA"},' +
                '{"Id":"a9W3K00000003D7UAI","Name":"SO-00155","Utility_Account_Subscription__c":"a1d3K0000000mpwQAA"},' +
                '{"Id":"a9W3K00000003D8UAI","Name":"SO-00157","Utility_Account_Subscription__c":"a1d3K0000000mq4QAA"},' +
                '{"Id":"a9W3K00000003CpUAI","Name":"SO-00116","Utility_Account_Subscription__c":"a1d3K0000000mqBQAQ"},' +
                '{"Id":"a9W3K00000003CoUAI","Name":"SO-00115","Utility_Account_Subscription__c":"a1d3K0000000mqAQAQ"},' +
                '{"Id":"a9W3K00000003D1UAI","Name":"SO-00128","Utility_Account_Subscription__c":"a1d3K00000011FjQAI"}' +
                ']';

            switch on methodCall.stubbedMethodName {
                when 'selectUnenactedByUASId' {
                    return (List<Subscription_Order__c>)JSON.deserialize(subscriptionOrdersAsString, List<Subscription_Order__c>.class);
                }
            }
            return null;
        }
    }

    public static List<Schedule_Z_Subscription__c> getSZSMock(){
        Schedule_Z_Subscription__c szsOne = new Schedule_Z_Subscription__c(
            Id = 'a543K0000000ISSQA2',
            Utility_Account_Subscription__c = 'a1d3K0000000mq8QAA'
        );
        Schedule_Z_Subscription__c szsTwo = new Schedule_Z_Subscription__c(
            Id = 'a543K0000000ISSQA3',
            Utility_Account_Subscription__c = 'a1d3K0000000mq7QAA'
        );
        Schedule_Z_Subscription__c szsThree = new Schedule_Z_Subscription__c(
            Id = 'a543K0000000ISSQA4',
            Utility_Account_Subscription__c = 'a1d3K0000000mq8QAA'
        );
        Schedule_Z_Subscription__c szsFour = new Schedule_Z_Subscription__c(
            Id = 'a543K0000000ISSQA5',
            Utility_Account_Subscription__c = 'a1d3K0000000mq6QAA'
        );
        Schedule_Z_Subscription__c szsFive = new Schedule_Z_Subscription__c(
            Id = 'a543K0000000ISSQA6',
            Utility_Account_Subscription__c = 'a1d3K0000000mq5QAA'
        );
        Schedule_Z_Subscription__c szsSix = new Schedule_Z_Subscription__c(
            Id = 'a543K0000000ISSQA7',
            Utility_Account_Subscription__c = 'a1d3K0000000mq4QAA'
        );
        Schedule_Z_Subscription__c szsSeven = new Schedule_Z_Subscription__c(
            Id = 'a543K0000000ISSQA8',
            Utility_Account_Subscription__c = 'a1d3K0000000mq3QAA'
        );
        Schedule_Z_Subscription__c szsEight = new Schedule_Z_Subscription__c(
            Id = 'a543K0000000ISSQA9',
            Utility_Account_Subscription__c = 'a1d3K0000000mpwQAA'
        );
        Schedule_Z_Subscription__c szsNine = new Schedule_Z_Subscription__c(
            Id = 'a543K0000000ISSQB1',
            Utility_Account_Subscription__c = 'a1d3K0000000mpzQAA'
        );
        Schedule_Z_Subscription__c szsTen = new Schedule_Z_Subscription__c(
            Id = 'a543K0000000ISSQB2',
            Utility_Account_Subscription__c = 'a1d3K0000000mqBQAQ'
        );
        Schedule_Z_Subscription__c szsEleven = new Schedule_Z_Subscription__c(
            Id = 'a543K0000000ISSQB3',
            Utility_Account_Subscription__c = 'a1d3K00000011FjQAI'
        );
        Schedule_Z_Subscription__c szsTweleve = new Schedule_Z_Subscription__c(
            Id = 'a543K0000000ISSQB4',
            Utility_Account_Subscription__c = 'a1d3K0000000mqAQAQ'
        );
        Schedule_Z_Subscription__c szsThirteen = new Schedule_Z_Subscription__c(
            Id = 'a543K0000000ISSQB5',
            Utility_Account_Subscription__c = 'a1d3K0000000mqAQBB'
        );
        List<Schedule_Z_Subscription__c> szsList = new List<Schedule_Z_Subscription__c>{
            szsOne, szsTwo, szsThree, szsFour, szsFive, szsSix, szsSeven,
            szsEight, szsNine, szsTen, szsEleven, szsTweleve, szsThirteen
        };
        return szsList;
    }

    public static List<Schedule_Z_Subscription__c> getSZSMockSameUAS(){
        Schedule_Z_Subscription__c szsOne = new Schedule_Z_Subscription__c(
            Id = 'a543K0000000ISSQA2',
            Utility_Account_Subscription__c = 'a1d3K0000000mq8QAA'
        );
        Schedule_Z_Subscription__c szsTwo = new Schedule_Z_Subscription__c(
            Id = 'a543K0000000ISSQA3',
            Utility_Account_Subscription__c = 'a1d3K0000000mq7QAA'
        );
        Schedule_Z_Subscription__c szsThree = new Schedule_Z_Subscription__c(
            Id = 'a543K0000000ISSQA4',
            Utility_Account_Subscription__c = 'a1d3K0000000mq7QAA'
        );
        Schedule_Z_Subscription__c szsFour = new Schedule_Z_Subscription__c(
            Id = 'a543K0000000ISSQA5',
            Utility_Account_Subscription__c = 'a1d3K0000000mq7QAA'
        );
        Schedule_Z_Subscription__c szsFive = new Schedule_Z_Subscription__c(
            Id = 'a543K0000000ISSQA6',
            Utility_Account_Subscription__c = 'a1d3K0000000mq7QAA'
        );
        List<Schedule_Z_Subscription__c> szsList = new List<Schedule_Z_Subscription__c>{
            szsOne, szsTwo, szsThree, szsFour, szsFive
        };
        return szsList;
    }
}