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
        Contract contract = ccs.createContractFromLead(lead.Id, 1);

        System.assertNotEquals(null, contract, 'Method should have created and returned a Contract record');
        System.assertEquals(lead.Id, contract.Lead__c, 'Contract lead__c should be the input lead');
        System.assertEquals(lead.Product__c, contract.Product__c, 'Contract product__c should reflect the product on the related lead');
        System.assertEquals(Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('Customer_Contract').getRecordTypeId(), contract.RecordTypeId, 'Contract record type should be \"Customer Contract\"');
        System.assertEquals(lead.Accounts__r[0].Id, contract.AccountId, 'Contract accountid should reflect the oldest property account on the related lead');
        System.assertEquals('Generic', contract.Contract_Type__c, 'Contract type should be \"Generic\" because Product__c has an associated generic Conga template');
        System.assert(!contract.Generate_Disclosure_Form__c, 'Contract should not generate a disclosure form, as the number of contract documents is 1');
    }
    

    @IsTest
    static void testCreateContractFromLeadProjectSpecific(){
        Lead lead = [SELECT Id, Product__c, (SELECT Id FROM Accounts__r) FROM Lead LIMIT 1];
        CustomerContractService ccs = new CustomerContractService();
        Contract contract = ccs.createContractFromLead(lead.Id, 2);

        System.assertNotEquals(null, contract, 'Method should have created and returned a Contract record');
        System.assertEquals(lead.Id, contract.Lead__c, 'Contract lead__c should be the input lead');
        System.assertEquals(lead.Product__c, contract.Product__c, 'Contract product__c should reflect the product on the related lead');
        System.assertEquals(Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('Customer_Contract').getRecordTypeId(), contract.RecordTypeId, 'Contract record type should be \"Customer Contract\"');
        System.assertEquals(lead.Accounts__r[0].Id, contract.AccountId, 'Contract accountid should reflect the oldest property account on the related lead');
        System.assertEquals('Project Specific', contract.Contract_Type__c, 'Contract type should be \"Project Specific\" because Product__c has an associated generic Conga template');
        System.assert(contract.Generate_Disclosure_Form__c, 'Contract should generate a disclosure form, as the number of contract documents is 2');
    }


    @IsTest
    static void testFailCreateContractFromLead() {
        Lead lead = new Lead(
            FirstName = 'System',
            LastName = 'Testcase',
            Email = 'test@invalid.bluewavesolar.com',
            Company = 'System Testcase',
            LeadSource = 'Website',
            Phone = '4444444444'
        );
        insert lead;

        Boolean expectedResult = false;
        try {
            CustomerContractService ccs = new CustomerContractService();
            ccs.createContractFromLead(lead.Id, 1);
            System.assert(false, 'Method should have thrown an error due to missing child Account');
        } catch(Util.BWException bwe) {
            expectedResult = true;
        } catch(Exception ex) {
            System.assert(false, 'Method should have thrown a custom BW exception due to missing child Account; instead exception is ' + ex);
        }
        System.assert(expectedResult, 'Method should have thrown a custom BW exception due to missing child Account');
    }


    @IsTest
    static void testRegenerateDocs() {
        Lead lead = [SELECT Id, Product__c, (SELECT Id FROM Accounts__r) FROM Lead LIMIT 1];
        Lead lead2 = new Lead(
            FirstName = 'System2',
            LastName = 'Testcase2',
            Email = 'test2@invalid.bluewavesolar.com',
            Company = 'System2 Testcase2',
            LeadSource = 'Website',
            Phone = '2222222222'
        );
        insert lead2;
        Account acct = new Account(
            Lead__c = lead2.Id,
            Name = 'test2 account'
        );
        insert acct;
        
        Id recordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('Customer_Contract').getRecordTypeId();
        Contract c1 = new Contract(Lead__c = lead.Id, AccountId = lead.Accounts__r[0].Id, RecordTypeId = recordTypeId);
        Contract c2 = new Contract(Lead__c = lead.Id, AccountId = lead.Accounts__r[0].Id, RecordTypeId = recordTypeId);
        Contract cDiff = new Contract(Lead__c = lead2.Id, AccountId = acct.Id, RecordTypeId = recordTypeId);
        insert new List<Contract>{c1, c2, cDiff};

        List<Contract> lead1Contracts = [SELECT Id, Generate_Review_Version__c FROM Contract WHERE Lead__c = :lead.Id];
        List<Contract> lead2Contracts = [SELECT Id, Generate_Review_Version__c FROM Contract WHERE Lead__c = :lead2.Id];
        System.assertEquals(2, lead1Contracts.size(), 'Expected 2 contracts associated with the first lead');
        System.assertEquals(1, lead2Contracts.size(), 'Expected 1 contract associated with the second lead');
        System.assert(!lead1Contracts[0].Generate_Review_Version__c, 'Generate_Review_Version__c should be false before call to regenerate method');
        System.assert(!lead1Contracts[1].Generate_Review_Version__c, 'Generate_Review_Version__c should be false before call to regenerate method');
        System.assert(!lead2Contracts[0].Generate_Review_Version__c, 'Generate_Review_Version__c should be false before call to regenerate method');

        Test.startTest();
            CustomerContractService ccs = new CustomerContractService();
            ccs.regenerateDocuments(lead.Id);
        Test.stopTest();

        List<Error_Log__c> errorLogs = [SELECT Id, Message__c FROM Error_Log__c WHERE Class__c = 'CustomerContractService' AND Method__c = 'regenerateDocuments'];
        lead1Contracts = [SELECT Id, Generate_Review_Version__c FROM Contract WHERE Lead__c = :lead.Id];
        lead2Contracts = [SELECT Id, Generate_Review_Version__c FROM Contract WHERE Lead__c = :lead2.Id];
        System.assert(errorLogs.isEmpty(), 'No error logs should have been generated by the operation; instead there was ' + errorLogs);
        System.assertEquals(2, lead1Contracts.size(), 'Expected 2 contracts associated with the first lead');
        System.assertEquals(1, lead2Contracts.size(), 'Expected 1 contract associated with the second lead');
        System.assert(lead1Contracts[0].Generate_Review_Version__c, 'Generate_Review_Version__c should be true after call to regenerate method for lead specified in call');
        System.assert(lead1Contracts[1].Generate_Review_Version__c, 'Generate_Review_Version__c should be true after call to regenerate method for lead specified in call');
        System.assert(!lead2Contracts[0].Generate_Review_Version__c, 'Generate_Review_Version__c should be false after call to regenerate method for lead NOT specified in call');
    }


    @IsTest
    static void testSignDocs() {
        Lead lead = [SELECT Id, Product__c, (SELECT Id FROM Accounts__r) FROM Lead LIMIT 1];
        Lead lead2 = new Lead(
            FirstName = 'System2',
            LastName = 'Testcase2',
            Email = 'test2@invalid.bluewavesolar.com',
            Company = 'System2 Testcase2',
            LeadSource = 'Website',
            Phone = '2222222222'
        );
        insert lead2;
        Account acct = new Account(
            Lead__c = lead2.Id,
            Name = 'test2 account'
        );
        insert acct;
        
        Id recordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('Customer_Contract').getRecordTypeId();
        Contract c1 = new Contract(Lead__c = lead.Id, AccountId = lead.Accounts__r[0].Id, RecordTypeId = recordTypeId);
        Contract c2 = new Contract(Lead__c = lead.Id, AccountId = lead.Accounts__r[0].Id, RecordTypeId = recordTypeId);
        Contract cDiff = new Contract(Lead__c = lead2.Id, AccountId = acct.Id, RecordTypeId = recordTypeId);
        insert new List<Contract>{c1, c2, cDiff};

        List<Contract> lead1Contracts = [SELECT Id, Generate_Signed_Version__c, Customer_Signature_Date_Time__c FROM Contract WHERE Lead__c = :lead.Id];
        List<Contract> lead2Contracts = [SELECT Id, Generate_Signed_Version__c, Customer_Signature_Date_Time__c FROM Contract WHERE Lead__c = :lead2.Id];
        System.assertEquals(2, lead1Contracts.size(), 'Expected 2 contracts associated with the first lead');
        System.assertEquals(1, lead2Contracts.size(), 'Expected 1 contract associated with the second lead');
        System.assert(!lead1Contracts[0].Generate_Signed_Version__c, 'Generate_Signed_Version__c should be false before call to regenerate method');
        System.assertEquals(null, lead1Contracts[0].Customer_Signature_Date_Time__c, 'Customer_Signature_Date_Time__c should be null before call to regenerate method');
        System.assert(!lead1Contracts[1].Generate_Signed_Version__c, 'Generate_Signed_Version__c should be false before call to regenerate method');
        System.assertEquals(null, lead1Contracts[1].Customer_Signature_Date_Time__c, 'Customer_Signature_Date_Time__c should be null before call to regenerate method');
        System.assert(!lead2Contracts[0].Generate_Signed_Version__c, 'Generate_Signed_Version__c should be false before call to regenerate method');
        System.assertEquals(null, lead2Contracts[0].Customer_Signature_Date_Time__c, 'Customer_Signature_Date_Time__c should be null before call to regenerate method');

        Test.startTest();
            CustomerContractService ccs = new CustomerContractService();
            ccs.signCustomerContracts(lead.Id);
        Test.stopTest();

        Date today = Datetime.now().date();
        List<Error_Log__c> errorLogs = [SELECT Id, Message__c FROM Error_Log__c WHERE Class__c = 'CustomerContractService' AND Method__c = 'regenerateDocuments'];
        lead1Contracts = [SELECT Id, Generate_Signed_Version__c, Customer_Signature_Date_Time__c FROM Contract WHERE Lead__c = :lead.Id];
        lead2Contracts = [SELECT Id, Generate_Signed_Version__c, Customer_Signature_Date_Time__c FROM Contract WHERE Lead__c = :lead2.Id];
        System.assert(errorLogs.isEmpty(), 'No error logs should have been generated by the operation; instead there was ' + errorLogs);
        System.assertEquals(2, lead1Contracts.size(), 'Expected 2 contracts associated with the first lead');
        System.assertEquals(1, lead2Contracts.size(), 'Expected 1 contract associated with the second lead');
        System.assert(lead1Contracts[0].Generate_Signed_Version__c, 'Generate_Signed_Version__c should be true after call to regenerate method for lead specified in call');
        System.assertEquals(today, lead1Contracts[0].Customer_Signature_Date_Time__c.date(), 'Customer_Signature_Date_Time__c should be today after call to regenerate method for lead specified in call');
        System.assert(lead1Contracts[1].Generate_Signed_Version__c, 'Generate_Signed_Version__c should be true after call to regenerate method for lead specified in call');
        System.assertEquals(today, lead1Contracts[1].Customer_Signature_Date_Time__c.date(), 'Customer_Signature_Date_Time__c should be today after call to regenerate method for lead specified in call');
        System.assert(!lead2Contracts[0].Generate_Signed_Version__c, 'Generate_Signed_Version__c should be false after call to regenerate method for lead NOT specified in call');
        System.assertEquals(null, lead2Contracts[0].Customer_Signature_Date_Time__c, 'Customer_Signature_Date_Time__c should be null after call to regenerate method for lead NOT specified in call');
    }


    @IsTest
    static void testSignDocsFail() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        Boolean expectedResult = false;
        Test.startTest();
            try {
                CustomerContractService ccs = new CustomerContractService();
                ccs.signCustomerContracts(lead.Id);
                System.assert(false, 'Method should have thrown an error, as there are no contracts associated with the lead');
            } catch(Util.BWException bwe) {
                expectedResult = true;
            } catch(Exception ex) {
                System.assert(false, 'Method should have thrown a custom BW exception, as there are no contracts associated with the lead; instead exception is ' + ex);
            }
        Test.stopTest();

        System.assert(expectedResult, 'Method should have thrown a custom BW exception, as there are no contracts associated with the lead');
    }


    @IsTest
    static void testCreateForOpportunity() {
        Lead lead = [SELECT Id, Product__c, (SELECT Id FROM Accounts__r) FROM Lead LIMIT 1];
        
        CustomerContractService ccs = new CustomerContractService();
        Contract parentContract = ccs.createContractFromLead(lead.Id, null);
        parentContract.Customer_Signature_Date_Time__c = Date.today();
        update parentContract;
        
        Opportunity opp = new Opportunity();
        opp.Lead__c = lead.Id;
        opp.Product__c = lead.Product__c;
        opp.AccountId = lead.Accounts__r[0].Id;

        Contract contract = CustomerContractService.createForOpportunity(opp, parentContract);
        System.assertNotEquals(null, contract, 'Method should have created and returned a Contract record');
        System.assertEquals(lead.Id, contract.Lead__c, 'Contract lead__c should be the input lead');
        System.assertEquals(lead.Product__c, contract.Product__c, 'Contract product__c should reflect the product on the related lead');
        System.assertEquals(Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('Customer_Contract').getRecordTypeId(), contract.RecordTypeId, 'Contract record type should be \"Customer Contract\"');
        System.assertEquals(lead.Accounts__r[0].Id, contract.AccountId, 'Contract accountid should reflect the oldest property account on the related lead');
        System.assertEquals('Project Specific', contract.Contract_Type__c, 'Contract type should be \"Project Specific\" because Product__c has an associated generic Conga template');
        System.assertEquals(parentContract.Id, contract.Parent_Contract__c, 'Parent contract should be the contract input into the method');
    }
}