/**
 * @description Created by jeffparlin on 1/6/22.
 */
@IsTest
@SuppressWarnings('PMD.AvoidHardcodingId')
public without sharing class PartnerCommissionStructureLocatorTest {

    private static final Map<String, Id> MOCK_RECORD_IDS = new Map<String, String>{
        'partnerRecord' => 'a0s3K0000006wCRQAY',
        'partnerAccountA' => '0010a00001Ljv4ZAAR',
        'partnerAccountB' => '0010a00001Ljx5ZBBC',
        'opportunityA' => '0061U000004opJiQAI',
        'opportunityB' => '0061U000004opKiQAI',
        'opportunityC' => '0061U000004opLiQAI',
        'systemA' => 'a1J3K0000005hM1UAI',
        'systemB' => 'a1J3K0000005hM0UAI',
        'commissionStructureA' => 'a4w3K0000000EMABC2',
        'commissionStructureB' => 'a4w3K0000000EMDEF2'
    };
    private static Opportunity mockOpportunityA = new Opportunity( // Only legacy Partner_tag_lookup__c set
        Id = MOCK_RECORD_IDS.get('opportunityA'),
        Shared_Solar_System__c = MOCK_RECORD_IDS.get('systemB'),
        Partner_tag_lookup__c = MOCK_RECORD_IDS.get('partnerRecord') // Should map to Partner Account B
    );
    private static Opportunity mockOpportunityB = new Opportunity( // Only Partner_Account__c set
        Id = MOCK_RECORD_IDS.get('opportunityB'),
        Shared_Solar_System__c = MOCK_RECORD_IDS.get('systemA'),
        Partner_Account__c = MOCK_RECORD_IDS.get('partnerAccountA')
    );
    private static Opportunity mockOpportunityC = new Opportunity( // Partner Account reference set, but no PSSSE
        Id = MOCK_RECORD_IDS.get('opportunityC'),
        Shared_Solar_System__c = MOCK_RECORD_IDS.get('systemA'),
        Partner_Account__c = Util.getFakeId(Account.SObjectType) // No mock Partner_Shared_Solar_System_Eligibility__c
    );

    @IsTest
    private static void mockSetStructureOnOpportunities() {
        // Setup Test
        useMocks();
        List<Opportunity> opportunities = new List<Opportunity>{
            mockOpportunityA, mockOpportunityB, mockOpportunityC
        };

        // Run Test
        PartnerCommissionStructureLocator locator = new PartnerCommissionStructureLocator(opportunities);
        locator.setStructureOnOpportunities();

        // Verify Results
        System.assertEquals(MOCK_RECORD_IDS.get('commissionStructureB'), mockOpportunityA.Commission_Structure__c,
            'Mock Opportunity A should have Commission Structure B applied.');
        System.assertEquals(MOCK_RECORD_IDS.get('commissionStructureA'), mockOpportunityB.Commission_Structure__c,
            'Mock Opportunity B should have Commission Structure A applied.');
        System.assertEquals(null, mockOpportunityC.Commission_Structure__c,
            'No Commission Should have been set on Mock Opportunity C.');
    }

    @IsTest
    private static void systemTestPartnerQuery() {
        Account partnerAccount1 = new Account(Name = 'Partner Account 1');
        Account partnerAccount2 = new Account(Name = 'Partner Account 2');
        insert new List<Account>{partnerAccount1, partnerAccount2};

        Partner__c partner1 = new Partner__c(Name = 'Partner 1', Account__c = partnerAccount1.Id);
        Partner__c partner2 = new Partner__c(Name = 'Partner 2', Account__c = partnerAccount2.Id);
        insert new List<Partner__c>{partner1, partner2};

        Opportunity opp1 = new Opportunity(Partner_tag_lookup__c = partner1.Id);
        Opportunity opp2 = new Opportunity(Partner_tag_lookup__c = partner2.Id);
        Opportunity opp3 = new Opportunity(Partner_tag_lookup__c = null);

        PartnerSelector partnerSelector = new PartnerSelector();
        Map<Id,Id> result = partnerSelector.legacyGetPartnerAccountIdsByOpp(new List<Opportunity>{opp1, opp2, opp3});

        System.assertEquals(2, result.size());
        System.assertEquals(partnerAccount1.Id, result.get(partner1.Id));
        System.assertEquals(partnerAccount2.Id, result.get(partner2.Id));
    }

    private static void useMocks() {
        PartnerCommissionStructureLocator.commissionStructureSelector = (CommissionStructureSelector)
            Test.createStub(CommissionStructureSelector.class, new MockCommStructureSelector());
        PartnerCommissionStructureLocator.eligibilitySelector = (PartnerSSSEligibilitySelector)
            Test.createStub(PartnerSSSEligibilitySelector.class, new MockPartnerSSSEligibilitySelector());
        PartnerCommissionStructureLocator.partnerSelector = (PartnerSelector)
            Test.createStub(PartnerSelector.class, new MockPartnerSelector());
    }

    public class MockCommStructureSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            sfab_FabricatedSObject commStructure1 = new sfab_FabricatedSObject(Commission_Structure__c.class);
            commStructure1.setField(Commission_Structure__c.Id, MOCK_RECORD_IDS.get('commissionStructureA'));
            commStructure1.setField(Commission_Structure__c.Partner__c, MOCK_RECORD_IDS.get('partnerRecord'));
            commStructure1.setField(Commission_Structure__c.Cents_kW_DC_Up_Front__c, 0.1000);
            Commission_Structure__c commissionStructureA = (Commission_Structure__c) commStructure1.toSObject();

            sfab_FabricatedSObject commStructure2 = new sfab_FabricatedSObject(Commission_Structure__c.class);
            commStructure2.setField(Commission_Structure__c.Id, MOCK_RECORD_IDS.get('commissionStructureB'));
            commStructure2.setField(Commission_Structure__c.Partner__c, MOCK_RECORD_IDS.get('partnerRecord'));
            commStructure2.setField(Commission_Structure__c.Cents_kW_DC_Up_Front__c, 0.1400);
            Commission_Structure__c commissionStructureB = (Commission_Structure__c) commStructure2.toSObject();

            switch on methodCall.stubbedMethodName {
                when 'getCommissionStructureMapByIds' {
                    Map<Id, Commission_Structure__c> commissionStructureMap = new Map<Id, Commission_Structure__c>();
                    commissionStructureMap.put(commissionStructureA.Id, commissionStructureA);
                    commissionStructureMap.put(commissionStructureB.Id, commissionStructureB);
                    return commissionStructureMap;
                }
            }
            return null;
        }
    }

    public class MockPartnerSSSEligibilitySelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            sfab_FabricatedSObject eligibility1 = new sfab_FabricatedSObject(Partner_Shared_Solar_System_Eligibility__c.class);
            eligibility1.setField(Partner_Shared_Solar_System_Eligibility__c.Account__c, MOCK_RECORD_IDS.get('partnerAccountA'));
            eligibility1.setField(Partner_Shared_Solar_System_Eligibility__c.Shared_Solar_System__c, MOCK_RECORD_IDS.get('systemA'));
            eligibility1.setField(Partner_Shared_Solar_System_Eligibility__c.Commission_Structure__c, MOCK_RECORD_IDS.get('commissionStructureA'));
            Partner_Shared_Solar_System_Eligibility__c eligibilityA = (Partner_Shared_Solar_System_Eligibility__c) eligibility1.toSObject();

            sfab_FabricatedSObject eligibility2 = new sfab_FabricatedSObject(Partner_Shared_Solar_System_Eligibility__c.class);
            eligibility2.setField(Partner_Shared_Solar_System_Eligibility__c.Account__c, MOCK_RECORD_IDS.get('partnerAccountB'));
            eligibility2.setField(Partner_Shared_Solar_System_Eligibility__c.Shared_Solar_System__c, MOCK_RECORD_IDS.get('systemB'));
            eligibility2.setField(Partner_Shared_Solar_System_Eligibility__c.Commission_Structure__c, MOCK_RECORD_IDS.get('commissionStructureB'));
            Partner_Shared_Solar_System_Eligibility__c eligibilityB = (Partner_Shared_Solar_System_Eligibility__c) eligibility2.toSObject();

            switch on methodCall.stubbedMethodName {
                when 'getSSSByPartner' {
                    return new List<Partner_Shared_Solar_System_Eligibility__c>{
                        eligibilityA, eligibilityB
                    };
                }
            }
            return null;
        }
    }

    /**
     * @description TODO: Deprecate in the future when Partner__c object becomes obsolete
     */
    public class MockPartnerSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'legacyGetPartnerAccountIdsByOpp' {
                    Map<Id, Id> queryResult = new Map<Id, Id>(); // Maps Opportunity to Partner Account id
                    queryResult.put(MOCK_RECORD_IDS.get('partnerRecord'), MOCK_RECORD_IDS.get('partnerAccountB'));
                    return queryResult;
                }
            }
            return null;
        }
    }
}