/**
 * @description Created by PeterYao on 11/14/2020.
 */
@IsTest
public with sharing class PartnerSSSEligibilitySelectorTest {
    @IsTest
    private static void testGetPartnersBySSS() {
        Account partnerAccount = new Account(
            Name = 'Test Partner Account',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Account').getRecordTypeId()
        );
        Account partnerAccount2 = new Account(
            Name = 'Test Partner Account2',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Account').getRecordTypeId()
        );
        insert new List<Account>{partnerAccount, partnerAccount2};

        Partner__c partner = new Partner__c(
            Name = 'Test Partner',
            Account__c = partnerAccount.Id
        );
        Partner__c partner2 = new Partner__c(
            Name = 'Test Partner2',
            Account__c = partnerAccount2.Id
        );
        insert new List<Partner__c>{partner, partner2};
        partnerAccount.Partner__c = partner.Id;
        partnerAccount2.Partner__c = partner2.Id;
        update new List<Account>{partnerAccount, partnerAccount2};

        Shared_Solar_System__c sss = new Shared_Solar_System__c(
            Name = 'Test System'
        );
        insert sss;

        Partner_Shared_Solar_System_Eligibility__c partner1Eligibility =
            new Partner_Shared_Solar_System_Eligibility__c(
                Account__c = partnerAccount.Id,
                Shared_Solar_System__c = sss.Id,
                Active__c = true
            );
        Partner_Shared_Solar_System_Eligibility__c partner2Eligibility =
            new Partner_Shared_Solar_System_Eligibility__c(
                Account__c = partnerAccount2.Id,
                Shared_Solar_System__c = sss.Id,
                Active__c = false
            );
        insert new List<Partner_Shared_Solar_System_Eligibility__c>{partner1Eligibility, partner2Eligibility};

        MultiMap partnersBySSSMultiMap = new PartnerSSSEligibilitySelector().getPartnersBySSS();
        System.assert(partnersBySSSMultiMap.containsKey(sss.Id),
            'Expected the SSS to be selected in the multimap');
        System.assertEquals(2, partnersBySSSMultiMap.getValues(sss.Id).size(),
            'Expected to find only one partner eligible for the system (by Account and Partner Id');
        Id partnerId = (Id) partnersBySSSMultiMap.getValues(sss.Id)[0];
        if (partnerId.getSobjectType().getDescribe().getName() == 'Account') {
            System.assertEquals(partnerAccount.Id, partnerId,
                'Expected Test Partner Account to be the eligible partner, and not Test Partner 2');
        } else {
            System.assertEquals(partner.Id, partnerId,
                'Expected Test Partner Partner record to be the eligible partner, and not Test Partner 2');
        }
    }
}