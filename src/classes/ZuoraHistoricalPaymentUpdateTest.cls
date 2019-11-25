@IsTest
public with sharing class ZuoraHistoricalPaymentUpdateTest {
    @TestSetup
    public static void testSetup(){
        ZuoraAPIHelperTest.testSetup();
    }

    private static ZuoraHistoricalPaymentUpdate batchUpdate = new ZuoraHistoricalPaymentUpdate();

    public static void useMocks() {
        batchUpdate.transactionSelector = (ChargentTransactionSelector) Test.createStub(ChargentTransactionSelector.class, new MockChargentTransactionSelector());
    }

    @IsTest
    public static void testDataQuerySubmittal() {
        Test.startTest();
            ZuoraHistoricalPaymentUpdate.queueDataQueryForHistoricPayments();
            ZuoraHistoricalPaymentUpdate.queueDataQueryForReturnedPayments();
        Test.stopTest();

        List<Zuora_Data_Query__c> dataQuery = [
            SELECT Id
            FROM Zuora_Data_Query__c
        ];
        System.assertEquals(2,dataQuery.size());
    }

    @IsTest
    public static void testChargentFieldUpdates() {
        useMocks();
        String dataString = '[' +
            '{"Id":"2c92c0fa6e3a938d016e3e55343f41c5","TransactionId_Zcustom":"a21S00000011rB7IAA"},' +
            '{"Id":"2c92c0fa6e3a938d016e3e553bed41ee","TransactionId_Zcustom":"a21S00000011rB7IAB"},' +
            '{"Id":"2c92c0fa6e3a938d016e3e553e77420e","TransactionId_Zcustom":"a21S00000011rB7IAC"},' +
            '{"Id":"2c92c0fa6e3a938d016e3e55400c4216","TransactionId_Zcustom":"a21S00000011rB7IAD"},' +
            '{"Id":"2c92c0fa6e3a938d016e3e55421b421e","TransactionId_Zcustom":"a21S00000011rB7IAE"}]';

        batchUpdate.paymentsToUpdate = (Set<ZuoraAPI.Payment>)JSON.deserialize(dataString, Set<ZuoraAPI.Payment>.class);
        batchUpdate.updatedPayments = new Set<ZuoraAPI.Payment>();
        batchUpdate.isPayment = true;
        batchUpdate.historicalChargentDataMigration();

        List<Error_Log__c> logs = [
            SELECT Id, Message__c, Method__c
            FROM Error_Log__c
        ];

        system.debug(logs);

        System.assertEquals(5,batchUpdate.updatedPayments.size());
        List<ZuoraAPI.Payment> updatedPaymentList = new List<ZuoraAPI.Payment>();
        updatedPaymentList.addAll(batchUpdate.updatedPayments);

        ZuoraAPI.ArchivedChargentData chargentData;

        chargentData = (ZuoraAPI.ArchivedChargentData)System.JSON.deserialize(updatedPaymentList[0].ArchivedChargentData_Zcustom, ZuoraAPI.ArchivedChargentData.class);
        System.assertEquals('BWTrust',chargentData.GatewayName);
        System.assertEquals('BW-0028241',chargentData.ClientNumber);
        System.assertEquals('Check',chargentData.PaymentMethod);
        System.assertEquals('xxx12345679',chargentData.GatewayRefId);

        chargentData = (ZuoraAPI.ArchivedChargentData)System.JSON.deserialize(updatedPaymentList[1].ArchivedChargentData_Zcustom, ZuoraAPI.ArchivedChargentData.class);
        System.assertEquals('Gateway One',chargentData.GatewayName);
        System.assertEquals('BW-000123333',chargentData.ClientNumber);
        System.assertEquals('ACH',chargentData.PaymentMethod);
        System.assertEquals('xxx12345679',chargentData.GatewayRefId);

        chargentData = (ZuoraAPI.ArchivedChargentData)System.JSON.deserialize(updatedPaymentList[2].ArchivedChargentData_Zcustom, ZuoraAPI.ArchivedChargentData.class);
        System.assertEquals('Gateway Two',chargentData.GatewayName);
        System.assertEquals('BW-000123333',chargentData.ClientNumber);
        System.assertEquals('CreditCard',chargentData.PaymentMethod);
        System.assertEquals('xxx12345679',chargentData.GatewayRefId);

        chargentData = (ZuoraAPI.ArchivedChargentData)System.JSON.deserialize(updatedPaymentList[3].ArchivedChargentData_Zcustom, ZuoraAPI.ArchivedChargentData.class);
        System.assertEquals('Gateway Two',chargentData.GatewayName);
        System.assertEquals('BW-000123333',chargentData.ClientNumber);
        System.assertEquals('ACH',chargentData.PaymentMethod);
        System.assertEquals('xxx12345679',chargentData.GatewayRefId);

        chargentData = (ZuoraAPI.ArchivedChargentData)System.JSON.deserialize(updatedPaymentList[4].ArchivedChargentData_Zcustom, ZuoraAPI.ArchivedChargentData.class);
        System.assertEquals('Gateway Three',chargentData.GatewayName);
        System.assertEquals('BW-000123333',chargentData.ClientNumber);
        System.assertEquals('CreditCard',chargentData.PaymentMethod);
        System.assertEquals('xxx12345679',chargentData.GatewayRefId);
    }

  /**************
  *** MOCKS ***
  *************/

    public class MockChargentTransactionSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getTransactionsById' {
                    Map<Id,ChargentOrders__Transaction__c> trxMap = new Map<Id,ChargentOrders__Transaction__c>();
                    ChargentOrders__Transaction__c trxOne = getTransaction('Check (Paper)','Gateway One');
                    ChargentOrders__Transaction__c trxTwo = getTransaction('Check','Gateway One');
                    ChargentOrders__Transaction__c trxThree = getTransaction('Credit Card','Gateway Two');
                    ChargentOrders__Transaction__c trxFour = getTransaction('Check','Gateway Two');
                    ChargentOrders__Transaction__c trxFive = getTransaction('Credit Card','Gateway Three');
                    String trxIdMinus1Digit = 'a21S00000011rB7IA';
                    trxMap.put(trxIdMinus1Digit + 'A',trxOne);
                    trxMap.put(trxIdMinus1Digit + 'B',trxTwo);
                    trxMap.put(trxIdMinus1Digit + 'C',trxThree);
                    trxMap.put(trxIdMinus1Digit + 'D',trxFour);
                    trxMap.put(trxIdMinus1Digit + 'E',trxFive);
                    return trxMap;
                }
            }
            return null;
        }

        private ChargentOrders__Transaction__c getTransaction(String paymentMethod, String gatewayName) {
            String serialized = '{' +
                '"attributes" : {' +
                '"type" : "ChargentOrders__Transaction__c",' +
                '"url" : "/services/data/v46.0/sobjects/ChargentOrders__Transaction__c/a21S00000011rB7IAI"' +
                '},' +
                '"Id" : "a21S00000011rB7IAI",' +
                '"ChargentOrders__Amount__c" : 1668.299,' +
                '"ChargentOrders__Gateway_ID__c" : "xxx12345679",'+
                '"ChargentOrders__Order__c" : "a1yS0000000tv4wIAA",' +
                '"Client__c" : "001S000000yKIOEIA4",' +
                '"CreatedDate" : "2019-06-20T04:20:19.000+0000",' +
                '"ChargentOrders__Order__r" : {' +
                '"attributes" : {' +
                '"type" : "ChargentOrders__ChargentOrder__c",' +
                '"url" : "/services/data/v46.0/sobjects/ChargentOrders__ChargentOrder__c/a1yS0000000tv4wIAA"' +
                '},' +
                '"Id" : "a1yS0000000tv4wIAA",' +
                '"ChargentOrders__Payment_Method__c" : "' + paymentMethod + '",' +
                '"Entity__c" : "a1IS0000002MNiPMAW",' +
                '"Account_Bill__r":{"attributes":{"type":"Account_Bill__c","url":"/services/data/v46.0/sobjects/Account_Bill__c/a1n0a000002wHyNAAU"},' +
                '"Id":"a1n0a000002wHyNAAU",' +
                '"Parent_Account__c":"001j000000kWP1CAAW",' +
                '"Parent_Account__r":{"attributes":{"type":"Account","url":"/services/data/v46.0/sobjects/Account/001j000000kWP1CAAW"},' +
                '"Id":"001j000000kWP1CAAW",' +
                '"Zuora_Id__c":"2c92c0f96c8afb5d016c8c5b4d4c7b6e"}' +
                '}' +
                '},' +
                '"Client__r" : {' +
                '"attributes" : {' +
                '"type" : "Account",' +
                '"url" : "/services/data/v46.0/sobjects/Account/001S000000yKIOEIA4"' +
                '},' +
                '"Id" : "001S000000yKIOEIA4",' +
                '"Account_Number__c" : "BW-000123333"' +
                '},'+
                '"ChargentOrders__Gateway__r" : {' +
                '"attributes" : {' +
                '"type" : "ChargentOrders__Gateway__c",' +
                '"url" : "/services/data/v46.0/sobjects/ChargentOrders__Gateway__c/a1yS0000000tv4yICC"' +
                '},' +
                '"Id" : "a1yS0000000tv4yICC",' +
                '"Name" : "' + gatewayName + '"}' +
                '}';
            return (ChargentOrders__Transaction__c) JSON.deserialize(serialized, ChargentOrders__Transaction__c.class);
        }
    }
}