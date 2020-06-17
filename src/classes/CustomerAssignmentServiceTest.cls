/**
 * Created by peteryao on 6/17/20.
 */
@IsTest
public with sharing class CustomerAssignmentServiceTest {
    private static String oldOppMapJson = '{' +
        '"006000000000000AAA":{"Id":"006000000000000AAA"},' +
        '"006000000000001AAA":{"Id":"006000000000001AAA","Assignment_Agreement__c":"800000000000001AAA"},' +
        '"006000000000002AAA":{"Id":"006000000000002AAA","Assignment_Agreement__c":"800000000000002AAA"},' +
        '"006000000000003AAA":{"Id":"006000000000003AAA","Assignment_Agreement__c":"800000000000003AAA"}' +
        '}';
    private static String newOppMapJson = '{' +
        '"006000000000000AAA":{"Id":"006000000000000AAA","Assignment_Agreement__c":"800000000000000AAA"},' + // add assignment agreement
        '"006000000000001AAA":{"Id":"006000000000001AAA","Assignment_Agreement__c":"800000000000001AAA"},' + // no change
        '"006000000000002AAA":{"Id":"006000000000002AAA","Assignment_Agreement__c":"800000000000003AAA"},' + // changed AA
        '"006000000000003AAA":{"Id":"006000000000003AAA"}' + // removed AA
        '}';
    private static String oldContractMapJson = '{' +
        '"800000000000007":{"Id":"800000000000007"},' +
        '"800000000000008":{"Id":"800000000000008","Assignment_Agreement__c":"800000000000001AAA"},' +
        '"800000000000009":{"Id":"800000000000009","Assignment_Agreement__c":"800000000000002AAA"},' +
        '"800000000000000":{"Id":"800000000000000","Assignment_Agreement__c":"800000000000003AAA"}' +
        '}';
    private static String newContractMapJson = '{' +
        '"800000000000007":{"Id":"800000000000007","Assignment_Agreement__c":"800000000000000AAA"},' + // added
        '"800000000000008":{"Id":"800000000000008","Assignment_Agreement__c":"800000000000001AAA"},' + // no change
        '"800000000000009":{"Id":"800000000000009","Assignment_Agreement__c":"800000000000003AAA"},' + // changed AA
        '"800000000000000":{"Id":"800000000000000"}' + // removed AA
        '}';

    @IsTest
    private static void testFindOppsWithUpdatedAgreements() {
        Map<Id, Opportunity> oldOppMap = (Map<Id, Opportunity>) JSON.deserialize(oldOppMapJson, Map<Id, Opportunity>.class);
        Map<Id, Opportunity> newOppMap = (Map<Id, Opportunity>) JSON.deserialize(newOppMapJson, Map<Id, Opportunity>.class);

        Map<Id, Id> oppToAssignmentAgreementMap =
            new CustomerAssignmentService().getOppsWithUpdatedAssignmentAgreements(oldOppMap, newOppMap);
        System.assertEquals(3, oppToAssignmentAgreementMap.size(), 'Expected to find three opps with updated assignment agreements');
        for (Id oppId : oppToAssignmentAgreementMap.keySet()) {
            System.assertNotEquals('006000000000001AAA', oppId, 'This opp should not have a changed assignment agreement');
        }
    }

    @IsTest
    private static void testUpdateAssignmentAgreementsFromOpportunity() {
        Map<String, Boolean> featureFlagMap = new Map<String, Boolean>{'Customer_Contract_Object'=>false};
        CustomerAssignmentService.featureService =
            (FeatureService) Test.createStub(FeatureService.class, new FeatureService.Mock(featureFlagMap));
        CustomerAssignmentService.subscriptionOrderSelector =
            (SubscriptionOrderSelector) Test.createStub(SubscriptionOrderSelector.class, new MockSubscriptionOrderSelector());
        CustomerAssignmentService customerAssignmentService = new CustomerAssignmentService();
        Util.mockDML = true;

        Map<Id, Opportunity> oldOppMap = (Map<Id, Opportunity>) JSON.deserialize(oldOppMapJson, Map<Id, Opportunity>.class);
        Map<Id, Opportunity> newOppMap = (Map<Id, Opportunity>) JSON.deserialize(newOppMapJson, Map<Id, Opportunity>.class);

        customerAssignmentService.updateAssignmentAgreements(oldOppMap, newOppMap);
        List<Subscription_Order__c> subscriptionOrdersToUpdate = (List<Subscription_Order__c>) Util.objectsUpdatedIfMockingDML;

        System.assertEquals(3, subscriptionOrdersToUpdate.size(), 'Expected to update three orders');
        for (Subscription_Order__c so : subscriptionOrdersToUpdate) {
            switch on (String) so.Id {
                when 'a9W0v0000000000AAA' {
                    System.assertEquals('800000000000000AAA', so.Client_Assignment_Agreement__c);
                } when 'a9W0v0000000002AAA' {
                    System.assertEquals('800000000000003AAA', so.Client_Assignment_Agreement__c);
                } when 'a9W0v0000000003AAA' {
                    System.assertEquals(null, so.Client_Assignment_Agreement__c);
                } when else {
                    System.assert(false, 'Did not expect SO ' + so.Id + ' to be updated');
                }
            }
        }
    }

    @IsTest
    private static void testFindContractsWithUpdatedAgreements() {
        Map<Id, Contract> oldContractMap = (Map<Id, Contract>) JSON.deserialize(oldContractMapJson, Map<Id, Contract>.class);
        Map<Id, Contract> newContractMap = (Map<Id, Contract>) JSON.deserialize(newContractMapJson, Map<Id, Contract>.class);

        Map<Id, Id> contractToAssignmentAgreementMap =
            new CustomerAssignmentService().getContractsWithUpdatedAssignmentAgreements(oldContractMap, newContractMap);
        System.assertEquals(3, contractToAssignmentAgreementMap.size(), 'Expected to find three contracts with updated assignment agreements');
        for (Id contractId : contractToAssignmentAgreementMap.keySet()) {
            System.assertNotEquals('800000000000008', contractId, 'This contract should not have a changed assignment agreement');
        }
    }

    @IsTest
    private static void testUpdateAssignmentAgreementsFromContract() {
        Map<String, Boolean> featureFlagMap = new Map<String, Boolean>{'Customer_Contract_Object'=>true};
        CustomerAssignmentService.featureService =
            (FeatureService) Test.createStub(FeatureService.class, new FeatureService.Mock(featureFlagMap));
        CustomerAssignmentService.subscriptionOrderSelector =
            (SubscriptionOrderSelector) Test.createStub(SubscriptionOrderSelector.class, new MockSubscriptionOrderSelector());
        CustomerAssignmentService customerAssignmentService = new CustomerAssignmentService();
        Util.mockDML = true;

        Map<Id, Contract> oldContractMap = (Map<Id, Contract>) JSON.deserialize(oldContractMapJson, Map<Id, Contract>.class);
        Map<Id, Contract> newContractMap = (Map<Id, Contract>) JSON.deserialize(newContractMapJson, Map<Id, Contract>.class);

        customerAssignmentService.updateAssignmentAgreements(oldContractMap, newContractMap);
        List<Subscription_Order__c> subscriptionOrdersToUpdate = (List<Subscription_Order__c>) Util.objectsUpdatedIfMockingDML;

        System.assertEquals(3, subscriptionOrdersToUpdate.size(), 'Expected to update three orders');
        for (Subscription_Order__c so : subscriptionOrdersToUpdate) {
            switch on (String) so.Id {
                when 'a9W0v0000000000AAA' {
                    System.assertEquals('800000000000000AAA', so.Client_Assignment_Agreement__c);
                } when 'a9W0v0000000002AAA' {
                    System.assertEquals('800000000000003AAA', so.Client_Assignment_Agreement__c);
                } when 'a9W0v0000000003AAA' {
                    System.assertEquals(null, so.Client_Assignment_Agreement__c);
                } when else {
                    System.assert(false, 'Did not expect SO ' + so.Id + ' to be updated');
                }
            }
        }
    }

    public class MockSubscriptionOrderSelector extends MockProvider {
        public MockSubscriptionOrderSelector() {
        }
        public override Object handleMethodCall(MethodCall methodCall) {
            Set<Id> parentIds = (Set<Id>) methodCall.listOfArgs[0];
            switch on methodCall.stubbedMethodName {
                when 'selectApprovedByOppIds' {
                    String json = '[' +
                        '{"Id":"a9W0v0000000000AAA",' +
                        '"Client_Assignment_Agreement__c":"8000v000000EXYLAA4",' +
                        '"Utility_Account_Subscription__r":{"Id":"a1d0v000003Y3AxAAK","Opportunity__c":"006000000000000AAA"}},' +
                        '{"Id":"a9W0v0000000002AAA",' +
                        '"Client_Assignment_Agreement__c":"8000v000000EXYLAA4",' +
                        '"Utility_Account_Subscription__r":{"Id":"a1d0v000003Y3AyAAK","Opportunity__c":"006000000000002AAA"}},' +
                        '{"Id":"a9W0v0000000003AAA",' +
                        '"Client_Assignment_Agreement__c":"8000v000000EXYLAA4",' +
                        '"Utility_Account_Subscription__r":{"Id":"a1d0v000003Y3AyAAK","Opportunity__c":"006000000000003AAA"}}' +
                        ']';
                    return (List<Subscription_Order__c>) System.JSON.deserialize(json, List<Subscription_Order__c>.class);
                } when 'selectApprovedByContractIds' {
                    String json = '[' +
                        '{"Id":"a9W0v0000000000AAA",' +
                        '"Client_Assignment_Agreement__c":"8000v000000EXYLAA4",' +
                        '"Utility_Account_Subscription__r":{"Id":"a1d0v000003Y3B1AAK","Opportunity__r":{"Id":"006000000000000AAA","ContractId":"800000000000007"}}},' +
                        '{"Id":"a9W0v0000000002AAA",' +
                        '"Client_Assignment_Agreement__c":"8000v000000EXYLAA4",' +
                        '"Utility_Account_Subscription__r":{"Id":"a1d0v000003Y3B2AAK","Opportunity__r":{"Id":"006000000000002AAA","ContractId":"800000000000009"}}},' +
                        '{"Id":"a9W0v0000000003AAA",' +
                        '"Client_Assignment_Agreement__c":"8000v000000EXYLAA4",' +
                        '"Utility_Account_Subscription__r":{"Id":"a1d0v000003Y3B2AAK","Opportunity__r":{"Id":"006000000000003AAA","ContractId":"800000000000000"}}}' +
                        ']';
                    return (List<Subscription_Order__c>) System.JSON.deserialize(json, List<Subscription_Order__c>.class);
                }
            }
            return null;
        }
    }
}