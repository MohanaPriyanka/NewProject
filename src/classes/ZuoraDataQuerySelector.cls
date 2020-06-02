/**
 * Created by peteryao on 5/28/20.
 */

public inherited sharing class ZuoraDataQuerySelector {
    public Zuora_Data_Query__c selectDataQueryById(Id dataQueryId) {
        Zuora_Data_Query__c dataQuery = [
            SELECT Id, Processing_Parameter__c, Data_From_Zuora__c
            FROM Zuora_Data_Query__c
            WHERE Id = :dataQueryId
        ];
        return dataQuery;
    }
}