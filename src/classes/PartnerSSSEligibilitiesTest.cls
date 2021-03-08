/**
 * Created by PeterYao on 3/1/2021.
 */
@IsTest
private with sharing class PartnerSSSEligibilitiesTest {
    @IsTest
    private static void validateShouldPreventOverlappingEligibilities() {
        List<Partner_Shared_Solar_System_Eligibility__c> existingEligibilities =
            new List<Partner_Shared_Solar_System_Eligibility__c>();
        existingEligibilities.add(new Partner_Shared_Solar_System_Eligibility__c(
            Id = Util.getFakeId(Partner_Shared_Solar_System_Eligibility__c.SObjectType),
            Account__c = Util.getFakeId(Account.SObjectType),
            Shared_Solar_System__c = Util.getFakeId(Shared_Solar_System__c.SObjectType),
            Start_Date__c = Date.newInstance(2020,1,1),
            End_Date__c = Date.newInstance(2020,1,31)
        ));
        MockedPartnerSSSEligibilitySelector mockedPartnerSSSEligibilitySelector = new MockedPartnerSSSEligibilitySelector();
        mockedPartnerSSSEligibilitySelector.eligibilitiesToReturn = existingEligibilities;
        PartnerSSSEligibilities.partnerSSSEligibilitySelector =
            (PartnerSSSEligibilitySelector) Test.createStub(PartnerSSSEligibilitySelector.class, mockedPartnerSSSEligibilitySelector);

        Partner_Shared_Solar_System_Eligibility__c newEligibility = new Partner_Shared_Solar_System_Eligibility__c();
        new PartnerSSSEligibilities(new List<Partner_Shared_Solar_System_Eligibility__c>{newEligibility}).validate();
        System.assert(newEligibility.hasErrors(), 'Eligibility record should have an error because of a missing start date');
        System.assert(newEligibility.getErrors()[0].getMessage().contains('start date must be populated'),
            'Expected "start date must be populated", but got: ' + newEligibility.getErrors()[0].getMessage());

        newEligibility = new Partner_Shared_Solar_System_Eligibility__c(
            Account__c = Util.getFakeId(Account.SObjectType),
            Shared_Solar_System__c = Util.getFakeId(Shared_Solar_System__c.SObjectType),
            Start_Date__c = Date.newInstance(2020,12,31),
            End_Date__c = Date.newInstance(2020,1,1)
        );
        new PartnerSSSEligibilities(new List<Partner_Shared_Solar_System_Eligibility__c>{newEligibility}).validate();
        System.assert(newEligibility.hasErrors(), 'Eligibility record should have an error because of an end date before the start date');
        System.assert(newEligibility.getErrors()[0].getMessage().contains('end date should be after the start date'),
            'Expected "end date should be after the start date", but got: ' + newEligibility.getErrors()[0].getMessage());

        newEligibility = new Partner_Shared_Solar_System_Eligibility__c(
            Account__c = Util.getFakeId(Account.SObjectType),
            Shared_Solar_System__c = Util.getFakeId(Shared_Solar_System__c.SObjectType),
            Start_Date__c = Date.newInstance(2019,12,1),
            End_Date__c = Date.newInstance(2020,1,1)
        );
        new PartnerSSSEligibilities(new List<Partner_Shared_Solar_System_Eligibility__c>{newEligibility}).validate();
        System.assert(newEligibility.hasErrors(), 'Eligibility record should have an error, since it ends the same day as the existing one');

        newEligibility = new Partner_Shared_Solar_System_Eligibility__c(
            Account__c = Util.getFakeId(Account.SObjectType),
            Shared_Solar_System__c = Util.getFakeId(Shared_Solar_System__c.SObjectType),
            Start_Date__c = Date.newInstance(2019,12,1),
            End_Date__c = Date.newInstance(2020,2,3)
        );
        new PartnerSSSEligibilities(new List<Partner_Shared_Solar_System_Eligibility__c>{newEligibility}).validate();
        System.assert(newEligibility.hasErrors(), 'Eligibility record should have an error, since it encompasses the existing one');
    }

    @IsTest
    private static void validateShouldAllowDistinctEligibilities() {
        List<Partner_Shared_Solar_System_Eligibility__c> existingEligibilities =
            new List<Partner_Shared_Solar_System_Eligibility__c>();
        existingEligibilities.add(new Partner_Shared_Solar_System_Eligibility__c(
            Id = Util.getFakeId(Partner_Shared_Solar_System_Eligibility__c.SObjectType),
            Account__c = Util.getFakeId(Account.SObjectType),
            Shared_Solar_System__c = Util.getFakeId(Shared_Solar_System__c.SObjectType),
            Start_Date__c = Date.newInstance(2020,1,1),
            End_Date__c = Date.newInstance(2020,1,31)
        ));
        MockedPartnerSSSEligibilitySelector mockedPartnerSSSEligibilitySelector = new MockedPartnerSSSEligibilitySelector();
        mockedPartnerSSSEligibilitySelector.eligibilitiesToReturn = existingEligibilities;
        PartnerSSSEligibilities.partnerSSSEligibilitySelector =
            (PartnerSSSEligibilitySelector) Test.createStub(PartnerSSSEligibilitySelector.class, mockedPartnerSSSEligibilitySelector);

        Partner_Shared_Solar_System_Eligibility__c newEligibility = new Partner_Shared_Solar_System_Eligibility__c(
            Account__c = Util.getFakeId(Account.SObjectType),
            Shared_Solar_System__c = Util.getFakeId(Shared_Solar_System__c.SObjectType),
            Start_Date__c = Date.newInstance(2019,12,1),
            End_Date__c = Date.newInstance(2019,12,31)
        );
        new PartnerSSSEligibilities(new List<Partner_Shared_Solar_System_Eligibility__c>{newEligibility}).validate();
        System.assert(!newEligibility.hasErrors(), 'Eligibility record should not have any errors, since it starts and ends before the existing record');

        newEligibility = new Partner_Shared_Solar_System_Eligibility__c(
            Account__c = Util.incrementFakeId(Util.getFakeId(Account.SObjectType)),
            Shared_Solar_System__c = Util.getFakeId(Shared_Solar_System__c.SObjectType),
            Start_Date__c = Date.newInstance(2019,12,1),
            End_Date__c = Date.newInstance(2020,2,3)
        );
        new PartnerSSSEligibilities(new List<Partner_Shared_Solar_System_Eligibility__c>{newEligibility}).validate();
        System.assert(!newEligibility.hasErrors(), 'Should not have an error since the new eligibility is for a different partner account');

        newEligibility = new Partner_Shared_Solar_System_Eligibility__c(
            Account__c = Util.getFakeId(Account.SObjectType),
            Shared_Solar_System__c = Util.incrementFakeId(Util.getFakeId(Shared_Solar_System__c.SObjectType)),
            Start_Date__c = Date.newInstance(2019,12,1),
            End_Date__c = Date.newInstance(2020,2,3)
        );
        new PartnerSSSEligibilities(new List<Partner_Shared_Solar_System_Eligibility__c>{newEligibility}).validate();
        System.assert(!newEligibility.hasErrors(), 'Should not have an error since the new eligibility is for a different SSS');

        newEligibility = new Partner_Shared_Solar_System_Eligibility__c(
            Account__c = Util.getFakeId(Account.SObjectType),
            Shared_Solar_System__c = Util.incrementFakeId(Util.getFakeId(Shared_Solar_System__c.SObjectType)),
            Start_Date__c = Date.newInstance(2019,12,1),
            End_Date__c = Date.newInstance(2020,2,3)
        );
        new PartnerSSSEligibilities(new List<Partner_Shared_Solar_System_Eligibility__c>{newEligibility}).validate();
        System.assert(!newEligibility.hasErrors(), 'Should not have an error since the new eligibility is for a different SSS');

    }

    public class MockedPartnerSSSEligibilitySelector extends MockProvider {
        public List<Partner_Shared_Solar_System_Eligibility__c> eligibilitiesToReturn;

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getSSSByPartner' {
                    return eligibilitiesToReturn;
                }
            }
            return null;
        }
    }

}