/**
 * Created by peteryao on 9/25/20.
 */
@IsTest
public with sharing class EntitySelectorTest {
    @IsTest
    private static void testGetContractAssignmentEntitiesForClient() {
        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );
        insert eversource;

        Product2 normalCSProduct = new Product2(Name = 'BlueWave Community Solar',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = true);
        insert normalCSProduct;

        Account clientAccount = new Account(Name = 'Test Client');
        Account ampAccount = new Account(Name = 'AMP');
        insert new List<Account>{ampAccount, clientAccount};

        Entity__c entity1 = new Entity__c(
            Name = 'Project A Oak Road',
            Client_Account__c = clientAccount.Id
        );
        Entity__c entity2 = new Entity__c(
            Name = 'Project B Oak Road',
            Client_Account__c = clientAccount.Id
        );
        insert new List<Entity__c>{entity1, entity2};

        Shared_Solar_System__c sss1 =
            new Shared_Solar_System__c(Name = 'Project A Oak Road',
                Service_Territory__c = 'SEMA',
                Client_Account__c = clientAccount.Id,
                System_Utility__c = 'Eversource',
                Product__c = normalCSProduct.Id,
                BWC_Project_Entity_Manual__c = entity1.Id,
                Utility__c = eversource.Id,
                Contract_Assignment_Entity__c = entity1.Id
            );
        Shared_Solar_System__c sss2 =
            new Shared_Solar_System__c(Name = 'Project B Oak Road',
                Service_Territory__c = 'SEMA',
                Client_Account__c = clientAccount.Id,
                System_Utility__c = 'Eversource',
                Product__c = normalCSProduct.Id,
                BWC_Project_Entity_Manual__c = entity2.Id,
                Utility__c = eversource.Id,
                Contract_Assignment_Entity__c = entity2.Id
            );
        Shared_Solar_System__c sss3 =
            new Shared_Solar_System__c(Name = 'Project B Oak Road',
                Service_Territory__c = 'SEMA',
                Client_Account__c = clientAccount.Id,
                System_Utility__c = 'Eversource',
                Product__c = normalCSProduct.Id,
                BWC_Project_Entity_Manual__c = entity1.Id,
                Utility__c = eversource.Id,
                Contract_Assignment_Entity__c = entity1.Id
            );
        insert new List<Shared_Solar_System__c>{sss1, sss2, sss3};

        Test.startTest();
        EntitySelector entitySelector = new EntitySelector();
        List<List<Entity__c>> testClientEntities = InvocableEntitySelector.getContractAssignmentEntitiesByClient(new List<Id>{clientAccount.Id});
        System.assertEquals(1, testClientEntities.size(),
            'Expected to find a single list of entities since to support the invocable method');
        System.assertEquals(2, testClientEntities[0].size(),
            'Test Client should have two entities: A and B');
        System.assertEquals(0, entitySelector.getContractAssignmentEntitiesForClient(ampAccount.Id).size(),
            'Did not expect to find an entity for Amp');
        Test.stopTest();
    }
}