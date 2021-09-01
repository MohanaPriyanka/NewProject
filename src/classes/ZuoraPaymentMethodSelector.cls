public with sharing class ZuoraPaymentMethodSelector {
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static String getDefaultPaymentMethodId () {
        String queryString =
            'SELECT Id, AccountId ' +
            'FROM PaymentMethod ' +
            'WHERE Type = \'Cash\' ' +
            'AND AccountId = NULL LIMIT 1';
        String result = ZuoraAPIHelper.query(queryString, false);
        ZuoraAPI.ZuoraQueryResult queryResult = (ZuoraAPI.ZuoraQueryResult) JSON.deserialize(result, ZuoraAPI.ZuoraQueryResult.class);
        if (queryResult.records.size() >= 1) {
            return queryResult.records[0].Id;
        } else {
            throw new Util.FatalBWException('Did not find a default payment method id to use');
        }
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public Zuora__PaymentMethod__c getSFRecordFromZuoraId(String zuoraId) {
        List<Zuora__PaymentMethod__c> paymentMethods = [
            SELECT Id, Zuora__External_Id__c, Zuora__Type__c
            FROM Zuora__PaymentMethod__c
            WHERE Zuora__External_Id__c = :zuoraId
        ];
        if (paymentMethods.size() > 0) {
            return paymentMethods[0];
        }
        return null;
    }
}