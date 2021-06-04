/**
 * Created by PeterYao on 6/2/2021.
 */

@IsTest
public with sharing class ClientInvoicingBatchReconcilerTest {
    @TestSetup
    public static void setupData() {
        SharedSolarSystemHandlerTest.setupData();
        Account account = [SELECT Id FROM Account LIMIT 1];
        Contract contractA = new Contract(
            Name = 'Client Contract A',
            AccountId = account.Id,
            RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Client Contract').getRecordTypeId(),
            StartDate = System.today().addYears(-1)
        );
        insert contractA;
        Contract_Fee_Detail__c cfd = new Contract_Fee_Detail__c(
            Contract__c = contractA.Id,
            Fee__c = 0.10,
            Fee_Unit__c = 'per W',
            Acquisition_Type_Reacquisition__c = true,
            Acquisition_Cust_Group_Residential__c = true,
            Acquisition_Channels_BCS_Acquired__c = true,
            Acquisition_Channels_Non_BCS_Acquired__c = true,
            Acquisition_Sizing_Type_Upsizing__c = true,
            Acquisition_Cust_Group_Not_Specified__c = true,
            Approval_Status__c = 'Approved'
        );
        insert cfd;

        List<Shared_Solar_System__c> sharedSolarSystems = [
            SELECT Id, (SELECT Id FROM Opportunities__r LIMIT 1)
            FROM Shared_Solar_System__c
            ORDER BY Name
        ];

        List<Client_Contract__c> clientContracts = new List<Client_Contract__c>();
        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            clientContracts.add(new Client_Contract__c(
                Shared_Solar_System__c = sss.Id,
                Contract__c = contractA.Id,
                CS_Services_Type__c = 'Acquisition & Management',
                Effective_Date__c = System.today(),
                End_Date__c = System.today().addYears(1)
            ));
        }
        insert clientContracts;
        sharedSolarSystems[0].Reacquisition_Start_Date__c = System.today().addYears(-1);
        update sharedSolarSystems[0];

        Utility_Account_Subscription__c uas = [
            SELECT Id, Opportunity__c, Opportunity__r.AccountId
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__c = :sharedSolarSystems[0].Opportunities__r[0].Id
            LIMIT 1
        ];

        Subscription_Order__c so = new Subscription_Order__c(
            Effective_Date__c = System.today(),
            Type__c = 'Initial',
            Utility_Account_Subscription__c = uas.Id,
            New_Annual_kWh__c = 4800,
            Previous_Annual_kwh__c = 0
        );
        // so2 should have a Client Invoicing Type of Transfer, which will make Client Invoicing Fee $0, which we should not waive
        Subscription_Order__c so2 = new Subscription_Order__c(
            Effective_Date__c = System.today(),
            Type__c = 'Transfer',
            Utility_Account_Subscription__c = uas.Id,
            New_Annual_kWh__c = 5000,
            Previous_Annual_kwh__c = 4800
        );
        ContractRepository.clientContracts = null;
        ContractRepository.contractToFeeDetailMap = null;
        insert new List<Subscription_Order__c>{so, so2};
    }

    @IsTest
    private static void systemTest() {
        Subscription_Order__c subscriptionOrderShouldNotHaveCFD = [
            SELECT Contract_Fee_Detail__c
            FROM Subscription_Order__c
            WHERE Contract_Fee_Detail__c = NULL
            LIMIT 1
        ];
        Subscription_Order__c subscriptionOrderShouldHaveCFD = [
            SELECT Contract_Fee_Detail__c
            FROM Subscription_Order__c
            WHERE Contract_Fee_Detail__c != NULL
            LIMIT 1
        ];
        subscriptionOrderShouldNotHaveCFD.Contract_Fee_Detail__c = subscriptionOrderShouldHaveCFD.Contract_Fee_Detail__c;
        subscriptionOrderShouldHaveCFD.Contract_Fee_Detail__c = null;
        update new List<Subscription_Order__c>{subscriptionOrderShouldHaveCFD, subscriptionOrderShouldNotHaveCFD};

        Test.startTest();
        new ClientInvoicingBatchReconciler().execute(null);
        Test.stopTest();
        List<Error_Log__c> errorLogs = [
            SELECT Message__c
            FROM Error_Log__c
            WHERE Method__c = 'setSubscriptionOrderAcquisitionFee'
            AND Severity__c = :Logger.WARN
        ];
        System.assertEquals(1, errorLogs.size(), 'Expected one warning about SOs with the wrong CFD');
        System.assert(errorLogs[0].Message__c.contains(subscriptionOrderShouldHaveCFD.Id + ' has CFD: null but should have'),
            'BatchReconciler should have found subscriptionOrderShouldHaveCFD to have a null CFD');
        System.assert(errorLogs[0].Message__c.contains(subscriptionOrderShouldNotHaveCFD.Id + ' has CFD: ' + subscriptionOrderShouldNotHaveCFD.Contract_Fee_Detail__c + ' but should have'),
            'BatchReconciler should have found subscriptionOrderShouldNotHaveCFD to have a CFD when it should not');
    }
}