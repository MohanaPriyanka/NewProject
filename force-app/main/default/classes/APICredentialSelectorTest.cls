/**
 * Created by PeterYao on 12/9/2019.
 */
@IsTest
public with sharing class APICredentialSelectorTest {
    @IsTest
    private static void testGetCredentials() {
        API_Credential__c apiCredential = new API_Credential__c(
            Name = 'Authorize Credential',
            Credential_Id__c = '123455',
            Credential_Secret__c = 'abcde'
        );
        insert apiCredential;
        API_Credential__c apiCredential2 = new API_Credential__c(
            Name = 'LinkedToPay Credential',
            Credential_Id__c = '123455',
            Credential_Secret__c = 'abcde'
        );
        insert apiCredential2;
        APICredentialSelector apiCredentialSelector = new APICredentialSelector();
        List<API_Credential__c> apiCredentials = apiCredentialSelector.getApiCredentials('Authorize');
        System.assertEquals(1, apiCredentials.size(), 'Expected a single API Credential');
        System.assertEquals(apiCredential.Credential_Id__c, apiCredentials[0].Credential_Id__c, 'Expected to select out the API Credential that was inserted');
    }
}