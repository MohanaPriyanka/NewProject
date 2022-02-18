/**
 * Created by peteryao on 7/27/20.
 * Tested By: ZuoraContactSelectorTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class ZuoraContactSelector {
    public List<Zuora_Contact__c> selectAll(Set<String> zuoraContactIds) {
        return [
            SELECT Id, Name, Contact__c, Zuora_Id__c
            FROM Zuora_Contact__c
            WHERE Zuora_Id__c IN :zuoraContactIds
        ];
    }
}