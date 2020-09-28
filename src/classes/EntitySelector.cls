/**
 * Created by peteryao on 9/25/20.
 * Tested by: EntitySelectorTest
 */

public inherited sharing class EntitySelector {
    public List<Entity__c> getContractAssignmentEntitiesForClient(Id accountId) {
        List<AggregateResult> sharedSolarSystems = [
            SELECT Contract_Assignment_Entity__c Id, Contract_Assignment_Entity__r.Name Name
            FROM Shared_Solar_System__c
            WHERE Client_Account__c = :accountId
            AND Contract_Assignment_Entity__c != NULL
            GROUP BY Contract_Assignment_Entity__c, Contract_Assignment_Entity__r.Name
        ];
        List<Entity__c> entities = new List<Entity__c>();
        for (AggregateResult aggregateResult : sharedSolarSystems) {
            entities.add(new Entity__c(
                Id = (Id) aggregateResult.get('Id'),
                Name = (String) aggregateResult.get('Name')
            ));
        }
        return entities;
    }
}