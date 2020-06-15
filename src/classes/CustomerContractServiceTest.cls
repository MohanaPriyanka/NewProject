/**
 * Created by Lindsay Holmes (Gears CRM) on 2020-05-25.
 */


 @IsTest
 private class CustomerContractServiceTest {
     @TestSetup
     static void makeData(){
        Product2 product = new Product2(
            Name = 'CS Product',
            Generic_Terms_Conga_Template__c = null
        );
        insert product;
        
        Lead lead = new Lead(
            FirstName = 'System',
            LastName = 'Testcase',
            Email = 'test@invalid.bluewavesolar.com',
            Company = 'System Testcase',
            LeadSource = 'Website',
            Phone = '4444444444',
            Product__c = product.Id
        );
        insert lead;
        
        Account propertyAccount = new Account(
            Lead__c = lead.Id,
            Name = 'test account'
        );
        insert propertyAccount;
    }
    
    
    @IsTest
    static void testCreateContractFromLeadGeneric(){
        Lead lead = [SELECT Id, Product__c, (SELECT Id FROM Accounts__r) FROM Lead LIMIT 1];
        Product2 product = new Product2(Id = lead.Product__c, Generic_Terms_Conga_Template__c = '12345');
        update product;
        CustomerContractService ccs = new CustomerContractService();
        Contract contract = ccs.createContractFromLead(lead.Id);

        System.assertNotEquals(null, contract, 'Method should have created and returned a Contract record');
        System.assertEquals(lead.Id, contract.Lead__c, 'Contract lead__c should be the input lead');
        System.assertEquals(lead.Product__c, contract.Product__c, 'Contract product__c should reflect the product on the related lead');
        System.assertEquals(Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('Customer_Contract').getRecordTypeId(), contract.RecordTypeId, 'Contract record type should be \"Customer Contract\"');
        System.assertEquals(lead.Accounts__r[0].Id, contract.AccountId, 'Contract accountid should reflect the oldest property account on the related lead');
        System.assertEquals('Generic', contract.Contract_Type__c, 'Contract type should be \"Generic\" because Product__c has an associated generic Conga template');
    }
    

    @IsTest
    static void testCreateContractFromLeadProjectSpecific(){
        Lead lead = [SELECT Id, Product__c, (SELECT Id FROM Accounts__r) FROM Lead LIMIT 1];
        CustomerContractService ccs = new CustomerContractService();
        Contract contract = ccs.createContractFromLead(lead.Id);

        System.assertNotEquals(null, contract, 'Method should have created and returned a Contract record');
        System.assertEquals(lead.Id, contract.Lead__c, 'Contract lead__c should be the input lead');
        System.assertEquals(lead.Product__c, contract.Product__c, 'Contract product__c should reflect the product on the related lead');
        System.assertEquals(Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('Customer_Contract').getRecordTypeId(), contract.RecordTypeId, 'Contract record type should be \"Customer Contract\"');
        System.assertEquals(lead.Accounts__r[0].Id, contract.AccountId, 'Contract accountid should reflect the oldest property account on the related lead');
        System.assertEquals('Project Specific', contract.Contract_Type__c, 'Contract type should be \"Project Specific\" because Product__c has an associated generic Conga template');
    }
}