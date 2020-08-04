/*************************************************************************************
 * Created By: peteryao on 1/19/19  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class OpportunitiesSelectorTest {
    @TestSetup public static void testSetup() {
        Util.disableAllTriggers();

        TestFactory.insertBWAddress();
        Test.loadData(Utility__c.SObjectType, 'TestCSUtility');
        Test.loadData(Utility_NMC_Tariff__c.SObjectType, 'TestCSUtilityNMCTariff');
        Test.loadData(Load_U__c.SObjectType, 'TestCSLoadU');
        Test.loadData(ChargentBase__Gateway__c.SObjectType, 'TestCSGateway');
        Test.loadData(Contact.SObjectType, 'TestCSContact');
        Test.loadData(Account.SObjectType, 'TestCSAccount');
        Test.loadData(Entity__c.SObjectType, 'TestCSEntity');
        Test.loadData(Shared_Solar_System__c.SObjectType, 'TestCSSharedSolarSystem');
        Test.loadData(Utility_Account_Log__c.SObjectType, 'TestCSUtilityAccountLog');
        Test.loadData(Partner__c.SObjectType,'TestRLPartner');
        Test.loadData(Opportunity.SObjectType, 'TestCSOpportunity');
        Test.loadData(Utility_Account_Subscription__c.SObjectType, 'TestCSUtilityAccountSubscription');

        Util.enableAllTriggers();
    }

    @IsTest public static void testSelectAllCompleteCSWithUASesAndSystemBills() {
        System.assert(OpportunitiesSelector.selectAllCompleteCSWithUASesAndSystemBills().size() > 0, 'Expected Complete CS Opps');
    }

    @IsTest public static void testSelectForContractSend() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        System.assertNotEquals(null, OpportunitiesSelector.selectForContractSend(opp.Id));
    }

    @IsTest
    public static void testSelectForMap() {
        List<Opportunity> opps = [SElECT Id FROM Opportunity LIMIT 3];
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : opps) {
            oppIds.add(opp.Id);
        }
        OpportunitiesSelector opportunitiesSelector = new OpportunitiesSelector();
        System.assertNotEquals(null, opportunitiesSelector.selectOpportunityMap(oppIds));
    }

    @IsTest
    public static void testGetOppsForTestMethods() {
        List<Opportunity> opps = [SELECT Id FROM Opportunity LIMIT 3];
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : opps) {
            oppIds.add(opp.Id);
        }
        OpportunitiesSelector opportunitiesSelector = new OpportunitiesSelector();
        System.assertNotEquals(null, opportunitiesSelector.getOppsForTestMethods(oppIds));
    }

    @IsTest public static void testCommissionQueries() {
        List<Opportunity> oppList = [
            SELECT Id, AccountId
            FROM Opportunity
            LIMIT 3
        ];

        Commission_Structure__c onlyBill = new Commission_Structure__c(
            Cents_kW_DC_First_Bill_Paid__c = 0.07,
            Cents_kW_DC_First_Bill__c = 0
        );
        insert onlyBill;
        Commission_Structure__c onlyPayment = new Commission_Structure__c(
            Cents_kW_DC_First_Bill_Paid__c = 0,
            Cents_kW_DC_First_Bill__c = 0.13
        );
        insert onlyPayment;
        Commission_Structure__c both = new Commission_Structure__c(
            Cents_kW_DC_First_Bill_Paid__c = 0.07,
            Cents_kW_DC_First_Bill__c = 0.13
        );
        insert both;

        oppList[0].Commission_Structure__c = onlyBill.Id;
        oppList[1].Commission_Structure__c = both.Id;
        oppList[2].Commission_Structure__c = onlyPayment.Id;

        Account newAccount = new Account(Name = 'Test Acct');
        insert newAccount;
        Set<Id> accountIdSet = new Set<Id>{newAccount.Id};
        OpportunitiesSelector selector = new OpportunitiesSelector();
        System.assertEquals(0, selector.selectWithoutFirstInvoiceCommission(accountIdSet).size());
        System.assertEquals(0, selector.selectWithoutFirstPaymentCommission(accountIdSet).size());
    }

    @IsTest
    public static void testSelectBySSSId() {
        Opportunity opp = [
            SELECT Id, Shared_Solar_System__c
            FROM Opportunity
            WHERE Shared_Solar_System__c != null
            LIMIT 1
        ];
        Set<Id> sssIds = new Set<Id>();
        sssIds.add(opp.Shared_Solar_System__c);
        OpportunitiesSelector selector = new OpportunitiesSelector();
        System.assert(selector.getOppsFromSSS(sssIds).size() > 0);
    }

    @IsTest
    public static void testSelectByIdSet(){
        Opportunity opp = [
            SELECT Id, Shared_Solar_System__c
            FROM Opportunity
            LIMIT 1
        ];
        Set<Id> oppIds = new Set<Id>{opp.Id};
        OpportunitiesSelector selector = new OpportunitiesSelector();
        System.assert(selector.selectByIdWithApprovedCommissionPayment(oppIds).size() > 0);
    }

    @IsTest
    public static void testSelectOpportunitiesForClientAssignment(){
        List<Entity__c> entities = [
            SELECT Id
            FROM Entity__c
        ];
        System.assert(entities.size() > 0);
        List<String> entityIds = new List<String>();
        for (Entity__c entity : entities){
            entityIds.add(entity.Id);
        }
        List<Opportunity> opportunities;
        opportunities = OpportunitiesSelector.selectOpportunitiesForClientAssignment(new List<List<String>>{entityIds})[0];

        System.assert(opportunities.size() > 0);
    }

    @IsTest
    public static void testSelectFirstCustomerSignedDateByAssignmentAgreementOFF() {
        Map<String, Boolean> featureFlagMap = new Map<String, Boolean>{'Customer_Contract_Object'=>false};
        OpportunitiesSelector.featureService =
            (FeatureService) Test.createStub(FeatureService.class, new FeatureService.Mock(featureFlagMap));
        Account clientAccount = [
            SELECT Id
            FROM Account
            WHERE Name = 'Goldman'
            LIMIT 1
        ];
        Id aaTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Assignment Agreement').getRecordTypeId();

        Contract assignmentAgreement = new Contract(
            AccountId = clientAccount.Id,
            RecordTypeId = aaTypeId,
            CompanySignedDate = System.today().addMonths(-3)
        );
        insert assignmentAgreement;

        List<Opportunity> opportunities = [
            SELECT Id
            FROM Opportunity
        ];

        for (Opportunity opp: opportunities) {
            opp.Assignment_Agreement__c = assignmentAgreement.Id;
        }
        update opportunities;

        OpportunitiesSelector oppSelector = new OpportunitiesSelector();
        Map<Id, Date> checkMap = oppSelector.selectFirstCustomerSignedDateByAssignmentAgreement(new Set<Id> {assignmentAgreement.Id});

        System.assertEquals(4, checkMap.keySet().size(), 'Test setup has opportunities for 4 Shared Solar Systems');
        for (Date d : checkMap.values()) {
            System.assertEquals(System.today().addMonths(-3), d);
        }
    }

    @IsTest
    public static void testSelectFirstCustomerSignedDateByAssignmentAgreementON() {
        Map<String, Boolean> featureFlagMap = new Map<String, Boolean>{'Customer_Contract_Object'=>true};
        OpportunitiesSelector.featureService =
            (FeatureService) Test.createStub(FeatureService.class, new FeatureService.Mock(featureFlagMap));

        Account clientAccount = [
            SELECT Id
            FROM Account
            WHERE Name = 'Goldman'
            LIMIT 1
        ];

        Id aaTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Assignment Agreement').getRecordTypeId();

        Contract assignmentAgreement = new Contract(
            RecordTypeId = aaTypeId,
            CompanySignedDate = System.today().addMonths(-3),
            AccountId = clientAccount.Id
        );
        insert assignmentAgreement;

        List<Opportunity> opportunities = [
            SELECT Id, ContractId
            FROM Opportunity
        ];

        Map<Integer, Contract> contractMap = new Map<Integer, Contract>();
        for (Integer i = 0 ; i < opportunities.size(); i++) {
            Contract customerContract = new Contract(
                AccountId = clientAccount.Id,
                Assignment_Agreement__c = assignmentAgreement.Id
            );
            contractMap.put(i, customerContract);
        }
        insert contractMap.values();

        Integer counter = 0;
        for (Opportunity opp: opportunities) {
            opp.ContractId = contractMap.get(counter).Id;
            counter++;
        }
        update opportunities;

        OpportunitiesSelector oppSelector = new OpportunitiesSelector();
        Map<Id, Date> checkMap = oppSelector.selectFirstCustomerSignedDateByAssignmentAgreement(new Set<Id> {assignmentAgreement.Id});

        System.assertEquals(4, checkMap.keySet().size(), 'Test setup has opportunities for 4 Shared Solar Systems');
        for (Date d : checkMap.values()) {
            System.assertEquals(System.today().addMonths(-3), d);
        }
    }

    @IsTest
    public static void testGetCompleteOppsWithoutContracts(){
        OpportunitiesSelector oppSelector = new OpportunitiesSelector();
        List<Opportunity> oppList = oppSelector.getCompleteOppsWithoutContracts();

        System.assertEquals(17, oppList.size());
    }
}