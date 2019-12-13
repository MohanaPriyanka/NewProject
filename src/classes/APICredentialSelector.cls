/**
 * Created by PeterYao on 12/9/2019.
 * Tested By: APICredentialSelector
 */

public without sharing class APICredentialSelector {
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public List<API_Credential__c> getApiCredentials(String name) {
        name = '%' + name + '%';
        return [
            SELECT Id, Credential_Id__c, Credential_Secret__c, Name
            FROM API_Credential__c
            WHERE Name LIKE :name
        ];
    }
}