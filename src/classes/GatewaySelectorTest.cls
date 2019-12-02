@isTest
public class GatewaySelectorTest {
    @testSetup public static void testDataSetup() {
        Account bwAccount = new Account(Name = 'BlueWave');
        Account clientAccount = new Account(Name = 'Client');
        insert new List<Account>{bwAccount,clientAccount};


        Zuora__PaymentGateway__c clientGateway = new Zuora__PaymentGateway__c(
            Name = 'Other Client Gateway',
            Client_Owner__c = clientAccount.Id
        );
        Zuora__PaymentGateway__c bwGateway = new Zuora__PaymentGateway__c(
            Name = 'BCS Single Gateway',
            Client_Owner__c = bwAccount.Id
        );
        insert new List<Zuora__PaymentGateway__c>{clientGateway,bwGateway};
    }

    @isTest
    private static void testZuoraGatewayQuery() {
        GatewaySelector gatewaySelect = new GatewaySelector();
        List<Zuora__PaymentGateway__c> gateways = gatewaySelect.getAllZuoraGateways();
        System.assertEquals(2,gateways.size());
    }
}