/**
 * @description Created by PeterYao on 11/14/2020.
 */
@IsTest
public with sharing class PartnerSSSEligibilitySelectorTest {
    @TestSetup
    @SuppressWarnings('PMD.AvoidHardcodingId')
    public static void testSetup() {
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

        Product2 product1 = new Product2(
            Name = '10% Product',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = True);
        insert product1;

        Commission_Structure__c commissionOne = new Commission_Structure__c(
            Name = 'Commission Structure One',
            Partner__c = partner.Id,
            Partner_Account__c = partnerAccount.Id,
            Product__c = product1.Id,
            Active__c = true,
            Cents_kW_DC_Up_Front__c = 0.10,
            Cents_kW_DC_First_Bill__c = 0.23,
            Cents_kW_DC_First_Bill_Paid__c = 0.11
        );

        Commission_Structure__c commissionTwo = new Commission_Structure__c(
            Name = 'Commission Structure Two',
            Partner__c = partner2.Id,
            Partner_Account__c = partnerAccount2.Id,
            Product__c = product1.Id,
            Active__c = true,
            Cents_kW_DC_Up_Front__c = 0.12,
            Cents_kW_DC_First_Bill_Paid__c = 0.50
        );
        insert new List<Commission_Structure__c>{commissionOne, commissionTwo};

        Partner_Shared_Solar_System_Eligibility__c partner1Eligibility =
            new Partner_Shared_Solar_System_Eligibility__c(
                Account__c = partnerAccount.Id,
                Shared_Solar_System__c = sss.Id,
                Commission_Structure__c = commissionOne.Id,
                Active__c = true
            );

        Partner_Shared_Solar_System_Eligibility__c partner2Eligibility =
            new Partner_Shared_Solar_System_Eligibility__c(
                Account__c = partnerAccount2.Id,
                Shared_Solar_System__c = sss.Id,
                Commission_Structure__c = commissionTwo.Id,
                Active__c = false
            );
        insert new List<Partner_Shared_Solar_System_Eligibility__c>{partner1Eligibility, partner2Eligibility};
    }
    @IsTest
    private static void testGetPartnersBySSS() {
        Shared_Solar_System__c sss = [
            SELECT Id
            FROM Shared_Solar_System__c
            LIMIT 1
        ];

        Account partnerAccount = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Partner Account'
            LIMIT 1
        ];
        Partner__c partner = [
            SELECT Id
            FROM Partner__c
            WHERE Name = 'Test Partner'
            LIMIT 1
        ];

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

    @IsTest
    public static void testGetSSSByPartner() {
        Map<Id, Account> accountIds = new Map<Id, Account>([SELECT Id FROM Account]);

        List<Partner_Shared_Solar_System_Eligibility__c> eligibilityRecords = new PartnerSSSEligibilitySelector().getSSSByPartner(accountIds.keySet());
        System.assertEquals(2, eligibilityRecords.size(), 'Selector should return 2 eligibility junction records');
    }
}