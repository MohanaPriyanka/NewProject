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
        update oppList;
        Account newAccount = new Account(Name = 'Test Acct');
        insert newAccount;
        Set<Id> accountIdSet = new Set<Id>{newAccount.Id};
        OpportunitiesSelector selector = new OpportunitiesSelector();
        System.assertEquals(0, selector.selectWithoutFirstInvoiceCommission(accountIdSet).size());
        System.assertEquals(0, selector.selectWithoutFirstPaymentCommission(accountIdSet).size());
        System.assertEquals(0, selector.selectWithoutFirstInvoiceCommissionByOpp(CollectionUtil.getIdSet(oppList)).size());
        System.assertEquals(0, selector.selectWithoutFirstPaymentCommissionByOpp(CollectionUtil.getIdSet(oppList)).size());
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
        System.assert(selector.selectByIdWithCommissionPayment(oppIds).size() > 0);
    }

    @IsTest
    public static void testSelectOpportunitiesForClientAssignment(){
        Entity__c entity = [
            SELECT Id
            FROM Entity__c
            WHERE Name = 'BarrettProjCo'
            LIMIT 1
        ];
        List<Opportunity> opportunities =
            OpportunitiesSelector.selectOpportunitiesForClientAssignment(entity.Id, System.today(), false);
        System.assert(opportunities.size() > 0,
            'The TestCSOpportunities resource should load all BlueWave Acquired customers, but selectOpportunitiesForClientAssignment found none');
        opportunities =
            OpportunitiesSelector.selectOpportunitiesForClientAssignment(entity.Id, System.today(), true);
        System.assertEquals(0, opportunities.size(),
            'The TestCSOpportunities resource should load no Client Acquired customers');
    }

    @IsTest
    public static void testGetCustomerOpportunitiesByAssignmentAgreement(){
        Account clientAccount = new Account(Name = 'Client');
        insert clientAccount;
        Id rtAssign = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Assignment Agreement').getRecordTypeId();
        Contract assignmentAgreement = new Contract(
            Name = 'Assignment Agreement',
            RecordTypeId = rtAssign,
            AccountId = clientAccount.Id
        );
        insert assignmentAgreement;
        Contract customerContract = new Contract(
            Name = 'Customer Contract',
            AccountId = clientAccount.Id,
            Assignment_Agreement__c = assignmentAgreement.Id
        );
        insert customerContract;

        List<Opportunity> opportunityList = [
            SELECT ContractId
            FROM Opportunity
        ];
        for (Opportunity opp : opportunityList){
            opp.ContractId = customerContract.Id;
        }
        update opportunityList;

        OpportunitiesSelector oppSelector = new OpportunitiesSelector();
        List<Opportunity> oppList = oppSelector.getCustomerOpportunitiesByAssignmentAgreement(assignmentAgreement.Id);
        System.assert(oppList.size() > 0);
    }

    @IsTest
    public static void testSelectFirstCustomerSignedDateByAssignmentAgreementON() {
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

    @IsTest
    public static void testGetAggregateOpportunitySubscriptions() {
        Opportunity opp = [
            SELECT Id, Shared_Solar_System__c
            FROM Opportunity
            LIMIT 1
        ];
        Set<Id> oppIds = new Set<Id>{opp.Id};
        OpportunitiesSelector selector = new OpportunitiesSelector();
        System.assert(selector.getAggregateOpportunitySubscriptions(oppIds).size() > 0);
    }

    @IsTest
    public static void testSelectRetiredOpportunities(){
        Opportunity opp = [
            SELECT Id, Date_Removed_from_Project__c
            FROM Opportunity
            LIMIT 1
        ];
        opp.Date_Removed_from_Project__c = System.today();
        update opp;
        System.assertNotEquals(null, new OpportunitiesSelector().selectRetiredOpportunities(new Set<Id>{opp.Id}),
            'Expect a list of Opportunities with Date Removed From Project populated');
    }
}